/**
 * Общие правила импорта операций ФОТ из Excel.
 *
 * Модуль чистый (без React и Supabase), поэтому используется и в Node-роуте
 * разбора файла, и в браузере при предпросмотре.
 */

/** Виды операций, которые импортируются из Excel. */
export type PayrollImportKind = "payout" | "bonus" | "penalty";

/** Заголовки колонок файла и их допустимые написания (в нижнем регистре). */
export const PAYROLL_IMPORT_COLUMNS = {
  fullName: ["фио", "сотрудник", "фио сотрудника", "ф.и.о"],
  amount: ["сумма", "сумма выплаты", "сумма премии", "сумма удержания"],
  date: ["дата", "дата выплаты", "дата премии", "дата удержания"],
  object: ["объект"],
  note: ["примечание", "комментарий"],
} as const;

/** Колонки шаблона в порядке слева направо. */
export function templateColumns(kind: PayrollImportKind): string[] {
  return kind === "payout"
    ? ["ФИО", "Сумма", "Дата", "Комментарий"]
    : ["ФИО", "Сумма", "Дата", "Объект", "Примечание"];
}

/** Строка, прочитанная из файла — до сопоставления с сотрудником. */
export type PayrollImportRow = {
  rowNumber: number;
  fullName: string;
  amount: number;
  /** Дата `YYYY-MM-DD` или `null`, если в файле её нет. */
  date: string | null;
  objectName: string;
  note: string;
};

/** Результат сопоставления ФИО из файла со справочником сотрудников. */
export type PayrollImportMatch = {
  status: "matched" | "ambiguous" | "notFound";
  employeeIds: string[];
};

/**
 * Приводит ФИО к виду для сравнения: нижний регистр, «ё»→«е», точки убираются,
 * лишние пробелы схлопываются.
 */
export function normalizePersonName(value: string): string {
  return value
    .toLowerCase()
    .replace(/ё/g, "е")
    .replace(/\./g, " ")
    .replace(/\s+/g, " ")
    .trim();
}

/**
 * Сопоставляет ФИО из файла с сотрудниками.
 *
 * Сначала точное совпадение полного ФИО; если его нет — совпадение по началу
 * (в файле может не быть отчества). Несколько кандидатов — «неоднозначно»,
 * ни одного — «не найден».
 */
export function matchEmployeeIds(
  fullName: string,
  employees: { id: string; fullName: string }[]
): PayrollImportMatch {
  const target = normalizePersonName(fullName);
  if (!target) {
    return { status: "notFound", employeeIds: [] };
  }

  const exact = employees.filter(
    (employee) => normalizePersonName(employee.fullName) === target
  );
  const candidates =
    exact.length > 0
      ? exact
      : employees.filter((employee) =>
          normalizePersonName(employee.fullName).startsWith(`${target} `)
        );

  const employeeIds = candidates.map((employee) => employee.id);
  if (employeeIds.length === 0) {
    return { status: "notFound", employeeIds: [] };
  }
  if (employeeIds.length === 1) {
    return { status: "matched", employeeIds };
  }
  return { status: "ambiguous", employeeIds };
}

/** Индекс колонки по её заголовку среди допустимых написаний. */
export function findColumnIndex(
  headers: string[],
  aliases: readonly string[]
): number {
  const normalized = headers.map((header) => header.trim().toLowerCase());
  return normalized.findIndex((header) => aliases.includes(header));
}

/** Сумма из ячейки или строки: пробелы убираем, запятую читаем как точку. */
export function parseImportAmount(value: unknown): number | null {
  if (typeof value === "number") {
    return Number.isFinite(value) ? value : null;
  }
  if (typeof value !== "string") {
    return null;
  }
  const normalized = value.replace(/\s/g, "").replace(",", ".");
  if (!normalized) {
    return null;
  }
  const parsed = Number(normalized);
  return Number.isFinite(parsed) ? parsed : null;
}

/**
 * Дата из строки: `дд.мм.гггг`, `гггг-мм-дд` или ISO → `YYYY-MM-DD`.
 * Возвращает `null`, если дату распознать не удалось.
 */
export function parseImportDateString(value: string): string | null {
  const trimmed = value.trim();
  if (!trimmed) {
    return null;
  }

  const dotted = /^(\d{1,2})[.\-/](\d{1,2})[.\-/](\d{4})$/.exec(trimmed);
  if (dotted) {
    const [, day, month, year] = dotted;
    return `${year}-${month.padStart(2, "0")}-${day.padStart(2, "0")}`;
  }

  const iso = /^(\d{4})-(\d{2})-(\d{2})/.exec(trimmed);
  if (iso) {
    return `${iso[1]}-${iso[2]}-${iso[3]}`;
  }

  const parsed = new Date(trimmed);
  if (Number.isNaN(parsed.getTime())) {
    return null;
  }
  return `${parsed.getFullYear()}-${String(parsed.getMonth() + 1).padStart(2, "0")}-${String(parsed.getDate()).padStart(2, "0")}`;
}

/** Дата из ячейки Excel: `Date` или строка → `YYYY-MM-DD`. */
export function parseImportDateValue(value: unknown): string | null {
  if (value instanceof Date) {
    if (Number.isNaN(value.getTime())) {
      return null;
    }
    const year = value.getUTCFullYear();
    const month = String(value.getUTCMonth() + 1).padStart(2, "0");
    const day = String(value.getUTCDate()).padStart(2, "0");
    return `${year}-${month}-${day}`;
  }
  if (typeof value === "string") {
    return parseImportDateString(value);
  }
  return null;
}
