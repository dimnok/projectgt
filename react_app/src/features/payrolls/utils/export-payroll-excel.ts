import { employeeStatusLabel } from "@/features/employees/utils/employee-status";
import type {
  PayrollGridRow,
  PayrollPayoutItem,
  PayrollTransactionItem,
  PayrollTransactionKind,
} from "@/features/payrolls/types/payroll.types";
import {
  payoutMethodLabel,
  payoutTypeLabel,
} from "@/features/payrolls/utils/payroll.utils";

const SHEET_FONT_NAME = "Times New Roman";
const MONEY_FORMAT = "#,##0.00 ₽";
const HOURS_FORMAT = "0.00";
const DATE_FORMAT = "DD.MM.YYYY";

/** Номер строки с заголовками колонок: выше — название, период и дата. */
const HEADER_ROW = 4;
/** Первая строка с данными. */
const FIRST_DATA_ROW = HEADER_ROW + 1;

const borderThin = {
  top: { style: "thin" as const, color: { argb: "22000000" } },
  left: { style: "thin" as const, color: { argb: "22000000" } },
  bottom: { style: "thin" as const, color: { argb: "22000000" } },
  right: { style: "thin" as const, color: { argb: "22000000" } },
};

const fillHeader = {
  type: "pattern" as const,
  pattern: "solid" as const,
  fgColor: { argb: "FFF0F2F5" },
};

const fillTotal = {
  type: "pattern" as const,
  pattern: "solid" as const,
  fgColor: { argb: "FFE9ECEF" },
};

/** Уволенные сотрудники в ведомости — как в приложении. */
const fillFired = {
  type: "pattern" as const,
  pattern: "solid" as const,
  fgColor: { argb: "FFFFE6E6" },
};

/** Формула Excel с посчитанным значением: видно сразу и пересчитывается при правке. */
type SheetFormula = {
  formula: string;
  result: number;
};

type SheetCell = string | number | Date | null | SheetFormula;

type SheetColumn = {
  /** Нужен, чтобы ссылаться на колонку в формулах. */
  key: string;
  title: string;
  width: number;
  numFmt?: string;
  align?: "left" | "center" | "right";
};

type SheetOptions = {
  title: string;
  periodLabel: string;
  /** Начало имени файла: «ФОТ», «Премии», «Удержания», «Выплаты». */
  fileBase: string;
  columns: SheetColumn[];
  rows: SheetCell[][];
  /** Подсветка строки (уволенные). */
  highlightRows?: boolean[];
  /**
   * Значения строки ИТОГО, по одному на колонку. Первые две колонки занимает
   * объединённая надпись «ИТОГО», поэтому там значения не нужны.
   */
  total: SheetCell[];
};

/** Буква колонки Excel: 1 → A, 9 → I. */
function columnLetter(index: number): string {
  let value = index + 1;
  let letter = "";
  while (value > 0) {
    const rest = (value - 1) % 26;
    letter = String.fromCharCode(65 + rest) + letter;
    value = Math.floor((value - 1) / 26);
  }
  return letter;
}

/** Буквы колонок по их ключам: нужно для формул. */
function columnLetters(columns: SheetColumn[]): Map<string, string> {
  return new Map(columns.map((column, index) => [column.key, columnLetter(index)]));
}

/** Даты пишем настоящими датами: в Excel их можно сортировать и фильтровать. */
function toExcelDate(value: string): Date | null {
  const [year, month, day] = value.slice(0, 10).split("-").map(Number);
  if (!year || !month || !day) {
    return null;
  }
  return new Date(Date.UTC(year, month - 1, day));
}

