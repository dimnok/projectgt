import { serve } from "https://deno.land/std@0.208.0/http/server.ts";
import { encode } from "https://deno.land/std@0.208.0/encoding/base64.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.3";
import ExcelJS from "npm:exceljs@4.4.0";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
  "Access-Control-Allow-Headers": "authorization, content-type, apikey, x-client-info",
};

const borderStyle = {
  top: { style: "thin", color: { argb: "22000000" } },
  left: { style: "thin", color: { argb: "22000000" } },
  bottom: { style: "thin", color: { argb: "22000000" } },
  right: { style: "thin", color: { argb: "22000000" } },
} as const;

const objectPalette = [
  "FFE3F2FD",
  "FFE8F5E9",
  "FFFFF3E0",
  "FFF3E5F5",
  "FFE0F2F1",
  "FFFFEBEE",
  "FFF1F8E9",
  "FFE8EAF6",
  "FFFFF8E1",
  "FFEDE7F6",
  "FFE0F7FA",
  "FFFBE9E7",
];

const weekdayMap: Record<number, string> = {
  1: "пн",
  2: "вт",
  3: "ср",
  4: "чт",
  5: "пт",
  6: "сб",
  0: "вс",
};

interface ExportTimesheetRequest {
  companyId: string;
  startDate: string;
  endDate: string;
  objectIds?: string[];
  positions?: string[];
}

interface EmployeeRow {
  id: string;
  fullName: string;
  status: string;
}

