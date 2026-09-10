import type { EstimateImportItemInput } from "@/features/estimates/api/import-estimate";
import { toNumber } from "@/features/estimates/utils/estimate.utils";

export type ExcelEstimateValidationResult = {
  isValid: boolean;
  errors: string[];
  warnings: string[];
  items: EstimateImportItemInput[];
  totalRows: number;
  totalAmount: number;
  systems: string[];
};

export const REQUIRED_EXCEL_HEADERS = [
  "Система",
  "Подсистема",
  "№",
  "Наименование",
  "Артикул",
  "Производитель",
  "Ед. изм.",
  "Кол-во",
  "Цена",
  "Сумма",
];

function cellToString(val: unknown): string {
  if (val === null || val === undefined) return "";
  if (typeof val === "object" && val !== null) {
    // ExcelJS cell values can be rich text or formula results
    const obj = val as Record<string, unknown>;
    if ("result" in obj && obj.result !== undefined) {
      return String(obj.result ?? "").trim();
    }
    if ("text" in obj && obj.text !== undefined) {
      return String(obj.text ?? "").trim();
    }
  }
  return String(val).trim();
}

function cellToNumber(val: unknown): number {
  if (val === null || val === undefined) return 0;
  if (typeof val === "number") return Number.isFinite(val) ? val : 0;
  if (typeof val === "object" && val !== null) {
    const obj = val as Record<string, unknown>;
    if ("result" in obj && typeof obj.result === "number") {
      return Number.isFinite(obj.result) ? obj.result : 0;
    }
  }
  return toNumber(val);
}

/**
 * Parses and validates an Excel file buffer or ArrayBuffer for estimate import.
 */
export async function parseEstimateExcel(
  fileData: ArrayBuffer
): Promise<ExcelEstimateValidationResult> {
  const ExcelJS = await import("exceljs");
  const workbook = new ExcelJS.Workbook();
  await workbook.xlsx.load(fileData);

  const errors: string[] = [];
  const warnings: string[] = [];

  const sheet = workbook.worksheets[0];
  if (!sheet || sheet.rowCount <= 1) {
    errors.push("Файл пуст или не содержит строк данных");
    return {
      isValid: false,
      errors,
      warnings,
      items: [],
      totalRows: 0,
      totalAmount: 0,
      systems: [],
    };
  }

  // 1. Проверяем заголовок (первая строка)
  const headerRow = sheet.getRow(1);
  const actualHeaders: string[] = [];
  headerRow.eachCell({ includeEmpty: true }, (cell, colNumber) => {
    actualHeaders[colNumber - 1] = cellToString(cell.value).toLowerCase();
  });

  // Ищем соответствие колонок
  // Ожидаем порядок или совпадение названий
  const colIndex = {
    system: -1,
    subsystem: -1,
    number: -1,
    name: -1,
    article: -1,
    manufacturer: -1,
    unit: -1,
    quantity: -1,
    price: -1,
    total: -1,
  };

  for (let i = 0; i < actualHeaders.length; i++) {
    const h = (actualHeaders[i] || "").trim();
    if (h.includes("система") && !h.includes("подсистема")) colIndex.system = i + 1;
    else if (h.includes("подсистема")) colIndex.subsystem = i + 1;
    else if (h === "№" || h.includes("номер") || h === "n") colIndex.number = i + 1;
    else if (h.includes("наименование") || h.includes("название")) colIndex.name = i + 1;
    else if (h.includes("артикул")) colIndex.article = i + 1;
    else if (h.includes("производитель")) colIndex.manufacturer = i + 1;
    else if (h.includes("ед") && (h.includes("изм") || h.includes("измерения"))) colIndex.unit = i + 1;
    else if (h.includes("кол") || h.includes("количество")) colIndex.quantity = i + 1;
    else if (h.includes("цена")) colIndex.price = i + 1;
    else if (h.includes("сумма")) colIndex.total = i + 1;
  }

  // Если названия не совпали, но колонок 10+, берем стандартный порядок (1..10)
  if (colIndex.name === -1 && colIndex.quantity === -1) {
    colIndex.system = 1;
    colIndex.subsystem = 2;
    colIndex.number = 3;
    colIndex.name = 4;
    colIndex.article = 5;
    colIndex.manufacturer = 6;
    colIndex.unit = 7;
    colIndex.quantity = 8;
    colIndex.price = 9;
    colIndex.total = 10;
    warnings.push("Заголовки не совпали точно со стандартными, применен порядок колонок по умолчанию");
  }

  // 2. Считываем строки данных (начиная со 2-й)
  const items: EstimateImportItemInput[] = [];
  const systemSet = new Set<string>();
  let totalSum = 0;

  for (let r = 2; r <= sheet.rowCount; r++) {
    const row = sheet.getRow(r);
    // Проверка на пустую строку
    const name = cellToString(row.getCell(colIndex.name).value);
    const system = cellToString(row.getCell(colIndex.system).value);
    const subsystem = cellToString(row.getCell(colIndex.subsystem).value);
    const number = cellToString(row.getCell(colIndex.number).value);
    const article = cellToString(row.getCell(colIndex.article).value);
    const manufacturer = cellToString(row.getCell(colIndex.manufacturer).value);
    const unit = cellToString(row.getCell(colIndex.unit).value);
    const quantity = cellToNumber(row.getCell(colIndex.quantity).value);
    const price = cellToNumber(row.getCell(colIndex.price).value);

    // Если вся строка пустая — пропускаем
    if (!name && !system && quantity === 0 && price === 0) {
      continue;
    }

    if (!name) {
      errors.push(`Строка ${r}: отсутствует наименование`);
      continue;
    }

    if (system) {
      systemSet.add(system);
    }

    // Расчетная сумма: количество × цена
    const calcTotal = Math.round(quantity * price * 100) / 100;
    totalSum += calcTotal;

    items.push({
      system,
      subsystem,
      number,
      name,
      article,
      manufacturer,
      unit: unit || "шт",
      quantity,
      price,
      total: calcTotal,
    });
  }

  if (items.length === 0) {
    errors.push("В файле не найдено строк сметы для импорта");
  }

  return {
    isValid: errors.length === 0 && items.length > 0,
    errors,
    warnings,
    items,
    totalRows: items.length,
    totalAmount: Math.round(totalSum * 100) / 100,
    systems: Array.from(systemSet).sort(),
  };
}

