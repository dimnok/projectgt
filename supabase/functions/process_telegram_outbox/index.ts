import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.3";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
  "Access-Control-Allow-Headers":
    "Content-Type, Authorization, x-client-info, apikey"
};

type OutboxRow = {
  id: string;
  company_id: string;
  work_id: string;
  kind: string;
  payload: Record<string, unknown>;
  status: string;
  attempts: number;
  max_attempts: number;
};

async function invokeEdgeFunction(
  supabaseUrl: string,
  serviceKey: string,
  name: string,
  body: Record<string, unknown>
): Promise<{ ok: boolean; status: number; json: Record<string, unknown> | null; text: string }> {
  // ✅ Используем внутренний URL для вызова функций на self-hosted Supabase
  // На данном сервере функции слушают на порту 9999
  const internalUrl = "http://localhost:9999/" + name;
  
  const controller = new AbortController();
  const timeoutId = setTimeout(() => controller.abort(), 40000); // Увеличиваем таймаут до 40 секунд

  try {
    const res = await fetch(internalUrl, {
      method: "POST",
      headers: {
        Authorization: `Bearer ${serviceKey}`,
        apikey: serviceKey,
        "Content-Type": "application/json",
        Accept: "application/json"
      },
      body: JSON.stringify(body),
      signal: controller.signal
    });
    
    const text = await res.text();
    let json: Record<string, unknown> | null = null;
    try {
      json = text ? (JSON.parse(text) as Record<string, unknown>) : null;
    } catch {
      json = null;
    }
    return { ok: res.ok, status: res.status, json, text };
  } catch (err) {
    const isTimeout = err instanceof Error && err.name === "AbortError";
    return { 
      ok: false, 
      status: isTimeout ? 408 : 500, 
      json: null, 
      text: isTimeout ? "Internal timeout" : String(err) 
    };
  } finally {
    clearTimeout(timeoutId);
  }
}

function backoffSeconds(attemptsAfterIncrement: number): number {
  const base = 30 * Math.pow(2, Math.max(0, attemptsAfterIncrement - 1));
  return Math.min(900, Math.floor(base));
}

async function resetStaleProcessing(
  admin: ReturnType<typeof createClient>
): Promise<void> {
  const stale = new Date(Date.now() - 15 * 60 * 1000).toISOString();
  await admin
    .from("telegram_outbox")
    .update({ status: "pending", updated_at: new Date().toISOString() })
    .eq("status", "processing")
    .lt("updated_at", stale);
}

async function markOutcome(
  admin: ReturnType<typeof createClient>,
  row: OutboxRow,
  success: boolean,
  errorMessage: string | null
): Promise<void> {
  const now = new Date().toISOString();
  if (success) {
    await admin
      .from("telegram_outbox")
      .update({ status: "sent", last_error: null, updated_at: now })
      .eq("id", row.id);
    return;
  }
  const nextAttempts = row.attempts + 1;
  const failed = nextAttempts >= row.max_attempts;
  const delaySec = backoffSeconds(nextAttempts);
  const nextRun = new Date(Date.now() + delaySec * 1000).toISOString();
  await admin
    .from("telegram_outbox")
    .update({
      status: failed ? "failed" : "pending",
      attempts: nextAttempts,
      next_run_at: failed ? now : nextRun,
      last_error: errorMessage?.slice(0, 2000) ?? "unknown",
      updated_at: now
    })
    .eq("id", row.id);
}

async function processOpening(
  admin: ReturnType<typeof createClient>,
  supabaseUrl: string,
  serviceKey: string,
  row: OutboxRow
): Promise<{ ok: boolean; err: string | null }> {
  const names = row.payload?.worker_names;
  const workerNames = Array.isArray(names)
    ? (names as unknown[]).map((x) => String(x))
    : [];

  const inv = await invokeEdgeFunction(supabaseUrl, serviceKey, "send_work_opening_report_to_telegram", {
    work_id: row.work_id,
    worker_names: workerNames
  });

  const data = inv.json;
  const success = inv.ok && data?.success === true;
  const messageId = data?.message_id as number | undefined;

  if (success && messageId != null && Number.isFinite(messageId)) {
    await admin
      .from("works")
      .update({ telegram_message_id: messageId })
      .eq("id", row.work_id)
      .eq("company_id", row.company_id);
    return { ok: true, err: null };
  }

  const err =
    (data?.error as string) ||
    inv.text?.slice(0, 500) ||
    `HTTP ${inv.status}`;
  return { ok: false, err };
}

