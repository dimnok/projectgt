/**
 * Генерация черновика унифицированной формы КС-2 из шаблона в Storage (`ks2_templates` / `ks2_template.xlsx`).
 *
 * Заполняется шапка по данным договора, карточки объекта, контрагента и организации. При передаче
 * доп. соглашений вставляются строки в лист перед блоком акта (`insertAddendumRowsIfNeeded`).
 * Список передаётся как `addenda` (массив `{ number, date }`); устаревшие поля `addendum1*` / `addendum2*`
 * учитываются, только если `addenda` не передан или пустой.
 * Таблица позиций не меняется.
 */
import { serve } from "https://deno.land/std@0.208.0/http/server.ts";
import { encode } from "https://deno.land/std@0.208.0/encoding/base64.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.3";
import ExcelJS from "npm:exceljs@4.4.0";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
  "Access-Control-Allow-Headers":
    "authorization, content-type, apikey, x-client-info",
};

const KS2_TEMPLATE_BUCKET = "ks2_templates";
const KS2_TEMPLATE_OBJECT_PATH = "ks2_template.xlsx";
/** ОКУД унифицированной формы № КС-2 (постановление Госкомстата № 100). */
const KS2_OKUD = "0322005";

/** Строка, перед которой в шаблоне вставляются блоки доп. соглашений (после даты договора в 21-й). */
const KS2_ROW_INSERT_BEFORE = 22;
/** В базовом шаблоне: данные акта (E/F/G/H). После вставки доп. соглашений сдвигается на +2 строки на каждый блок. */
const KS2_BASE_ACT_ROW = 26;
/** Строка с текстом сметной стоимости (A…). */
const KS2_BASE_COST_ROW = 27;

/** Единый шрифт заполняемого листа КС-2 (как в типовой форме). */
const KS2_SHEET_FONT_NAME = "Times New Roman";
const KS2_SHEET_FONT_SIZE = 10;
/** Последняя колонка, на которую распространяется смена шрифта (в шаблоне — до AA). */
const KS2_SHEET_FONT_LAST_COL = 30;

interface Body {
  companyId: string;
  contractId: string;
  /** Номер акта (документа). */
  actNumber?: string | null;
  /** Дата составления акта, ISO `yyyy-mm-dd`. */
  actDocDate?: string | null;
  /** Начало отчётного периода, ISO `yyyy-mm-dd`. */
  reportingPeriodFrom?: string | null;
  /** Конец отчётного периода, ISO `yyyy-mm-dd`. */
  reportingPeriodTo?: string | null;
  /** Список доп. соглашений (номер и дата ISO). При непустом массиве поля `addendum1*` / `addendum2*` игнорируются. */
  addenda?: Array<{ number?: string | null; date?: string | null }> | null;
  /** @deprecated Используйте [addenda]. Доп. соглашение 1: номер (строка). */
  addendum1Number?: string | null;
  /** @deprecated Используйте [addenda]. Доп. соглашение 1: дата, ISO `yyyy-mm-dd`. */
  addendum1Date?: string | null;
  /** @deprecated Используйте [addenda]. Доп. соглашение 2: номер. */
  addendum2Number?: string | null;
  /** @deprecated Используйте [addenda]. Доп. соглашение 2: дата, ISO `yyyy-mm-dd`. */
  addendum2Date?: string | null;
}

const MAX_ADDENDA = 50;

interface AddendumBlock {
  number: string;
  dateIso: string | null;
}

interface CompanyRow {
  name_short: string | null;
  name_full: string | null;
  legal_address: string | null;
  actual_address: string | null;
  okpo: string | null;
}

interface ContractorRow {
  short_name: string | null;
  full_name: string | null;
  legal_address: string | null;
  actual_address: string | null;
  okpo: string | null;
}

interface ObjectRow {
  name: string | null;
  address: string | null;
}

