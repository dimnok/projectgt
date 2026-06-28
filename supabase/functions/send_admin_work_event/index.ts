import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
  "Access-Control-Allow-Headers": "authorization, apikey, content-type, x-client-info",
};

/** Роли в `public.roles`, которым шлём push (как в legacy; плюс «Админ»). */
const NOTIFY_ROLE_NAMES = ["Администратор", "Супер-админ", "Админ"] as const;

/** Платформы FCM, на которые отправляем push. */
const PUSH_PLATFORMS = new Set(["ios", "android", "web"]);

// Функция форматирования суммы: 245766 -> "245 766 ₽"
const formatCurrency = (num: number) => {
  const rounded = Math.round(num);
  const formatted = rounded.toString().replace(/\B(?=(\d{3})+(?!\d))/g, " ");
  return `${formatted} ₽`;
};

async function getFcmAccessToken(serviceAccountJson: string) {
  const sa = JSON.parse(serviceAccountJson);
  const now = Math.floor(Date.now() / 1000);
  const header = {
    alg: "RS256",
    typ: "JWT",
  };
  const claim = {
    iss: sa.client_email,
    scope: "https://www.googleapis.com/auth/firebase.messaging",
    aud: sa.token_uri,
    iat: now,
    exp: now + 3600,
  };

  const enc = new TextEncoder();
  const b64url = (u8: Uint8Array) =>
    btoa(String.fromCharCode(...u8)).replace(/\+/g, "-").replace(/\//g, "_").replace(
      /=+$/,
      "",
    );
  const hB64 = b64url(enc.encode(JSON.stringify(header)));
  const cB64 = b64url(enc.encode(JSON.stringify(claim)));
  const toSign = `${hB64}.${cB64}`;

  const keyDer = (() => {
    const body = sa.private_key
      .replace("-----BEGIN PRIVATE KEY-----", "")
      .replace("-----END PRIVATE KEY-----", "")
      .replace(/\n/g, "");
    return Uint8Array.from(atob(body), (c) => c.charCodeAt(0));
  })();

  const cryptoKey = await crypto.subtle.importKey(
    "pkcs8",
    keyDer,
    {
      name: "RSASSA-PKCS1-v1_5",
      hash: "SHA-256",
    },
    false,
    ["sign"],
  );

  const sig = new Uint8Array(
    await crypto.subtle.sign("RSASSA-PKCS1-v1_5", cryptoKey, enc.encode(toSign)),
  );
  const jwt = `${toSign}.${b64url(sig)}`;

  const res = await fetch(sa.token_uri, {
    method: "POST",
    headers: {
      "Content-Type": "application/x-www-form-urlencoded",
    },
    body: new URLSearchParams({
      grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
      assertion: jwt,
    }),
  });

  if (!res.ok) throw new Error(`token exchange ${res.status}`);
  const data = await res.json();
  return data.access_token;
}

type SupabaseSvc = ReturnType<typeof createClient>;

/** Убираем отключённых по `profiles.status === false`. */
async function filterProfilesEligible(
  svc: SupabaseSvc,
  userIds: string[],
): Promise<string[]> {
  if (userIds.length === 0) return [];
  const { data: profs, error: profErr } = await svc
    .from("profiles")
    .select("id, status")
    .in("id", userIds);

  if (profErr) {
    console.error("send_admin_work_event: profiles_error", profErr);
    return userIds;
  }

  return (profs ?? [])
    .filter((p: { status: boolean | null }) => p.status !== false)
    .map((p: { id: string }) => p.id);
}

/**
 * Все активные участники компании смены (без фильтра по роли).
 * По умолчанию шлём всем участникам компании; режим «только админы» — при `notify_all: false` (настройка позже).
 */
async function resolveAllCompanyMemberUserIds(
  svc: SupabaseSvc,
  companyId: string,
): Promise<string[]> {
  const { data: rows, error } = await svc
    .from("company_members")
    .select("user_id")
    .eq("company_id", companyId)
    .eq("is_active", true);

  if (error) {
    console.error("send_admin_work_event: all_company_members_error", error);
    return [];
  }

  const unique = [
    ...new Set((rows ?? []).map((r: { user_id: string }) => r.user_id)),
  ];
  return filterProfilesEligible(svc, unique);
}

/**
 * UUID пользователей, которым нужно отправить push: владельцы компании смены,
 * члены с ролями «Администратор» / «Супер-админ» / «Админ»,
 * все активные «Супер-админ» (глобально), затем фильтр `profiles.status`.
 */
