import type { Worksheet } from "exceljs";

import type { Employee } from "@/features/employees/types/employee.types";
import { employeeFullName } from "@/features/employees/utils/employee.utils";
import type {
  TimesheetEntry,
  TimesheetObjectOption,
} from "@/features/timesheet/types/timesheet.types";
import {
  formatRuDate,
  getMonthDaysHeader,
  getStartAndEndDates,
} from "@/features/timesheet/utils/timesheet-date";
import {
  filterEmployeesByPositionKeys,
  isTimesheetGridEmployeeVisible,
  TimesheetHoursIndex,
} from "@/features/timesheet/utils/timesheet-visibility";

const SHEET_FONT_NAME = "Times New Roman";

const borderThin = {
  top: { style: "thin" as const, color: { argb: "22000000" } },
  left: { style: "thin" as const, color: { argb: "22000000" } },
  bottom: { style: "thin" as const, color: { argb: "22000000" } },
  right: { style: "thin" as const, color: { argb: "22000000" } },
};

function formatHoursValue(hours: number): string {
  if (hours <= 0) return "";
  if (Number.isInteger(hours)) {
    return String(hours);
  }
  return hours.toFixed(1).replace(".", ",");
}

export type ExportTimesheetExcelOptions = {
  year: number;
  month: number;
  employees: Employee[];
  entries: TimesheetEntry[];
  objectOptions: TimesheetObjectOption[];
  hasObjectFilter: boolean;
  selectedPositionKeys?: string[];
  onlyEmployeeIds?: Set<string>;
};

