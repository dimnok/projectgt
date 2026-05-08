import { serve } from "https://deno.land/std@0.208.0/http/server.ts";
import { encode } from "https://deno.land/std@0.208.0/encoding/base64.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.3";
import ExcelJS from "npm:exceljs@4.4.0";

const cors = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
  "Access-Control-Allow-Headers": "authorization, content-type, apikey, x-client-info",
};

const borderStyle = {
  top: { style: "thin" as const, color: { argb: "FF000000" } },
  left: { style: "thin" as const, color: { argb: "FF000000" } },
  bottom: { style: "thin" as const, color: { argb: "FF000000" } },
  right: { style: "thin" as const, color: { argb: "FF000000" } },
};

const headerFill = {
  type: "pattern" as const,
  pattern: "solid" as const,
  fgColor: { argb: "FF4472C4" },
};

const headerFont = {
  bold: true,
  color: { argb: "FFFFFFFF" },
  size: 11,
};

const totalFill = {
  type: "pattern" as const,
  pattern: "solid" as const,
  fgColor: { argb: "FFF2F2F2" },
};

const firedFill = {
  type: "pattern" as const,
  pattern: "solid" as const,
  fgColor: { argb: "FFFFE6E6" },
};

const monthNames = [
  "Январь", "Февраль", "Март", "Апрель", "Май", "Июнь",
  "Июль", "Август", "Сентябрь", "Октябрь", "Ноябрь", "Декабрь",
];

const STATUS_LABELS: Record<string, string> = {
  working: "Работает",
  vacation: "Отпуск",
  sickLeave: "Больничный",
  unpaidLeave: "Без содержания",
  fired: "Уволен",
};

interface PayrollMonthRow {
  employee_id: string;
  full_name: string;
  total_hours: number;
  base_salary: number;
  business_trip_total: number;
  bonuses_total: number;
  penalties_total: number;
  net_salary: number;
  current_hourly_rate: number;
}

interface PayoutRow {
  employee_id: string;
  amount: number;
  payout_date: string;
}

function num(v: unknown): number {
  if (v === null || v === undefined) return 0;
  const n = Number(v);
  return Number.isFinite(n) ? n : 0;
}

/** Соответствует `payoutsByEmployeeAndMonthFIFOProvider` в `payroll_providers.dart`. */
function buildFifoForYear(
  year: number,
  accrualsBeforeYear: Map<string, number>,
  allPayouts: PayoutRow[],
  payrollNetByEmployeeMonth: Map<string, Map<number, number>>,
): Map<string, { payouts: Map<number, number>; balances: Map<number, number> }> {
  const payoutsByEmployee = new Map<string, PayoutRow[]>();
  const sorted = [...allPayouts].sort(
    (a, b) => new Date(a.payout_date).getTime() - new Date(b.payout_date).getTime(),
  );
  for (const p of sorted) {
    const list = payoutsByEmployee.get(p.employee_id) ?? [];
    list.push(p);
    payoutsByEmployee.set(p.employee_id, list);
  }

  const allEmployeeIds = new Set<string>();
  accrualsBeforeYear.forEach((_, id) => allEmployeeIds.add(id));
  payoutsByEmployee.forEach((_, id) => allEmployeeIds.add(id));
  payrollNetByEmployeeMonth.forEach((_, id) => allEmployeeIds.add(id));

  const result = new Map<string, { payouts: Map<number, number>; balances: Map<number, number> }>();

  for (const employeeId of allEmployeeIds) {
    const employeePayouts = payoutsByEmployee.get(employeeId) ?? [];
    const employeePayrolls = payrollNetByEmployeeMonth.get(employeeId) ?? new Map<number, number>();

    let remainingHistoricalDebt = accrualsBeforeYear.get(employeeId) ?? 0;
    const payoutsForMonth = new Map<number, number>();

    for (const payout of employeePayouts) {
      let remainingPayout = num(payout.amount);
      const payoutDate = new Date(payout.payout_date);

      if (remainingHistoricalDebt > 0) {
        const toApplyToHistory = remainingPayout > remainingHistoricalDebt
          ? remainingHistoricalDebt
          : remainingPayout;
        remainingHistoricalDebt -= toApplyToHistory;
        remainingPayout -= toApplyToHistory;
      }

      if (remainingPayout > 0) {
        for (let m = 1; m <= 12 && remainingPayout > 0; m++) {
          const accrualForMonth = employeePayrolls.get(m) ?? 0;
          if (accrualForMonth <= 0) continue;

          const alreadyPaidInMonth = payoutsForMonth.get(m) ?? 0;
          const remainingInMonth = accrualForMonth - alreadyPaidInMonth;

          if (remainingInMonth > 0) {
            const toApplyToMonth = remainingPayout > remainingInMonth ? remainingInMonth : remainingPayout;
            payoutsForMonth.set(m, (payoutsForMonth.get(m) ?? 0) + toApplyToMonth);
            remainingPayout -= toApplyToMonth;
          }
        }
      }

      if (remainingPayout > 0 && payoutDate.getFullYear() === year) {
        const calMonth = payoutDate.getMonth() + 1;
        payoutsForMonth.set(calMonth, (payoutsForMonth.get(calMonth) ?? 0) + remainingPayout);
      }
    }

    const balancesForMonth = new Map<number, number>();
    let currentRunningBalance = remainingHistoricalDebt;

    for (let m = 1; m <= 12; m++) {
      const accrual = employeePayrolls.get(m) ?? 0;
      const payoutFIFO = payoutsForMonth.get(m) ?? 0;
      currentRunningBalance += accrual - payoutFIFO;
      balancesForMonth.set(m, currentRunningBalance);
    }

    result.set(employeeId, { payouts: payoutsForMonth, balances: balancesForMonth });
  }

  return result;
}