interface ContractRow {
  number: string;
  date: string;
  amount: string | number | null;
  vat_rate: string | number | null;
  vat_amount: string | number | null;
  contract_kind: string | null;
  company_id: string;
  customer_legal_name: string | null;
  contractor_legal_name: string | null;
  object: ObjectRow | ObjectRow[] | null;
  contractor: ContractorRow | ContractorRow[] | null;
}

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { status: 204, headers: corsHeaders });
  }

  if (req.method !== "POST") {
    return jsonError("Method not allowed", 405);
  }

  try {
    const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
    const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
    if (!supabaseUrl || !serviceRoleKey) {
      throw new Error("Missing Supabase environment variables");
    }

    const supabase = createClient(supabaseUrl, serviceRoleKey, {
      auth: { persistSession: false },
    });

    const body = (await req.json()) as Body;
    if (!body.companyId?.trim()) {
      throw new Error("Нужен companyId");
    }
    if (!body.contractId?.trim()) {
      throw new Error("Нужен contractId");
    }

    await ensureCompanyAccess(supabase, req, body.companyId);

    const payload = await loadKs2HeaderPayload(
      supabase,
      body.companyId,
      body.contractId,
    );

    const { data: fileBlob, error: dlErr } = await supabase.storage
      .from(KS2_TEMPLATE_BUCKET)
      .download(KS2_TEMPLATE_OBJECT_PATH);
    if (dlErr) {
      throw new Error(
        `Не удалось скачать шаблон из Storage: ${dlErr.message}`,
      );
    }

    const workbook = new ExcelJS.Workbook();
    await workbook.xlsx.load(await fileBlob.arrayBuffer());

    const sheet = workbook.worksheets[0];
    if (!sheet) {
      throw new Error("В шаблоне нет листов");
    }

    applyKs2Header(sheet, payload, body);

    const buffer = await workbook.xlsx.writeBuffer();
    const file = encode(new Uint8Array(buffer));
    const filename = buildKs2DraftFilename(payload.contract.number);

    return new Response(JSON.stringify({ file, filename }), {
      status: 200,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  } catch (e) {
    const message = e instanceof Error ? e.message : String(e);
    console.error("[export-ks2-form-header]", e);
    return jsonError(message, 400);
  }
});

function singleOrNull<T>(v: T | T[] | null | undefined): T | null {
  if (v == null) return null;
  return Array.isArray(v) ? (v[0] ?? null) : v;
}

function trimStr(v: string | null | undefined): string {
  return (v ?? "").trim();
}

function companyRequisites(c: CompanyRow | null): string {
  if (!c) return "";
  const name = trimStr(c.name_short) || trimStr(c.name_full);
  const addr = trimStr(c.legal_address) || trimStr(c.actual_address);
  return [name, addr].filter(Boolean).join(", ");
}

function contractorRequisites(c: ContractorRow | null): string {
  if (!c) return "";
  const name = trimStr(c.short_name) || trimStr(c.full_name);
  const addr = trimStr(c.legal_address) || trimStr(c.actual_address);
  return [name, addr].filter(Boolean).join(", ");
}

/** Как [ks2DefaultPartyPickIds] + реквизиты в приложении. */
function resolveKs2Parties(
  contract: ContractRow,
  company: CompanyRow | null,
  contractor: ContractorRow | null,
): {
  customerText: string;
  customerOkpo: string;
  contractorText: string;
  contractorOkpo: string;
} {
  const hasCompany = company != null;
  const custLegal = trimStr(contract.customer_legal_name);
  const contLegal = trimStr(contract.contractor_legal_name);
  const kind = trimStr(contract.contract_kind) || "customer";

  if (kind === "customer") {
    const customerText = contractorRequisites(contractor) || custLegal;
    const contractorText = companyRequisites(company) || contLegal;
    return {
      customerText,
      customerOkpo: trimStr(contractor?.okpo),
      contractorText,
      contractorOkpo: trimStr(company?.okpo),
    };
  }

  // subcontract | supply
  const customerText = companyRequisites(company) || custLegal;
  const contractorText = contractorRequisites(contractor) || contLegal;
  return {
    customerText,
    customerOkpo: hasCompany ? trimStr(company?.okpo) : "",
    contractorText,
    contractorOkpo: trimStr(contractor?.okpo),
  };
}

async function loadKs2HeaderPayload(
  supabase: ReturnType<typeof createClient>,
  companyId: string,
  contractId: string,
): Promise<{
  contract: ContractRow;
  company: CompanyRow | null;
  object: ObjectRow | null;
  contractor: ContractorRow | null;
}> {
  const { data: row, error } = await supabase
    .from("contracts")
    .select(
      "number, date, amount, vat_rate, vat_amount, contract_kind, company_id, customer_legal_name, contractor_legal_name, object:objects(name, address), contractor:contractors(short_name, full_name, legal_address, actual_address, okpo)",
    )
    .eq("id", contractId)
    .eq("company_id", companyId)
    .maybeSingle();

  if (error) throw error;
  if (!row) {
    throw new Error("Договор не найден или нет доступа по company_id");
  }

  const contract = row as unknown as ContractRow;
  const cid = trimStr(contract.company_id);
  let company: CompanyRow | null = null;
  if (cid) {
    const { data: comp, error: cErr } = await supabase
      .from("companies")
      .select(
        "name_short, name_full, legal_address, actual_address, okpo",
      )
      .eq("id", cid)
      .maybeSingle();
    if (cErr) throw cErr;
    company = comp as unknown as CompanyRow | null;
  }

  return {
    contract,
    company,
    object: singleOrNull<ObjectRow>(contract.object),
    contractor: singleOrNull<ContractorRow>(contract.contractor),
  };
}