/**
 * Generates and downloads an Excel template for estimate import.
 */
export async function downloadEstimateTemplate(contractNumber?: string): Promise<void> {
  const ExcelJS = await import("exceljs");
  const workbook = new ExcelJS.Workbook();
  workbook.creator = "ProjectGT";
  workbook.created = new Date();

  const sheet = workbook.addWorksheet("Смета", {
    views: [{ state: "frozen", xSplit: 0, ySplit: 1, activeCell: "A2" }],
  });

  sheet.columns = [
    { header: "Система", key: "system", width: 22 },
    { header: "Подсистема", key: "subsystem", width: 22 },
    { header: "№", key: "number", width: 10 },
    { header: "Наименование", key: "name", width: 38 },
    { header: "Артикул", key: "article", width: 16 },
    { header: "Производитель", key: "manufacturer", width: 20 },
    { header: "Ед. изм.", key: "unit", width: 10 },
    { header: "Кол-во", key: "quantity", width: 14 },
    { header: "Цена", key: "price", width: 16 },
    { header: "Сумма", key: "total", width: 18 },
  ];

  // Стилизуем заголовок
  const headerRow = sheet.getRow(1);
  headerRow.height = 26;
  headerRow.eachCell((cell) => {
    cell.font = { name: "Calibri", size: 11, bold: true, color: { argb: "FFFFFFFF" } };
    cell.fill = { type: "pattern", pattern: "solid", fgColor: { argb: "FF1E293B" } };
    cell.alignment = { vertical: "middle", horizontal: "center", wrapText: true };
    cell.border = {
      top: { style: "thin", color: { argb: "FF334155" } },
      left: { style: "thin", color: { argb: "FF334155" } },
      bottom: { style: "thin", color: { argb: "FF334155" } },
      right: { style: "thin", color: { argb: "FF334155" } },
    };
  });

  // Добавляем типовую строку-пример
  const exampleRow = sheet.addRow({
    system: "Электроснабжение",
    subsystem: "Освещение",
    number: "1.1",
    name: "Светильник светодиодный потолочный 36Вт",
    article: "LED-36W-01",
    manufacturer: "ООО Светотехника",
    unit: "шт",
    quantity: 10,
    price: 1500,
    total: { formula: "H2*I2", result: 15000 },
  });

  exampleRow.eachCell((cell, colNumber) => {
    cell.font = { name: "Calibri", size: 10 };
    if (colNumber === 8 || colNumber === 9 || colNumber === 10) {
      cell.alignment = { horizontal: "right", vertical: "middle" };
    }
  });

  const buffer = await workbook.xlsx.writeBuffer();
  const blob = new Blob([buffer], {
    type: "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
  });
  const url = URL.createObjectURL(blob);
  const a = document.createElement("a");
  a.href = url;
  const fileName = contractNumber
    ? `Шаблон_сметы_${contractNumber.replace(/[\\/:*?"<>|]/g, "_")}.xlsx`
    : "Шаблон_сметы.xlsx";
  a.download = fileName;
  document.body.appendChild(a);
  a.click();
  document.body.removeChild(a);
  URL.revokeObjectURL(url);
}
