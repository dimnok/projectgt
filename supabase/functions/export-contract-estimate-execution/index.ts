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

const VIEW = "estimates_with_contracts";
const PAGE_SIZE = 1000;
/** Размер пакета id для RPC (как в приложении — агрегация в БД). */
const RPC_ESTIMATE_IDS_CHUNK = 500;
const SHEET_NAME = "Смета";
const FONT_MAIN = { name: "Times New Roman", size: 11 } as const;
const COL_COUNT = 12;

const borderThin = {
  top: { style: "thin" as const, color: { argb: "FF000000" } },
  left: { style: "thin" as const, color: { argb: "FF000000" } },
  bottom: { style: "thin" as const, color: { argb: "FF000000" } },
  right: { style: "thin" as const, color: { argb: "FF000000" } },
};

interface Body {
  companyId: string;
  contractId: string;
  estimateTitle: string;
  objectId?: string | null;
}

interface EstimateRow {
  estimateId: string;
  system: string;
  subsystem: string;
  number: string;
  name: string;
  article: string;
  manufacturer: string;
  unit: string;
  contractQuantity: number;
  contractPrice: number;
  contractTotal: number;
}

interface ExecutionAgg {
  completedQuantity: number;
}

function str(v: unknown): string {
  return v == null ? "" : String(v);
}

function toNum(v: unknown): number {
  if (v == null) return 0;
  if (typeof v === "number" && !Number.isNaN(v)) return v;
  const s = String(v).replace(/,/g, ".");
  const n = parseFloat(s);
  return Number.isNaN(n) ? 0 : n;
}