/** Собирает книгу Excel и отдаёт её браузеру на скачивание. */
async function downloadWorkbook({
  title,
  periodLabel,
  fileBase,
  columns,
  rows,
  highlightRows,
  total,
}: SheetOptions): Promise<void> {
  const ExcelJS = await import("exceljs");
  const workbook = new ExcelJS.Workbook();
  workbook.creator = "ProjectGT";
  workbook.created = new Date();

  const worksheet = workbook.addWorksheet(title);
  const lastColumn = columns.length;

  // Название, период и дата формирования
  const headerLines: {
    text: string;
    bold?: boolean;
    italic?: boolean;
    size: number;
  }[] = [
    { text: title.toUpperCase(), bold: true, size: 14 },
    { text: `Период: ${periodLabel}`, size: 11 },
    {
      text: `Дата формирования: ${new Date().toLocaleString("ru-RU")}`,
      italic: true,
      size: 9,
    },
  ];

  headerLines.forEach((line, index) => {
    const rowIndex = index + 1;
    worksheet.mergeCells(rowIndex, 1, rowIndex, lastColumn);
    const cell = worksheet.getCell(rowIndex, 1);
    cell.value = line.text;
    cell.font = {
      name: SHEET_FONT_NAME,
      size: line.size,
      bold: line.bold,
      italic: line.italic,
    };
    cell.alignment = { horizontal: "center", vertical: "middle" };
  });

  // Заголовки колонок
  const headerRow = worksheet.getRow(HEADER_ROW);
  headerRow.height = 24;
  columns.forEach((column, index) => {
    const cell = headerRow.getCell(index + 1);
    cell.value = column.title;
    cell.border = borderThin;
    cell.fill = fillHeader;
    cell.font = { name: SHEET_FONT_NAME, bold: true, size: 10 };
    cell.alignment = { horizontal: "center", vertical: "middle", wrapText: true };
  });

  // Данные
  rows.forEach((rowCells, rowIndex) => {
    const row = worksheet.getRow(FIRST_DATA_ROW + rowIndex);
    row.height = 20;
    const isHighlighted = highlightRows?.[rowIndex] ?? false;

    columns.forEach((column, index) => {
      const cell = row.getCell(index + 1);
      cell.value = rowCells[index] ?? null;
      cell.border = borderThin;
      cell.font = { name: SHEET_FONT_NAME, size: 10 };
      cell.alignment = {
        horizontal: column.align ?? "left",
        vertical: "middle",
      };
      if (column.numFmt) {
        cell.numFmt = column.numFmt;
      }
      if (isHighlighted) {
        cell.fill = fillFired;
      }
    });
  });

  // Итого
  const totalRowIndex = FIRST_DATA_ROW + rows.length;
  const totalRow = worksheet.getRow(totalRowIndex);
  totalRow.height = 24;
  worksheet.mergeCells(totalRowIndex, 1, totalRowIndex, 2);

  const totalLabelCell = totalRow.getCell(1);
  totalLabelCell.value = "ИТОГО";
  totalLabelCell.border = borderThin;
  totalLabelCell.fill = fillTotal;
  totalLabelCell.font = { name: SHEET_FONT_NAME, bold: true, size: 10 };
  totalLabelCell.alignment = { horizontal: "center", vertical: "middle" };

  columns.forEach((column, index) => {
    const cell = totalRow.getCell(index + 1);
    // В объединённую ячейку с надписью значение не пишем: null её стирает.
    if (index >= 2) {
      cell.value = total[index] ?? null;
    }
    cell.border = borderThin;
    cell.fill = fillTotal;
    cell.font = { name: SHEET_FONT_NAME, bold: true, size: 10 };
    cell.alignment = {
      horizontal: index === 0 ? "center" : (column.align ?? "left"),
      vertical: "middle",
    };
    if (column.numFmt) {
      cell.numFmt = column.numFmt;
    }
  });

  // Ширина колонок, закрепление шапки и фильтр по колонкам
  columns.forEach((column, index) => {
    worksheet.getColumn(index + 1).width = column.width;
  });
  worksheet.views = [{ state: "frozen", ySplit: HEADER_ROW }];
  if (rows.length > 0) {
    worksheet.autoFilter = {
      from: { row: HEADER_ROW, column: 1 },
      to: { row: totalRowIndex - 1, column: lastColumn },
    };
  }

  const buffer = await workbook.xlsx.writeBuffer();
  const blob = new Blob([buffer], {
    type: "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
  });

  const filename = `${fileBase}_${periodLabel.replace(/\s+/g, "_")}.xlsx`;
  const url = window.URL.createObjectURL(blob);
  const link = document.createElement("a");
  link.href = url;
  link.download = filename;
  document.body.appendChild(link);
  link.click();
  document.body.removeChild(link);
  window.URL.revokeObjectURL(url);
}

