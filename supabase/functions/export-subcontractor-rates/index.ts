import { serve } from "https://deno.land/std@0.208.0/http/server.ts";
import { encode } from "https://deno.land/std@0.208.0/encoding/base64.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.3";
import ExcelJS from "npm:exceljs@4.4.0";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
  "Access-Control-Allow-Headers": "authorization, content-type, apikey, x-client-info",
};

const SHEET_NAME = "Расценки суба";
const EXECUTION_SHEET_NAME = "Выполнение";

const COL_COUNT = 12;

/** Как в UI [SubcontractorsEstimateTableView]; первая колонка — для импорта по UUID. */
const HEADERS = [
  "ID позиции",
  "№",
  "Наименование",
  "Артикул",
  "Производитель",
  "Ед. изм.",
  "Кол-во",
  "Цена",
  "Сумма",
  "Кол-во суб",
  "Цена суб",
  "Сумма суб",
];

const EXECUTION_HEADERS = [
  "ID позиции",
  "№",
  "Наименование",
  "Ед. изм.",
  "Кол-во",
  "Цена",
  "Сумма",
  "Выполнено",
  "Сумма вып.",
  "%",
  "Остаток",
  "Сумма ост.",
];

const FONT_MAIN = { name: "Times New Roman", size: 11 } as const;

/** Буква столбца Excel (1 = A). */
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

const borderThin = {
  top: { style: "thin" as const, color: { argb: "FF000000" } },
  left: { style: "thin" as const, color: { argb: "FF000000" } },
  bottom: { style: "thin" as const, color: { argb: "FF000000" } },
  right: { style: "thin" as const, color: { argb: "FF000000" } },
};

interface Body {
  /** rates — текущий экспорт расценок; execution — лист выполнения. */
  exportMode?: "rates" | "execution";
  companyId: string;
  contractId: string;
  objectId: string;
  /** Если задан — подставить из БД расценку и объём подрядчика по позициям. */
  contractorId?: string;
  /** Если задан непустой список — выгрузить только выбранные позиции. */
  estimateIds?: string[];
}

interface PriceRow {
  unit_price: number | null;
  contractor_quantity: number | null;
}

interface ExecutionRow {
  completed_quantity: number;
  rows_count: number;
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
    if (!body.companyId || !body.contractId || !body.objectId) {
      throw new Error("Нужны companyId, contractId и objectId");
    }
    const selectedEstimateIds = normalizeEstimateIds(body.estimateIds);
    const exportMode = body.exportMode === "execution" ? "execution" : "rates";
    if (exportMode === "execution" && !body.contractorId) {
      throw new Error("Для экспорта выполнения выберите подрядчика");
    }

    await ensureCompanyAccess(supabase, req, body.companyId);

    const { data: contract, error: contractErr } = await supabase
      .from("contracts")
      .select("id, number, company_id")
      .eq("id", body.contractId)
      .eq("company_id", body.companyId)
      .single();

    if (contractErr || !contract) {
      throw new Error("Договор не найден или нет доступа");
    }

    let estimatesQuery = supabase
      .from("estimates")
      .select(
        "id, estimate_title, number, name, article, manufacturer, unit, quantity, price, total",
      )
      .eq("company_id", body.companyId)
      .eq("contract_id", body.contractId)
      .eq("object_id", body.objectId);
    if (selectedEstimateIds.length > 0) {
      estimatesQuery = estimatesQuery.in("id", selectedEstimateIds);
    }
    const { data: rawEstimates, error: estErr } = await estimatesQuery;

    if (estErr) throw estErr;

    const rows = (rawEstimates ?? []) as Record<string, unknown>[];
    const sorted = [...rows].sort(compareForExport);
    const groups = buildTitleGroups(sorted);