function sanitizeFileNameComponent(name: string): string {
  return name.replace(/[\\/:*?"<>|]/g, "_").replace(/\s+/g, " ").trim();
}

function jsonResponse(body: Record<string, unknown>, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
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
  const { data: membership, error: mErr } = await supabase
    .from("company_members")
    .select("id")
    .eq("company_id", companyId)
    .eq("user_id", userData.user.id)
    .eq("is_active", true)
    .maybeSingle();
  if (mErr || !membership) {
    throw new Error("Нет доступа к выбранной компании");
  }
}

function applySheetFont(sheet: ExcelJS.Worksheet) {
  sheet.eachRow({ includeEmpty: true }, (row) => {
    row.eachCell({ includeEmpty: true }, (cell) => {
      const f = cell.font;
      cell.font = {
        name: FONT_MAIN.name,
        size: f?.size ?? FONT_MAIN.size,
        bold: f?.bold,
        italic: f?.italic,
        color: f?.color,
      };
    });
  });
}

function columnWidthForIndex(c1Based: number): number {
  const widths = [38, 18, 22, 10, 52, 16, 16, 8, 14, 12, 16, 16];
  return widths[c1Based - 1] ?? 12;
}

function colLetter(col1Based: number): string {
  let n = col1Based;
  let s = "";
  while (n > 0) {
    const r = (n - 1) % 26;
    s = String.fromCharCode(65 + r) + s;
    n = Math.floor((n - 1) / 26);
  }
  return s;
}

/**
 * Выполнение по позициям — тот же RPC, что и вкладка «Выполнения» в приложении.
 * Прямой SELECT из work_items обрезался лимитом PostgREST (1000 строк).
 */
async function loadExecutionByEstimateId(
  userSupabase: ReturnType<typeof createClient>,
  companyId: string,
  estimateIds: string[],
): Promise<Map<string, ExecutionAgg>> {
  const result = new Map<string, ExecutionAgg>();
  if (estimateIds.length === 0) {
    return result;
  }

  for (let i = 0; i < estimateIds.length; i += RPC_ESTIMATE_IDS_CHUNK) {
    const part = estimateIds.slice(i, i + RPC_ESTIMATE_IDS_CHUNK);
    const { data, error } = await userSupabase.rpc(
      "get_estimate_completion_by_ids",
      {
        p_company_id: companyId,
        p_estimate_ids: part,
      },
    );
    if (error) {
      throw error;
    }

    const rows = Array.isArray(data) ? data : [];
    for (const raw of rows) {
      if (raw == null || typeof raw !== "object") continue;
      const rec = raw as Record<string, unknown>;
      const estimateId = str(rec.estimate_id).trim();
      if (!estimateId) continue;
      result.set(estimateId, {
        completedQuantity: toNum(rec.completed_quantity),
      });
    }
  }

  return result;
}

function styleHeaderRow(sheet: ExcelJS.Worksheet, rowIndex: number) {
  const row = sheet.getRow(rowIndex);
  row.height = rowIndex === 1 ? 22 : 26;
  row.font = { ...FONT_MAIN, bold: true };
  for (let hc = 1; hc <= COL_COUNT; hc++) {
    const cell = row.getCell(hc);
    cell.alignment = {
      vertical: "middle",
      horizontal: "center",
      wrapText: true,
    };
    cell.border = borderThin;
    cell.fill = {
      type: "pattern",
      pattern: "solid",
      fgColor: { argb: "FFF0F0F0" },
    };
  }
}

function styleDataRow(sheet: ExcelJS.Worksheet, rowNumber: number) {
  for (let col = 1; col <= COL_COUNT; col++) {
    const cell = sheet.getRow(rowNumber).getCell(col);
    cell.border = borderThin;
    const isNum = col >= 8;
    cell.alignment = {
      vertical: "top",
      horizontal: isNum ? "right" : "left",
      wrapText: col === 5,
    };
    if (isNum && typeof cell.value === "number") {
      cell.numFmt = "#,##0.00";
    }
  }
}

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { status: 204, headers: corsHeaders });
  }

  if (req.method !== "POST") {
    return jsonResponse({ success: false, message: "Method not allowed" }, 405);
  }

  try {
    const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
    const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
    const anonKey = Deno.env.get("SUPABASE_ANON_KEY") ?? "";
    const authHeader = req.headers.get("Authorization") ?? "";
    if (!supabaseUrl || !serviceRoleKey || !anonKey) {
      throw new Error("Missing Supabase environment variables");
    }
    if (!authHeader.trim()) {
      throw new Error("Нужен токен Authorization");
    }

    const supabase = createClient(supabaseUrl, serviceRoleKey, {
      auth: { persistSession: false },
    });
    const userSupabase = createClient(supabaseUrl, anonKey, {
      auth: { persistSession: false },
      global: { headers: { Authorization: authHeader } },
    });

    const body = (await req.json()) as Body;
    const companyId = str(body.companyId).trim();
    const contractId = str(body.contractId).trim();
    const trimmedTitle = str(body.estimateTitle).trim();
    const objectIdRaw = body.objectId;
    const objectId = objectIdRaw != null && str(objectIdRaw).trim() !== ""
      ? str(objectIdRaw).trim()
      : null;

    if (!companyId) {
      throw new Error("Не задан companyId");
    }
    if (!contractId) {
      throw new Error("Не задан contractId");
    }
    if (!trimmedTitle) {
      throw new Error("Не задан заголовок сметы для выгрузки");
    }

    await ensureCompanyAccess(supabase, req, companyId);

    const { data: contractRow, error: contractErr } = await supabase
      .from("contracts")
      .select("number")
      .eq("id", contractId)
      .eq("company_id", companyId)
      .maybeSingle();

    if (contractErr) {
      throw contractErr;
    }
    const contractNoRaw = str(contractRow?.number).trim();
    const contractNo = contractNoRaw.length > 0 ? contractNoRaw : contractId;

    const estimateMaps: Record<string, unknown>[] = [];
    let estOffset = 0;
    while (true) {
      let q = supabase
        .from(VIEW)
        .select(
          "id, system, subsystem, number, name, article, manufacturer, unit, quantity, price, total",
        )
        .eq("company_id", companyId)
        .eq("contract_id", contractId)
        .eq("estimate_title", trimmedTitle)
        .order("system", { ascending: true })
        .order("number", { ascending: true })
        .range(estOffset, estOffset + PAGE_SIZE - 1);

      if (objectId == null) {
        q = q.is("object_id", null);
      } else {
        q = q.eq("object_id", objectId);
      }

      const { data: chunk, error: estErr } = await q;
      if (estErr) {
        throw estErr;
      }
      const rows = chunk ?? [];
      if (rows.length === 0) {
        break;
      }
      estimateMaps.push(...rows);
      if (rows.length < PAGE_SIZE) {
        break;
      }
      estOffset += PAGE_SIZE;
    }

    if (estimateMaps.length === 0) {
      throw new Error("Нет строк сметы для выгрузки");
    }

    const rows: EstimateRow[] = estimateMaps.map((m) => ({
      estimateId: str(m.id).trim(),
      system: str(m.system),
      subsystem: str(m.subsystem),
      number: str(m.number),
      name: str(m.name),
      article: str(m.article),
      manufacturer: str(m.manufacturer),
      unit: str(m.unit),
      contractQuantity: toNum(m.quantity),
      contractPrice: toNum(m.price),
      contractTotal: toNum(m.total),
    }));

    const estimateIds = rows
      .map((r) => r.estimateId)
      .filter((id) => id.length > 0);
    const executionByEstimateId = await loadExecutionByEstimateId(
      userSupabase,
      companyId,
      estimateIds,
    );

    const header: string[] = [
      "Система",
      "Подсистема",
      "№",
      "Наименование",
      "Артикул",
      "Производитель",
      "Ед. изм.",
      "Кол-во (договор)",
      "Цена",
      "Сумма (договор)",
      "Кол-во (Выполнено)",
      "Сумма (Выполнено)",
    ];

    const workbook = new ExcelJS.Workbook();
    workbook.creator = "ProjectGT";
    workbook.created = new Date();

    const sheet = workbook.addWorksheet(SHEET_NAME, {
      views: [
        {
          state: "frozen",
          xSplit: 0,
          ySplit: 2,
          activeCell: "A3",
        },
      ],
    });

    sheet.columns = Array.from({ length: COL_COUNT }, (_, i) => ({
      width: columnWidthForIndex(i + 1),
    }));

    sheet.addRow([]);
    const top = sheet.getRow(1);
    top.getCell(1).value = "Позиция";
    sheet.mergeCells("A1:G1");
    top.getCell(8).value = "Договор";
    sheet.mergeCells(`${colLetter(8)}1:${colLetter(10)}1`);
    top.getCell(11).value = "Выполнение";
    sheet.mergeCells(`${colLetter(11)}1:${colLetter(12)}1`);

    sheet.addRow(header);
    styleHeaderRow(sheet, 1);
    styleHeaderRow(sheet, 2);

    let sumContractQty = 0;
    let sumContractTotal = 0;
    let sumCompletedQty = 0;
    let sumCompletedTotal = 0;

    for (const row of rows) {
      const execution = executionByEstimateId.get(row.estimateId);
      const completedQty = execution?.completedQuantity ?? 0;
      const completedTotal = row.contractPrice * completedQty;

      sumContractQty += row.contractQuantity;
      sumContractTotal += row.contractTotal;
      sumCompletedQty += completedQty;
      sumCompletedTotal += completedTotal;

      const r = sheet.addRow([
        row.system,
        row.subsystem,
        row.number,
        row.name,
        row.article,
        row.manufacturer,
        row.unit,
        row.contractQuantity,
        row.contractPrice,
        row.contractTotal,
        completedQty,
        completedTotal,
      ]);
      styleDataRow(sheet, r.number);
    }

    const footer = sheet.addRow([
      "",
      "",
      "",
      "Итого по договору",
      "",
      "",
      "",
      sumContractQty,
      "",
      sumContractTotal,
      sumCompletedQty,
      sumCompletedTotal,
    ]);
    for (let c = 1; c <= COL_COUNT; c++) {
      const cell = footer.getCell(c);
      cell.border = borderThin;
      cell.font = { ...FONT_MAIN, bold: true };
      cell.fill = {
        type: "pattern",
        pattern: "solid",
        fgColor: { argb: "FFF0F0F0" },
      };
      if (c === 4) {
        cell.alignment = { vertical: "middle", horizontal: "left" };
      } else if (c >= 8) {
        cell.alignment = { vertical: "middle", horizontal: "right" };
        if (typeof cell.value === "number") {
          cell.numFmt = "#,##0.00";
        }
      }
    }

    applySheetFont(sheet);
    const buffer = await workbook.xlsx.writeBuffer();
    const base64 = encode(new Uint8Array(buffer));
    const safeNo = sanitizeFileNameComponent(contractNo);
    const safeTitle = sanitizeFileNameComponent(trimmedTitle);
    const filename = `Смета_выполнение_${safeNo}_${safeTitle}.xlsx`;

    return jsonResponse({
      success: true,
      filename,
      base64,
      rows: rows.length,
      message: "Excel со сметой и выполнением сформирован",
    });
  } catch (error) {
    const message = error instanceof Error ? error.message : String(error);
    return jsonResponse({ success: false, message }, 500);
  }
});