interface TimesheetEntryRow {
  employeeId: string;
  objectId: string;
  objectName: string;
  date: string;
  hours: number;
}

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response(null, {
      status: 204,
      headers: corsHeaders,
    });
  }

  if (req.method !== "POST") {
    return jsonResponse(
      { success: false, message: "Method not allowed" },
      405,
    );
  }

  try {
    const request = await req.json() as ExportTimesheetRequest;
    validateRequest(request);

    const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
    const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
    if (!supabaseUrl || !serviceRoleKey) {
      throw new Error("Missing Supabase environment variables");
    }

    const supabase = createClient(supabaseUrl, serviceRoleKey, { auth: { persistSession: false } });
    await ensureCompanyAccess(supabase, req, request.companyId);

    const employeeRows = await loadEmployees(supabase, request);
    const objectRows = await loadObjects(supabase, request);

    const objectNameById = new Map<string, string>(
      objectRows.map((row: { id: string; name: string }) => [row.id, row.name]),
    );
    const employeeIds = employeeRows.map((row) => row.id);

    const entries = employeeIds.length === 0
      ? []
      : await loadTimesheetEntries(
        supabase,
        request,
        employeeIds,
        objectNameById,
      );

    const employeeIdsWithHours = new Set(entries.map((entry) => entry.employeeId));
    
    const hasObjectFilter = request.objectIds && request.objectIds.length > 0;

    const visibleEmployees = employeeRows
      .filter((employee) => {
        // Если включен фильтр по объектам, показываем ТОЛЬКО тех, у кого есть часы
        if (hasObjectFilter) {
          return employeeIdsWithHours.has(employee.id);
        }
        // Иначе показываем всех активных + уволенных с часами
        return employee.status !== "fired" || employeeIdsWithHours.has(employee.id);
      })
      .sort((a, b) => a.fullName.localeCompare(b.fullName, "ru"));

    if (visibleEmployees.length === 0) {
      return jsonResponse({
        success: false,
        message: "Нет данных для экспорта по выбранным фильтрам",
      });
    }

    const legendItems = buildLegendItems(entries);
    const objectColorById = new Map<string, string>(
      legendItems.map((item) => [item.objectId, item.color]),
    );

    const workbook = new ExcelJS.Workbook();
    const worksheet = workbook.addWorksheet("Табель");
    const daysInRange = buildDateRange(request.startDate, request.endDate);
    const totalColumns = daysInRange.length + 2;

    worksheet.views = [{ state: "frozen", xSplit: 1, ySplit: 5, activeCell: "B6" }];

    worksheet.mergeCells(1, 1, 1, totalColumns);
    worksheet.getCell(1, 1).value = "ТАБЕЛЬ РАБОЧЕГО ВРЕМЕНИ";
    worksheet.getCell(1, 1).font = { bold: true, size: 14 };
    worksheet.getCell(1, 1).alignment = {
      horizontal: "center",
      vertical: "middle",
    };

    worksheet.mergeCells(2, 1, 2, totalColumns);
    worksheet.getCell(2, 1).value =
      `Период: ${formatRuDate(request.startDate)} - ${formatRuDate(request.endDate)}`;
    worksheet.getCell(2, 1).alignment = {
      horizontal: "center",
      vertical: "middle",
    };

    worksheet.mergeCells(3, 1, 3, totalColumns);
    worksheet.getCell(3, 1).value =
      `Дата формирования: ${new Date().toLocaleString("ru-RU")}`;
    worksheet.getCell(3, 1).alignment = {
      horizontal: "center",
      vertical: "middle",
    };
    worksheet.getCell(3, 1).font = { italic: true, size: 10 };

    const headerRow = worksheet.getRow(4);
    headerRow.values = [
      "Сотрудник",
      ...daysInRange.map((day) => day.getDate()),
      "Итого",
    ];
    headerRow.height = 24;

    const weekdayRow = worksheet.getRow(5);
    weekdayRow.values = [
      "",
      ...daysInRange.map((day) => weekdayMap[day.getDay()] ?? ""),
      "",
    ];
    weekdayRow.height = 22;

    styleHeaderRow(headerRow, daysInRange, totalColumns);
    styleWeekdayRow(weekdayRow, daysInRange, totalColumns);

    const cellMap = buildCellMap(entries);
    let currentRowNumber = 6;

    for (const employee of visibleEmployees) {
      const row = worksheet.getRow(currentRowNumber);
      row.getCell(1).value = employee.fullName;
      row.getCell(1).alignment = {
        vertical: "middle",
        horizontal: "left",
        wrapText: false,
      };

      let employeeTotal = 0;

      daysInRange.forEach((day, index) => {
        const dayKey = toDateKey(day);
        const cell = cellMap.get(`${employee.id}__${dayKey}`);
        const worksheetCell = row.getCell(index + 2);

        if (cell && cell.totalHours > 0) {
          worksheetCell.value = cell.totalHours;
          worksheetCell.numFmt = getHoursNumFmt(cell.totalHours);
          worksheetCell.fill = buildExcelFill(cell.objectHours, objectColorById);
          employeeTotal += cell.totalHours;
        }

        worksheetCell.alignment = {
          horizontal: "center",
          vertical: "middle",
        };
      });

      const totalCell = row.getCell(totalColumns);
      totalCell.value = employeeTotal;
      totalCell.numFmt = getHoursNumFmt(employeeTotal);
      totalCell.font = { bold: true };
      totalCell.alignment = { horizontal: "center", vertical: "middle" };

      row.eachCell({ includeEmpty: true }, (cell) => {
        cell.border = borderStyle;
      });
      row.height = 24;
      currentRowNumber += 1;
    }

    const totalRow = worksheet.getRow(currentRowNumber);
    totalRow.getCell(1).value = "Итого по дням";
    totalRow.getCell(1).font = { bold: true };
    totalRow.getCell(1).fill = {
      type: "pattern",
      pattern: "solid",
      fgColor: { argb: "FFF2F2F2" },
    };

    let grandTotal = 0;
    daysInRange.forEach((day, index) => {
      const dayKey = toDateKey(day);
      let dayTotal = 0;
      for (const employee of visibleEmployees) {
        const cell = cellMap.get(`${employee.id}__${dayKey}`);
        dayTotal += cell?.totalHours ?? 0;
      }
      grandTotal += dayTotal;

      const worksheetCell = totalRow.getCell(index + 2);
      worksheetCell.value = dayTotal;
      worksheetCell.numFmt = getHoursNumFmt(dayTotal);
      worksheetCell.font = { bold: true };
      worksheetCell.alignment = { horizontal: "center", vertical: "middle" };
      worksheetCell.fill = {
        type: "pattern",
        pattern: "solid",
        fgColor: { argb: "FFF2F2F2" },
      };
    });

    const grandTotalCell = totalRow.getCell(totalColumns);
    grandTotalCell.value = grandTotal;
    grandTotalCell.numFmt = getHoursNumFmt(grandTotal);
    grandTotalCell.font = { bold: true };
    grandTotalCell.alignment = { horizontal: "center", vertical: "middle" };
    grandTotalCell.fill = {
      type: "pattern",
      pattern: "solid",
      fgColor: { argb: "FFF2F2F2" },
    };

    totalRow.eachCell({ includeEmpty: true }, (cell) => {
      cell.border = borderStyle;
    });

    let legendStartRow = currentRowNumber + 3;
    if (legendItems.length > 0) {
      worksheet.mergeCells(legendStartRow, 1, legendStartRow, 2);
      worksheet.getCell(legendStartRow, 1).value = "Легенда объектов";
      worksheet.getCell(legendStartRow, 1).font = { bold: true };
      legendStartRow += 1;

      for (const item of legendItems) {
        const row = worksheet.getRow(legendStartRow);
        const colorCell = row.getCell(1);
        const nameCell = row.getCell(2);

        colorCell.value = "";
        colorCell.fill = {
          type: "pattern",
          pattern: "solid",
          fgColor: { argb: item.color },
        };
        colorCell.border = borderStyle;

        nameCell.value = item.objectName;
        nameCell.border = borderStyle;

        legendStartRow += 1;
      }
    }

    worksheet.columns = [
      { width: 30 },
      ...daysInRange.map(() => ({ width: 6.5 })),
      { width: 10 },
    ];

    const buffer = await workbook.xlsx.writeBuffer();
    const base64 = encode(new Uint8Array(buffer));

    return jsonResponse({
      success: true,
      filename: `Табель_${request.startDate}_${request.endDate}.xlsx`,
      base64,
      rows: visibleEmployees.length,
      message: "Excel-файл табеля успешно сформирован",
    });
  } catch (error) {
    const message = error instanceof Error ? error.message : String(error);
    return jsonResponse({ success: false, message }, 500);
  }
});