    const priceByEstimateId = new Map<string, PriceRow>();
    if (body.contractorId) {
      const ids = sorted.map((e) => String(e["id"] ?? ""));
      const chunk = 200;
      for (let i = 0; i < ids.length; i += chunk) {
        const part = ids.slice(i, i + chunk);
        const { data: priceRows, error: prErr } = await supabase
          .from("estimate_contractor_prices")
          .select("estimate_id, unit_price, contractor_quantity")
          .eq("company_id", body.companyId)
          .eq("contractor_id", body.contractorId)
          .in("estimate_id", part);
        if (prErr) throw prErr;
        for (const pr of priceRows ?? []) {
          const rec = pr as Record<string, unknown>;
          const eid = String(rec["estimate_id"] ?? "");
          if (!eid) continue;
          const up = rec["unit_price"];
          const cq = rec["contractor_quantity"];
          priceByEstimateId.set(eid, {
            unit_price: up == null ? null : toNum(up),
            contractor_quantity: cq == null ? null : toNum(cq),
          });
        }
      }
    }

    if (exportMode === "execution") {
      const executionByEstimateId = await loadExecutionByEstimateId(
        supabase,
        body,
        sorted.map((e) => String(e["id"] ?? "")).filter((id) => id.length > 0),
      );
      return await buildExecutionResponse(
        groups,
        priceByEstimateId,
        executionByEstimateId,
        (contract as { number?: string }).number || "договор",
      );
    }

    const workbook = new ExcelJS.Workbook();
    const sheet = workbook.addWorksheet(SHEET_NAME, {
      views: [{ state: "frozen", ySplit: 1, xSplit: 0 }],
    });

