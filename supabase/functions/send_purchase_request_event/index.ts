import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

/**
 * Отправка push по заявкам на закупку.
 *
 * Вызывается клиентом сразу после действия по заявке (как `send_admin_work_event`
 * для смен). Получатели не вычисляются здесь повторно: функция берёт готовые
 * строки `purchase_request_notifications` с `pushed_at IS NULL` — то есть push
 * уходит ровно тем, кому база уже записала уведомление (участники роли этапа
 * плюс инициатор по согласованиям и оплате).
 *
 * Вход: `{ request_id: string, origin?: string }`.
 * `origin` — адрес сайта, из которого пришёл вызов: нужен для перехода по push
 * на карточку заявки в веб-приложении.
 */

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
  "Access-Control-Allow-Headers": "authorization, apikey, content-type, x-client-info",
};

/** Платформы FCM, на которые отправляем push. */
const PUSH_PLATFORMS = new Set(["ios", "android", "web"]);

/** Иконка в баннере (файл лежит в `react_app/public`). */
const WEB_ICON = "/icon-192.png";

/** Тема APNs нативного iOS-приложения. */
const APNS_TOPIC = "com.projectgt.stroyka";

/** Получение access token сервисного аккаунта Firebase (FCM HTTP v1). */
async function getFcmAccessToken(serviceAccountJson: string) {
  const sa = JSON.parse(serviceAccountJson);
  const now = Math.floor(Date.now() / 1000);
  const header = { alg: "RS256", typ: "JWT" };
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
    { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
    false,
    ["sign"],
  );

  const sig = new Uint8Array(
    await crypto.subtle.sign("RSASSA-PKCS1-v1_5", cryptoKey, enc.encode(toSign)),
  );
  const jwt = `${toSign}.${b64url(sig)}`;

  const res = await fetch(sa.token_uri, {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({
      grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
      assertion: jwt,
    }),
  });

  if (!res.ok) throw new Error(`token exchange ${res.status}`);
  const data = await res.json();
  return data.access_token as string;
}

type SupabaseSvc = ReturnType<typeof createClient>;

/** Убираем отключённых сотрудников (`profiles.status === false`). */
async function filterProfilesEligible(
  svc: SupabaseSvc,
  userIds: string[],
): Promise<string[]> {
  if (userIds.length === 0) return [];
  const { data, error } = await svc
    .from("profiles")
    .select("id, status")
    .in("id", userIds);

  if (error) {
    console.error("send_purchase_request_event: profiles_error", error);
    return userIds;
  }

  return (data ?? [])
    .filter((p: { status: boolean | null }) => p.status !== false)
    .map((p: { id: string }) => p.id);
}

/** Один актуальный токен на устройство (ключ `installation_id`), а не один на всю платформу. */
async function resolveDeviceTokens(
  svc: SupabaseSvc,
  userIds: string[],
): Promise<{ user_id: string; token: string; platform: string }[]> {
  if (userIds.length === 0) return [];

  const { data, error } = await svc
    .from("user_tokens")
    .select("user_id, token, platform, installation_id, is_active, updated_at")
    .in("user_id", userIds);

  if (error) {
    console.error("send_purchase_request_event: tokens_error", error);
    return [];
  }

  const active = (data ?? []).filter((t: { is_active: boolean; platform: string }) =>
    t.is_active === true && PUSH_PLATFORMS.has(t.platform)
  );

  const latestByDevice = new Map<
    string,
    { user_id: string; token: string; platform: string; updated_at: string }
  >();

  for (const t of active as Array<{
    user_id: string;
    token: string;
    platform: string;
    installation_id: string | null;
    updated_at: string;
  }>) {
    const deviceKey = t.installation_id
      ? `${t.user_id}:${t.platform}:${t.installation_id}`
      : `${t.user_id}:${t.platform}:${t.token}`;
    const existing = latestByDevice.get(deviceKey);
    if (!existing || t.updated_at > existing.updated_at) {
      latestByDevice.set(deviceKey, {
        user_id: t.user_id,
        token: t.token,
        platform: t.platform,
        updated_at: t.updated_at,
      });
    }
  }

  return [...latestByDevice.values()]
    .filter((entry) => Boolean(entry.token))
    .map(({ user_id, token, platform }) => ({ user_id, token, platform }));
}