function sum<T>(rows: T[], getValue: (row: T) => number): number {
  let total = 0;
  for (const row of rows) {
    total += getValue(row);
  }
  return total;
}

const MONEY_COLUMN = { numFmt: MONEY_FORMAT, align: "right" as const };

const PAYROLL_SHEET_COLUMNS: SheetColumn[] = [
  { key: "employee", title: "Сотрудник", width: 32, align: "left" },
  { key: "status", title: "Статус", width: 14, align: "left" },
  { key: "hours", title: "Часы", width: 10, numFmt: HOURS_FORMAT, align: "right" },
  { key: "rate", title: "Ставка", width: 14, ...MONEY_COLUMN },
  { key: "base", title: "База", width: 16, ...MONEY_COLUMN },
  { key: "bonus", title: "Премии", width: 14, ...MONEY_COLUMN },
  { key: "penalty", title: "Удержания", width: 14, ...MONEY_COLUMN },
  { key: "trip", title: "Суточные", width: 14, ...MONEY_COLUMN },
  { key: "net", title: "К выплате", width: 16, ...MONEY_COLUMN },
  { key: "payout", title: "Выплаты", width: 14, ...MONEY_COLUMN },
  { key: "remainder", title: "Остаток", width: 16, ...MONEY_COLUMN },
  { key: "balance", title: "Баланс", width: 16, ...MONEY_COLUMN },
];

/**
 * Ведомость ФОТ за месяц: то же, что на экране, вместе со статусами.
 *
 * «К выплате» и «Остаток» — формулы от колонок листа, строка «ИТОГО» — суммы.
 * «База» остаётся числом: ставка подбирается на дату каждой смены, поэтому
 * из «Часы × Ставка» она не выводится. «Баланс» тоже число — это накопленный
 * итог по всей истории, в месячном листе его не из чего сложить.
 */
export async function exportPayrollSheetToExcel({
  rows,
  periodLabel,
}: {
  rows: PayrollGridRow[];
  periodLabel: string;
}): Promise<void> {
  const letter = columnLetters(PAYROLL_SHEET_COLUMNS);
  const at = (key: string, row: number) => `${letter.get(key)}${row}`;
  const lastDataRow = FIRST_DATA_ROW + rows.length - 1;

  const sumFormula = (key: string, result: number): SheetFormula => ({
    formula:
      rows.length > 0
        ? `SUM(${at(key, FIRST_DATA_ROW)}:${at(key, lastDataRow)})`
        : "0",
    result,
  });

  await downloadWorkbook({
    title: "Ведомость ФОТ",
    periodLabel,
    fileBase: "ФОТ",
    columns: PAYROLL_SHEET_COLUMNS,
    rows: rows.map((row, index) => {
      const excelRow = FIRST_DATA_ROW + index;
      return [
        row.fullName,
        row.status ? employeeStatusLabel(row.status) : "",
        row.hours,
        row.hourlyRate,
        row.baseSalary,
        row.bonusesTotal,
        row.penaltiesTotal,
        row.businessTripTotal,
        {
          formula: `${at("base", excelRow)}+${at("trip", excelRow)}+${at("bonus", excelRow)}-${at("penalty", excelRow)}`,
          result: row.netSalary,
        },
        row.payout,
        {
          formula: `${at("net", excelRow)}-${at("payout", excelRow)}`,
          result: row.remainder,
        },
        row.balance,
      ];
    }),
    highlightRows: rows.map((row) => row.status === "fired"),
    total: [
      null,
      null,
      sumFormula("hours", sum(rows, (row) => row.hours)),
      null,
      sumFormula("base", sum(rows, (row) => row.baseSalary)),
      sumFormula("bonus", sum(rows, (row) => row.bonusesTotal)),
      sumFormula("penalty", sum(rows, (row) => row.penaltiesTotal)),
      sumFormula("trip", sum(rows, (row) => row.businessTripTotal)),
      sumFormula("net", sum(rows, (row) => row.netSalary)),
      sumFormula("payout", sum(rows, (row) => row.payout)),
      sumFormula("remainder", sum(rows, (row) => row.remainder)),
      sumFormula("balance", sum(rows, (row) => row.balance)),
    ],
  });
}

