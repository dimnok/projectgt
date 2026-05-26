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
  quantity: number | string | null;
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

/** Убирает устаревший суффикс «(в т.ч. перенос с прошлых ВОР: …)» из наименования. */
export function stripBacklogSuffixFromActLineName(name: string): string {
  const trimmed = name.trim();
  const stripped = trimmed.replace(
    /\s*\(в т\.ч\. перенос с прошлых ВОР:[^)]*\)\s*$/u,
    "",
  ).trim();
  return stripped || "—";
}

/** Размер чанка для `.in(id, …)` — длинный GET-URL ломает PostgREST на крупных ВОР. */
const ESTIMATE_IDS_CHUNK_SIZE = 80;

type BilledMap = Map<string, number>;

interface VorHeader {
  id: string;
  company_id: string;
  contract_id: string;
  end_date: string;
}

interface GroupedVorLine {
  estimateId: string;
  name: string;
  unit: string;
  sortOrder: number;
  vorItemId: string;
  currentPeriodQty: number;
}

async function fetchEstimatesMap(
  supabase: SupabaseClient,
  estimateIds: string[],
): Promise<Map<string, EstimateRow>> {
  const estimatesMap = new Map<string, EstimateRow>();
  for (let i = 0; i < estimateIds.length; i += ESTIMATE_IDS_CHUNK_SIZE) {
    const chunk = estimateIds.slice(i, i + ESTIMATE_IDS_CHUNK_SIZE);
    const { data: estRows, error: estErr } = await supabase
      .from("estimates")
      .select("id, price, quantity, name, unit, estimate_title, number")
      .in("id", chunk);
    if (estErr) throw estErr;
    for (const e of (estRows ?? []) as EstimateRow[]) {
      estimatesMap.set(e.id, e);
    }
  }
  return estimatesMap;
}

async function fetchVorHeader(
  supabase: SupabaseClient,
  vorId: string,
): Promise<VorHeader> {
  const { data, error } = await supabase
    .from("vors")
    .select("id, company_id, contract_id, end_date")
    .eq("id", vorId)
    .maybeSingle();
  if (error) throw error;
  if (!data) throw new Error("Ведомость ВОР не найдена");
  return data as VorHeader;
}

async function fetchVorItems(
  supabase: SupabaseClient,
  vorId: string,
): Promise<VorItemRow[]> {
  const { data, error } = await supabase
    .from("vor_items")
    .select("id, estimate_item_id, name, unit, quantity, is_extra, sort_order")
    .eq("vor_id", vorId)
    .order("sort_order", { ascending: true });
  if (error) throw error;
  return (data ?? []) as VorItemRow[];
}

/** Есть ли по договору уже акт КС-2 по более ранней утверждённой ВОР. */
async function hasPriorKs2Act(
  supabase: SupabaseClient,
  contractId: string,
  currentVorEndDate: string,
): Promise<boolean> {
  const { data: acts, error: actsErr } = await supabase
    .from("contract_acts")
    .select("vor_id")
    .eq("contract_id", contractId)
    .eq("act_kind", "ks2");
  if (actsErr) throw actsErr;
  const vorIds = (acts ?? [])
    .map((a) => a.vor_id as string | null)
    .filter((id): id is string => typeof id === "string" && id.length > 0);
  if (vorIds.length === 0) return false;

  const { data: vors, error: vorsErr } = await supabase
    .from("vors")
    .select("id")
    .in("id", vorIds)
    .eq("contract_id", contractId)
    .eq("status", "approved")
    .lt("end_date", currentVorEndDate)
    .limit(1);
  if (vorsErr) throw vorsErr;
  return (vors ?? []).length > 0;
}

