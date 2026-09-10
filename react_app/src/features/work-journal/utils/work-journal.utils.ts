import { format } from "date-fns";
import type { DateRange } from "react-day-picker";

import type { WorkJournalDateRange } from "@/features/work-journal/types/work-journal.types";

export function formatCurrency(value: number): string {
  return new Intl.NumberFormat("ru-RU", {
    style: "currency",
    currency: "RUB",
    minimumFractionDigits: 2,
    maximumFractionDigits: 2,
  }).format(value);
}

export function formatQuantity(value: number): string {
  return new Intl.NumberFormat("ru-RU", {
    maximumFractionDigits: 3,
  }).format(value);
}

export function formatRuDate(value: string | null | undefined): string {
  if (!value) {
    return "—";
  }
  const clean = value.split("T")[0];
  const [year, month, day] = clean.split("-");
  if (!year || !month || !day) {
    return value;
  }
  return `${day}.${month}.${year}`;
}

export function toApiDate(date: Date): string {
  return format(date, "yyyy-MM-dd");
}

export function parseApiDate(value: string): Date {
  const [year, month, day] = value.split("-").map(Number);
  return new Date(year, (month ?? 1) - 1, day ?? 1);
}

export function dateRangeToPicker(
  range: WorkJournalDateRange | null
): DateRange | undefined {
  if (!range) {
    return undefined;
  }
  return {
    from: parseApiDate(range.from),
    to: parseApiDate(range.to),
  };
}

export function pickerToDateRange(
  range: DateRange | undefined
): WorkJournalDateRange | null {
  if (!range?.from || !range.to) {
    return null;
  }
  return {
    from: toApiDate(range.from),
    to: toApiDate(range.to),
  };
}

export function formatDateRangeLabel(range: WorkJournalDateRange | null): string {
  if (!range) {
    return "Период";
  }
  return `${formatRuDate(range.from)} — ${formatRuDate(range.to)}`;
}

export function emptyToNull(values: string[] | undefined): string[] | null {
  if (!values || values.length === 0) {
    return null;
  }
  return values;
}

export function pruneSelected(selected: string[], available: string[]): string[] {
  if (selected.length === 0 || available.length === 0) {
    return selected.filter((value) => available.includes(value));
  }
  return selected.filter((value) => available.includes(value));
}

export function sameStringList(left: string[], right: string[]): boolean {
  if (left.length !== right.length) {
    return false;
  }
  return left.every((value, index) => value === right[index]);
}
