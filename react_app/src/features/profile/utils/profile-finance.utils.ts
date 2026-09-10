import type { ProfileFinancePeriod } from "@/features/profile/types/profile-finance.types";

export function currentFinancePeriod(): ProfileFinancePeriod {
  const now = new Date();
  return { year: now.getFullYear(), month: now.getMonth() + 1 };
}

export function shiftFinancePeriod(
  period: ProfileFinancePeriod,
  deltaMonths: number
): ProfileFinancePeriod {
  const date = new Date(period.year, period.month - 1 + deltaMonths, 1);
  return { year: date.getFullYear(), month: date.getMonth() + 1 };
}

export function isFutureFinancePeriod(period: ProfileFinancePeriod) {
  const current = currentFinancePeriod();
  return (
    period.year > current.year ||
    (period.year === current.year && period.month > current.month)
  );
}

export function formatFinanceMonth(period: ProfileFinancePeriod) {
  const label = new Intl.DateTimeFormat("ru-RU", {
    month: "long",
    year: "numeric",
  }).format(new Date(period.year, period.month - 1, 1));
  return label.charAt(0).toUpperCase() + label.slice(1);
}

export function formatFinanceMoney(value: number) {
  return new Intl.NumberFormat("ru-RU", {
    style: "currency",
    currency: "RUB",
    minimumFractionDigits: 2,
    maximumFractionDigits: 2,
  }).format(value);
}

export function formatFinanceHours(value: number) {
  return new Intl.NumberFormat("ru-RU", {
    minimumFractionDigits: 0,
    maximumFractionDigits: 2,
  }).format(value);
}

export function formatFinanceDay(value: string) {
  const clean = value.split("T")[0];
  const [year, month, day] = clean.split("-");
  if (!year || !month || !day) {
    return value;
  }
  return `${day}.${month}.${year}`;
}

export function toFinanceNumber(value: unknown) {
  const parsed = typeof value === "number" ? value : Number(value);
  return Number.isFinite(parsed) ? parsed : 0;
}