async function processClose(
  admin: ReturnType<typeof createClient>,
  supabaseUrl: string,
  serviceKey: string,
  row: OutboxRow
): Promise<{ ok: boolean; err: string | null }> {
  const { data: workRow, error: wErr } = await admin
    .from("works")
    .select("id, telegram_message_id")
    .eq("id", row.work_id)
    .eq("company_id", row.company_id)
    .maybeSingle();

  if (wErr || !workRow) {
    return { ok: false, err: wErr?.message ?? "work not found" };
  }

  const tgId = workRow.telegram_message_id as number | null | undefined;
  if (tgId != null && Number.isFinite(tgId)) {
    const upd = await invokeEdgeFunction(
      supabaseUrl,
      serviceKey,
      "update_work_opening_report_to_telegram",
      {
        work_id: row.work_id,
        telegram_message_id: tgId
      }
    );
    const uj = upd.json;
    if (!upd.ok || uj?.success !== true) {
      const err =
        (uj?.error as string) || upd.text?.slice(0, 500) || `HTTP ${upd.status}`;
      return { ok: false, err };
    }
  }

  const rep = await invokeEdgeFunction(supabaseUrl, serviceKey, "send_work_report_to_telegram", {
    work_id: row.work_id
  });
  const rj = rep.json;
  if (rep.ok && rj?.success === true) {
    return { ok: true, err: null };
  }
  const err =
    (rj?.error as string) || rep.text?.slice(0, 500) || `HTTP ${rep.status}`;
  return { ok: false, err };
}

serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { status: 204, headers: corsHeaders });
  }

  if (req.method !== "POST") {
    return new Response(JSON.stringify({ error: "Method not allowed" }), {
      status: 405,
      headers: { "Content-Type": "application/json", ...corsHeaders }
    });
  }

  const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
  const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? Deno.env.get("SERVICE_ROLE_KEY") ?? "";
  const anonKey = Deno.env.get("SUPABASE_ANON_KEY") ?? "";
  const workerSecret = Deno.env.get("OUTBOX_WORKER_SECRET") ?? "";

  if (!supabaseUrl || !serviceKey) {
    return new Response(JSON.stringify({ error: "Missing server configuration" }), {
      status: 500,
      headers: { "Content-Type": "application/json", ...corsHeaders }
    });
  }

  const authHeader = req.headers.get("Authorization") ?? "";
  const token = authHeader.replace(/^Bearer\s+/i, "").trim();

  const admin = createClient(supabaseUrl, serviceKey, {
    auth: { persistSession: false }
  });

  await resetStaleProcessing(admin);

  let rows: OutboxRow[] | null = null;
  let fetchError: Error | null = null;

  if (workerSecret && token === workerSecret) {
    const { data, error } = await admin.rpc("claim_telegram_outbox_cron", {
      p_limit: 25
    });
    if (error) fetchError = error;
    else rows = data as OutboxRow[];
  } else if (token && anonKey) {
    const userClient = createClient(supabaseUrl, anonKey, {
      auth: { persistSession: false },
      global: { headers: { Authorization: authHeader } }
    });
    const { data, error } = await userClient.rpc("claim_telegram_outbox_for_user", {
      p_limit: 15
    });
    if (error) fetchError = error;
    else rows = data as OutboxRow[];
  } else {
    return new Response(JSON.stringify({ error: "Unauthorized" }), {
      status: 401,
      headers: { "Content-Type": "application/json", ...corsHeaders }
    });
  }

  if (fetchError) {
    return new Response(
      JSON.stringify({ error: fetchError.message }),
      { status: 500, headers: { "Content-Type": "application/json", ...corsHeaders } }
    );
  }

  // ✅ Обрабатываем задачи параллельно для ускорения доставки
  const processingPromises = (rows ?? []).map(async (row) => {
    let ok = false;
    let errMsg: string | null = null;

    try {
      if (row.kind === "work_opening_telegram") {
        const r = await processOpening(admin, supabaseUrl, serviceKey, row);
        ok = r.ok;
        errMsg = r.err;
      } else if (row.kind === "work_close_telegram") {
        const r = await processClose(admin, supabaseUrl, serviceKey, row);
        ok = r.ok;
        errMsg = r.err;
      } else {
        errMsg = `unknown kind: ${row.kind}`;
      }
    } catch (e) {
      ok = false;
      errMsg = e instanceof Error ? e.message : String(e);
    } finally {
      await markOutcome(admin, row, ok, errMsg);
    }
    
    return { id: row.id, kind: row.kind, ok };
  });

  const processedResults = await Promise.all(processingPromises);

  return new Response(
    JSON.stringify({
      processed: processedResults.length,
      results: processedResults
    }),
    { status: 200, headers: { "Content-Type": "application/json", ...corsHeaders } }
  );
});
