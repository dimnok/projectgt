import type { CashFlowMonthAnalyticsRow } from "@/types/database.types";
import type {
  CashFlowMonthAnalytics,
  CashFlowType,
} from "@/features/cash-flow/types/cash-flow.types";
import { toNumber } from "@/features/cash-flow/utils/cash-flow.utils";

/** Формат короткого названия месяца на русском: «янв.». */
const MONTH_FORMAT = new Intl.DateTimeFormat("ru-RU", { month: "short" });

/**
 * Первое число месяца из строки базы (`2026-01-01`).
 *
 * Дата собирается из частей, а не разбором строки: иначе часовой пояс мог бы
 * сдвинуть месяц на предыдущий.
 */
function monthDate(month: string): Date | null {
  const [year, monthNumber] = month.split("-");
  if (!year || !monthNumber) {
    return null;
  }
  const date = new Date(Number(year), Number(monthNumber) - 1, 1);
  return Number.isNaN(date.getTime()) ? null : date;
}

/** Подпись месяца: `2026-01-01` → `янв. 2026`. */
export function formatMonthLabel(month: string): string {
  const date = monthDate(month);
  return date ? `${MONTH_FORMAT.format(date)} ${month.slice(0, 4)}` : month;
}

/** Короткая подпись месяца без года: `2026-01-01` → `янв.`. */
export function formatMonthShort(month: string): string {
  const date = monthDate(month);
  return date ? MONTH_FORMAT.format(date) : month;
}

/** Подпись статьи: у операции без статьи названия нет. */
export function categoryLabel(name: string): string {
  return name || "Без статьи";
}

/** Разбивка сумм по статьям: пустое значение базы — пустой объект. */
function toCategoryAmounts(
  source: Record<string, number | string> | null
): Record<string, number> {
  const amounts: Record<string, number> = {};
  for (const [name, value] of Object.entries(source ?? {})) {
    amounts[name] = toNumber(value);
  }
  return amounts;
}

/** Месяц аналитики из базы → месяц для интерфейса. */
export function mapCashFlowMonthRow(
  row: CashFlowMonthAnalyticsRow
): CashFlowMonthAnalytics {
  const income = toNumber(row.income);
  const expense = toNumber(row.expense);
  return {
    month: row.month,
    income,
    expense,
    balance: income - expense,
    incomeByCategory: toCategoryAmounts(row.income_by_category),
    expenseByCategory: toCategoryAmounts(row.expense_by_category),
  };
}

/**
 * Названия статей, которые встречаются в месяцах, по алфавиту подписей.
 *
 * Расшифровка строится по всему периоду: статья, которая была только в одном
 * месяце, всё равно получает строку — так её видно в сравнении с другими
 * месяцами, а пустые месяцы помечаются прочерком.
 */
export function analyticsCategoryNames(
  months: CashFlowMonthAnalytics[],
  type: CashFlowType
): string[] {
  const names = new Set<string>();
  for (const month of months) {
    const amounts =
      type === "income" ? month.incomeByCategory : month.expenseByCategory;
    for (const name of Object.keys(amounts)) {
      names.add(name);
    }
  }
  return [...names].sort((left, right) =>
    categoryLabel(left).localeCompare(categoryLabel(right), "ru")
  );
}

/** Сумма статьи за конкретный месяц. */
export function monthCategoryAmount(
  month: CashFlowMonthAnalytics,
  type: CashFlowType,
  name: string
): number {
  const amounts =
    type === "income" ? month.incomeByCategory : month.expenseByCategory;
  return amounts[name] ?? 0;
}

/**
 * Итоги отчёта за период.
 *
 * Складываем месяцы, а не берём суммы отдельным запросом: итоговая колонка
 * всегда сходится с тем, что видно в столбцах.
 */
export function analyticsTotals(months: CashFlowMonthAnalytics[]): {
  income: number;
  expense: number;
  balance: number;
} {
  const income = months.reduce((total, month) => total + month.income, 0);
  const expense = months.reduce((total, month) => total + month.expense, 0);
  return { income, expense, balance: income - expense };
}

/** Итог статьи за период. */
export function analyticsCategoryTotal(
  months: CashFlowMonthAnalytics[],
  type: CashFlowType,
  name: string
): number {
  return months.reduce(
    (total, month) => total + monthCategoryAmount(month, type, name),
    0
  );
}
