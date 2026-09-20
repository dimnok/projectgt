import ExcelJS from "exceljs";
import { NextResponse } from "next/server";

import {
  PAYROLL_IMPORT_COLUMNS,
  findColumnIndex,
  parseImportAmount,
  parseImportDateValue,
  type PayrollImportRow,
} from "@/features/payrolls/utils/payroll-import";
import { getUserIdFromRequest } from "@/lib/supabase/server";

export const runtime = "nodejs";
export const dynamic = "force-dynamic";

/** Максимум строк в файле — защита от случайно огромных таблиц. */
const MAX_ROWS = 2000;

/** Разворачивает значение ячейки Excel в простое значение. */
function unwrapCellValue(value: ExcelJS.CellValue): unknown {
  if (value === null || value === undefined) {
    return null;
  }
  if (
    typeof value === "string" ||
    typeof value === "number" ||
    value instanceof Date
  ) {
    return value;
  }
  if (typeof value === "object") {
    const cell = value as {
      result?: unknown;
      text?: unknown;
      richText?: { text: string }[];
    };
    if (cell.result !== undefined && cell.result !== null) {
      return cell.result;
    }
    if (Array.isArray(cell.richText)) {
      return cell.richText.map((part) => part.text).join("");
    }
    if (typeof cell.text === "string") {
      return cell.text;
    }
  }
  return null;
}

function cellText(value: ExcelJS.CellValue): string {
  const unwrapped = unwrapCellValue(value);
  if (typeof unwrapped === "string") {
    return unwrapped.trim();
  }
  if (typeof unwrapped === "number") {
    return String(unwrapped);
  }
  return "";
}

/**
 * Разбирает `.xlsx` с операциями ФОТ и возвращает строки без записи в базу.
 *
 * Ожидаемые колонки: «ФИО» и «Сумма» обязательны, «Дата», «Объект» и
 * «Примечание»/«Комментарий» — по желанию. Сопоставление с сотрудниками
 * делает браузер: у Node-роута нет сессии пользователя для чтения справочника.
 */
export async function POST(request: Request) {
  const userId = await getUserIdFromRequest(request);
  if (!userId) {
    return NextResponse.json({ error: "Нужно войти в аккаунт" }, { status: 401 });
  }

  let form: FormData;
  try {
    form = await request.formData();
  } catch {
    return NextResponse.json({ error: "Не удалось прочитать файл" }, { status: 400 });
  }

  const file = form.get("file");
  if (!(file instanceof File)) {
    return NextResponse.json({ error: "Файл не передан" }, { status: 400 });
  }

  const workbook = new ExcelJS.Workbook();
  try {
    await workbook.xlsx.load(await file.arrayBuffer());
  } catch {
    return NextResponse.json(
      { error: "Не удалось открыть файл. Нужен формат .xlsx" },
      { status: 400 }
    );
  }

  const sheet = workbook.worksheets[0];
  if (!sheet) {
    return NextResponse.json({ error: "В файле нет листов" }, { status: 400 });
  }

  // Заголовок ищем в первых строках: перед таблицей иногда есть шапка отчёта.
  let headerRowNumber = -1;
  let nameIndex = -1;
  let amountIndex = -1;
  let dateIndex = -1;
  let objectIndex = -1;
  let noteIndex = -1;

  const scanLimit = Math.min(sheet.rowCount, 20);
  for (let rowNumber = 1; rowNumber <= scanLimit; rowNumber += 1) {
    const headers = sheet.getRow(rowNumber).values;
    const headerTexts = (Array.isArray(headers) ? headers : []).map((cell) =>
      cellText(cell as ExcelJS.CellValue)
    );
    const candidateName = findColumnIndex(
      headerTexts,
      PAYROLL_IMPORT_COLUMNS.fullName
    );
    const candidateAmount = findColumnIndex(
      headerTexts,
      PAYROLL_IMPORT_COLUMNS.amount
    );
    if (candidateName !== -1 && candidateAmount !== -1) {
      headerRowNumber = rowNumber;
      nameIndex = candidateName;
      amountIndex = candidateAmount;
      dateIndex = findColumnIndex(headerTexts, PAYROLL_IMPORT_COLUMNS.date);
      objectIndex = findColumnIndex(headerTexts, PAYROLL_IMPORT_COLUMNS.object);
      noteIndex = findColumnIndex(headerTexts, PAYROLL_IMPORT_COLUMNS.note);
      break;
    }
  }

  if (headerRowNumber === -1) {
    return NextResponse.json(
      { error: "Не найдены колонки «ФИО» и «Сумма»" },
      { status: 400 }
    );
  }

  const rows: PayrollImportRow[] = [];
  for (
    let rowNumber = headerRowNumber + 1;
    rowNumber <= sheet.rowCount;
    rowNumber += 1
  ) {
    const values = sheet.getRow(rowNumber).values;
    const cells = Array.isArray(values) ? values : [];

    const fullName = cellText(cells[nameIndex] as ExcelJS.CellValue);
    const amount = parseImportAmount(
      unwrapCellValue(cells[amountIndex] as ExcelJS.CellValue)
    );

    if (!fullName && amount === null) {
      continue;
    }

    rows.push({
      rowNumber,
      fullName,
      amount: amount ?? 0,
      date:
        dateIndex !== -1
          ? parseImportDateValue(unwrapCellValue(cells[dateIndex] as ExcelJS.CellValue))
          : null,
      objectName:
        objectIndex !== -1 ? cellText(cells[objectIndex] as ExcelJS.CellValue) : "",
      note: noteIndex !== -1 ? cellText(cells[noteIndex] as ExcelJS.CellValue) : "",
    });

    if (rows.length > MAX_ROWS) {
      return NextResponse.json(
        { error: `В файле больше ${MAX_ROWS} строк` },
        { status: 400 }
      );
    }
  }

  return NextResponse.json({ rows });
}
