/**
 * Генерация черновика унифицированной формы КС-2 из шаблона в Storage (`ks2_templates` / `ks2_template.xlsx`).
 *
 * Заполняется шапка по данным договора, карточки объекта, контрагента и организации. При передаче
 * доп. соглашений вставляются строки в лист перед блоком акта (`insertAddendumRowsIfNeeded`).
 * Список передаётся как `addenda` (массив `{ number, date }`); устаревшие поля `addendum1*` / `addendum2*`
 * учитываются, только если `addenda` не передан или пустой.
 *
 * При передаче [vorId] таблица работ заполняется из утверждённой ВОР (та же логика, что `ks2_operations` preview).
 */
import { serve } from "https://deno.land/std@0.208.0/http/server.ts";
import { encode } from "https://deno.land/std@0.208.0/encoding/base64.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.3";
import ExcelJS from "npm:exceljs@4.4.0";
import {
  buildKs2PreviewPayload,
  loadVorForKs2,
  toNum,
} from "./ks2_preview.ts";

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
/** Первая строка данных таблицы работ (после заголовков 29–31). */
const KS2_BASE_TABLE_FIRST_DATA_ROW = 32;
/** Число зарезервированных в шаблоне строк под позиции (32…63). */
const KS2_TEMPLATE_DATA_ROW_CAPACITY = 32;
/** «Итого по разделу» / блок итогов акта в базовом шаблоне. */
const KS2_BASE_FOOTER_SECTION_TOTAL_ROW = 64;
const KS2_BASE_FOOTER_ACT_TOTAL_ROW = 65;
const KS2_BASE_FOOTER_VAT_ROW = 66;
const KS2_BASE_FOOTER_GRAND_TOTAL_ROW = 67;
/**
 * Подписи в шаблоне: строка данных (текст + линии) и следующая — подписи полей.
 * Между блоками «Сдал» и «Принял» — 3 пустые строки (72–74 в базовом шаблоне).
 */
const KS2_SIGN_DATA_ROW_HEIGHT_PT = 58;
const KS2_BASE_SIGN_HANDOVER_DATA_ROW = 70;
const KS2_BASE_SIGN_HANDOVER_LABELS_ROW = 71;
const KS2_BASE_SIGN_ACCEPT_DATA_ROW = 75;
const KS2_BASE_SIGN_ACCEPT_LABELS_ROW = 76;

/** Единый шрифт заполняемого листа КС-2 (как в типовой форме). */
const KS2_SHEET_FONT_NAME = "Times New Roman";
const KS2_SHEET_FONT_SIZE = 10;
/** Последняя колонка, на которую распространяется смена шрифта (в шаблоне — до K). */
const KS2_SHEET_FONT_LAST_COL = 11;
/** Денежный формат: 2 знака, без символа валюты (Excel локализует под ru-RU). */
const KS2_NUMFMT_MONEY = "#,##0.00";
/** Количество: 2 знака после запятой (как цена/стоимость). */
const KS2_NUMFMT_QUANTITY = "#,##0.00";
/** Значение колонки «Номер ед. расценки» (F) по форме КС-2. */
const KS2_ESTIMATE_CODE_COL_VALUE = "Х";
/** Эталонная высота строки данных в шаблоне (pt). */
const KS2_TEMPLATE_DATA_ROW_HEIGHT = 16;
/** Символов в строке для колонки C (слито C:E). */
const KS2_NAME_CHARS_PER_LINE = 44;
const KS2_LINE_HEIGHT_PT = 11;

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
  /** Утверждённая ВОР: при указании заполняется таблица работ. */
  vorId?: string | null;
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

    const rowShift = applyKs2Header(sheet, payload, body);

    let tableInsertShift = 0;
    const vorId = trimStr(body.vorId);
    if (vorId) {
      await loadVorForKs2(supabase, vorId, body.companyId, body.contractId);
      const preview = await buildKs2PreviewPayload(supabase, vorId);
      tableInsertShift = applyKs2PositionsTable(
        sheet,
        preview.candidates,
        preview.totalAmount,
        payload.contract,
        rowShift,
      );
    }

    const parties = resolveKs2Parties(
      payload.contract,
      payload.company,
      payload.contractor,
    );
    applyKs2Signatures(sheet, parties, rowShift + tableInsertShift);

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