function jsonResponse(body: Record<string, unknown>, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      ...corsHeaders,
      "Content-Type": "application/json",
    },
  });
}

function validateRequest(request: ExportTimesheetRequest) {
  if (!request.companyId) {
    throw new Error("companyId is required");
  }
  if (!request.startDate || !request.endDate) {
    throw new Error("startDate and endDate are required");
  }
}

async function ensureCompanyAccess(
  supabase: ReturnType<typeof createClient>,
  req: Request,
  companyId: string,
) {
  const authHeader = req.headers.get("Authorization");
  const token = authHeader?.replace(/^Bearer\s+/i, "").trim();

  if (!token) {
    throw new Error("Authorization token is required");
  }

  const { data: userData, error: userError } = await supabase.auth.getUser(token);
  if (userError || !userData.user) {
    throw new Error("Не удалось определить пользователя");
  }

  const { data: membership, error: membershipError } = await supabase
    .from("company_members")
    .select("id")
    .eq("company_id", companyId)
    .eq("user_id", userData.user.id)
    .eq("is_active", true)
    .maybeSingle();

  if (membershipError || !membership) {
    throw new Error("Нет доступа к выбранной компании");
  }
}

async function loadEmployees(
  supabase: ReturnType<typeof createClient>,
  request: ExportTimesheetRequest,
): Promise<EmployeeRow[]> {
  let query = supabase
    .from("employees")
    .select("id, last_name, first_name, middle_name, position, status")
    .eq("company_id", request.companyId);

  if (request.positions && request.positions.length > 0) {
    query = query.in("position", request.positions);
  }

  const { data, error } = await query;
  if (error) throw error;

  return (data ?? []).map((employee: Record<string, unknown>) => ({
    id: String(employee.id),
    fullName: buildFullName(employee),
    status: String(employee.status ?? ""),
  }));
}

