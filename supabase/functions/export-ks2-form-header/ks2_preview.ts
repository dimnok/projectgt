import { type SupabaseClient } from "https://esm.sh/@supabase/supabase-js@2.39.3";

export interface VorItemRow {
  id: string;
  estimate_item_id: string | null;
  name: string | null;
  unit: string | null;
  quantity: number | string | null;
  is_extra: boolean | null;
  sort_order: number | string | null;
}

export interface EstimateRow {
  id: string;
  price: number | string | null;
  name: string | null;
  unit: string | null;
  estimate_title: string | null;
  number: string | null;
}

export interface Ks2PreviewPayload {
  candidates: Record<string, unknown>[];
  skipped: Record<string, unknown>[];
  totalAmount: number;
  stats: {
    candidatesCount: number;
    skippedCount: number;
  };
}

export function toNum(v: number | string | null | undefined): number {
  if (v == null) return 0;
  const n = typeof v === "number" ? v : Number(v);
  return Number.isFinite(n) ? n : 0;
}

/** Состав акта КС-2 по строкам утверждённой ВОР (без превышения сметы). */
export async function buildKs2PreviewPayload(
  supabase: SupabaseClient,
  vorId: string,
): Promise<Ks2PreviewPayload> {
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

export async function loadVorForKs2(
  supabase: SupabaseClient,
  vorId: string,
  companyId: string,
  contractId: string,
): Promise<{
  id: string;
  contract_id: string;
  company_id: string;
  status: string;
  start_date: string;
  end_date: string;
}> {
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
  const row = vor as {
    id: string;
    contract_id: string;
    company_id: string;
    status: string;
    start_date: string;
    end_date: string;
  };
  if (row.contract_id !== contractId) {
    throw new Error("ВОР не относится к выбранному договору");
  }
  if (row.status !== "approved") {
    throw new Error("Акт КС-2 можно сформировать только из утверждённой ВОР");
  }
  return row;
}