/** Наименование стороны для строки «Подрядчик:/Заказчик:» (без адреса из шапки). */
function ks2PartyOrgLineForSignature(partyText: string): string {
  const t = trimStr(partyText);
  if (!t) return "";
  const comma = t.indexOf(",");
  return comma >= 0 ? trimStr(t.slice(0, comma)) : t;
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
/** Заполняет шапку; возвращает сдвиг строк из-за доп. соглашений. */
function applyKs2Header(
  sheet: ExcelJS.Worksheet,
  payload: {
    contract: ContractRow;
    company: CompanyRow | null;
    object: ObjectRow | null;
    contractor: ContractorRow | null;
  },
  body: Body,
): number {
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

  return rowShift;
}

interface Ks2SectionBucket {
  sectionKey: string;
  rows: Record<string, unknown>[];
}

function groupCandidatesBySection(
  candidates: Record<string, unknown>[],
): Ks2SectionBucket[] {
  const buckets: Ks2SectionBucket[] = [];
  for (const c of candidates) {
    const key = trimStr(c.sectionTitle as string | undefined) || "—";
    if (buckets.length === 0 || buckets[buckets.length - 1]!.sectionKey !== key) {
      buckets.push({ sectionKey: key, rows: [c] });
    } else {
      buckets[buckets.length - 1]!.rows.push(c);
    }
  }
  return buckets;
}

function clearKs2DataRow(sheet: ExcelJS.Worksheet, row: number) {
  for (const col of ["A", "B", "C", "F", "G", "H", "I", "J"] as const) {
    sheet.getCell(`${col}${row}`).value = null;
  }
}

/** Число для ячейки Excel: ноль остаётся нулём, а не пустой ячейкой. */
function excelNumericCell(value: number): number {
  return Number.isFinite(value) ? value : 0;
}

/** Стоимость позиции: количество (H) × цена (I). */
function ks2PositionCostCellValue(
  row: number,
  cachedAmount: number,
): ExcelJS.CellValue {
  return {
    formula: `H${row}*I${row}`,
    result: excelNumericCell(cachedAmount),
  };
}

/** Итого по разделу: сумма стоимости (J) по строкам позиций раздела. */
function ks2SectionCostSumCellValue(
  fromRow: number,
  toRow: number,
  cachedTotal: number,
): ExcelJS.CellValue {
  return {
    formula: `SUM(J${fromRow}:J${toRow})`,
    result: excelNumericCell(cachedTotal),
  };
}

/** Ячейка с формулой и кэшированным результатом для открытия без пересчёта. */
function ks2FormulaCellValue(
  formula: string,
  cachedResult: number,
): ExcelJS.CellValue {
  return {
    formula,
    result: excelNumericCell(cachedResult),
  };
}

/** Сумма по строкам «Итого по разделу» (колонка J). */
function ks2ActTotalFromSectionsFormula(sectionTotalRows: number[]): string {
  if (sectionTotalRows.length === 0) return "0";
  if (sectionTotalRows.length === 1) {
    return `J${sectionTotalRows[0]}`;
  }
  return `SUM(${sectionTotalRows.map((r) => `J${r}`).join(",")})`;
}

function ks2TableFont(bold: boolean): Partial<ExcelJS.Font> {
  return {
    name: KS2_SHEET_FONT_NAME,
    size: KS2_SHEET_FONT_SIZE,
    bold,
  };
}

function applyKs2MoneyCellStyle(
  cell: ExcelJS.Cell,
  horizontal: "left" | "center" | "right",
  bold = false,
) {
  cell.numFmt = KS2_NUMFMT_MONEY;
  cell.font = ks2TableFont(bold);
  cell.alignment = { horizontal, vertical: "middle" };
}

function applyKs2DataRowStyle(sheet: ExcelJS.Worksheet, row: number) {
  const centerTextCols = ["B", "G"] as const;
  for (const col of centerTextCols) {
    const cell = sheet.getCell(`${col}${row}`);
    cell.font = ks2TableFont(false);
    cell.alignment = { horizontal: "center", vertical: "middle" };
  }

  applyKs2EstimateCodeColumn(sheet, row, false);

  const aCell = sheet.getCell(`A${row}`);
  aCell.font = ks2TableFont(false);
  aCell.alignment = { horizontal: "center", vertical: "middle" };

  const hCell = sheet.getCell(`H${row}`);
  hCell.font = ks2TableFont(false);
  hCell.numFmt = KS2_NUMFMT_QUANTITY;
  hCell.alignment = { horizontal: "center", vertical: "middle" };

  applyKs2MoneyCellStyle(sheet.getCell(`I${row}`), "right", false);
  applyKs2MoneyCellStyle(sheet.getCell(`J${row}`), "right", false);
}

function applyKs2MergedDescriptionAlignment(
  sheet: ExcelJS.Worksheet,
  row: number,
  opts: {
    bold?: boolean;
    horizontal?: "left" | "center" | "right";
  } = {},
) {
  const cell = sheet.getCell(`C${row}`);
  cell.font = ks2TableFont(opts.bold ?? false);
  cell.alignment = {
    horizontal: opts.horizontal ?? "left",
    vertical: "middle",
    wrapText: true,
  };
}

/** Колонка F — «Номер ед. расценки»: везде «Х», по центру. */
function applyKs2EstimateCodeColumn(
  sheet: ExcelJS.Worksheet,
  row: number,
  bold = false,
) {
  const cell = sheet.getCell(`F${row}`);
  cell.value = KS2_ESTIMATE_CODE_COL_VALUE;
  cell.font = ks2TableFont(bold);
  cell.alignment = { horizontal: "center", vertical: "middle" };
}

function applyKs2SectionTotalRowStyle(sheet: ExcelJS.Worksheet, row: number) {
  mergeKs2RowCellsCE(sheet, row);
  applyKs2MergedDescriptionAlignment(sheet, row, {
    bold: true,
    horizontal: "right",
  });
  applyKs2EstimateCodeColumn(sheet, row, true);
  applyKs2MoneyCellStyle(sheet.getCell(`J${row}`), "right", true);
}

function applyKs2SectionHeadingStyle(sheet: ExcelJS.Worksheet, row: number) {
  mergeKs2RowCellsCE(sheet, row);
  applyKs2MergedDescriptionAlignment(sheet, row, {
    bold: true,
    horizontal: "center",
  });
  applyKs2EstimateCodeColumn(sheet, row, true);
}

/** Оформление строки итогов акта: подпись (C) и сумма (J) жирным. */
function applyKs2ActFooterRowStyle(sheet: ExcelJS.Worksheet, row: number) {
  mergeKs2RowCellsCE(sheet, row);
  applyKs2MergedDescriptionAlignment(sheet, row, {
    bold: true,
    horizontal: "right",
  });
  applyKs2EstimateCodeColumn(sheet, row, true);
}

function setKs2ActFooterMoneyCell(
  sheet: ExcelJS.Worksheet,
  row: number,
  value: ExcelJS.CellValue,
) {
  const cell = sheet.getCell(`J${row}`);
  cell.value = value;
  applyKs2MoneyCellStyle(cell, "right", true);
}

function fillKs2DataRow(
  sheet: ExcelJS.Worksheet,
  row: number,
  orderNum: number,
  item: Record<string, unknown>,
) {
  const estimateNumber = trimStr(item.estimateNumber as string | undefined) ||
    "—";
  const name = trimStr(item.name as string | undefined) || "—";
  const unit = trimStr(item.unit as string | undefined) || "—";
  const qty = toNum(item.quantity as number | string | null | undefined);
  const price = toNum(item.price as number | string | null | undefined);
  const amount = toNum(item.amount as number | string | null | undefined);

  sheet.getCell(`A${row}`).value = orderNum;
  sheet.getCell(`B${row}`).value = estimateNumber === "—" ? null : estimateNumber;
  sheet.getCell(`C${row}`).value = name;
  sheet.getCell(`G${row}`).value = unit === "—" ? null : unit;
  sheet.getCell(`H${row}`).value = excelNumericCell(qty);
  sheet.getCell(`I${row}`).value = excelNumericCell(price);
  sheet.getCell(`J${row}`).value = ks2PositionCostCellValue(row, amount);

  applyKs2DataRowStyle(sheet, row);
  applyKs2DataRowLayout(sheet, row, name);
}

function fillKs2SectionHeadingRow(
  sheet: ExcelJS.Worksheet,
  row: number,
  title: string,
) {
  sheet.getCell(`C${row}`).value = title;
  for (const col of ["A", "B", "F", "G", "H", "I", "J"] as const) {
    sheet.getCell(`${col}${row}`).value = null;
  }
  applyKs2SectionHeadingStyle(sheet, row);
  sheet.getRow(row).height = Math.max(18, estimateKs2RowHeightPt(title, 18));
}

function fillKs2SectionTotalRow(
  sheet: ExcelJS.Worksheet,
  row: number,
  sectionTotal: number,
  dataRowFrom?: number,
  dataRowTo?: number,
) {
  sheet.getCell(`C${row}`).value = "Итого по разделу без учёта НДС";
  if (
    dataRowFrom != null &&
    dataRowTo != null &&
    dataRowFrom <= dataRowTo
  ) {
    sheet.getCell(`J${row}`).value = ks2SectionCostSumCellValue(
      dataRowFrom,
      dataRowTo,
      sectionTotal,
    );
  } else {
    sheet.getCell(`J${row}`).value = excelNumericCell(sectionTotal);
  }
  applyKs2SectionTotalRowStyle(sheet, row);
}

type Ks2TableLine =
  | { kind: "heading"; title: string }
  | { kind: "data"; item: Record<string, unknown> }
  | { kind: "sectionTotal"; amount: number };

/** Собирает строки таблицы при нескольких разделах сметы. */
function buildKs2MultiSectionLines(
  candidates: Record<string, unknown>[],
): Ks2TableLine[] {
  const buckets = groupCandidatesBySection(candidates);
  const lines: Ks2TableLine[] = [];

  for (const bucket of buckets) {
    const title = bucket.sectionKey === "—"
      ? "Без названия раздела"
      : bucket.sectionKey;
    lines.push({ kind: "heading", title });
    for (const item of bucket.rows) {
      lines.push({ kind: "data", item });
    }
    const sectionTotal = bucket.rows.reduce(
      (s, r) => s + toNum(r.amount as number | string | null | undefined),
      0,
    );
    lines.push({ kind: "sectionTotal", amount: sectionTotal });
  }
  return lines;
}

function shouldShowKs2SectionHeadings(
  candidates: Record<string, unknown>[],
): boolean {
  const buckets = groupCandidatesBySection(candidates);
  return buckets.length > 1 ||
    (buckets.length === 1 && buckets[0]!.sectionKey !== "—");
}

type Ks2TableRenderResult = {
  nextRow: number;
  /** Номера строк «Итого по разделу» (колонка J) для формулы «Всего по акту». */
  sectionTotalRows: number[];
};

/** Рисует последовательность [lines] начиная с [firstDataRow]. */
function renderKs2TableLines(
  sheet: ExcelJS.Worksheet,
  lines: Ks2TableLine[],
  firstDataRow: number,
): Ks2TableRenderResult {
  let orderNum = 0;
  let sectionFirstDataRow: number | null = null;
  let sectionLastDataRow: number | null = null;
  const sectionTotalRows: number[] = [];
  for (let i = 0; i < lines.length; i++) {
    const row = firstDataRow + i;
    const line = lines[i]!;

    if (line.kind === "heading") {
      sectionFirstDataRow = null;
      sectionLastDataRow = null;
      copyRowFormattingFrom(sheet, KS2_BASE_TABLE_FIRST_DATA_ROW, row);
      fillKs2SectionHeadingRow(sheet, row, line.title);
      continue;
    }

    if (line.kind === "data") {
      if (sectionFirstDataRow === null) {
        sectionFirstDataRow = row;
      }
      sectionLastDataRow = row;
      if (row !== KS2_BASE_TABLE_FIRST_DATA_ROW) {
        copyRowFormattingFrom(sheet, KS2_BASE_TABLE_FIRST_DATA_ROW, row);
      }
      orderNum++;
      fillKs2DataRow(sheet, row, orderNum, line.item);
      continue;
    }

    copyRowFormattingFrom(sheet, KS2_BASE_FOOTER_SECTION_TOTAL_ROW, row);
    fillKs2SectionTotalRow(
      sheet,
      row,
      line.amount,
      sectionFirstDataRow ?? undefined,
      sectionLastDataRow ?? undefined,
    );
    sectionTotalRows.push(row);
    sectionFirstDataRow = null;
    sectionLastDataRow = null;
  }
  return { nextRow: firstDataRow + lines.length, sectionTotalRows };
}

/**
 * Заполняет таблицу работ и итоги акта (строки 32+ и блок 64–67 с учётом [rowShift]).
 *
 * Возвращает число вставленных строк таблицы (сдвиг блока подписей вниз).
 */
function applyKs2PositionsTable(
  sheet: ExcelJS.Worksheet,
  candidates: Record<string, unknown>[],
  totalAmount: number,
  contract: ContractRow,
  rowShift: number,
): number {
  if (candidates.length === 0) return 0;

  const firstDataRow = KS2_BASE_TABLE_FIRST_DATA_ROW + rowShift;
  let sectionTotalRow = KS2_BASE_FOOTER_SECTION_TOTAL_ROW + rowShift;
  const showSectionHeadings = shouldShowKs2SectionHeadings(candidates);

  if (showSectionHeadings) {
    const lines = buildKs2MultiSectionLines(candidates);
    const actFooterRows = 3;
    const templateBlockSize = KS2_TEMPLATE_DATA_ROW_CAPACITY + 4;
    const extraRows = Math.max(0, lines.length + actFooterRows - templateBlockSize);

    const templateDataRow = firstDataRow;
    if (extraRows > 0) {
      insertKs2TableDataRows(sheet, sectionTotalRow, extraRows, templateDataRow);
      sectionTotalRow += extraRows;
    }

    const { nextRow, sectionTotalRows } = renderKs2TableLines(
      sheet,
      lines,
      firstDataRow,
    );
    normalizeKs2TableRowMerges(sheet, firstDataRow, nextRow - 1);
    fillKs2ActFooterTotals(
      sheet,
      contract,
      totalAmount,
      nextRow,
      nextRow + 1,
      nextRow + 2,
      sectionTotalRows,
    );
    return extraRows;
  }

  const dataCount = candidates.length;
  const templateDataRow = firstDataRow;
  const extraRows = Math.max(0, dataCount - KS2_TEMPLATE_DATA_ROW_CAPACITY);
  if (extraRows > 0) {
    insertKs2TableDataRows(sheet, sectionTotalRow, extraRows, templateDataRow);
    sectionTotalRow += extraRows;
  }

  let orderNum = 0;
  for (let i = 0; i < dataCount; i++) {
    const row = firstDataRow + i;
    if (row !== templateDataRow) {
      copyRowFormattingFrom(sheet, templateDataRow, row);
    }
    orderNum++;
    fillKs2DataRow(sheet, row, orderNum, candidates[i]!);
  }

  for (let row = firstDataRow + dataCount; row < sectionTotalRow; row++) {
    clearKs2DataRow(sheet, row);
  }

  copyRowFormattingFrom(sheet, KS2_BASE_FOOTER_SECTION_TOTAL_ROW, sectionTotalRow);
  fillKs2SectionTotalRow(
    sheet,
    sectionTotalRow,
    totalAmount,
    firstDataRow,
    firstDataRow + dataCount - 1,
  );

  normalizeKs2TableRowMerges(sheet, firstDataRow, sectionTotalRow);

  fillKs2ActFooterTotals(
    sheet,
    contract,
    totalAmount,
    sectionTotalRow + 1,
    sectionTotalRow + 2,
    sectionTotalRow + 3,
    [sectionTotalRow],
  );
  return extraRows;
}

/** Подписи: строки 70 и 75 — те же наименования сторон, что в шапке (C9/C11). */
function applyKs2Signatures(
  sheet: ExcelJS.Worksheet,
  parties: ReturnType<typeof resolveKs2Parties>,
  totalRowShift: number,
) {
  applyKs2SignerDataRow(sheet, {
    dataRow: KS2_BASE_SIGN_HANDOVER_DATA_ROW + totalRowShift,
    actionLabel: "Сдал",
    partyLabel: "Подрядчик",
    orgName: ks2PartyOrgLineForSignature(parties.contractorText),
  });

  applyKs2SignerDataRow(sheet, {
    dataRow: KS2_BASE_SIGN_ACCEPT_DATA_ROW + totalRowShift,
    actionLabel: "Принял",
    partyLabel: "Заказчик",
    orgName: ks2PartyOrgLineForSignature(parties.customerText),
  });
}

/** Строки ячейки подписи ниже «действие + организация» (например «Генеральный директор» из шаблона). */
function ks2SignerTailLinesFromTemplate(
  existing: ExcelJS.CellValue,
  headLineCount: number,
): string[] {
  if (existing == null) return [];
  let text = "";
  if (typeof existing === "string") {
    text = existing;
  } else if (
    typeof existing === "object" &&
    existing !== null &&
    "richText" in existing &&
    Array.isArray((existing as { richText: { text: string }[] }).richText)
  ) {
    text = (existing as { richText: { text: string }[] }).richText
      .map((p) => p.text)
      .join("");
  } else {
    text = String(existing);
  }
  const parts = text.split(/\r?\n/).map((l) => l.trim());
  if (parts.length <= headLineCount) return [];
  return parts.slice(headLineCount);
}

/** Многострочный текст в A{dataRow}; строка подписей полей и линии — из шаблона. */
function applyKs2SignerDataRow(
  sheet: ExcelJS.Worksheet,
  opts: {
    dataRow: number;
    actionLabel: string;
    partyLabel: string;
    orgName: string;
  },
) {
  const { dataRow, actionLabel, partyLabel, orgName } = opts;

  sheet.getRow(dataRow).height = KS2_SIGN_DATA_ROW_HEIGHT_PT;

  const orgLine = trimStr(orgName);
  const head: string[] = [actionLabel];
  head.push(orgLine ? `${partyLabel}: ${orgLine}` : partyLabel);

  const cell = sheet.getCell(`A${dataRow}`);
  const tail = ks2SignerTailLinesFromTemplate(cell.value, head.length);
  cell.value = [...head, ...tail].join("\n");
  cell.font = ks2TableFont(true);
  cell.alignment = {
    horizontal: "left",
    vertical: "top",
    wrapText: true,
  };
}

function fillKs2ActFooterTotals(
  sheet: ExcelJS.Worksheet,
  contract: ContractRow,
  totalAmount: number,
  actTotalRow: number,
  vatRow: number,
  grandTotalRow: number,
  sectionTotalRows: number[],
) {
  const vatRate = toNumberOrNull(contract.vat_rate);
  const vatAmount = vatRate != null && vatRate > 0
    ? Math.round(totalAmount * vatRate / 100 * 100) / 100
    : 0;
  const grandTotal = Math.round((totalAmount + vatAmount) * 100) / 100;

  const actTotalFormula = ks2ActTotalFromSectionsFormula(sectionTotalRows);

  for (const row of [actTotalRow, vatRow, grandTotalRow]) {
    applyKs2ActFooterRowStyle(sheet, row);
  }

  setKs2ActFooterMoneyCell(
    sheet,
    actTotalRow,
    ks2FormulaCellValue(actTotalFormula, totalAmount),
  );

  if (vatRate != null && vatRate > 0) {
    sheet.getCell(`C${vatRow}`).value =
      `НДС ${formatVatRateDisplay(vatRate)}%`;
    setKs2ActFooterMoneyCell(
      sheet,
      vatRow,
      ks2FormulaCellValue(
        `ROUND(J${actTotalRow}*${vatRate}/100,2)`,
        vatAmount,
      ),
    );
    setKs2ActFooterMoneyCell(
      sheet,
      grandTotalRow,
      ks2FormulaCellValue(
        `J${actTotalRow}+J${vatRow}`,
        grandTotal,
      ),
    );
  } else {
    sheet.getCell(`C${vatRow}`).value = "НДС";
    setKs2ActFooterMoneyCell(
      sheet,
      vatRow,
      ks2FormulaCellValue("0", 0),
    );
    setKs2ActFooterMoneyCell(
      sheet,
      grandTotalRow,
      ks2FormulaCellValue(`J${actTotalRow}`, totalAmount),
    );
  }
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

/** Оценка высоты строки по длине текста в C (при wrapText). */
function estimateKs2RowHeightPt(text: string, minPt = KS2_TEMPLATE_DATA_ROW_HEIGHT): number {
  const t = text.trim();
  if (!t) return minPt;
  const lines = Math.max(1, Math.ceil(t.length / KS2_NAME_CHARS_PER_LINE));
  return Math.max(minPt, lines * KS2_LINE_HEIGHT_PT + 6);
}

/** Индекс колонки Excel: A=1, B=2, C=3, … */
function colLettersToIndex(col: string): number {
  let n = 0;
  for (const ch of col.toUpperCase()) {
    n = n * 26 + (ch.charCodeAt(0) - 64);
  }
  return n;
}

/** Диапазон merge `A1:J10` или `null`. */
function parseMergeRef(
  ref: string,
): { c1: number; r1: number; c2: number; r2: number } | null {
  const m = /^([A-Z]+)(\d+):([A-Z]+)(\d+)$/i.exec(ref.trim());
  if (!m) return null;
  return {
    c1: colLettersToIndex(m[1]!),
    r1: Number(m[2]),
    c2: colLettersToIndex(m[3]!),
    r2: Number(m[4]),
  };
}

/** Merge пересекает строку [row] и колонки C–F (наименование + пустые D–F в шаблоне). */
function mergeTouchesRowColsCtoF(
  ref: string,
  row: number,
): boolean {
  const box = parseMergeRef(ref);
  if (!box) return false;
  if (row < box.r1 || row > box.r2) return false;
  const colC = colLettersToIndex("C");
  const colF = colLettersToIndex("F");
  return box.c2 >= colC && box.c1 <= colF;
}

/** Merge пересекает вертикальный диапазон строк и колонки C–F. */
function mergeIntersectsRowsColsCtoF(
  ref: string,
  fromRow: number,
  toRow: number,
): boolean {
  const box = parseMergeRef(ref);
  if (!box) return false;
  if (box.r2 < fromRow || box.r1 > toRow) return false;
  const colC = colLettersToIndex("C");
  const colF = colLettersToIndex("F");
  return box.c2 >= colC && box.c1 <= colF;
}

/** Снимает все merge на [row] в блоке C–F (иначе mergeCells молча не срабатывает). */
function unmergeRowColsCtoF(sheet: ExcelJS.Worksheet, row: number) {
  const merges = sheet.model.merges;
  if (!Array.isArray(merges) || merges.length === 0) return;

  const toDrop: string[] = [];
  for (const ref of merges) {
    if (mergeTouchesRowColsCtoF(ref, row)) {
      toDrop.push(ref);
    }
  }
  for (const ref of toDrop) {
    try {
      sheet.unMergeCells(ref);
    } catch {
      //
    }
  }
  if (toDrop.length > 0) {
    sheet.model.merges = merges.filter((ref) => !toDrop.includes(ref));
  }
}

/** Объединяет C:E в одной строке (как в шаблоне `ks2_template.xlsx`). */
function mergeKs2RowCellsCE(sheet: ExcelJS.Worksheet, row: number) {
  unmergeRowColsCtoF(sheet, row);
  sheet.mergeCells(`C${row}:E${row}`);
}

/** Объединение C:E и высота строки для позиции с наименованием. */
function applyKs2DataRowLayout(
  sheet: ExcelJS.Worksheet,
  row: number,
  name: string,
) {
  mergeKs2RowCellsCE(sheet, row);
  applyKs2MergedDescriptionAlignment(sheet, row);
  sheet.getRow(row).height = estimateKs2RowHeightPt(name);
}

/**
 * После spliceRows адреса merge в модели не сдвигаются — снимаем все C–F в диапазоне и задаём C:E построчно.
 */
function normalizeKs2TableRowMerges(
  sheet: ExcelJS.Worksheet,
  fromRow: number,
  toRow: number,
) {
  if (toRow < fromRow) return;

  const merges = sheet.model.merges;
  if (Array.isArray(merges) && merges.length > 0) {
    const toDrop: string[] = [];
    for (const ref of merges) {
      if (mergeIntersectsRowsColsCtoF(ref, fromRow, toRow)) {
        toDrop.push(ref);
      }
    }
    for (const ref of toDrop) {
      try {
        sheet.unMergeCells(ref);
      } catch {
        //
      }
    }
    sheet.model.merges = merges.filter((ref) => !toDrop.includes(ref));
  }

  for (let row = fromRow; row <= toRow; row++) {
    const cVal = sheet.getCell(`C${row}`).value;
    if (cVal == null || `${cVal}`.trim() === "") continue;
    sheet.mergeCells(`C${row}:E${row}`);
    const text = `${cVal}`;
    const isTotal = text.includes("Итого по разделу");
    const isHeading = !isTotal &&
      sheet.getCell(`A${row}`).value == null &&
      sheet.getCell(`B${row}`).value == null;
    const bold = isTotal || isHeading;
    const horizontal: "left" | "center" | "right" = isTotal
      ? "right"
      : isHeading
      ? "center"
      : "left";
    applyKs2MergedDescriptionAlignment(sheet, row, { bold, horizontal });
    applyKs2EstimateCodeColumn(sheet, row, bold);
  }
}

/** Вставляет строки таблицы работ с копированием стиля эталонной строки данных. */
function insertKs2TableDataRows(
  sheet: ExcelJS.Worksheet,
  insertAtRow: number,
  count: number,
  templateDataRow: number,
) {
  if (count <= 0) return;
  const emptyRows: any[][] = Array.from({ length: count }, () => []);
  sheet.spliceRows(insertAtRow, 0, ...emptyRows);
  for (let i = 0; i < count; i++) {
    const row = insertAtRow + i;
    copyRowFormattingFrom(sheet, templateDataRow, row);
  }
}

/** Быстрое клонирование стиля ячейки без разделения ссылок в памяти (чтобы избежать сбитого форматирования). */
function cloneExcelStyle(st: ExcelJS.Style): ExcelJS.Style {
  const res: any = {};
  if (st.numFmt !== undefined) res.numFmt = st.numFmt;
  if (st.font) res.font = { ...st.font };
  if (st.alignment) res.alignment = { ...st.alignment };
  if (st.border) {
    const b: any = {};
    if (st.border.top) b.top = { ...st.border.top };
    if (st.border.left) b.left = { ...st.border.left };
    if (st.border.bottom) b.bottom = { ...st.border.bottom };
    if (st.border.right) b.right = { ...st.border.right };
    res.border = b;
  }
  if (st.fill) res.fill = { ...st.fill };
  if (st.protection) res.protection = { ...st.protection };
  return res as ExcelJS.Style;
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
      dc.style = cloneExcelStyle(st);
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