async function loadObjects(
  supabase: ReturnType<typeof createClient>,
  request: ExportTimesheetRequest,
) {
  let query = supabase
    .from("objects")
    .select("id, name")
    .eq("company_id", request.companyId);

  if (request.objectIds && request.objectIds.length > 0) {
    query = query.in("id", request.objectIds);
  }

  const { data, error } = await query;
  if (error) throw error;

  return data ?? [];
}

async function loadTimesheetEntries(
  supabase: ReturnType<typeof createClient>,
  request: ExportTimesheetRequest,
  employeeIds: string[],
  objectNameById: Map<string, string>,
): Promise<TimesheetEntryRow[]> {
  const results: TimesheetEntryRow[] = [];

  let workQuery = supabase
    .from("work_hours")
    .select(`
      employee_id,
      hours,
      works!inner (
        date,
        object_id,
        status,
        company_id
      )
    `)
    .eq("company_id", request.companyId)
    .eq("works.status", "closed")
    .eq("works.company_id", request.companyId)
    .in("employee_id", employeeIds)
    .gte("works.date", request.startDate)
    .lte("works.date", request.endDate);

  if (request.objectIds && request.objectIds.length > 0) {
    workQuery = workQuery.in("works.object_id", request.objectIds);
  }

  const { data: workRows, error: workError } = await workQuery;
  if (workError) throw workError;

  for (const row of workRows ?? []) {
    const workSource = row.works as Record<string, unknown> | Record<string, unknown>[] | null;
    const work = Array.isArray(workSource) ? workSource[0] ?? null : workSource;
    if (!work?.date || !work.object_id) continue;

    const objectId = String(work.object_id);
    results.push({
      employeeId: String(row.employee_id),
      objectId,
      objectName: objectNameById.get(objectId) ?? "Объект",
      date: String(work.date),
      hours: Number(row.hours) || 0,
    });
  }

  let attendanceQuery = supabase
    .from("employee_attendance")
    .select("employee_id, object_id, date, hours")
    .eq("company_id", request.companyId)
    .in("employee_id", employeeIds)
    .gte("date", request.startDate)
    .lte("date", request.endDate);

  if (request.objectIds && request.objectIds.length > 0) {
    attendanceQuery = attendanceQuery.in("object_id", request.objectIds);
  }

  const { data: attendanceRows, error: attendanceError } = await attendanceQuery;
  if (attendanceError) throw attendanceError;

  for (const row of attendanceRows ?? []) {
    const objectId = String(row.object_id);
    results.push({
      employeeId: String(row.employee_id),
      objectId,
      objectName: objectNameById.get(objectId) ?? "Объект",
      date: String(row.date),
      hours: Number(row.hours) || 0,
    });
  }

  return results;
}

function buildFullName(employee: Record<string, unknown>): string {
  const lastName = String(employee.last_name ?? "").trim();
  const firstName = String(employee.first_name ?? "").trim();
  const middleName = String(employee.middle_name ?? "").trim();

  return [lastName, firstName, middleName]
    .filter((value) => value.length > 0)
    .join(" ");
}

function buildDateRange(startDate: string, endDate: string): Date[] {
  const dates: Date[] = [];
  const current = new Date(`${startDate}T00:00:00`);
  const end = new Date(`${endDate}T00:00:00`);

  while (current <= end) {
    dates.push(new Date(current));
    current.setDate(current.getDate() + 1);
  }

  return dates;
}

function toDateKey(date: Date): string {
  const year = date.getFullYear();
  const month = `${date.getMonth() + 1}`.padStart(2, "0");
  const day = `${date.getDate()}`.padStart(2, "0");
  return `${year}-${month}-${day}`;
}