/** Утверждённые ВОР с актом КС-2 до текущей, по порядку периодов. */
async function fetchPriorVorIdsWithKs2Acts(
  supabase: SupabaseClient,
  contractId: string,
  beforeEndDate: string,
): Promise<string[]> {
  const { data: acts, error: actsErr } = await supabase
    .from("contract_acts")
    .select("vor_id")
    .eq("contract_id", contractId)
    .eq("act_kind", "ks2");
  if (actsErr) throw actsErr;

  const vorIds = (acts ?? [])
    .map((a) => a.vor_id as string | null)
    .filter((id): id is string => typeof id === "string" && id.length > 0);
  if (vorIds.length === 0) return [];

  const { data: vors, error: vorsErr } = await supabase
    .from("vors")
    .select("id")
    .in("id", vorIds)
    .eq("contract_id", contractId)
    .eq("status", "approved")
    .lt("end_date", beforeEndDate)
    .order("end_date", { ascending: true });
  if (vorsErr) throw vorsErr;
  return (vors ?? []).map((v) => v.id as string);
}

/** Превышение сметы из подписанных ВОР до текущей (очередь на перенос в акт). */
async function fetchBacklogByEstimate(
  supabase: SupabaseClient,
  contractId: string,
  beforeEndDate: string,
): Promise<Map<string, number>> {
  const { data, error } = await supabase
    .from("vor_items")
    .select("estimate_item_id, quantity, vors!inner(contract_id, status, end_date)")
    .eq("vors.contract_id", contractId)
    .eq("vors.status", "approved")
    .lt("vors.end_date", beforeEndDate)
    .eq("is_extra", true);
  if (error) throw error;

  const map = new Map<string, number>();
  for (const row of data ?? []) {
    const estId = row.estimate_item_id as string | null;
    if (!estId) continue;
    map.set(estId, (map.get(estId) ?? 0) + toNum(row.quantity as number));
  }
  return map;
}

function groupCurrentVorItems(items: VorItemRow[]): Map<string, GroupedVorLine> {
  const map = new Map<string, GroupedVorLine>();
  for (const row of items) {
    const estId = row.estimate_item_id;
    if (!estId) continue;
    const qty = toNum(row.quantity);
    const existing = map.get(estId);
    if (existing) {
      existing.currentPeriodQty += qty;
      if (toNum(row.sort_order) < existing.sortOrder) {
        existing.sortOrder = toNum(row.sort_order);
        existing.vorItemId = row.id;
        existing.name = (row.name ?? existing.name).trim() || existing.name;
        existing.unit = (row.unit ?? existing.unit).trim() || existing.unit;
      }
    } else {
      map.set(estId, {
        estimateId: estId,
        name: (row.name ?? "").trim() || "—",
        unit: (row.unit ?? "").trim() || "—",
        sortOrder: toNum(row.sort_order),
        vorItemId: row.id,
        currentPeriodQty: qty,
      });
    }
  }
  return map;
}

/**
 * Сколько по позиции сметы войдёт в акт по одной ВОР (с учётом очереди и лимита сметы).
 * [billedBefore] — уже закрыто предыдущими актами КС-2 по договору.
 */
async function allocateBillableForVor(
  supabase: SupabaseClient,
  vorId: string,
  billedBefore: BilledMap,
): Promise<Map<string, number>> {
  const vor = await fetchVorHeader(supabase, vorId);
  const items = await fetchVorItems(supabase, vorId);
  const priorAct = await hasPriorKs2Act(
    supabase,
    vor.contract_id,
    vor.end_date,
  );
  const result = new Map<string, number>();

  if (!priorAct) {
    for (const row of items) {
      if (row.is_extra === true) continue;
      const estId = row.estimate_item_id;
      if (!estId) continue;
      const qty = toNum(row.quantity);
      result.set(estId, (result.get(estId) ?? 0) + qty);
    }
    return result;
  }

  const backlog = await fetchBacklogByEstimate(
    supabase,
    vor.contract_id,
    vor.end_date,
  );
  const currentGrouped = groupCurrentVorItems(items);
  const estimateIds = new Set<string>([
    ...currentGrouped.keys(),
    ...backlog.keys(),
  ]);
  if (estimateIds.size === 0) return result;

  const estimatesMap = await fetchEstimatesMap(
    supabase,
    [...estimateIds],
  );

  for (const estId of estimateIds) {
    const currentTotal = currentGrouped.get(estId)?.currentPeriodQty ?? 0;
    const backlogQty = backlog.get(estId) ?? 0;
    const requested = currentTotal + backlogQty;
    if (requested <= 0) continue;

    const estimateLimit = toNum(estimatesMap.get(estId)?.quantity);
    const alreadyBilled = billedBefore.get(estId) ?? 0;
    const room = Math.max(0, estimateLimit - alreadyBilled);
    const billQty = Math.min(requested, room);
    if (billQty > 0) {
      result.set(estId, billQty);
    }
  }

  return result;
}

