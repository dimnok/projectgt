import type { Worksheet } from "exceljs";

import type { WorkJournalRow } from "@/features/work-journal/types/work-journal.types";
import {
  aggregateGeneralRows,
  aggregatePtoRows,
} from "@/features/work-journal/utils/work-journal-excel-aggregate";
import { parseApiDate } from "@/features/work-journal/utils/work-journal.utils";

const FONT_FAMILY = "Calibri";
const FILL_WORK = "FFF6F8FA";
const FILL_MONEY = "FFEAEFF7";
const FILL_FOOTER = "FFF0F2F5";
const TEXT_HEADER = "FF1F2328";
const TEXT_BODY = "FF24292F";
const BORDER_COLOR = "FFD0D7DE";

const borderThin = {
  top: { style: "thin" as const, color: { argb: BORDER_COLOR } },
  left: { style: "thin" as const, color: { argb: BORDER_COLOR } },
  bottom: { style: "thin" as const, color: { argb: BORDER_COLOR } },
  right: { style: "thin" as const, color: { argb: BORDER_COLOR } },
};

export type ExportWorkJournalExcelOptions = {
  items: WorkJournalRow[];
  objectName?: string;
  dateFrom?: string | null;
  dateTo?: string | null;
};

function sanitizeFileName(name: string): string {
  return name.replace(/[\\/:*?"<>|]/g, "_").replace(/\s+/g, " ").trim();
}

function applyHeaderLook(
  sheet: Worksheet,
  colCount: number,
  moneyFromColumn: number
) {
  const topRow = sheet.getRow(1);
  const headerRow = sheet.getRow(2);
  topRow.height = 24;
  headerRow.height = 26;

  for (const row of [topRow, headerRow]) {
    row.font = {
      name: FONT_FAMILY,
      size: 10,
      bold: true,
      color: { argb: TEXT_HEADER },
    };
    for (let c = 1; c <= colCount; c += 1) {
      const cell = row.getCell(c);
      cell.border = borderThin;
      cell.alignment = {
        vertical: "middle",
        horizontal: "center",
        wrapText: true,
      };
      cell.fill = {
        type: "pattern",
        pattern: "solid",
        fgColor: { argb: c < moneyFromColumn ? FILL_WORK : FILL_MONEY },
      };
    }
  }
}

function applyFooterLook(
  sheet: Worksheet,
  footerRowIndex: number,
  colCount: number,
  labelColumn: number,
  numberFormats: Record<number, string>
) {
  const footerRow = sheet.getRow(footerRowIndex);
  footerRow.height = 24;

  for (let c = 1; c <= colCount; c += 1) {
    const cell = footerRow.getCell(c);
    cell.border = {
      top: { style: "medium" as const, color: { argb: TEXT_HEADER } },
      bottom: { style: "double" as const, color: { argb: TEXT_HEADER } },
      left: { style: "thin" as const, color: { argb: BORDER_COLOR } },
      right: { style: "thin" as const, color: { argb: BORDER_COLOR } },
    };
    cell.font = {
      name: FONT_FAMILY,
      size: 10,
      bold: true,
      color: { argb: TEXT_HEADER },
    };
    cell.fill = {
      type: "pattern",
      pattern: "solid",
      fgColor: { argb: FILL_FOOTER },
    };
    if (c === labelColumn || numberFormats[c]) {
      cell.alignment = { vertical: "middle", horizontal: "right" };
    }
    if (numberFormats[c]) {
      cell.numFmt = numberFormats[c];
    }
  }
}

function autosizeColumns(
  sheet: Worksheet,
  labels: string[],
  minWidths: number[],
  startRow: number,
  endRow: number
) {
  const colCount = labels.length;
  for (let c = 1; c <= colCount; c += 1) {
    let maxContentLength = labels[c - 1]?.length ?? 10;

    for (let r = startRow; r <= endRow; r += 1) {
      const cell = sheet.getRow(r).getCell(c);
      let strLen = 0;

      if (cell.value != null) {
        if (typeof cell.value === "object" && "result" in cell.value) {
          const res = cell.value.result;
          strLen = res != null ? String(res).length + 4 : 0;
        } else if (cell.value instanceof Date) {
          strLen = 10;
        } else if (typeof cell.value === "number") {
          strLen = String(Math.round(cell.value)).length + 5;
        } else {
          const lines = String(cell.value).split(/\r?\n/);
          strLen = Math.max(...lines.map((line) => line.length));
        }
      }

      if (strLen > maxContentLength) {
        maxContentLength = strLen;
      }
    }

    sheet.getColumn(c).width = Math.max(
      maxContentLength + 4,
      minWidths[c - 1] ?? 10
    );
  }
}

function fillJournalSheet(sheet: Worksheet, items: WorkJournalRow[]) {
  const labels = [
    "Дата",
    "Система",
    "Подсистема",
    "Участок",
    "Этаж",
    "№",
    "Наименование",
    "Ед. изм.",
    "Кол-во",
    "Цена",
    "Сумма",
  ];
  const colCount = labels.length;
  const moneyFrom = 9;

  sheet.columns = labels.map(() => ({ width: 14 }));
  sheet.views = [{ state: "frozen", xSplit: 0, ySplit: 2, activeCell: "A3" }];

  const topRow = sheet.addRow([]);
  topRow.getCell(1).value = "Выполненные работы";
  sheet.mergeCells("A1:H1");
  topRow.getCell(moneyFrom).value = "Стоимость";
  sheet.mergeCells("I1:K1");
  sheet.addRow(labels);
  applyHeaderLook(sheet, colCount, moneyFrom);

  const startRow = 3;
  let currentRowIndex = startRow;

  for (const item of items) {
    const rIdx = currentRowIndex;
    const total =
      item.total ?? (item.price === null ? null : item.price * item.quantity);
    const row = sheet.addRow([
      parseApiDate(item.workDate.split("T")[0] ?? item.workDate),
      item.system || "—",
      item.subsystem || "—",
      item.section || "—",
      item.floor || "—",
      item.positionNumber || "—",
      item.workName || "—",
      item.unit || "—",
      item.quantity,
      item.price,
      item.price === null
        ? null
        : { formula: `I${rIdx}*J${rIdx}`, result: total ?? 0 },
    ]);
    row.font = { name: FONT_FAMILY, size: 10, color: { argb: TEXT_BODY } };

    for (let c = 1; c <= colCount; c += 1) {
      const cell = row.getCell(c);
      cell.border = borderThin;
      if (c === 1) {
        cell.alignment = { vertical: "middle", horizontal: "center" };
        cell.numFmt = "DD.MM.YYYY";
      } else if (c < moneyFrom) {
        cell.alignment = {
          vertical: "middle",
          horizontal: c === 5 || c === 6 || c === 8 ? "center" : "left",
          wrapText: false,
        };
      } else {
        cell.alignment = { vertical: "middle", horizontal: "right" };
        cell.numFmt = c === 9 ? "#,##0.00" : "#,##0.00 ₽";
      }
    }
    currentRowIndex += 1;
  }

  const endRow = Math.max(currentRowIndex - 1, startRow);
  const sumTotal = items.reduce((acc, item) => acc + (item.total ?? 0), 0);
  sheet.addRow([
    "",
    "",
    "",
    "",
    "",
    "",
    "Итого:",
    "",
    "",
    "",
    items.length > 0
      ? { formula: `SUM(K${startRow}:K${endRow})`, result: sumTotal }
      : 0,
  ]);
  applyFooterLook(sheet, endRow + 1, colCount, 7, { 11: "#,##0.00 ₽" });
  sheet.autoFilter = {
    from: { row: 2, column: 1 },
    to: { row: items.length > 0 ? endRow : 2, column: colCount },
  };
  autosizeColumns(sheet, labels, [12, 15, 15, 12, 10, 8, 30, 10, 12, 14, 16], startRow, endRow);
}

function fillPtoSheet(sheet: Worksheet, items: WorkJournalRow[]) {
  const rows = aggregatePtoRows(items);
  const labels = [
    "Система",
    "Подсистема",
    "Участок",
    "Этаж",
    "№",
    "Наименование",
    "М-15",
    "Ед. изм.",
    "Кол-во",
  ];
  const colCount = labels.length;
  const moneyFrom = 9;

  sheet.columns = labels.map(() => ({ width: 14 }));
  sheet.views = [{ state: "frozen", xSplit: 0, ySplit: 2, activeCell: "A3" }];

  const topRow = sheet.addRow([]);
  topRow.getCell(1).value = "ПТО";
  sheet.mergeCells("A1:H1");
  topRow.getCell(moneyFrom).value = "Количество";
  sheet.addRow(labels);
  applyHeaderLook(sheet, colCount, moneyFrom);

  const startRow = 3;
  let currentRowIndex = startRow;
  let sumQuantity = 0;

  for (const item of rows) {
    sumQuantity += item.quantity;
    const row = sheet.addRow([
      item.system,
      item.subsystem,
      item.section,
      item.floor,
      item.positionNumber,
      item.workName,
      item.m15Name,
      item.unit,
      item.quantity,
    ]);
    row.font = { name: FONT_FAMILY, size: 10, color: { argb: TEXT_BODY } };
    for (let c = 1; c <= colCount; c += 1) {
      const cell = row.getCell(c);
      cell.border = borderThin;
      if (c === 6 || c === 7) {
        cell.alignment = { vertical: "middle", horizontal: "left", wrapText: true };
      } else if (c === 9) {
        cell.alignment = { vertical: "middle", horizontal: "right" };
        cell.numFmt = "#,##0.00";
      } else {
        cell.alignment = { vertical: "middle", horizontal: "center" };
      }
    }
    currentRowIndex += 1;
  }

  const endRow = Math.max(currentRowIndex - 1, startRow);
  sheet.addRow([
    "",
    "",
    "",
    "",
    "",
    "Итого:",
    "",
    "",
    rows.length > 0
      ? { formula: `SUM(I${startRow}:I${endRow})`, result: sumQuantity }
      : 0,
  ]);
  applyFooterLook(sheet, endRow + 1, colCount, 6, { 9: "#,##0.00" });
  sheet.autoFilter = {
    from: { row: 2, column: 1 },
    to: { row: rows.length > 0 ? endRow : 2, column: colCount },
  };
  autosizeColumns(sheet, labels, [15, 15, 12, 10, 8, 30, 24, 10, 12], startRow, endRow);
}

function fillGeneralSheet(sheet: Worksheet, items: WorkJournalRow[]) {
  const rows = aggregateGeneralRows(items);
  const labels = [
    "Объект",
    "Договор",
    "Система",
    "Подсистема",
    "№",
    "Наименование",
    "М-15",
    "Ед. изм.",
    "Кол-во",
    "Цена",
    "Сумма",
  ];
  const colCount = labels.length;
  const moneyFrom = 9;

  sheet.columns = labels.map(() => ({ width: 14 }));
  sheet.views = [{ state: "frozen", xSplit: 0, ySplit: 2, activeCell: "A3" }];

  const topRow = sheet.addRow([]);
  topRow.getCell(1).value = "Сводка";
  sheet.mergeCells("A1:H1");
  topRow.getCell(moneyFrom).value = "Стоимость";
  sheet.mergeCells("I1:K1");
  sheet.addRow(labels);
  applyHeaderLook(sheet, colCount, moneyFrom);

  const startRow = 3;
  let currentRowIndex = startRow;
  let sumTotal = 0;

  for (const item of rows) {
    const rIdx = currentRowIndex;
    const total =
      item.price === null ? item.total : item.price * item.quantity;
    sumTotal += total;
    const row = sheet.addRow([
      item.objectName,
      item.contractNumber,
      item.system,
      item.subsystem,
      item.positionNumber,
      item.workName,
      item.m15Name,
      item.unit,
      item.quantity,
      item.price,
      item.price === null
        ? item.total
        : { formula: `I${rIdx}*J${rIdx}`, result: total },
    ]);
    row.font = { name: FONT_FAMILY, size: 10, color: { argb: TEXT_BODY } };
    for (let c = 1; c <= colCount; c += 1) {
      const cell = row.getCell(c);
      cell.border = borderThin;
      if (c === 6 || c === 7) {
        cell.alignment = { vertical: "middle", horizontal: "left", wrapText: true };
      } else if (c >= moneyFrom) {
        cell.alignment = { vertical: "middle", horizontal: "right" };
        cell.numFmt = c === 9 ? "#,##0.00" : "#,##0.00 ₽";
      } else {
        cell.alignment = { vertical: "middle", horizontal: "center" };
      }
    }
    currentRowIndex += 1;
  }

  const endRow = Math.max(currentRowIndex - 1, startRow);
  sheet.addRow([
    "",
    "",
    "",
    "",
    "",
    "Итого:",
    "",
    "",
    "",
    "",
    rows.length > 0
      ? { formula: `SUM(K${startRow}:K${endRow})`, result: sumTotal }
      : 0,
  ]);
  applyFooterLook(sheet, endRow + 1, colCount, 6, { 11: "#,##0.00 ₽" });
  sheet.autoFilter = {
    from: { row: 2, column: 1 },
    to: { row: rows.length > 0 ? endRow : 2, column: colCount },
  };
  autosizeColumns(
    sheet,
    labels,
    [16, 14, 15, 15, 8, 30, 24, 10, 12, 14, 16],
    startRow,
    endRow
  );
}

/**
 * Builds and downloads a work-journal Excel file in the browser (ExcelJS).
 * Sheets: journal (by shift), PTO, and general — grouping matches Flutter.
 */
export async function exportWorkJournalToExcel({
  items,
  objectName,
  dateFrom,
  dateTo,
}: ExportWorkJournalExcelOptions): Promise<void> {
  const ExcelJS = await import("exceljs");
  const workbook = new ExcelJS.Workbook();
  workbook.creator = "ProjectGT";
  workbook.created = new Date();

  fillJournalSheet(workbook.addWorksheet("Журнал работ"), items);
  fillPtoSheet(workbook.addWorksheet("ПТО"), items);
  fillGeneralSheet(workbook.addWorksheet("Общий"), items);

  const buffer = await workbook.xlsx.writeBuffer();
  const blob = new Blob([buffer], {
    type: "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
  });

  const parts = ["Журнал_работ"];
  if (objectName) {
    parts.push(sanitizeFileName(objectName));
  }
  if (dateFrom && dateTo) {
    parts.push(`${dateFrom}_${dateTo}`);
  }

  const url = window.URL.createObjectURL(blob);
  const anchor = document.createElement("a");
  anchor.href = url;
  anchor.download = `${parts.join("_")}.xlsx`;
  document.body.appendChild(anchor);
  anchor.click();
  document.body.removeChild(anchor);
  window.URL.revokeObjectURL(url);
}