/**
 * Ячейки — базовый шаблон `assets/templates/ks2/ks2_template.xlsx`.
 * При наличии доп. соглашений вставляются пары строк перед блоком «Вид операции» (строка 22),
 * блок акта и строка сметной стоимости сдвигаются вниз.
 */
function applyKs2Header(
  sheet: ExcelJS.Worksheet,
  payload: {
    contract: ContractRow;
    company: CompanyRow | null;
    object: ObjectRow | null;
    contractor: ContractorRow | null;
  },
  body: Body,
) {
  const { contract, company, object, contractor } = payload;
  const parties = resolveKs2Parties(contract, company, contractor);

  const objectName = trimStr(object?.name);
  const objectAddress = trimStr(object?.address);
  const construction = objectAddress || objectName || null;
  const objectCell = objectName || null;

  const amt = toNumberOrNull(contract.amount);
  const vat = toNumberOrNull(contract.vat_amount);
  const vatRate = toNumberOrNull(contract.vat_rate);

  const addenda = buildAddendaFromBody(body);
  const insertedRowCount = insertAddendumRowsIfNeeded(sheet, addenda);
  const rowShift = insertedRowCount;

  sheet.getCell("H5").value = KS2_OKUD;
  sheet.getCell("C9").value = parties.customerText || null;
  sheet.getCell("H9").value = parties.customerOkpo || null;
  sheet.getCell("C11").value = parties.contractorText || null;
  sheet.getCell("H11").value = parties.contractorOkpo || null;
  sheet.getCell("C13").value = construction;
  sheet.getCell("C16").value = objectCell;

  sheet.getCell("H19").value = null;
  sheet.getCell("H20").value = trimStr(contract.number) || null;
  setDateSplitInRow(sheet, 21, contract.date);

  for (let i = 0; i < addenda.length; i++) {
    fillAddendumBlock(sheet, KS2_ROW_INSERT_BEFORE + i * 2, addenda[i]!);
  }

  if (rowShift > 0) {
    clearVidOperationRowAt(sheet, KS2_ROW_INSERT_BEFORE + rowShift);
  } else {
    sheet.getCell("H22").value = null;
  }

  const actRow = KS2_BASE_ACT_ROW + rowShift;
  const costRow = KS2_BASE_COST_ROW + rowShift;

  sheet.getCell(`E${actRow}`).value = trimStr(body.actNumber) || null;
  sheet.getCell(`F${actRow}`).value = formatRuDateCell(body.actDocDate);
  sheet.getCell(`G${actRow}`).value = formatRuDateCell(body.reportingPeriodFrom);
  sheet.getCell(`H${actRow}`).value = formatRuDateCell(body.reportingPeriodTo);

  sheet.getCell(`A${costRow}`).value = buildContractCostA27Phrase(
    amt,
    vat,
    vatRate,
  );

  applyTimesNewRoman10ToSheet(sheet);
}

function buildAddendaFromBody(body: Body): AddendumBlock[] {
  const raw = body.addenda;
  if (Array.isArray(raw) && raw.length > 0) {
    const out: AddendumBlock[] = [];
    for (const item of raw.slice(0, MAX_ADDENDA)) {
      if (item == null || typeof item !== "object") continue;
      const rec = item as Record<string, unknown>;
      const n = trimStr(rec.number as string | null | undefined);
      const d = trimStr(rec.date as string | null | undefined);
      if (n || d) {
        out.push({ number: n, dateIso: d || null });
      }
    }
    return out;
  }

  const out: AddendumBlock[] = [];
  const a1n = trimStr(body.addendum1Number);
  const a1d = trimStr(body.addendum1Date);
  if (a1n || a1d) {
    out.push({ number: a1n, dateIso: a1d || null });
  }
  const a2n = trimStr(body.addendum2Number);
  const a2d = trimStr(body.addendum2Date);
  if (a2n || a2d) {
    out.push({ number: a2n, dateIso: a2d || null });
  }
  return out;
}