/** Уже закрыто по строкам сохранённых актов КС-2 (до текущей ВОР). */
async function fetchBilledMapFromActLines(
  supabase: SupabaseClient,
  contractId: string,
  companyId: string,
  beforeEndDate: string,
): Promise<BilledMap> {
  const priorVorIds = await fetchPriorVorIdsWithKs2Acts(
    supabase,
    contractId,
    beforeEndDate,
  );
  if (priorVorIds.length === 0) return new Map();

  const { data: acts, error: actsErr } = await supabase
    .from("contract_acts")
    .select("id")
    .eq("contract_id", contractId)
    .eq("company_id", companyId)
    .eq("act_kind", "ks2")
    .in("vor_id", priorVorIds);
  if (actsErr) throw actsErr;

  const actIds = (acts ?? []).map((a) => a.id as string);
  if (actIds.length === 0) return new Map();

  const { data: lines, error: linesErr } = await supabase
    .from("contract_act_lines")
    .select("estimate_item_id, quantity")
    .in("contract_act_id", actIds);
  if (linesErr) throw linesErr;

  const billed: BilledMap = new Map();
  for (const line of lines ?? []) {
    const estId = line.estimate_item_id as string | null;
    if (!estId) continue;
    billed.set(estId, (billed.get(estId) ?? 0) + toNum(line.quantity));
  }
  return billed;
}

/** Накопленно закрыто предыдущими актами КС-2 (для лимита сметы). */
async function computeBilledBeforeCurrentVor(
  supabase: SupabaseClient,
  contractId: string,
  companyId: string,
  currentVorEndDate: string,
): Promise<BilledMap> {
  const fromLines = await fetchBilledMapFromActLines(
    supabase,
    contractId,
    companyId,
    currentVorEndDate,
  );

  const priorVorIds = await fetchPriorVorIdsWithKs2Acts(
    supabase,
    contractId,
    currentVorEndDate,
  );
  if (priorVorIds.length === 0) return fromLines;

  const { count, error: countErr } = await supabase
    .from("contract_act_lines")
    .select("id", { count: "exact", head: true })
    .eq("contract_id", contractId)
    .eq("company_id", companyId);
  if (countErr) throw countErr;

  if ((count ?? 0) > 0) {
    return fromLines;
  }

  const billed: BilledMap = new Map();
  for (const priorVorId of priorVorIds) {
    const slice = await allocateBillableForVor(supabase, priorVorId, billed);
    for (const [estId, qty] of slice) {
      billed.set(estId, (billed.get(estId) ?? 0) + qty);
    }
  }
  return billed;
}

function sortCandidates(candidates: Record<string, unknown>[]): void {
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
}