export async function exportTimesheetToExcel({
  year,
  month,
  employees,
  entries,
  objectOptions,
  hasObjectFilter,
  selectedPositionKeys = [],
  onlyEmployeeIds,
}: ExportTimesheetExcelOptions): Promise<void> {
  const ExcelJS = await import("exceljs");
  const workbook = new ExcelJS.Workbook();
  workbook.creator = "ProjectGT";
  workbook.created = new Date();

  const worksheet = workbook.addWorksheet("Табель");

  const { startDate, endDate, daysCount } = getStartAndEndDates(year, month);
  const daysHeader = getMonthDaysHeader(year, month);
  const totalColumns = daysCount + 3; // #, Сотрудник, days 1..N, Итого

  const hoursIndex = new TimesheetHoursIndex(entries);

  // 1. Filter visible employees for export
  let visible = employees.filter((e) =>
    isTimesheetGridEmployeeVisible({
      isFired: e.status === "fired",
      includeInTimesheet: e.includeInTimesheet,
      employeeId: e.id,
      hoursIndex,
      hasObjectFilter,
    })
  );

  visible = filterEmployeesByPositionKeys(visible, selectedPositionKeys);

  const isPartial = onlyEmployeeIds && onlyEmployeeIds.size > 0;
  if (isPartial) {
    visible = visible.filter((e) => onlyEmployeeIds.has(e.id));
  }

  visible.sort((a, b) =>
    employeeFullName(a).localeCompare(employeeFullName(b), "ru")
  );

  // Object color mapping (hex with FF alpha prefix for Excel)
  const objectColorMap = new Map<string, string>();
  for (const opt of objectOptions) {
    objectColorMap.set(opt.id, `FF${opt.colorHex}`);
  }

  // 2. Title & Period Header
  worksheet.mergeCells(1, 1, 1, totalColumns);
  const titleCell = worksheet.getCell(1, 1);
  titleCell.value = "ТАБЕЛЬ УЧЁТА РАБОЧЕГО ВРЕМЕНИ";
  titleCell.font = { name: SHEET_FONT_NAME, size: 14, bold: true };
  titleCell.alignment = { horizontal: "center", vertical: "middle" };

  worksheet.mergeCells(2, 1, 2, totalColumns);
  const periodCell = worksheet.getCell(2, 1);
  periodCell.value = `Период: ${formatRuDate(startDate)} - ${formatRuDate(endDate)}`;
  periodCell.font = { name: SHEET_FONT_NAME, size: 11 };
  periodCell.alignment = { horizontal: "center", vertical: "middle" };

  worksheet.mergeCells(3, 1, 3, totalColumns);
  const dateCell = worksheet.getCell(3, 1);
  dateCell.value = `Дата формирования: ${new Date().toLocaleString("ru-RU")}`;
  dateCell.font = { name: SHEET_FONT_NAME, italic: true, size: 9 };
  dateCell.alignment = { horizontal: "center", vertical: "middle" };

  // 3. Table Column Headers
  const headerRow = worksheet.getRow(4);
  headerRow.values = [
    "№",
    "Сотрудник",
    ...daysHeader.map((d) => d.dayNumber),
    "Итого",
  ];
  headerRow.height = 24;

  const weekdayRow = worksheet.getRow(5);
  weekdayRow.values = [
    "",
    "",
    ...daysHeader.map((d) => d.weekdayName),
    "",
  ];
  weekdayRow.height = 20;

  worksheet.mergeCells(4, 1, 5, 1); // №
  worksheet.mergeCells(4, 2, 5, 2); // Сотрудник
  worksheet.mergeCells(4, totalColumns, 5, totalColumns); // Итого

  const fillHeader = {
    type: "pattern" as const,
    pattern: "solid" as const,
    fgColor: { argb: "FFF0F2F5" },
  };

  const fillWeekend = {
    type: "pattern" as const,
    pattern: "solid" as const,
    fgColor: { argb: "FFE9ECEF" },
  };

  for (let c = 1; c <= totalColumns; c += 1) {
    const isWeekendCol =
      c >= 3 && c < totalColumns && daysHeader[c - 3]?.isWeekend;

    const cell4 = headerRow.getCell(c);
    cell4.border = borderThin;
    cell4.font = { name: SHEET_FONT_NAME, bold: true, size: 10 };
    cell4.alignment = { horizontal: "center", vertical: "middle" };
    cell4.fill = isWeekendCol ? fillWeekend : fillHeader;

    const cell5 = weekdayRow.getCell(c);
    cell5.border = borderThin;
    cell5.font = { name: SHEET_FONT_NAME, size: 9 };
    cell5.alignment = { horizontal: "center", vertical: "middle" };
    cell5.fill = isWeekendCol ? fillWeekend : fillHeader;
  }

  // 4. Data rows
  const entriesByEmployeeAndDate = new Map<string, Map<string, TimesheetEntry[]>>();
  const usedObjectIds = new Set<string>();

  for (const entry of entries) {
    let empMap = entriesByEmployeeAndDate.get(entry.employeeId);
    if (!empMap) {
      empMap = new Map();
      entriesByEmployeeAndDate.set(entry.employeeId, empMap);
    }
    let dayEntries = empMap.get(entry.date);
    if (!dayEntries) {
      dayEntries = [];
      empMap.set(entry.date, dayEntries);
    }
    dayEntries.push(entry);
    if (entry.hours > 0 && entry.objectId) {
      usedObjectIds.add(entry.objectId);
    }
  }

  let currentRowIdx = 6;
  const daySums = new Array<number>(daysCount).fill(0);
  let grandSum = 0;

  for (let i = 0; i < visible.length; i += 1) {
    const employee = visible[i];
    const empMap = entriesByEmployeeAndDate.get(employee.id);
    const row = worksheet.getRow(currentRowIdx);
    row.height = 22;

    const rowNumberCell = row.getCell(1);
    rowNumberCell.value = i + 1;
    rowNumberCell.border = borderThin;
    rowNumberCell.font = { name: SHEET_FONT_NAME, size: 10 };
    rowNumberCell.alignment = { horizontal: "center", vertical: "middle" };

    const nameCell = row.getCell(2);
    nameCell.value = employeeFullName(employee);
    nameCell.border = borderThin;
    nameCell.font = { name: SHEET_FONT_NAME, size: 10 };
    nameCell.alignment = { horizontal: "left", vertical: "middle" };

    let empTotal = 0;

    for (let d = 0; d < daysCount; d += 1) {
      const colIdx = d + 3;
      const dateStr = daysHeader[d].date;
      const dayEntries = empMap?.get(dateStr) ?? [];

      let hours = 0;
      let primaryObjectId: string | null = null;
      for (const e of dayEntries) {
        hours += e.hours;
        if (!primaryObjectId && e.objectId) {
          primaryObjectId = e.objectId;
        }
      }

      const cell = row.getCell(colIdx);
      cell.border = borderThin;
      cell.font = { name: SHEET_FONT_NAME, size: 10 };
      cell.alignment = { horizontal: "center", vertical: "middle" };

      if (hours > 0) {
        cell.value = hours;
        empTotal += hours;
        daySums[d] += hours;

        if (primaryObjectId && objectColorMap.has(primaryObjectId)) {
          cell.fill = {
            type: "pattern",
            pattern: "solid",
            fgColor: { argb: objectColorMap.get(primaryObjectId) },
          };
        }
      } else {
        cell.value = "";
        if (daysHeader[d].isWeekend) {
          cell.fill = {
            type: "pattern",
            pattern: "solid",
            fgColor: { argb: "FFFBFBFC" },
          };
        }
      }
    }

    grandSum += empTotal;

    const totalCell = row.getCell(totalColumns);
    totalCell.value = empTotal > 0 ? empTotal : "";
    totalCell.border = borderThin;
    totalCell.font = { name: SHEET_FONT_NAME, bold: true, size: 10 };
    totalCell.alignment = { horizontal: "center", vertical: "middle" };
    totalCell.fill = {
      type: "pattern",
      pattern: "solid",
      fgColor: { argb: "FFF5F5F5" },
    };

    currentRowIdx += 1;
  }

  // 5. Total Row
  const totalsRow = worksheet.getRow(currentRowIdx);
  totalsRow.height = 24;

  worksheet.mergeCells(currentRowIdx, 1, currentRowIdx, 2);
  const totalLabelCell = totalsRow.getCell(1);
  totalLabelCell.value = "ИТОГО";
  totalLabelCell.border = borderThin;
  totalLabelCell.font = { name: SHEET_FONT_NAME, bold: true, size: 10 };
  totalLabelCell.alignment = { horizontal: "center", vertical: "middle" };
  totalLabelCell.fill = {
    type: "pattern",
    pattern: "solid",
    fgColor: { argb: "FFE9ECEF" },
  };

  for (let d = 0; d < daysCount; d += 1) {
    const colIdx = d + 3;
    const cell = totalsRow.getCell(colIdx);
    cell.value = daySums[d] > 0 ? daySums[d] : "";
    cell.border = borderThin;
    cell.font = { name: SHEET_FONT_NAME, bold: true, size: 10 };
    cell.alignment = { horizontal: "center", vertical: "middle" };
    cell.fill = {
      type: "pattern",
      pattern: "solid",
      fgColor: { argb: "FFE9ECEF" },
    };
  }

  const grandTotalCell = totalsRow.getCell(totalColumns);
  grandTotalCell.value = grandSum > 0 ? grandSum : "";
  grandTotalCell.border = borderThin;
  grandTotalCell.font = { name: SHEET_FONT_NAME, bold: true, size: 11 };
  grandTotalCell.alignment = { horizontal: "center", vertical: "middle" };
  grandTotalCell.fill = {
    type: "pattern",
    pattern: "solid",
    fgColor: { argb: "FFDEE2E6" },
  };

  // 6. Legend for Objects
  const usedOptions = objectOptions.filter((opt) => usedObjectIds.has(opt.id));
  if (usedOptions.length > 0) {
    let legendRowIdx = currentRowIdx + 2;
    worksheet.mergeCells(legendRowIdx, 1, legendRowIdx, 2);
    const legendHeader = worksheet.getCell(legendRowIdx, 1);
    legendHeader.value = "Легенда объектов";
    legendHeader.font = { name: SHEET_FONT_NAME, bold: true, size: 10 };
    legendRowIdx += 1;

    for (const opt of usedOptions) {
      const legRow = worksheet.getRow(legendRowIdx);
      const colorBox = legRow.getCell(1);
      colorBox.value = "";
      colorBox.border = borderThin;
      colorBox.fill = {
        type: "pattern",
        pattern: "solid",
        fgColor: { argb: `FF${opt.colorHex}` },
      };

      const nameBox = legRow.getCell(2);
      nameBox.value = opt.name;
      nameBox.border = borderThin;
      nameBox.font = { name: SHEET_FONT_NAME, size: 9 };
      legendRowIdx += 1;
    }
  }

  // Column widths
  worksheet.getColumn(1).width = 5;
  worksheet.getColumn(2).width = 30;
  for (let d = 0; d < daysCount; d += 1) {
    worksheet.getColumn(d + 3).width = 4.8;
  }
  worksheet.getColumn(totalColumns).width = 8;

  // Build and trigger download
  const buffer = await workbook.xlsx.writeBuffer();
  const blob = new Blob([buffer], {
    type: "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
  });

  const filename = isPartial
    ? `Табель_выбранные_${formatRuDate(startDate)}_${formatRuDate(endDate)}.xlsx`
    : `Табель_${formatRuDate(startDate)}_${formatRuDate(endDate)}.xlsx`;

  const url = window.URL.createObjectURL(blob);
  const a = document.createElement("a");
  a.href = url;
  a.download = filename;
  document.body.appendChild(a);
  a.click();
  document.body.removeChild(a);
  window.URL.revokeObjectURL(url);
}