/** Безопасный адрес перехода по push: только http(s) и без хвостового слэша. */
function safeOrigin(value: unknown): string | null {
  if (typeof value !== "string" || !value.trim()) return null;
  try {
    const url = new URL(value.trim());
    if (url.protocol !== "http:" && url.protocol !== "https:") return null;
    return url.origin;
  } catch {
    return null;
  }
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { status: 204, headers: corsHeaders });
  }

  if (req.method !== "POST") {
    return new Response("Method Not Allowed", { status: 405, headers: corsHeaders });
  }

  try {
    const body = await req.json() as { request_id?: string; origin?: string };
    const requestId = body.request_id;
    const origin = safeOrigin(body.origin);

    if (!requestId) {
      return new Response(JSON.stringify({ error: "request_id required" }), {
        status: 400,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const url = Deno.env.get("SUPABASE_URL")!;
    const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
    const anonKey = Deno.env.get("SUPABASE_ANON_KEY")!;
    const svcClient = createClient(url, serviceKey);

    // Кто вызвал: любой авторизованный, но только участник компании заявки.
    const authHeader = req.headers.get("Authorization") ?? "";
    const userClient = createClient(url, anonKey, {
      global: { headers: { Authorization: authHeader } },
    });
    const { data: userData } = await userClient.auth.getUser();
    const callerId = userData?.user?.id ?? null;

    if (!callerId) {
      return new Response(JSON.stringify({ error: "unauthorized" }), {
        status: 401,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const { data: request } = await svcClient
      .from("purchase_requests")
      .select("id, company_id, number, status")
      .eq("id", requestId)
      .maybeSingle();

    if (!request) {
      return new Response(JSON.stringify({ error: "request_not_found" }), {
        status: 404,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const { data: membership } = await svcClient
      .from("company_members")
      .select("user_id")
      .eq("company_id", request.company_id)
      .eq("user_id", callerId)
      .eq("is_active", true)
      .maybeSingle();

    if (!membership) {
      return new Response(JSON.stringify({ error: "forbidden" }), {
        status: 403,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // Неотправленные уведомления по этой заявке — источник получателей и текстов.
    const { data: pendingRows, error: pendingError } = await svcClient
      .from("purchase_request_notifications")
      .select("id, user_id, title, body, created_at")
      .eq("request_id", requestId)
      .is("pushed_at", null)
      .order("created_at", { ascending: false });

    if (pendingError) {
      console.error("send_purchase_request_event: pending_error", pendingError);
      throw new Error(pendingError.message);
    }

    const pending = (pendingRows ?? []) as Array<{
      id: string;
      user_id: string;
      title: string | null;
      body: string | null;
      created_at: string;
    }>;

    const ctx = { request_id: requestId, pending: pending.length };
    console.log("send_purchase_request_event: start", ctx);

    if (pending.length === 0) {
      return new Response(JSON.stringify({ sent: 0, pending: 0 }), {
        status: 200,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // По одному самому свежему уведомлению на получателя.
    const latestByUser = new Map<string, { title: string; body: string }>();
    for (const row of pending) {
      if (!latestByUser.has(row.user_id)) {
        latestByUser.set(row.user_id, {
          title: row.title ?? "Заявка на закупку",
          body: row.body ?? "",
        });
      }
    }

    const recipientIds = await filterProfilesEligible(
      svcClient,
      [...latestByUser.keys()],
    );
    const tokens = await resolveDeviceTokens(svcClient, recipientIds);

    /** Отмечаем уведомления отправленными, чтобы не слать их повторно. */
    async function markPushed() {
      const { error } = await svcClient
        .from("purchase_request_notifications")
        .update({ pushed_at: new Date().toISOString() })
        .eq("request_id", requestId)
        .is("pushed_at", null);
      if (error) {
        console.error("send_purchase_request_event: mark_error", error);
      }
    }

    const serviceAccount = Deno.env.get("SERVICE_ACCOUNT");
    if (!serviceAccount) {
      return new Response(JSON.stringify({
        error: "SERVICE_ACCOUNT not set",
        recipients: recipientIds.length,
      }), {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    if (tokens.length === 0) {
      console.log("send_purchase_request_event: no_tokens", {
        ...ctx,
        recipients: recipientIds.length,
      });
      await markPushed();
      return new Response(JSON.stringify({
        sent: 0,
        total: 0,
        recipients: recipientIds.length,
        pending: pending.length,
      }), {
        status: 200,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const accessToken = await getFcmAccessToken(serviceAccount);
    const projectId = JSON.parse(serviceAccount).project_id;
    const link = origin ? `${origin}/purchase-requests?requestId=${requestId}` : null;

    let sent = 0;

    for (const { user_id, token, platform } of tokens) {
      const text = latestByUser.get(user_id);
      if (!text) continue;

      const dataPayload = {
        type: "purchase_request",
        request_id: String(requestId),
        status: String(request.status ?? ""),
      };

      // Веб/PWA: только webpush — без top-level notification, иначе два баннера.
      const payload = platform === "web"
        ? {
          message: {
            token,
            data: dataPayload,
            webpush: {
              headers: { Urgency: "high" },
              notification: {
                title: text.title,
                body: text.body,
                icon: WEB_ICON,
              },
              ...(link ? { fcm_options: { link } } : {}),
            },
          },
        }
        : {
          message: {
            token,
            notification: { title: text.title, body: text.body },
            data: dataPayload,
            apns: {
              headers: {
                "apns-push-type": "alert",
                "apns-priority": "10",
                "apns-topic": APNS_TOPIC,
              },
              payload: { aps: { sound: "default" } },
            },
            android: {
              priority: "HIGH",
              notification: { sound: "default" },
            },
          },
        };

      const response = await fetch(
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

      if (response.ok) {
        sent++;
      } else {
        console.error(
          "send_purchase_request_event: fcm_error",
          response.status,
          await response.text(),
        );
      }
    }

    await markPushed();

    console.log("send_purchase_request_event: summary", {
      ...ctx,
      recipients: recipientIds.length,
      tokens: tokens.length,
      sent,
    });

    return new Response(JSON.stringify({
      sent,
      total: tokens.length,
      recipients: recipientIds.length,
      pending: pending.length,
    }), {
      status: 200,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  } catch (e) {
    console.error("send_purchase_request_event: error", String(e));
    return new Response(JSON.stringify({ error: String(e) }), {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});
