import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.3";
import {
  buildKs2PreviewPayload,
  loadVorForKs2,
} from "./ks2_preview.ts";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

interface Body {
  action: string;
  contractId: string;
  companyId: string;
  /** Идентификатор утверждённой ВОР (обязателен для preview/create). */
  vorId?: string | null;
  actNumber?: string | null;
  actDate?: string | null;
}

/** Текст ошибки для JSON-ответа (PostgREST-объекты не дают нормальный String()). */
function formatKs2Error(error: unknown): string {
  if (error instanceof Error && error.message) {
    return error.message;
  }
  if (error && typeof error === "object") {
    const o = error as Record<string, unknown>;
    const parts: string[] = [];
    if (typeof o.message === "string" && o.message) parts.push(o.message);
    if (typeof o.details === "string" && o.details) parts.push(o.details);
    if (typeof o.hint === "string" && o.hint) parts.push(o.hint);
    if (parts.length > 0) return parts.join(" — ");
    try {
      return JSON.stringify(error);
    } catch {
      /* ignore */
    }
  }
  return String(error);
}

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const supabase = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "",
    );

    const body = (await req.json()) as Body;
    const { action, contractId, companyId, vorId, actNumber, actDate } = body;

    if (!contractId) {
      throw new Error("contractId is required");
    }
    if (!companyId) {
      throw new Error("companyId is required");
    }

    const vid = typeof vorId === "string" ? vorId.trim() : "";
    if (!vid) {
      throw new Error("vorId is required");
    }

    if (action === "preview") {
      return await handlePreview(supabase, contractId, companyId, vid);
    }
    if (action === "create") {
      if (!actNumber?.trim() || !actDate?.trim()) {
        throw new Error("actNumber and actDate are required for creation");
      }
      return await handleCreate(
        supabase,
        contractId,
        companyId,
        vid,
        actNumber.trim(),
        actDate.trim(),
      );
    }

    throw new Error("Invalid action. Use 'preview' or 'create'");
  } catch (error) {
    console.error("ks2_operations error:", error);
    const msg = formatKs2Error(error);
    return new Response(JSON.stringify({ error: msg }), {
      status: 400,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});

async function assertNoExistingActForVor(
  supabase: ReturnType<typeof createClient>,
  vorId: string,
  companyId: string,
) {
  const { data: existing, error } = await supabase
    .from("ks2_acts")
    .select("id")
    .eq("vor_id", vorId)
    .eq("company_id", companyId)
    .maybeSingle();

  if (error) throw error;
  if (existing) {
    throw new Error("По этой ВОР уже создан акт КС-2");
  }
}

async function handlePreview(
  supabase: ReturnType<typeof createClient>,
  contractId: string,
  companyId: string,
  vorId: string,
) {
  await loadVorForKs2(supabase, vorId, companyId, contractId);
  const payload = await buildKs2PreviewPayload(supabase, vorId);

  return new Response(JSON.stringify(payload), {
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

async function handleCreate(
  supabase: ReturnType<typeof createClient>,
  contractId: string,
  companyId: string,
  vorId: string,
  number: string,
  actDateIso: string,
) {
  const vor = await loadVorForKs2(supabase, vorId, companyId, contractId);
  await assertNoExistingActForVor(supabase, vorId, companyId);

  const payload = await buildKs2PreviewPayload(supabase, vorId);
  if (payload.candidates.length === 0) {
    throw new Error(
      "Нет строк ВОР для акта (все позиции — превышение сметы или без сметы)",
    );
  }

  const { data: act, error: actError } = await supabase
    .from("ks2_acts")
    .insert({
      contract_id: contractId,
      company_id: companyId,
      vor_id: vorId,
      number,
      date: actDateIso,
      period_from: vor.start_date,
      period_to: vor.end_date,
      total_amount: payload.totalAmount,
      status: "draft",
    })
    .select()
    .single();

  if (actError) throw actError;

  return new Response(
    JSON.stringify({
      success: true,
      actId: act.id as string,
      itemsCount: payload.candidates.length,
    }),
    {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    },
  );
}