/** Вставляет по 2 строки на каждое доп. соглашение перед строкой 22. Возвращает число вставленных строк. */
function insertAddendumRowsIfNeeded(
  sheet: ExcelJS.Worksheet,
  addenda: AddendumBlock[],
): number {
  const n = addenda.length;
  if (n === 0) return 0;
  const count = n * 2;
  const blanks = Array.from({ length: count }, () => [] as unknown[]);
  sheet.spliceRows(KS2_ROW_INSERT_BEFORE, 0, ...blanks);
  return count;
}

/** Копирует высоту строки и стили ячеек с эталонной строки шаблона (как у строк 20–21 для договора). */
function copyRowFormattingFrom(
  sheet: ExcelJS.Worksheet,
  sourceRow: number,
  destRow: number,
) {
  const lastCol = 11; // A…K — достаточно для блока F…J
  const src = sheet.getRow(sourceRow);
  const dst = sheet.getRow(destRow);
  const h = src.height;
  if (h != null) dst.height = h;
  for (let col = 1; col <= lastCol; col++) {
    const sc = src.getCell(col);
    const dc = dst.getCell(col);
    const st = sc.style;
    if (st != null && typeof st === "object" && Object.keys(st).length > 0) {
      try {
        dc.style = structuredClone(st) as ExcelJS.Style;
      } catch {
        dc.style = JSON.parse(JSON.stringify(st)) as ExcelJS.Style;
      }
    }
  }
}

/**
 * Задаёт для листа шрифт Times New Roman 10 pt (сохраняя жирный/курсив из шаблона).
 * Вызывается после всех вставок и подстановок значений.
 */
function applyTimesNewRoman10ToSheet(sheet: ExcelJS.Worksheet): void {
  const lastRow = Math.max(sheet.lastRow?.number ?? 1, 1);
  for (let rowNum = 1; rowNum <= lastRow; rowNum++) {
    const row = sheet.getRow(rowNum);
    for (let col = 1; col <= KS2_SHEET_FONT_LAST_COL; col++) {
      const cell = row.getCell(col);
      const prev = cell.font;
      cell.font = {
        ...prev,
        name: KS2_SHEET_FONT_NAME,
        size: KS2_SHEET_FONT_SIZE,
      };
    }
  }
}

function fillAddendumBlock(
  sheet: ExcelJS.Worksheet,
  startRow: number,
  block: AddendumBlock,
) {
  copyRowFormattingFrom(sheet, 20, startRow);
  copyRowFormattingFrom(sheet, 21, startRow + 1);

  try {
    sheet.unMergeCells(`H${startRow}:J${startRow}`);
  } catch {
    //
  }

  sheet.getCell(`F${startRow}`).value = "Дополнительное соглашение";
  sheet.getCell(`G${startRow}`).value = "номер";
  sheet.getCell(`H${startRow}`).value = null;
  const addendumNumberCell = sheet.getCell(`I${startRow}`);
  addendumNumberCell.value = trimStr(block.number) || null;
  addendumNumberCell.alignment = {
    ...addendumNumberCell.alignment,
    horizontal: "center",
    vertical: "middle",
  };
  sheet.getCell(`J${startRow}`).value = null;

  sheet.getCell(`G${startRow + 1}`).value = "дата";
  setDateSplitInRow(sheet, startRow + 1, block.dateIso ?? "");
}

/** Убирает строку «Вид операции», сдвинутую вниз после вставок. */
function clearVidOperationRowAt(sheet: ExcelJS.Worksheet, row: number) {
  const gVal = sheet.getCell(`G${row}`).value;
  const g = typeof gVal === "string" ? gVal : "";
  if (!g.includes("Вид операции")) return;
  try {
    sheet.unMergeCells(`H${row}:J${row}`);
  } catch {
    //
  }
  sheet.getCell(`G${row}`).value = null;
  sheet.getCell(`H${row}`).value = null;
  sheet.getCell(`I${row}`).value = null;
  sheet.getCell(`J${row}`).value = null;
}

/** Дата в три ячейки: H — число дня, I — месяц двумя цифрами (`01`…`12`), J — год. [iso] — yyyy-mm-dd или пусто. */
function setDateSplitInRow(sheet: ExcelJS.Worksheet, row: number, iso: string) {
  const p = parseIsoDateParts(iso);
  if (!p) {
    sheet.getCell(`H${row}`).value = null;
    sheet.getCell(`I${row}`).value = null;
    sheet.getCell(`J${row}`).value = null;
    return;
  }
  sheet.getCell(`H${row}`).value = p.day;
  sheet.getCell(`I${row}`).value = String(p.month).padStart(2, "0");
  sheet.getCell(`J${row}`).value = p.year;
}