    sheet.addRow(HEADERS);
    const headerRow = sheet.getRow(1);
    headerRow.font = { bold: true, ...FONT_MAIN };
    headerRow.height = 28;
    for (let c = 1; c <= COL_COUNT; c++) {
      const cell = headerRow.getCell(c);
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

    // ID+№: 7, Наименование: 105, Артикул/Производитель/Цена/Сумма: 15, Ед.изм+Кол-во: 10, блок суба
    const colWidths: { width: number }[] = [
      { width: 7 },
      { width: 7 },
      { width: 105 },
      { width: 15 },
      { width: 15 },
      { width: 10 },
      { width: 10 },
      { width: 15 },
      { width: 15 },
      { width: 14 },
      { width: 15 },
      { width: 16 },
    ];
    colWidths.forEach((w, i) => {
      sheet.getColumn(i + 1).width = w.width;
    });

    /** Номера строк «Итого по разделу» (колонки I и L) — для формулы «Итого по договору». */
    const sectionFooterRows: number[] = [];

    for (const g of groups) {
      const titleRow = sheet.addRow(new Array(COL_COUNT).fill(""));
      // Без merge: подпись группы в колонке «Наименование» (кол. 3)
      for (let c = 1; c <= COL_COUNT; c++) {
        const cell = titleRow.getCell(c);
        cell.border = borderThin;
        cell.fill = {
          type: "pattern",
          pattern: "solid",
          fgColor: { argb: "FFD8D8D8" },
        };
        if (c === 3) {
          cell.value = g.displayTitle;
          cell.font = { bold: true, ...FONT_MAIN };
          cell.alignment = {
            vertical: "middle",
            horizontal: "left",
            wrapText: true,
          };
        } else {
          cell.alignment = { vertical: "middle" };
        }
      }

      const firstDataRow = sheet.lastRow.number + 1;
      for (const e of g.items) {
        const eid = String(e["id"] ?? "");
        const pr = priceByEstimateId.get(eid);
        const priceSub = body.contractorId && pr?.unit_price != null
          ? pr.unit_price
          : "";
        const qtySub = !body.contractorId || pr?.unit_price == null
          ? ""
          : pr.contractor_quantity != null
          ? pr.contractor_quantity
          : toNum(e["quantity"]);
        const subNumeric = lineSubcontractorSum(e, pr, body.contractorId);
        const planTotal = toNum(e["total"]);

        const r = sheet.addRow([
          eid,
          String(e["number"] ?? ""),
          String(e["name"] ?? ""),
          String(e["article"] ?? ""),
          String(e["manufacturer"] ?? ""),
          String(e["unit"] ?? ""),
          toNum(e["quantity"]),
          toNum(e["price"]),
          null,
          qtySub,
          priceSub,
          body.contractorId ? null : "",
        ]);
        const rn = r.number;
        const gCol = colLetter(7);
        const hCol = colLetter(8);
        const jCol = colLetter(10);
        const kCol = colLetter(11);
        r.getCell(9).value = {
          formula: `${gCol}${rn}*${hCol}${rn}`,
          result: planTotal,
        };
        if (body.contractorId) {
          r.getCell(12).value = {
            formula: `${jCol}${rn}*${kCol}${rn}`,
            result: typeof subNumeric === "number" ? subNumeric : 0,
          };
        } else {
          r.getCell(12).value = "";
        }

        for (let c = 1; c <= COL_COUNT; c++) {
          r.getCell(c).border = borderThin;
        }
        r.getCell(3).alignment = {
          vertical: "top",
          horizontal: "left",
          wrapText: true,
        };
        r.getCell(7).numFmt = "#,##0.00";
        r.getCell(8).numFmt = "#,##0.00";
        r.getCell(9).numFmt = "#,##0.00";
        r.getCell(10).numFmt = "#,##0.00";
        r.getCell(11).numFmt = "#,##0.00";
        if (body.contractorId) {
          r.getCell(12).numFmt = "#,##0.00";
        }
      }
      const lastDataRow = sheet.lastRow.number;

      const sumSection = g.items.reduce(
        (acc, e) => acc + toNum(e["total"]),
        0,
      );
      const sumSectionSub = sectionSubcontractorSum(
        g.items,
        priceByEstimateId,
        body.contractorId,
      );
      const totalRow = sheet.addRow([
        "",
        "",
        "Итого по разделу",
        "",
        "",
        "",
        "",
        "",
        null,
        "",
        "",
        body.contractorId ? null : "",
      ]);
      const tr = totalRow.number;
      if (firstDataRow <= lastDataRow) {
        totalRow.getCell(9).value = {
          formula: `SUM(I${firstDataRow}:I${lastDataRow})`,
          result: sumSection,
        };
        if (body.contractorId) {
          totalRow.getCell(12).value = {
            formula: `SUM(L${firstDataRow}:L${lastDataRow})`,
            result: typeof sumSectionSub === "number" ? sumSectionSub : 0,
          };
        }
      } else {
        totalRow.getCell(9).value = 0;
        if (body.contractorId) {
          totalRow.getCell(12).value = 0;
        }
      }

      for (let c = 1; c <= COL_COUNT; c++) {
        const cell = totalRow.getCell(c);
        cell.border = borderThin;
        cell.font = { bold: true, ...FONT_MAIN };
        if (c === 3) {
          cell.alignment = {
            vertical: "middle",
            horizontal: "left",
            wrapText: true,
          };
        } else if (c === 9 || c === 12) {
          cell.alignment = { vertical: "middle", horizontal: "right" };
        } else {
          cell.alignment = { vertical: "middle", horizontal: "left" };
        }
      }
      totalRow.getCell(9).numFmt = "#,##0.00";
      if (body.contractorId) {
        totalRow.getCell(12).numFmt = "#,##0.00";
      }

      sectionFooterRows.push(tr);
    }

    const { grandPlan, grandSub } = grandTotals(
      groups,
      priceByEstimateId,
      body.contractorId,
    );
    const contractRow = sheet.addRow([
      "",
      "",
      "Итого по договору",
      "",
      "",
      "",
      "",
      "",
      null,
      "",
      "",
      body.contractorId ? null : "",
    ]);
    for (let c = 1; c <= COL_COUNT; c++) {
      const cell = contractRow.getCell(c);
      cell.border = borderThin;
      cell.font = { bold: true, ...FONT_MAIN };
      cell.fill = {
        type: "pattern",
        pattern: "solid",
        fgColor: { argb: "FFF0F0F0" },
      };
      if (c === 3) {
        cell.alignment = {
          vertical: "middle",
          horizontal: "left",
          wrapText: true,
        };
      } else if (c === 9 || c === 12) {
        cell.alignment = { vertical: "middle", horizontal: "right" };
      } else {
        cell.alignment = { vertical: "middle", horizontal: "left" };
      }
    }
    if (sectionFooterRows.length === 0) {
      contractRow.getCell(9).value = 0;
      if (body.contractorId) {
        contractRow.getCell(12).value = 0;
      }
    } else {
      const iSum = sectionFooterRows.map((r) => `I${r}`).join("+");
      contractRow.getCell(9).value = {
        formula: iSum,
        result: grandPlan,
      };
      if (body.contractorId) {
        const lSum = sectionFooterRows.map((r) => `L${r}`).join("+");
        contractRow.getCell(12).value = {
          formula: lSum,
          result: typeof grandSub === "number" ? grandSub : 0,
        };
      }
    }
    contractRow.getCell(9).numFmt = "#,##0.00";
    if (body.contractorId) {
      contractRow.getCell(12).numFmt = "#,##0.00";
    }

    applySheetFont(sheet);

    const buffer = await workbook.xlsx.writeBuffer();
    const file = encode(new Uint8Array(buffer));

    const num = (contract as { number?: string }).number || "договор";
    const filename = `Расценки_суба_${sanitizeFilenamePart(num)}_${todayRu()}.xlsx`;

    return new Response(JSON.stringify({ file, filename }), {
      status: 200,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  } catch (e) {
    const message = e instanceof Error ? e.message : String(e);
    console.error("[export-subcontractor-rates]", e);
    return jsonError(message, 400);
  }
});

function jsonError(message: string, status: number) {
  return new Response(JSON.stringify({ error: message }), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

async function loadExecutionByEstimateId(
  supabase: ReturnType<typeof createClient>,
  body: Body,
  estimateIds: string[],
): Promise<Map<string, ExecutionRow>> {
  const result = new Map<string, ExecutionRow>();
  if (!body.contractorId || estimateIds.length === 0) {
    return result;
  }

  const chunk = 200;
  for (let i = 0; i < estimateIds.length; i += chunk) {
    const part = estimateIds.slice(i, i + chunk);
    const { data, error } = await supabase
      .from("work_items")
      .select("estimate_id, quantity, works!inner(object_id, status)")
      .eq("company_id", body.companyId)
      .eq("contractor_id", body.contractorId)
      .eq("works.object_id", body.objectId)
      .eq("works.status", "closed")
      .in("estimate_id", part);
    if (error) throw error;

    for (const raw of data ?? []) {
      const rec = raw as Record<string, unknown>;
      const estimateId = String(rec["estimate_id"] ?? "");
      if (!estimateId) continue;
      const prev = result.get(estimateId) ?? {
        completed_quantity: 0,
        rows_count: 0,
      };
      prev.completed_quantity += toNum(rec["quantity"]);
      prev.rows_count += 1;
      result.set(estimateId, prev);
    }
  }

  return result;
}

async function buildExecutionResponse(
  groups: { key: string; displayTitle: string; items: Record<string, unknown>[] }[],
  priceByEstimateId: Map<string, PriceRow>,
  executionByEstimateId: Map<string, ExecutionRow>,
  contractNumber: string,
): Promise<Response> {
  const workbook = new ExcelJS.Workbook();
  const sheet = workbook.addWorksheet(EXECUTION_SHEET_NAME, {
    views: [{ state: "frozen", ySplit: 1, xSplit: 0 }],
  });

  sheet.addRow(EXECUTION_HEADERS);
  const headerRow = sheet.getRow(1);
  headerRow.font = { bold: true, ...FONT_MAIN };
  headerRow.height = 28;
  for (let c = 1; c <= COL_COUNT; c++) {
    const cell = headerRow.getCell(c);
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

  const colWidths: { width: number }[] = [
    { width: 7 },
    { width: 7 },
    { width: 105 },
    { width: 10 },
    { width: 12 },
    { width: 15 },
    { width: 16 },
    { width: 13 },
    { width: 16 },
    { width: 10 },
    { width: 13 },
    { width: 16 },
  ];
  colWidths.forEach((w, i) => {
    sheet.getColumn(i + 1).width = w.width;
  });

  const sectionFooterRows: number[] = [];

  for (const g of groups) {
    const visibleItems = g.items.filter((e) => {
      const eid = String(e["id"] ?? "");
      const hasPrice = priceByEstimateId.has(eid);
      const completed = executionByEstimateId.get(eid)?.completed_quantity ?? 0;
      return hasPrice || completed > 0;
    });
    if (visibleItems.length === 0) continue;

    const titleRow = sheet.addRow(new Array(COL_COUNT).fill(""));
    for (let c = 1; c <= COL_COUNT; c++) {
      const cell = titleRow.getCell(c);
      cell.border = borderThin;
      cell.fill = {
        type: "pattern",
        pattern: "solid",
        fgColor: { argb: "FFD8D8D8" },
      };
      if (c === 3) {
        cell.value = g.displayTitle;
        cell.font = { bold: true, ...FONT_MAIN };
        cell.alignment = {
          vertical: "middle",
          horizontal: "left",
          wrapText: true,
        };
      } else {
        cell.alignment = { vertical: "middle" };
      }
    }

    const firstDataRow = sheet.lastRow.number + 1;
    for (const e of visibleItems) {
      const eid = String(e["id"] ?? "");
      const pr = priceByEstimateId.get(eid);
      const execution = executionByEstimateId.get(eid);
      const hasPrice = pr?.unit_price != null;
      const planQuantity = !hasPrice
        ? ""
        : pr!.contractor_quantity != null
        ? pr!.contractor_quantity
        : toNum(e["quantity"]);
      const unitPrice = hasPrice ? pr!.unit_price! : "";
      const completedQuantity = execution?.completed_quantity ?? 0;

      const r = sheet.addRow([
        eid,
        String(e["number"] ?? ""),
        String(e["name"] ?? ""),
        String(e["unit"] ?? ""),
        planQuantity,
        unitPrice,
        hasPrice ? null : "",
        completedQuantity,
        hasPrice ? null : "",
        hasPrice ? null : "",
        hasPrice ? null : "",
        hasPrice ? null : "",
      ]);
      const rn = r.number;
      if (hasPrice) {
        r.getCell(7).value = {
          formula: `E${rn}*F${rn}`,
          result: toNum(planQuantity) * toNum(unitPrice),
        };
        r.getCell(9).value = {
          formula: `H${rn}*F${rn}`,
          result: completedQuantity * toNum(unitPrice),
        };
        r.getCell(10).value = {
          formula: `IF(E${rn}=0,"",H${rn}/E${rn})`,
          result: toNum(planQuantity) === 0 ? 0 : completedQuantity / toNum(planQuantity),
        };
        r.getCell(11).value = {
          formula: `E${rn}-H${rn}`,
          result: toNum(planQuantity) - completedQuantity,
        };
        r.getCell(12).value = {
          formula: `K${rn}*F${rn}`,
          result: (toNum(planQuantity) - completedQuantity) * toNum(unitPrice),
        };
      }

      for (let c = 1; c <= COL_COUNT; c++) {
        const cell = r.getCell(c);
        cell.border = borderThin;
        cell.alignment = c === 3
          ? { vertical: "top", horizontal: "left", wrapText: true }
          : { vertical: "middle", horizontal: c >= 5 ? "right" : "center" };
      }
      for (const c of [5, 6, 7, 8, 9, 11, 12]) {
        r.getCell(c).numFmt = "#,##0.00";
      }
      r.getCell(10).numFmt = "0.0%";
    }
    const lastDataRow = sheet.lastRow.number;

    const totalRow = sheet.addRow([
      "",
      "",
      "Итого по разделу",
      "",
      null,
      "",
      null,
      null,
      null,
      null,
      null,
      null,
    ]);
    const tr = totalRow.number;
    if (firstDataRow <= lastDataRow) {
      totalRow.getCell(5).value = {
        formula: `SUM(E${firstDataRow}:E${lastDataRow})`,
        result: sumExecutionColumn(visibleItems, priceByEstimateId, executionByEstimateId, "planQuantity"),
      };
      totalRow.getCell(7).value = {
        formula: `SUM(G${firstDataRow}:G${lastDataRow})`,
        result: sumExecutionColumn(visibleItems, priceByEstimateId, executionByEstimateId, "planAmount"),
      };
      totalRow.getCell(8).value = {
        formula: `SUM(H${firstDataRow}:H${lastDataRow})`,
        result: sumExecutionColumn(visibleItems, priceByEstimateId, executionByEstimateId, "completedQuantity"),
      };
      totalRow.getCell(9).value = {
        formula: `SUM(I${firstDataRow}:I${lastDataRow})`,
        result: sumExecutionColumn(visibleItems, priceByEstimateId, executionByEstimateId, "completedAmount"),
      };
      totalRow.getCell(10).value = {
        formula: `IF(E${tr}=0,"",H${tr}/E${tr})`,
        result: ratio(
          sumExecutionColumn(visibleItems, priceByEstimateId, executionByEstimateId, "completedQuantity"),
          sumExecutionColumn(visibleItems, priceByEstimateId, executionByEstimateId, "planQuantity"),
        ),
      };
      totalRow.getCell(11).value = {
        formula: `SUM(K${firstDataRow}:K${lastDataRow})`,
        result: sumExecutionColumn(visibleItems, priceByEstimateId, executionByEstimateId, "remainingQuantity"),
      };
      totalRow.getCell(12).value = {
        formula: `SUM(L${firstDataRow}:L${lastDataRow})`,
        result: sumExecutionColumn(visibleItems, priceByEstimateId, executionByEstimateId, "remainingAmount"),
      };
    }

    for (let c = 1; c <= COL_COUNT; c++) {
      const cell = totalRow.getCell(c);
      cell.border = borderThin;
      cell.font = { bold: true, ...FONT_MAIN };
      cell.alignment = c === 3
        ? { vertical: "middle", horizontal: "left", wrapText: true }
        : { vertical: "middle", horizontal: c >= 5 ? "right" : "left" };
    }
    for (const c of [5, 7, 8, 9, 11, 12]) {
      totalRow.getCell(c).numFmt = "#,##0.00";
    }
    totalRow.getCell(10).numFmt = "0.0%";
    sectionFooterRows.push(tr);
  }

  const contractRow = sheet.addRow([
    "",
    "",
    "Итого по договору",
    "",
    null,
    "",
    null,
    null,
    null,
    null,
    null,
    null,
  ]);
  for (let c = 1; c <= COL_COUNT; c++) {
    const cell = contractRow.getCell(c);
    cell.border = borderThin;
    cell.font = { bold: true, ...FONT_MAIN };
    cell.fill = {
      type: "pattern",
      pattern: "solid",
      fgColor: { argb: "FFF0F0F0" },
    };
    cell.alignment = c === 3
      ? { vertical: "middle", horizontal: "left", wrapText: true }
      : { vertical: "middle", horizontal: c >= 5 ? "right" : "left" };
  }

  if (sectionFooterRows.length === 0) {
    for (const c of [5, 7, 8, 9, 10, 11, 12]) {
      contractRow.getCell(c).value = 0;
    }
  } else {
    for (const [col, letter] of [
      [5, "E"],
      [7, "G"],
      [8, "H"],
      [9, "I"],
      [11, "K"],
      [12, "L"],
    ] as const) {
      contractRow.getCell(col).value = {
        formula: sectionFooterRows.map((r) => `${letter}${r}`).join("+"),
      };
    }
    const cr = contractRow.number;
    contractRow.getCell(10).value = {
      formula: `IF(E${cr}=0,"",H${cr}/E${cr})`,
    };
  }
  for (const c of [5, 7, 8, 9, 11, 12]) {
    contractRow.getCell(c).numFmt = "#,##0.00";
  }
  contractRow.getCell(10).numFmt = "0.0%";

  applySheetFont(sheet);

  const buffer = await workbook.xlsx.writeBuffer();
  const file = encode(new Uint8Array(buffer));
  const filename =
    `Выполнение_суба_${sanitizeFilenamePart(contractNumber)}_${todayRu()}.xlsx`;

  return new Response(JSON.stringify({ file, filename }), {
    status: 200,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

type ExecutionMetric =
  | "planQuantity"
  | "planAmount"
  | "completedQuantity"
  | "completedAmount"
  | "remainingQuantity"
  | "remainingAmount";

function sumExecutionColumn(
  items: Record<string, unknown>[],
  priceByEstimateId: Map<string, PriceRow>,
  executionByEstimateId: Map<string, ExecutionRow>,
  metric: ExecutionMetric,
): number {
  let sum = 0;
  for (const e of items) {
    const eid = String(e["id"] ?? "");
    const pr = priceByEstimateId.get(eid);
    const execution = executionByEstimateId.get(eid);
    const completedQuantity = execution?.completed_quantity ?? 0;
    const hasPrice = pr?.unit_price != null;
    const planQuantity = hasPrice
      ? pr!.contractor_quantity != null
        ? pr!.contractor_quantity
        : toNum(e["quantity"])
      : 0;
    const unitPrice = hasPrice ? pr!.unit_price ?? 0 : 0;

    switch (metric) {
      case "planQuantity":
        sum += planQuantity;
        break;
      case "planAmount":
        sum += planQuantity * unitPrice;
        break;
      case "completedQuantity":
        sum += completedQuantity;
        break;
      case "completedAmount":
        sum += completedQuantity * unitPrice;
        break;
      case "remainingQuantity":
        sum += hasPrice ? planQuantity - completedQuantity : 0;
        break;
      case "remainingAmount":
        sum += hasPrice ? (planQuantity - completedQuantity) * unitPrice : 0;
        break;
    }
  }
  return sum;
}

function ratio(numerator: number, denominator: number): number {
  if (denominator === 0) return 0;
  return numerator / denominator;
}

function normalizeEstimateIds(value: unknown): string[] {
  if (value == null) return [];
  if (!Array.isArray(value)) {
    throw new Error("estimateIds должен быть массивом");
  }
  const ids = value
    .map((id) => String(id ?? "").trim())
    .filter((id) => id.length > 0);
  return [...new Set(ids)];
}

/** Сумма по строке суба (расценка × объём суба или сметный объём); пусто без подрядчика/цены. */
function lineSubcontractorSum(
  e: Record<string, unknown>,
  pr: PriceRow | undefined,
  contractorId: string | undefined,
): number | "" {
  if (!contractorId) return "";
  if (pr?.unit_price == null) return "";
  const q = pr.contractor_quantity != null
    ? pr.contractor_quantity
    : toNum(e["quantity"]);
  return pr.unit_price * q;
}

function sectionSubcontractorSum(
  items: Record<string, unknown>[],
  priceByEstimateId: Map<string, PriceRow>,
  contractorId: string | undefined,
): number | "" {
  if (!contractorId) return "";
  let s = 0;
  for (const e of items) {
    const eid = String(e["id"] ?? "");
    const pr = priceByEstimateId.get(eid);
    if (pr?.unit_price == null) continue;
    const q = pr.contractor_quantity != null
      ? pr.contractor_quantity
      : toNum(e["quantity"]);
    s += pr.unit_price * q;
  }
  return s;
}

function grandTotals(
  groups: { items: Record<string, unknown>[] }[],
  priceByEstimateId: Map<string, PriceRow>,
  contractorId: string | undefined,
): { grandPlan: number; grandSub: number | "" } {
  let grandPlan = 0;
  let grandSub = 0;
  for (const g of groups) {
    for (const e of g.items) {
      grandPlan += toNum(e["total"]);
      if (!contractorId) continue;
      const eid = String(e["id"] ?? "");
      const pr = priceByEstimateId.get(eid);
      if (pr?.unit_price == null) continue;
      const q = pr.contractor_quantity != null
        ? pr.contractor_quantity
        : toNum(e["quantity"]);
      grandSub += pr.unit_price * q;
    }
  }
  return {
    grandPlan,
    grandSub: contractorId ? grandSub : "",
  };
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

/** Сгруппировать подряд идущие позиции с одинаковым `estimate_title` (после сортировки [compareForExport]). */
function buildTitleGroups(
  sorted: Record<string, unknown>[],
): { key: string; displayTitle: string; items: Record<string, unknown>[] }[] {
  const groups: {
    key: string;
    displayTitle: string;
    items: Record<string, unknown>[];
  }[] = [];
  for (const e of sorted) {
    const key = String((e["estimate_title"] as string) ?? "").trim();
    const displayTitle = key === "" ? "Без названия сметы" : key;
    const last = groups[groups.length - 1];
    if (last && last.key === key) {
      last.items.push(e);
    } else {
      groups.push({ key, displayTitle, items: [e] });
    }
  }
  return groups;
}

function toNum(v: unknown): number {
  if (v == null) return 0;
  if (typeof v === "number" && !Number.isNaN(v)) return v;
  const n = parseFloat(String(v));
  return Number.isNaN(n) ? 0 : n;
}

function sanitizeFilenamePart(s: string): string {
  return s.replace(/[\\/:*?"<>|]/g, "_").replace(/\s+/g, "_").trim() || "договор";
}

function todayRu(): string {
  const d = new Date();
  const dd = String(d.getDate()).padStart(2, "0");
  const mm = String(d.getMonth() + 1).padStart(2, "0");
  return `${dd}.${mm}.${d.getFullYear()}`;
}

/** Как в приложении: сначала по estimate_title, затем по «номеру сметы». */
function compareForExport(
  a: Record<string, unknown>,
  b: Record<string, unknown>,
): number {
  const ka = String((a["estimate_title"] as string) ?? "").trim();
  const kb = String((b["estimate_title"] as string) ?? "").trim();
  if (ka === "" && kb !== "") return 1;
  if (ka !== "" && kb === "") return -1;
  if (ka !== kb) {
    return ka.toLowerCase().localeCompare(kb.toLowerCase(), "ru");
  }
  const n = compareByNumber(
    String(a["number"] ?? ""),
    String(b["number"] ?? ""),
  );
  if (n !== 0) return n;
  return String(a["id"] ?? "").localeCompare(String(b["id"] ?? ""), "ru");
}

function compareByNumber(na: string, nb: string): number {
  const keyA = parseNumberSortKey(na);
  const keyB = parseNumberSortKey(nb);
  if (keyA.priority !== keyB.priority) {
    return keyA.priority - keyB.priority;
  }
  const minLen = Math.min(keyA.segments.length, keyB.segments.length);
  for (let i = 0; i < minLen; i++) {
    if (keyA.segments[i] !== keyB.segments[i]) {
      return keyA.segments[i] - keyB.segments[i];
    }
  }
  if (keyA.segments.length !== keyB.segments.length) {
    return keyA.segments.length - keyB.segments.length;
  }
  if (keyA.normalized !== keyB.normalized) {
    return keyA.normalized.localeCompare(keyB.normalized, "ru");
  }
  return 0;
}

function parseNumberSortKey(value: string): {
  priority: number;
  segments: number[];
  normalized: string;
} {
  const normalized = (value || "").trim().toLowerCase();
  if (!normalized) {
    return { priority: 3, segments: [], normalized: "" };
  }
  if (/^\d+$/.test(normalized)) {
    return {
      priority: 0,
      segments: [parseInt(normalized, 10) || 0],
      normalized,
    };
  }
  if (/^\d+(?:\.\d+)+$/.test(normalized)) {
    const parts = normalized.split(".").map((p) => parseInt(p, 10) || 0);
    return { priority: 1, segments: parts, normalized };
  }
  if (normalized.startsWith("д-")) {
    const tail = normalized.substring(2);
    const n = parseInt(tail, 10) || 0;
    return { priority: 2, segments: [n], normalized };
  }
  return { priority: 3, segments: [], normalized };
}