/** Список премий или удержаний. Сумма удержаний — со знаком минус. */
export async function exportPayrollTransactionsToExcel({
  kind,
  periodLabel,
  rows,
}: {
  kind: PayrollTransactionKind;
  periodLabel: string;
  rows: PayrollTransactionItem[];
}): Promise<void> {
  const isPenalty = kind === "penalty";
  const sign = isPenalty ? -1 : 1;

  const columns: SheetColumn[] = [
    { key: "date", title: "Дата", width: 14, numFmt: DATE_FORMAT, align: "center" },
    { key: "employee", title: "Сотрудник", width: 32, align: "left" },
    { key: "amount", title: "Сумма", width: 16, ...MONEY_COLUMN },
    { key: "object", title: "Объект", width: 28, align: "left" },
    { key: "note", title: "Примечание", width: 48, align: "left" },
  ];
  const amountLetter = columnLetters(columns).get("amount") ?? "C";
  const lastDataRow = FIRST_DATA_ROW + rows.length - 1;

  await downloadWorkbook({
    title: isPenalty ? "Удержания" : "Премии",
    periodLabel,
    fileBase: isPenalty ? "Удержания" : "Премии",
    columns,
    rows: rows.map((row) => [
      toExcelDate(row.date),
      row.employeeName,
      row.amount * sign,
      row.objectName,
      row.note,
    ]),
    total: [
      null,
      null,
      {
        formula:
          rows.length > 0
            ? `SUM(${amountLetter}${FIRST_DATA_ROW}:${amountLetter}${lastDataRow})`
            : "0",
        result: sum(rows, (row) => row.amount) * sign,
      },
      null,
      null,
    ],
  });
}

/** Список выплат: сумма, способ, тип и комментарий. */
export async function exportPayrollPayoutsToExcel({
  periodLabel,
  rows,
}: {
  periodLabel: string;
  rows: PayrollPayoutItem[];
}): Promise<void> {
  const columns: SheetColumn[] = [
    { key: "date", title: "Дата", width: 14, numFmt: DATE_FORMAT, align: "center" },
    { key: "employee", title: "Сотрудник", width: 32, align: "left" },
    { key: "amount", title: "Сумма", width: 16, ...MONEY_COLUMN },
    { key: "method", title: "Способ", width: 22, align: "left" },
    { key: "type", title: "Тип", width: 14, align: "left" },
    { key: "comment", title: "Комментарий", width: 48, align: "left" },
  ];
  const amountLetter = columnLetters(columns).get("amount") ?? "C";
  const lastDataRow = FIRST_DATA_ROW + rows.length - 1;

  await downloadWorkbook({
    title: "Выплаты",
    periodLabel,
    fileBase: "Выплаты",
    columns,
    rows: rows.map((row) => [
      toExcelDate(row.date),
      row.employeeName,
      row.amount,
      payoutMethodLabel(row.method),
      payoutTypeLabel(row.type),
      row.comment,
    ]),
    total: [
      null,
      null,
      {
        formula:
          rows.length > 0
            ? `SUM(${amountLetter}${FIRST_DATA_ROW}:${amountLetter}${lastDataRow})`
            : "0",
        result: sum(rows, (row) => row.amount),
      },
      null,
      null,
      null,
    ],
  });
}