function employeeStatusLabel(status: string | null | undefined): string {
  if (!status) return STATUS_LABELS.working;
  return STATUS_LABELS[status] ?? status;
}

/** Буква колонки Excel (1 → A, 9 → I). */
function colLetter(col: number): string {
  let n = col;
  let s = "";
  while (n > 0) {
    const r = (n - 1) % 26;
    s = String.fromCharCode(65 + r) + s;
    n = Math.floor((n - 1) / 26);
  }
  return s;
}

/** Длина текста для автоширины (учёт формул с result). */
function cellTextLength(cell: { value: unknown }): number {
  const v = cell.value;
  if (v == null) return 0;
  if (typeof v === "object" && v !== null && "formula" in v) {
    const r = (v as { result?: unknown }).result;
    return r != null ? String(r).length : 0;
  }
  return String(v).length;
}

serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { status: 204, headers: cors });
  }

  try {
    const body = await req.json() as {
      year?: number;
      month?: number;
      companyId?: string;
      objectIds?: string[] | null;
      searchQuery?: string | null;
    };

    const year = Number(body.year);
    const month = Number(body.month);
    const companyId = body.companyId;

    if (!year || !month || !companyId) {
      throw new Error("Параметры year, month и companyId обязательны");
    }

    const objectIds = Array.isArray(body.objectIds) && body.objectIds.length > 0 ? body.objectIds : null;
    const searchRaw = typeof body.searchQuery === "string" ? body.searchQuery.trim().toLowerCase() : "";

    const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
    const supabaseKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
    const supabase = createClient(supabaseUrl, supabaseKey);

    const { data: monthRows, error: rpcError } = await supabase.rpc(
      "calculate_payroll_for_month",
      {
        p_year: year,
        p_month: month,
        p_object_ids: objectIds,
        p_company_id: companyId,
      },
    );

    if (rpcError) throw rpcError;

    let rows: PayrollMonthRow[] = (monthRows as Record<string, unknown>[] ?? []).map((row) => ({
      employee_id: String(row.employee_id),
      full_name: String(row.full_name ?? "").trim(),
      total_hours: num(row.total_hours),
      base_salary: num(row.base_salary),
      business_trip_total: num(row.business_trip_total),
      bonuses_total: num(row.bonuses_total),
      penalties_total: num(row.penalties_total),
      net_salary: num(row.net_salary),
      current_hourly_rate: num(row.current_hourly_rate),
    }));

    if (searchRaw.length > 0) {
      rows = rows.filter((r) => r.full_name.toLowerCase().includes(searchRaw));
    }

    if (rows.length === 0) {
      return new Response(
        JSON.stringify({ success: false, message: "Нет данных для экспорта" }),
        { status: 200, headers: { ...cors, "Content-Type": "application/json" } },
      );
    }

    const employeeIds = [...new Set(rows.map((r) => r.employee_id))];

    const { data: empStatusRows, error: empErr } = await supabase
      .from("employees")
      .select("id, status")
      .eq("company_id", companyId)
      .in("id", employeeIds);

    if (empErr) throw empErr;

    const statusById = new Map<string, string>();
    for (const e of empStatusRows ?? []) {
      const rec = e as { id: string; status: string | null };
      if (rec.id) statusById.set(rec.id, rec.status ?? "working");
    }

    const startOfYear = `${year}-01-01T00:00:00.000Z`;

    const accrualsBeforeYear = new Map<string, number>();
    const { data: histRows, error: histErr } = await supabase.rpc(
      "calculate_employee_balances_before_date",
      { p_before_date: startOfYear, p_company_id: companyId },
    );

    if (!histErr && histRows) {
      for (const row of histRows as { employee_id: string; accruals_sum: unknown }[]) {
        accrualsBeforeYear.set(row.employee_id, num(row.accruals_sum));
      }
    }

    const { data: payoutRows, error: payErr } = await supabase
      .from("payroll_payout")
      .select("employee_id, amount, payout_date")
      .eq("company_id", companyId)
      .order("payout_date", { ascending: false });

    if (payErr) throw payErr;

    const allPayouts: PayoutRow[] = (payoutRows as PayoutRow[] ?? []).map((p) => ({
      employee_id: p.employee_id,
      amount: num(p.amount),
      payout_date: p.payout_date,
    }));

    const payrollNetByEmployeeMonth = new Map<string, Map<number, number>>();

    const monthFutures = Array.from({ length: 12 }, (_, i) => {
      const m = i + 1;
      return supabase.rpc(
        "calculate_payroll_for_month",
        { p_year: year, p_month: m, p_company_id: companyId },
      ).then(({ data: mr, error: e }) => {
        if (e) throw e;
        return { m, list: mr as Record<string, unknown>[] ?? [] };
      });
    });

    const monthResults = await Promise.all(monthFutures);

    for (const { m, list } of monthResults) {
      for (const row of list) {
        const empId = String(row.employee_id);
        const netSalary = num(row.net_salary);
        if (!payrollNetByEmployeeMonth.has(empId)) {
          payrollNetByEmployeeMonth.set(empId, new Map());
        }
        payrollNetByEmployeeMonth.get(empId)!.set(m, netSalary);
      }
    }

    const fifoByEmployee = buildFifoForYear(year, accrualsBeforeYear, allPayouts, payrollNetByEmployeeMonth);

    const workbook = new ExcelJS.Workbook();
    const sheetName = `${monthNames[month - 1]} ${year}`;
    const sheet = workbook.addWorksheet(sheetName);

    const headers = [
      "Сотрудник", "Статус", "Часы", "Ставка", "Базовая сумма", "Премии",
      "Штрафы", "Суточные", "К выплате", "Выплаты", "Остаток", "Баланс",
    ];

    const lastCol = headers.length;

    // Закрепить шапку (первую строку).
    sheet.views = [{ state: "frozen", ySplit: 1, topLeftCell: "A2", activeCell: "A2" }];

    const headerRow = sheet.getRow(1);
    headerRow.height = 25;
    for (let c = 1; c <= lastCol; c++) {
      const cell = headerRow.getCell(c);
      cell.value = headers[c - 1];
      cell.font = headerFont;
      cell.fill = headerFill;
      cell.alignment = { horizontal: "center", vertical: "middle" };
      cell.border = borderStyle;
    }

    rows.sort((a, b) => a.full_name.localeCompare(b.full_name, "ru"));

    rows.forEach((row, idx) => {
      const rowIndex = idx + 2;
      const netSalary = row.net_salary;
      const fifo = fifoByEmployee.get(row.employee_id);
      const payouts = fifo?.payouts.get(month) ?? 0;
      const balanceEndMonth = fifo?.balances.get(month) ?? 0;
      const remainder = netSalary - payouts;
      const st = statusById.get(row.employee_id) ?? "working";
      const isFired = st === "fired";

      const excelRow = sheet.getRow(rowIndex);
      excelRow.getCell(1).value = row.full_name;
      excelRow.getCell(2).value = employeeStatusLabel(st);
      excelRow.getCell(3).value = row.total_hours;
      excelRow.getCell(4).value = row.current_hourly_rate;
      excelRow.getCell(5).value = row.base_salary;
      excelRow.getCell(6).value = row.bonuses_total;
      excelRow.getCell(7).value = row.penalties_total;
      excelRow.getCell(8).value = row.business_trip_total;
      // К выплате = база + суточные + премии − штрафы (как net_salary в RPC).
      excelRow.getCell(9).value = {
        formula: `E${rowIndex}+H${rowIndex}+F${rowIndex}-G${rowIndex}`,
        result: netSalary,
      };
      excelRow.getCell(10).value = payouts;
      // Остаток = к выплате − выплаты (FIFO за месяц).
      excelRow.getCell(11).value = {
        formula: `I${rowIndex}-J${rowIndex}`,
        result: remainder,
      };
      excelRow.getCell(12).value = balanceEndMonth;

      for (let i = 1; i <= lastCol; i++) {
        const cell = excelRow.getCell(i);
        cell.border = borderStyle;
        if (isFired) {
          cell.fill = firedFill;
        }
        if (i === 1 || i === 2) {
          cell.alignment = { horizontal: "left", vertical: "middle" };
        } else {
          cell.alignment = { horizontal: "center", vertical: "middle" };
          cell.numFmt = i === 3 ? "0.00" : "#,##0.00 ₽";
        }
      }
    });

    const totalRowIndex = rows.length + 2;
    const totalRow = sheet.getRow(totalRowIndex);
    totalRow.getCell(1).value = "ИТОГО";
    sheet.mergeCells(totalRowIndex, 1, totalRowIndex, 2);

    const colsToSum = [3, 5, 6, 7, 8, 9, 10, 11, 12];
    const firstDataRow = 2;
    const lastDataRow = totalRowIndex - 1;

    colsToSum.forEach((col) => {
      const letter = colLetter(col);
      const cell = totalRow.getCell(col);
      cell.value = {
        formula: `SUM(${letter}${firstDataRow}:${letter}${lastDataRow})`,
        result: undefined,
      };
      cell.border = borderStyle;
      cell.fill = totalFill;
      cell.font = { bold: true };
      cell.numFmt = col === 3 ? "0.00" : "#,##0.00 ₽";
      cell.alignment = { horizontal: "center", vertical: "middle" };
    });

    const totalLabelCell = totalRow.getCell(1);
    totalLabelCell.border = borderStyle;
    totalLabelCell.fill = totalFill;
    totalLabelCell.font = { bold: true };
    totalLabelCell.alignment = { horizontal: "left", vertical: "middle" };

    const totalLabelCellB = totalRow.getCell(2);
    totalLabelCellB.border = borderStyle;
    totalLabelCellB.fill = totalFill;
    totalLabelCellB.font = { bold: true };

    // Колонка «Ставка» (4) — в итогах без формулы SUM (как раньше).
    const rateTotalCell = totalRow.getCell(4);
    rateTotalCell.border = borderStyle;
    rateTotalCell.fill = totalFill;
    rateTotalCell.font = { bold: true };
    rateTotalCell.alignment = { horizontal: "center", vertical: "middle" };

    for (let c = 1; c <= lastCol; c++) {
      const column = sheet.getColumn(c);
      let maxLen = headers[c - 1].length;
      column.eachCell({ includeEmpty: true }, (cell) => {
        const len = cellTextLength(cell);
        if (len > maxLen) maxLen = len;
      });
      column.width = Math.min(Math.max(maxLen + 5, 10), 40);
    }

    const buffer = await workbook.xlsx.writeBuffer();
    const base64 = encode(new Uint8Array(buffer));
    const filename = `ФОТ_${sheetName}.xlsx`;

    return new Response(
      JSON.stringify({
        success: true,
        filename,
        base64,
        rows: rows.length,
        message: "Экспорт ФОТ успешно сформирован",
      }),
      { status: 200, headers: { ...cors, "Content-Type": "application/json" } },
    );
  } catch (error: unknown) {
    const message = error instanceof Error ? error.message : String(error);
    return new Response(JSON.stringify({ success: false, message }), {
      status: 500,
      headers: { ...cors, "Content-Type": "application/json" },
    });
  }
});
