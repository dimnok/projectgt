import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.3";

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

interface VorHeader {
  id: string;
  contract_id: string;
  company_id: string;
  status: string;
  start_date: string;
  end_date: string;
}

interface VorItemRow {
  id: string;
  estimate_item_id: string | null;
  name: string | null;
  unit: string | null;
  quantity: number | string | null;
  is_extra: boolean | null;
  sort_order: number | null;
}

interface EstimateRow {
  id: string;
  price: number | string | null;
  name: string | null;
  unit: string | null;
  estimate_title: string | null;
  number: string | null;
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
    const msg = error instanceof Error ? error.message : String(error);
    return new Response(JSON.stringify({ error: msg }), {
      status: 400,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});

async function loadVorForKs2(
  supabase: ReturnType<typeof createClient>,
  vorId: string,
  companyId: string,
  contractId: string,
): Promise<VorHeader> {
  const { data: vor, error } = await supabase
    .from("vors")
    .select("id, contract_id, company_id, status, start_date, end_date")
    .eq("id", vorId)
    .eq("company_id", companyId)
    .maybeSingle();

  if (error) throw error;
  if (!vor) {
    throw new Error("ВОР не найдена или нет доступа");
  }
  const row = vor as VorHeader;
  if (row.contract_id !== contractId) {
    throw new Error("ВОР не относится к выбранному договору");
  }
  if (row.status !== "approved") {
    throw new Error("Акт КС-2 можно сформировать только из утверждённой ВОР");
  }
  return row;
}

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

function toNum(v: number | string | null | undefined): number {
  if (v == null) return 0;
  const n = typeof v === "number" ? v : Number(v);
  return Number.isFinite(n) ? n : 0;
}

async function buildPreviewPayload(
  supabase: ReturnType<typeof createClient>,
  vorId: string,
) {
  const { data: itemsRaw, error: itemsError } = await supabase
    .from("vor_items")
    .select("id, estimate_item_id, name, unit, quantity, is_extra, sort_order")
    .eq("vor_id", vorId)
    .order("sort_order", { ascending: true });

  if (itemsError) throw itemsError;
  const items = (itemsRaw ?? []) as VorItemRow[];

  const estimateIds = [
    ...new Set(
      items
        .map((i) => i.estimate_item_id)
        .filter((x): x is string => typeof x === "string" && x.length > 0),
    ),
  ];

  const estimatesMap = new Map<string, EstimateRow>();
  if (estimateIds.length > 0) {
    const { data: estRows, error: estErr } = await supabase
      .from("estimates")
      .select("id, price, name, unit, estimate_title, number")
      .in("id", estimateIds);
    if (estErr) throw estErr;
    for (const e of (estRows ?? []) as EstimateRow[]) {
      estimatesMap.set(e.id, e);
    }
  }

  const candidates: Record<string, unknown>[] = [];
  const skipped: Record<string, unknown>[] = [];

  for (const row of items) {
    const isExtra = row.is_extra === true;
    if (isExtra) {
      skipped.push({
        vorItemId: row.id,
        estimateId: row.estimate_item_id,
        name: row.name,
        unit: row.unit,
        quantity: toNum(row.quantity),
        reason: "Превышение сметы — в акт КС-2 не включается",
      });
      continue;
    }

    const estId = row.estimate_item_id;
    if (!estId) {
      skipped.push({
        vorItemId: row.id,
        name: row.name,
        quantity: toNum(row.quantity),
        reason: "Нет привязки к позиции сметы",
      });
      continue;
    }

    const est = estimatesMap.get(estId);
    const price = toNum(est?.price);
    const qty = toNum(row.quantity);
    const name = (row.name ?? est?.name ?? "").trim() || "—";
    const unit = (row.unit ?? est?.unit ?? "").trim() || "—";
    const amount = qty * price;

    const sectionTitle = ((est?.estimate_title ?? "") as string).trim() ||
      "—";

    const estimateNumber = ((est?.number ?? "") as string).trim() || "—";

    candidates.push({
      vorItemId: row.id,
      estimateId: estId,
      estimateNumber,
      name,
      unit,
      quantity: qty,
      price,
      amount,
      sectionTitle,
      sortOrder: toNum(row.sort_order),
    });
  }

  candidates.sort((a, b) => {
    const sa = String(a.sectionTitle ?? "");
    const sb = String(b.sectionTitle ?? "");
    if (sa !== sb) return sa.localeCompare(sb, "ru");
    const oa = toNum(a.sortOrder as number | string | null | undefined);
    const ob = toNum(b.sortOrder as number | string | null | undefined);
    if (oa !== ob) return oa - ob;
    const nc = String(a.estimateNumber ?? "").localeCompare(
      String(b.estimateNumber ?? ""),
      "ru",
      { numeric: true },
    );
    if (nc !== 0) return nc;
    return String(a.name ?? "").localeCompare(String(b.name ?? ""), "ru");
  });

  const totalAmount = candidates.reduce(
    (s, c) => s + toNum(c.amount as number),
    0,
  );

  return {
    candidates,
    skipped,
    totalAmount,
    stats: {
      candidatesCount: candidates.length,
      skippedCount: skipped.length,
    },
  };
}

async function handlePreview(
  supabase: ReturnType<typeof createClient>,
  contractId: string,
  companyId: string,
  vorId: string,
) {
  await loadVorForKs2(supabase, vorId, companyId, contractId);
  const payload = await buildPreviewPayload(supabase, vorId);

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

  const payload = await buildPreviewPayload(supabase, vorId);
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