/** Текст для ячейки A27: сметная стоимость и НДС только цифрами (без прописи). */
function buildContractCostA27Phrase(
  amountRub: number | null,
  vatRub: number | null,
  vatRatePercent: number | null,
): string | null {
  if (amountRub == null) return null;
  const amountFmt = formatAmountRuDisplay(amountRub);
  let text =
    `Сметная (договорная) стоимость в соответствии с договором подряда (субподряда) ${amountFmt} рублей`;

  if (vatRub != null && vatRub > 0) {
    const vatFmt = formatAmountRuDisplay(vatRub);
    const ratePart = vatRatePercent != null && vatRatePercent > 0
      ? `НДС ${formatVatRateDisplay(vatRatePercent)}%`
      : "НДС";
    text += ` в том числе ${ratePart} ${vatFmt} рублей`;
  }
  return text;
}

function formatVatRateDisplay(rate: number): string {
  if (Number.isInteger(rate)) return String(rate);
  const s = String(rate);
  return s.replace(/(\.\d*?)0+$/, "$1").replace(/\.$/, "");
}

/** Пробелы между группами тысяч, запятая — десятичные (как в UI). */
function formatAmountRuDisplay(value: number): string {
  const sign = value < 0 ? "-" : "";
  const abs = Math.abs(value);
  const fixed = abs.toFixed(2);
  const [intPart, frac] = fixed.split(".");
  const withGroups = intPart.replace(/\B(?=(\d{3})+(?!\d))/g, " ");
  return `${sign}${withGroups},${frac}`;
}

function toNumberOrNull(v: string | number | null | undefined): number | null {
  if (v === null || v === undefined) return null;
  const n = typeof v === "number" ? v : Number(String(v).replace(",", "."));
  return Number.isFinite(n) ? n : null;
}

function parseIsoDateParts(iso: string): {
  day: number;
  month: number;
  year: number;
} | null {
  if (!trimStr(iso)) return null;
  const part = iso.slice(0, 10);
  const d = part.split("-");
  if (d.length !== 3) return null;
  const year = Number(d[0]);
  const month = Number(d[1]);
  const day = Number(d[2]);
  if (!Number.isFinite(year) || !Number.isFinite(month) || !Number.isFinite(day)) {
    return null;
  }
  return { day, month, year };
}

/** Дата для одной ячейки (дд.мм.гггг) или `null`, если строка пустая / невалидная. */
function formatRuDateCell(iso: string | null | undefined): string | null {
  const s = trimStr(iso);
  if (!s) return null;
  const p = parseIsoDateParts(s);
  if (!p) return null;
  const dd = String(p.day).padStart(2, "0");
  const mm = String(p.month).padStart(2, "0");
  return `${dd}.${mm}.${p.year}`;
}

function buildKs2DraftFilename(contractNumber: string): string {
  const safe = sanitizeFilenamePart(contractNumber || "договор");
  const today = todayRu();
  return `КС-2_${safe}_${today}.xlsx`;
}

function sanitizeFilenamePart(s: string): string {
  return s.replace(/[\\/:*?"<>|]/g, "_").replace(/\s+/g, "_").trim() ||
    "договор";
}

function todayRu(): string {
  const d = new Date();
  const dd = String(d.getDate()).padStart(2, "0");
  const mm = String(d.getMonth() + 1).padStart(2, "0");
  return `${dd}.${mm}.${d.getFullYear()}`;
}

async function ensureCompanyAccess(
  supabase: ReturnType<typeof createClient>,
  req: Request,
  companyId: string,
) {
  const token = req.headers.get("Authorization")?.replace(/^Bearer\s+/i, "")
    .trim();
  if (!token) {
    throw new Error("Нужен токен Authorization");
  }

  const { data: userData, error: userError } = await supabase.auth.getUser(
    token,
  );
  if (userError || !userData.user) {
    throw new Error("Не удалось определить пользователя");
  }

  const { data: membership, error: membershipErr } = await supabase
    .from("company_members")
    .select("id, is_active")
    .eq("company_id", companyId)
    .eq("user_id", userData.user.id)
    .eq("is_active", true)
    .maybeSingle();
  if (membershipErr || !membership) {
    throw new Error("Нет доступа к выбранной компании");
  }
}

function jsonError(message: string, status: number) {
  return new Response(JSON.stringify({ error: message }), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}