/** Первый акт по договору: только строки «по смете» текущей ВОР (как раньше). */
function buildFirstActPreview(
  items: VorItemRow[],
  estimatesMap: Map<string, EstimateRow>,
): Ks2PreviewPayload {
  const candidates: Record<string, unknown>[] = [];
  const skipped: Record<string, unknown>[] = [];

  for (const row of items) {
    if (row.is_extra === true) {
      skipped.push({
        vorItemId: row.id,
        estimateId: row.estimate_item_id,
        name: row.name,
        unit: row.unit,
        quantity: toNum(row.quantity),
        reason:
          "Превышение сметы по этой ВОР — переносится в следующий акт при наличии лимита сметы",
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
      amount: qty * price,
      sectionTitle,
      sortOrder: toNum(row.sort_order),
      backlogQuantity: 0,
      currentPeriodQuantity: qty,
    });
  }

  sortCandidates(candidates);
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

/** Акт по 2-й и последующим ВОР: текущий период + очередь превышения, в пределах сметы. */
async function buildCumulativeActPreview(
  supabase: SupabaseClient,
  vor: VorHeader,
  items: VorItemRow[],
): Promise<Ks2PreviewPayload> {
  const candidates: Record<string, unknown>[] = [];
  const skipped: Record<string, unknown>[] = [];

  for (const row of items) {
    if (!row.estimate_item_id) {
      skipped.push({
        vorItemId: row.id,
        name: row.name,
        quantity: toNum(row.quantity),
        reason: "Нет привязки к позиции сметы",
      });
    }
  }

  const billedBefore = await computeBilledBeforeCurrentVor(
    supabase,
    vor.contract_id,
    vor.company_id,
    vor.end_date,
  );
  const backlog = await fetchBacklogByEstimate(
    supabase,
    vor.contract_id,
    vor.end_date,
  );
  const currentGrouped = groupCurrentVorItems(items);
  const billable = await allocateBillableForVor(
    supabase,
    vor.id,
    billedBefore,
  );

  const estimateIds = new Set<string>([
    ...billable.keys(),
    ...currentGrouped.keys(),
    ...backlog.keys(),
  ]);
  const estimatesMap = estimateIds.size > 0
    ? await fetchEstimatesMap(supabase, [...estimateIds])
    : new Map<string, EstimateRow>();

  for (const estId of billable.keys()) {
    const billQty = billable.get(estId) ?? 0;
    if (billQty <= 0) continue;

    const grouped = currentGrouped.get(estId);
    const backlogQty = backlog.get(estId) ?? 0;
    const currentPeriodQty = grouped?.currentPeriodQty ?? 0;
    const requested = currentPeriodQty + backlogQty;

    const est = estimatesMap.get(estId);
    const price = toNum(est?.price);
    const name = (grouped?.name ?? est?.name ?? "").trim() || "—";
    const unit = (grouped?.unit ?? est?.unit ?? "").trim() || "—";
    const sectionTitle = ((est?.estimate_title ?? "") as string).trim() ||
      "—";
    const estimateNumber = ((est?.number ?? "") as string).trim() || "—";

    candidates.push({
      vorItemId: grouped?.vorItemId ?? null,
      estimateId: estId,
      estimateNumber,
      name,
      unit,
      quantity: billQty,
      price,
      amount: billQty * price,
      sectionTitle,
      sortOrder: grouped?.sortOrder ?? 0,
      backlogQuantity: backlogQty,
      currentPeriodQuantity: currentPeriodQty,
    });

    if (billQty < requested) {
      const estimateLimit = toNum(est?.quantity);
      const alreadyBilled = billedBefore.get(estId) ?? 0;
      skipped.push({
        estimateId: estId,
        name,
        unit,
        quantity: requested - billQty,
        reason:
          `Не вошло в акт: лимит сметы ${estimateLimit} ${unit}, уже закрыто ранее ${alreadyBilled} ${unit}`,
      });
    }
  }

  // Превышение текущей ВОР, полностью покрытое переносом в других позициях — не дублируем в skipped.
  for (const row of items) {
    if (row.is_extra !== true) continue;
    const estId = row.estimate_item_id;
    if (!estId) continue;
    const rowQty = toNum(row.quantity);
    const grouped = currentGrouped.get(estId);
    if (!grouped) continue;
    const billQty = billable.get(estId) ?? 0;
    if (billQty <= 0) {
      skipped.push({
        vorItemId: row.id,
        estimateId: estId,
        name: row.name,
        unit: row.unit,
        quantity: rowQty,
        reason: "Превышение сметы — лимит сметы исчерпан, в акт не вошло",
      });
    }
  }

  sortCandidates(candidates);
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

/**
 * Состав акта КС-2 по утверждённой ВОР.
 * Первый акт: только «по смете» текущей ВОР.
 * Далее: объём текущей ВОР + очередь превышения с прошлых подписанных ВОР, в пределах сметы.
 */
export async function buildKs2PreviewPayload(
  supabase: SupabaseClient,
  vorId: string,
): Promise<Ks2PreviewPayload> {
  const vor = await fetchVorHeader(supabase, vorId);
  const items = await fetchVorItems(supabase, vorId);

  const estimateIds = [
    ...new Set(
      items
        .map((i) => i.estimate_item_id)
        .filter((x): x is string => typeof x === "string" && x.length > 0),
    ),
  ];

  const priorAct = await hasPriorKs2Act(
    supabase,
    vor.contract_id,
    vor.end_date,
  );

  if (!priorAct) {
    const estimatesMap = estimateIds.length > 0
      ? await fetchEstimatesMap(supabase, estimateIds)
      : new Map<string, EstimateRow>();
    return buildFirstActPreview(items, estimatesMap);
  }

  return await buildCumulativeActPreview(supabase, vor, items);
}

/** Сохраняет строки акта КС-2 из результата превью. */
export async function insertContractActLines(
  supabase: SupabaseClient,
  params: {
    companyId: string;
    contractId: string;
    contractActId: string;
    candidates: Record<string, unknown>[];
  },
): Promise<void> {
  const rows = params.candidates.map((c, index) => ({
    company_id: params.companyId,
    contract_id: params.contractId,
    contract_act_id: params.contractActId,
    estimate_item_id: (c.estimateId as string | null) ?? null,
    vor_item_id: (c.vorItemId as string | null) ?? null,
    sort_order: toNum(c.sortOrder as number) || index,
    estimate_number: String(c.estimateNumber ?? ""),
    section_title: String(c.sectionTitle ?? ""),
    name: String(c.name ?? "—"),
    unit: String(c.unit ?? ""),
    quantity: toNum(c.quantity as number),
    price: toNum(c.price as number),
    amount: toNum(c.amount as number),
    backlog_quantity: toNum(c.backlogQuantity as number),
    current_period_quantity: toNum(c.currentPeriodQuantity as number),
  }));

  if (rows.length === 0) return;

  const { error } = await supabase.from("contract_act_lines").insert(rows);
  if (error) throw error;
}

/** Превью состава акта из сохранённых строк (без пересчёта из ВОР). */
export async function buildKs2PreviewFromActLines(
  supabase: SupabaseClient,
  contractActId: string,
): Promise<Ks2PreviewPayload> {
  const { data: lines, error } = await supabase
    .from("contract_act_lines")
    .select("*")
    .eq("contract_act_id", contractActId)
    .order("sort_order", { ascending: true });
  if (error) throw error;

  const candidates: Record<string, unknown>[] = (lines ?? []).map((row) => ({
    vorItemId: row.vor_item_id,
    estimateId: row.estimate_item_id,
    estimateNumber: row.estimate_number,
    name: stripBacklogSuffixFromActLineName(String(row.name ?? "—")),
    unit: row.unit,
    quantity: toNum(row.quantity),
    price: toNum(row.price),
    amount: toNum(row.amount),
    sectionTitle: row.section_title,
    sortOrder: row.sort_order,
    backlogQuantity: toNum(row.backlog_quantity),
    currentPeriodQuantity: toNum(row.current_period_quantity),
  }));

  sortCandidates(candidates);
  const totalAmount = candidates.reduce(
    (s, c) => s + toNum(c.amount as number),
    0,
  );

  return {
    candidates,
    skipped: [],
    totalAmount,
    stats: {
      candidatesCount: candidates.length,
      skippedCount: 0,
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
