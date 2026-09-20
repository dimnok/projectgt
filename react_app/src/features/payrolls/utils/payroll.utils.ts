import { employeeFullName } from "@/features/employees/utils/employee.utils";
import type { PayrollPeriod } from "@/features/payrolls/types/payroll.types";
import { getMonthLabel } from "@/features/timesheet/utils/timesheet-date";

const MONEY_FORMAT = new Intl.NumberFormat("ru-RU", {
  style: "currency",
  currency: "RUB",
  minimumFractionDigits: 2,
  maximumFractionDigits: 2,
});

const QUANTITY_FORMAT = new Intl.NumberFormat("ru-RU", {
  minimumFractionDigits: 0,
  maximumFractionDigits: 3,
});

const PAYOUT_METHOD_LABELS: Record<string, string> = {
  card: "Карта",
  cash: "Наличные",
  bank_transfer: "Банковский перевод",
};

const PAYOUT_TYPE_LABELS: Record<string, string> = {
  salary: "Зарплата",
  advance: "Аванс",
};

/** Варианты способа выплаты для выпадающих списков. */
export const PAYOUT_METHOD_OPTIONS = Object.entries(PAYOUT_METHOD_LABELS).map(
  ([value, label]) => ({ value, label })
);

/** Варианты типа выплаты для выпадающих списков. */
export const PAYOUT_TYPE_OPTIONS = Object.entries(PAYOUT_TYPE_LABELS).map(
  ([value, label]) => ({ value, label })
);

function asText(value: unknown): string {
  return typeof value === "string" ? value : "";
}

/** Приводит значение из Supabase к числу; пустое и мусор — 0. */
export function toPayrollNumber(value: unknown): number {
  if (value === null || value === undefined) {
    return 0;
  }
  const parsed = Number(value);
  return Number.isFinite(parsed) ? parsed : 0;
}

/** Сумма в рублях: «1 234,56 ₽». */
export function formatPayrollMoney(value: number): string {
  return MONEY_FORMAT.format(value);
}

/** Сумма из поля ввода: пробелы убираем, запятую читаем как точку. */
export function parsePayrollAmount(raw: string): number | null {
  const normalized = raw.trim().replace(/\s/g, "").replace(",", ".");
  if (!normalized) {
    return null;
  }
  const value = Number(normalized);
  return Number.isFinite(value) ? value : null;
}

/** Часы: «1 234,5». */
export function formatPayrollQuantity(value: number): string {
  return QUANTITY_FORMAT.format(value);
}

/** Премии, удержания и выплаты: нулевые значения в таблице не показываются. */
export function formatPayrollMoneyOrDash(value: number): string {
  return value > 0 ? MONEY_FORMAT.format(value) : "—";
}

/** Последний день месяца в формате YYYY-MM-DD. */
export function lastDayOfMonth(year: number, month: number): string {
  const lastDay = new Date(year, month, 0).getDate();
  return `${year}-${String(month).padStart(2, "0")}-${String(lastDay).padStart(2, "0")}`;
}

/** Границы периода для запроса, включительно. Без ограничения — null. */
export function getPeriodBounds(period: PayrollPeriod): {
  start: string | null;
  end: string | null;
} {
  if (period.mode === "all") {
    return { start: null, end: null };
  }
  return {
    start: `${period.year}-${String(period.month).padStart(2, "0")}-01`,
    end: lastDayOfMonth(period.year, period.month),
  };
}

/** Ключ периода для кэша запросов. */
export function getPeriodKey(period: PayrollPeriod): string {
  return period.mode === "all"
    ? "all"
    : `${period.year}-${String(period.month).padStart(2, "0")}`;
}

/** Название периода: «Сентябрь 2026» или «Всё время». */
export function getPeriodLabel(period: PayrollPeriod): string {
  return period.mode === "all"
    ? "Всё время"
    : getMonthLabel(period.year, period.month);
}

/** Подпись периода для показателей: «за сентябрь 2026» или «за всё время». */
export function getPeriodPhrase(period: PayrollPeriod): string {
  return period.mode === "all"
    ? "за всё время"
    : `за ${getMonthLabel(period.year, period.month).toLowerCase()}`;
}

/** Подпись баланса: долг компании, переплата или полный расчёт. */
export function balanceSubtext(balance: number): string {
  if (balance > 0) {
    return "Компания должна сотрудникам";
  }
  if (balance < 0) {
    return "Переплата сотрудникам";
  }
  return "Полный расчёт";
}

/** Способ выплаты: `card` → «Карта». */
export function payoutMethodLabel(method: string): string {
  return PAYOUT_METHOD_LABELS[method] ?? method;
}

/** Тип выплаты: `advance` → «Аванс». */
export function payoutTypeLabel(type: string): string {
  return PAYOUT_TYPE_LABELS[type] ?? type;
}

/** ФИО из связанной записи `employees` (embedded-селект Supabase). */
export function embeddedEmployeeName(
  employee:
    | { last_name?: unknown; first_name?: unknown; middle_name?: unknown }
    | null
    | undefined
): string {
  return employeeFullName({
    lastName: asText(employee?.last_name),
    firstName: asText(employee?.first_name),
    middleName: asText(employee?.middle_name),
  });
}

/** Дата из Supabase (date или timestamptz) в виде YYYY-MM-DD. */
export function payrollDateOnly(value: unknown): string {
  const text = asText(value);
  return text ? text.slice(0, 10) : "";
}

/** Короткое имя из связанной записи `profiles` (автор операции). */
export function embeddedProfileName(
  profile: { short_name?: unknown; full_name?: unknown } | null | undefined
): string {
  const shortName = asText(profile?.short_name).trim();
  if (shortName) {
    return shortName;
  }
  return asText(profile?.full_name).trim();
}

/** Подсказка к колонке «Автор»: кто создал и, если другой, кто изменил. */
export function payrollAuthorTooltip(item: {
  createdByName: string;
  updatedByName: string;
}): string {
  const created = item.createdByName || "—";
  if (item.updatedByName && item.updatedByName !== item.createdByName) {
    return `Создал: ${created}\nИзменил: ${item.updatedByName}`;
  }
  return `Создал: ${created}`;
}
