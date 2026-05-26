import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.3";
import {
  buildKs2PreviewFromActLines,
  buildKs2PreviewPayload,
  insertContractActLines,
  loadVorForKs2,
} from "./ks2_preview.ts";
import {
  loadContractVatTerms,
  splitActAmountForStorage,
} from "./vat_calc.ts";

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
  /** Идентификатор сохранённого акта — превью из `contract_act_lines`. */
  actId?: string | null;
  actNumber?: string | null;
  actDate?: string | null;
  periodFrom?: string | null;
  periodTo?: string | null;
  advanceRetention?: number | null;
  warrantyRetention?: number | null;
  otherRetentions?: number | null;
}

function parseRetention(value: unknown): number {
  const n = Number(value);
  if (!Number.isFinite(n) || n < 0) return 0;
  return Math.round(n * 100) / 100;
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

function parseDateOnly(iso: string): string {
  const d = new Date(iso);
  if (Number.isNaN(d.getTime())) {
    throw new Error(`Некорректная дата: ${iso}`);
  }
  return d.toISOString().slice(0, 10);
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
    const {
      action,
      contractId,
      companyId,
      vorId,
      actId,
      actNumber,
      actDate,
      periodFrom,
      periodTo,
      advanceRetention,
      warrantyRetention,
      otherRetentions,
    } = body;

    if (!contractId) {
      throw new Error("contractId is required");
    }
    if (!companyId) {
      throw new Error("companyId is required");
    }

    const aid = typeof actId === "string" ? actId.trim() : "";
    if (action === "preview" && aid) {
      return await handlePreviewByAct(supabase, aid, companyId, contractId);
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
      const periodFromIso = periodFrom?.trim()
        ? parseDateOnly(periodFrom.trim())
        : null;
      const periodToIso = periodTo?.trim()
        ? parseDateOnly(periodTo.trim())
        : null;
      return await handleCreate(
        supabase,
        contractId,
        companyId,
        vid,
        actNumber.trim(),
        parseDateOnly(actDate.trim()),
        periodFromIso,
        periodToIso,
        parseRetention(advanceRetention),
        parseRetention(warrantyRetention),
        parseRetention(otherRetentions),
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
    .from("contract_acts")
    .select("id")
    .eq("vor_id", vorId)
    .eq("company_id", companyId)
    .eq("act_kind", "ks2")
    .maybeSingle();

  if (error) throw error;
  if (existing) {
    throw new Error("По этой ВОР уже создан акт КС-2");
  }
}

async function handlePreviewByAct(
  supabase: ReturnType<typeof createClient>,
  actId: string,
  companyId: string,
  contractId: string,
) {
  const { data: act, error } = await supabase
    .from("contract_acts")
    .select("id, contract_id, company_id, act_kind")
    .eq("id", actId)
    .eq("company_id", companyId)
    .maybeSingle();
  if (error) throw error;
  if (!act) throw new Error("Акт не найден");
  if (act.contract_id !== contractId) {
    throw new Error("Акт не относится к выбранному договору");
  }
  if (act.act_kind !== "ks2") {
    throw new Error("Строки доступны только для акта КС-2");
  }

  const payload = await buildKs2PreviewFromActLines(supabase, actId);
  return new Response(JSON.stringify(payload), {
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
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
  periodFromIso: string | null,
  periodToIso: string | null,
  advanceRetention: number,
  warrantyRetention: number,
  otherRetentions: number,
) {
  const vor = await loadVorForKs2(supabase, vorId, companyId, contractId);
  await assertNoExistingActForVor(supabase, vorId, companyId);

  const payload = await buildKs2PreviewPayload(supabase, vorId);
  if (payload.candidates.length === 0) {
    throw new Error(
      "Нет строк ВОР для акта (все позиции — превышение сметы или без сметы)",
    );
  }

  const periodFrom = periodFromIso ?? vor.start_date;
  const periodTo = periodToIso ?? vor.end_date;
  if (periodTo < periodFrom) {
    throw new Error(
      "Дата окончания периода не может быть раньше даты начала",
    );
  }

  const vatTerms = await loadContractVatTerms(supabase, contractId, companyId);
  const { amount, vatAmount } = splitActAmountForStorage(
    payload.totalAmount,
    vatTerms,
  );

  const { data: act, error: actError } = await supabase
    .from("contract_acts")
    .insert({
      company_id: companyId,
      contract_id: contractId,
      act_kind: "ks2",
      title: "КС-2",
      number,
      act_date: actDateIso,
      period_from: periodFrom,
      period_to: periodTo,
      amount,
      vat_amount: vatAmount,
      advance_retention: advanceRetention,
      warranty_retention: warrantyRetention,
      other_retentions: otherRetentions,
      amount_source: "vor_preview",
      workflow_status: "pending_approval",
      payment_status: "unpaid",
      vor_id: vorId,
    })
    .select()
    .single();

  if (actError) throw actError;

  await insertContractActLines(supabase, {
    companyId,
    contractId,
    contractActId: act.id as string,
    candidates: payload.candidates,
  });

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