function formatRuDate(date: string): string {
  return new Date(`${date}T00:00:00`).toLocaleDateString("ru-RU");
}

function getHoursNumFmt(value: number): string {
  return Number.isInteger(value) ? "0" : "0.###";
}

function styleHeaderRow(
  row: ExcelJS.Row,
  daysInRange: Date[],
  totalColumns: number,
) {
  row.eachCell({ includeEmpty: true }, (cell, index) => {
    const isWeekend = index > 1 &&
      index < totalColumns &&
      [0, 6].includes(daysInRange[index - 2].getDay());

    cell.font = { bold: true };
    cell.alignment = { horizontal: "center", vertical: "middle" };
    cell.border = borderStyle;
    cell.fill = {
      type: "pattern",
      pattern: "solid",
      fgColor: { argb: isWeekend ? "FFFDECEC" : "FFF2F2F2" },
    };
  });
}

function styleWeekdayRow(
  row: ExcelJS.Row,
  daysInRange: Date[],
  totalColumns: number,
) {
  row.eachCell({ includeEmpty: true }, (cell, index) => {
    const isWeekend = index > 1 &&
      index < totalColumns &&
      [0, 6].includes(daysInRange[index - 2].getDay());

    cell.font = { bold: true, size: 10 };
    cell.alignment = { horizontal: "center", vertical: "middle" };
    cell.border = borderStyle;
    cell.fill = {
      type: "pattern",
      pattern: "solid",
      fgColor: { argb: isWeekend ? "FFFDECEC" : "FFFAFAFA" },
    };
  });
}

function buildCellMap(entries: TimesheetEntryRow[]) {
  const cellMap = new Map<
    string,
    { totalHours: number; objectHours: Map<string, number> }
  >();

  for (const entry of entries) {
    const key = `${entry.employeeId}__${entry.date}`;
    const existing = cellMap.get(key) ?? {
      totalHours: 0,
      objectHours: new Map<string, number>(),
    };

    existing.totalHours += entry.hours;
    existing.objectHours.set(
      entry.objectId,
      (existing.objectHours.get(entry.objectId) ?? 0) + entry.hours,
    );
    cellMap.set(key, existing);
  }

  return cellMap;
}

function buildLegendItems(entries: TimesheetEntryRow[]) {
  const objects = new Map<string, string>();

  for (const entry of entries) {
    if (!entry.objectId) continue;
    if (!objects.has(entry.objectId)) {
      objects.set(entry.objectId, entry.objectName || "Объект");
    }
  }

  return Array.from(objects.entries())
    .sort((a, b) => a[1].localeCompare(b[1], "ru"))
    .map(([objectId, objectName], index) => ({
      objectId,
      objectName,
      color: objectPalette[index % objectPalette.length],
    }));
}

function buildExcelFill(
  objectHours: Map<string, number>,
  objectColorById: Map<string, string>,
): ExcelJS.Fill {
  const segments = Array.from(objectHours.entries())
    .filter(([, value]) => value > 0)
    .sort((a, b) => a[0].localeCompare(b[0]));

  if (segments.length <= 1) {
    const color = objectColorById.get(segments[0]?.[0] ?? "") ?? objectPalette[0];
    return {
      type: "pattern",
      pattern: "solid",
      fgColor: { argb: color },
    };
  }

  const totalHours = segments.reduce((sum, [, value]) => sum + value, 0);
  const stops: Array<{ position: number; color: { argb: string } }> = [];
  let currentStop = 0;

  for (let index = 0; index < segments.length; index++) {
    const [objectId, hours] = segments[index];
    const nextStop = index === segments.length - 1
      ? 1
      : Math.min(1, currentStop + (hours / totalHours));
    const color = objectColorById.get(objectId) ?? objectPalette[0];

    stops.push({ position: currentStop, color: { argb: color } });
    stops.push({ position: nextStop, color: { argb: color } });

    currentStop = nextStop;
  }

  return {
    type: "gradient",
    gradient: "angle",
    degree: 0,
    stops,
  };
}