async function resolveAdminUserIds(
  svc: SupabaseSvc,
  companyId: string,
): Promise<string[]> {
  const adminUserIds = new Set<string>();

  const { data: ownerRows, error: ownerErr } = await svc
    .from("company_members")
    .select("user_id")
    .eq("company_id", companyId)
    .eq("is_active", true)
    .eq("is_owner", true);

  if (ownerErr) {
    console.error("send_admin_work_event: company_owners_error", ownerErr);
  } else {
    for (const row of ownerRows ?? []) {
      adminUserIds.add((row as { user_id: string }).user_id);
    }
  }

  const { data: roleRows, error: rolesErr } = await svc
    .from("roles")
    .select("id, role_name, company_id")
    .in("role_name", [...NOTIFY_ROLE_NAMES]);

  if (rolesErr) {
    console.error("send_admin_work_event: roles_error", rolesErr);
    return filterProfilesEligible(svc, [...adminUserIds]);
  }

  if (!roleRows?.length) {
    return filterProfilesEligible(svc, [...adminUserIds]);
  }

  const roleIdsForCompany = roleRows.filter(
    (r: { company_id: string | null }) =>
      r.company_id == null || r.company_id === companyId,
  ).map((r: { id: string }) => r.id);

  const superAdminRole = roleRows.find(
    (r: { role_name: string; company_id: string | null }) =>
      r.role_name === "Супер-админ" && r.company_id == null,
  ) as { id: string } | undefined;

  if (roleIdsForCompany.length > 0) {
    const { data: companyRows, error: cmErr } = await svc
      .from("company_members")
      .select("user_id")
      .eq("company_id", companyId)
      .eq("is_active", true)
      .in("role_id", roleIdsForCompany);

    if (cmErr) {
      console.error("send_admin_work_event: company_members_error", cmErr);
    } else {
      for (const row of companyRows ?? []) {
        adminUserIds.add((row as { user_id: string }).user_id);
      }
    }
  }

  if (superAdminRole) {
    const { data: superRows, error: smErr } = await svc
      .from("company_members")
      .select("user_id")
      .eq("is_active", true)
      .eq("role_id", superAdminRole.id);

    if (smErr) {
      console.error("send_admin_work_event: super_admins_error", smErr);
    } else {
      for (const row of superRows ?? []) {
        adminUserIds.add((row as { user_id: string }).user_id);
      }
    }
  }

  return filterProfilesEligible(svc, [...adminUserIds]);
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response(null, {
      status: 204,
      headers: corsHeaders,
    });
  }

  if (req.method !== "POST") {
    return new Response("Method Not Allowed", {
      status: 405,
      headers: corsHeaders,
    });
  }

  try {
    const requestBody = await req.json() as {
      action?: string;
      work_id?: string;
      /**
       * По умолчанию (`undefined`) — push **всем** активным участникам компании смены.
       * Явно `false` — только админам (роли); для будущей настройки в приложении.
       */
      notify_all?: boolean;
    };
    const { action, work_id, notify_all } = requestBody;
    const notifyAllCompany = notify_all !== false;
    const ctx = {
      action,
      work_id,
      notify_all: notifyAllCompany,
    };
    console.log("send_admin_work_event: start", ctx);

    if (!action || !work_id) {
      return new Response(JSON.stringify({
        error: "action and work_id required",
      }), {
        status: 400,
        headers: {
          ...corsHeaders,
          "Content-Type": "application/json",
        },
      });
    }

    const url = Deno.env.get("SUPABASE_URL")!;
    const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

    const svcClient = createClient(url, serviceKey);

    const { data: work } = await svcClient
      .from("works")
      .select("id, company_id, object_id, opened_by")
      .eq("id", work_id)
      .maybeSingle();

    if (!work) {
      console.log("send_admin_work_event: work_not_found", ctx);
      return new Response(JSON.stringify({
        error: "work_not_found",
      }), {
        status: 404,
        headers: {
          ...corsHeaders,
          "Content-Type": "application/json",
        },
      });
    }

    const companyId = work.company_id as string | null;
    if (!companyId) {
      console.log("send_admin_work_event: work_no_company_id", ctx);
      return new Response(JSON.stringify({
        error: "work_has_no_company_id",
      }), {
        status: 422,
        headers: {
          ...corsHeaders,
          "Content-Type": "application/json",
        },
      });
    }

    const [{ data: obj }, { data: author }, { data: hours }, { data: items }] =
      await Promise.all([
        svcClient.from("objects").select("name").eq("id", work.object_id).maybeSingle(),
        svcClient.from("profiles").select("short_name, full_name").eq(
          "id",
          work.opened_by,
        ).maybeSingle(),
        svcClient.from("work_hours").select("employee_id").eq("work_id", work_id),
        svcClient.from("work_items").select("total").eq("work_id", work_id),
      ]);

    const objectName = obj?.name ?? "Объект";
    const userName = author?.short_name ?? author?.full_name ?? "Пользователь";
    const employeesCount = new Set((hours ?? []).map((h: { employee_id: string }) =>
      h.employee_id
    )).size;

    const sumRaw = (items ?? []).reduce(
      (acc: number, it: { total?: unknown }) =>
        acc +
        (typeof it.total === "number" ? it.total : Number(it.total ?? 0)),
      0,
    );
    const production = employeesCount > 0 ? sumRaw / employeesCount : 0;

    const recipientIds = notifyAllCompany
      ? await resolveAllCompanyMemberUserIds(svcClient, companyId)
      : await resolveAdminUserIds(svcClient, companyId);

    const { data: rawTokens } = await svcClient.from("user_tokens").select(
      "user_id, token, platform, is_active, updated_at",
    ).in(
      "user_id",
      recipientIds.length ? recipientIds : [
        "00000000-0000-0000-0000-000000000000",
      ],
    );

    const activeTokens = (rawTokens ?? []).filter((t: {
      is_active: boolean;
      platform: string;
    }) => t.is_active === true && PUSH_PLATFORMS.has(t.platform));

    // Один актуальный токен на пользователя и платформу (избегаем сотен дублей web).
    const latestByUserPlatform = new Map<string, {
      token: string;
      updated_at: string;
    }>();
    for (const t of activeTokens as Array<{
      user_id: string;
      token: string;
      platform: string;
      updated_at: string;
    }>) {
      const key = `${t.user_id}:${t.platform}`;
      const existing = latestByUserPlatform.get(key);
      if (!existing || t.updated_at > existing.updated_at) {
        latestByUserPlatform.set(key, {
          token: t.token,
          updated_at: t.updated_at,
        });
      }
    }

    const tokens = [...latestByUserPlatform.values()]
      .map((entry) => entry.token)
      .filter(Boolean);

    const diag = {
      admin_count: recipientIds.length,
      notify_all: notifyAllCompany,
      raw_tokens_count: (rawTokens ?? []).length,
      tokens_total: tokens.length,
    };

    if (tokens.length === 0) {
      console.log("send_admin_work_event: no_tokens", {
        ...ctx,
        ...diag,
      });
      return new Response(JSON.stringify({
        sent: 0,
        total: 0,
        ...diag,
      }), {
        status: 200,
        headers: {
          ...corsHeaders,
          "Content-Type": "application/json",
        },
      });
    }

    let title: string;
    let body: string;

    if (action === "open") {
      title = "🔓 Смена - ОТКРЫТА";
      body =
        `📍 Объект: ${objectName}\n👤 Пользователь: ${userName}\n👥 Сотрудников: ${employeesCount}`;
    } else {
      title = "🔒 Смена - ЗАКРЫТА";
      const sumFormatted = Number.isFinite(sumRaw) ? formatCurrency(sumRaw) : "0 ₽";
      const prodFormatted = Number.isFinite(production)
        ? formatCurrency(production)
        : "0 ₽";
      body =
        `📍 Объект: ${objectName}\n👤 Пользователь: ${userName}\n💰 Сумма: ${sumFormatted}\n⚙️ Выработка: ${prodFormatted}`;
    }

    const svc = Deno.env.get("SERVICE_ACCOUNT");
    if (!svc) {
      return new Response(JSON.stringify({
        error: "SERVICE_ACCOUNT not set",
        ...diag,
      }), {
        status: 500,
        headers: {
          ...corsHeaders,
          "Content-Type": "application/json",
        },
      });
    }

    const accessToken = await getFcmAccessToken(svc);
    const projectId = JSON.parse(svc).project_id;

    let sent = 0;

    for (const tk of tokens) {
      const payload = {
        message: {
          token: tk,
          notification: {
            title,
            body,
          },
          data: {
            type: "work_event",
            action,
            work_id: String(work_id),
            object_id: String(work.object_id),
          },
          apns: {
            headers: {
              "apns-push-type": "alert",
              "apns-priority": "10",
              "apns-topic": "com.projectgt.stroyka",
            },
            payload: {
              aps: {
                sound: "default",
              },
            },
          },
          android: {
            priority: "HIGH",
            notification: {
              sound: "default",
            },
          },
          webpush: {
            headers: {
              Urgency: "high",
            },
            notification: {
              title,
              body,
              icon: "/icons/Icon-192.png",
            },
            fcm_options: {
              link: `/works/${work_id}`,
            },
          },
        },
      };

      const r = await fetch(
        `https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`,
        {
          method: "POST",
          headers: {
            Authorization: `Bearer ${accessToken}`,
            "Content-Type": "application/json",
          },
          body: JSON.stringify(payload),
        },
      );

      if (r.ok) sent++;
    }

    console.log("send_admin_work_event: summary", {
      ...ctx,
      ...diag,
      sent,
    });

    return new Response(JSON.stringify({
      sent,
      total: tokens.length,
      ...diag,
    }), {
      status: 200,
      headers: {
        ...corsHeaders,
        "Content-Type": "application/json",
      },
    });
  } catch (e) {
    console.error("send_admin_work_event: error", String(e));
    return new Response(JSON.stringify({
      error: String(e),
    }), {
      status: 500,
      headers: {
        ...corsHeaders,
        "Content-Type": "application/json",
      },
    });
  }
});
