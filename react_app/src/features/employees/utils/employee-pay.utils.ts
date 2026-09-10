import type {
  EmployeeRate,
  EmployeeRateOverlap,
  EmployeeRateOverlapAction,
  EmployeeTripRate,
} from "@/features/employees/types/employee.types";
import { formatRuDate, todayDateInput } from "@/features/employees/utils/employee.utils";
import type {
  BusinessTripRatesRow,
  EmployeeRatesRow,
} from "@/types/database.types";

export function parseDecimal(value: string): number | null {
  const normalized = value.trim().replace(",", ".");
  if (!normalized) {
    return null;
  }
  const parsed = Number(normalized);
  return Number.isFinite(parsed) ? parsed : null;
}

export function toFiniteNumber(value: unknown, fallback = 0): number {
  if (typeof value === "number" && Number.isFinite(value)) {
    return value;
  }
  if (typeof value === "string" && value.trim()) {
    const parsed = Number(value);
    if (Number.isFinite(parsed)) {
      return parsed;
    }
  }
  return fallback;
}

function dateOnly(value: string | null | undefined): string {
  return value?.split("T")[0] ?? "";
}

export function shiftIsoDate(isoDate: string, days: number): string {
  const [year, month, day] = dateOnly(isoDate)
    .split("-")
    .map((part) => Number(part));
  if (!year || !month || !day) {
    return isoDate;
  }
  const next = new Date(Date.UTC(year, month - 1, day + days));
  const yyyy = next.getUTCFullYear();
  const mm = String(next.getUTCMonth() + 1).padStart(2, "0");
  const dd = String(next.getUTCDate()).padStart(2, "0");
  return `${yyyy}-${mm}-${dd}`;
}

export function formatHourlyRateShort(value: number): string {
  return `${value.toFixed(0)} ₽/час`;
}

export function formatTripRateShort(value: number): string {
  return `${value.toFixed(0)} ₽/смена`;
}

export function formatRatePeriod(rate: EmployeeRate): string {
  const start = formatRuDate(rate.validFrom);
  if (!rate.validTo) {
    return `с ${start}`;
  }
  return `${start} — ${formatRuDate(rate.validTo)}`;
}

export function formatTripPeriod(rate: EmployeeTripRate): string {
  const start = formatRuDate(rate.validFrom);
  if (!rate.validTo) {
    return `с ${start} (бессрочно)`;
  }
  return `${start} - ${formatRuDate(rate.validTo)}`;
}

export function isTripRateActive(
  rate: EmployeeTripRate,
  today = todayDateInput()
): boolean {
  const from = dateOnly(rate.validFrom);
  if (!from || today < from) {
    return false;
  }
  if (!rate.validTo) {
    return true;
  }
  return today <= dateOnly(rate.validTo);
}

export function tripRatesSummary(rates: EmployeeTripRate[]): string {
  if (rates.length === 0) {
    return "Не настроены";
  }
  const active = rates.filter((rate) => isTripRateActive(rate));
  if (active.length === 0) {
    return `${rates.length} настроек (неактивны)`;
  }
  if (active.length === 1) {
    return formatTripRateShort(active[0].rate);
  }
  return `${active.length} активных настроек`;
}

export function overlapActionForRate(
  existingFrom: string,
  newValidFrom: string
): EmployeeRateOverlapAction {
  if (existingFrom === newValidFrom) {
    return "replace";
  }
  if (existingFrom < newValidFrom) {
    return "close";
  }
  return "delete";
}

export function overlapActionLabel(
  overlap: EmployeeRateOverlap,
  newValidFrom: string
): string {
  if (overlap.action === "replace") {
    return "→ будет заменена";
  }
  if (overlap.action === "close") {
    return `→ будет закрыта ${formatRuDate(shiftIsoDate(newValidFrom, -1))}`;
  }
  return "→ будет удалена";
}

export function overlapPeriodText(rate: EmployeeRate): string {
  if (!rate.validTo) {
    return `с ${formatRuDate(rate.validFrom)} (открытая)`;
  }
  return `с ${formatRuDate(rate.validFrom)} по ${formatRuDate(rate.validTo)}`;
}

export function mapEmployeeRateRow(row: EmployeeRatesRow): EmployeeRate {
  return {
    id: row.id ?? "",
    employeeId: row.employee_id,
    hourlyRate: toFiniteNumber(row.hourly_rate),
    validFrom: dateOnly(row.valid_from),
    validTo: row.valid_to ? dateOnly(row.valid_to) : null,
  };
}

export function mapTripRateRow(row: BusinessTripRatesRow): EmployeeTripRate {
  return {
    id: row.id,
    objectId: row.object_id,
    employeeId: row.employee_id,
    rate: toFiniteNumber(row.rate),
    minimumHours: toFiniteNumber(row.minimum_hours),
    validFrom: dateOnly(row.valid_from),
    validTo: row.valid_to ? dateOnly(row.valid_to) : null,
    createdAt: row.created_at,
  };
}

export function sortTripRates(rates: EmployeeTripRate[]): EmployeeTripRate[] {
  return [...rates].sort((a, b) => {
    if (a.createdAt && b.createdAt && a.createdAt !== b.createdAt) {
      return a.createdAt < b.createdAt ? 1 : -1;
    }
    return a.validFrom < b.validFrom ? 1 : -1;
  });
}

export function mapRateWriteError(error: unknown): string {
  const message = error instanceof Error ? error.message : "";
  if (
    /row-level security|42501|permission denied|violates row-level security/i.test(
      message
    )
  ) {
    return "Нет права менять ставку. Для записи нужна зарплата: создание и изменение ставок.";
  }
  return message || "Не удалось сохранить ставку";
}

export function mapTripWriteError(error: unknown): string {
  const message = error instanceof Error ? error.message : "";
  if (
    /пересекается с существующими/i.test(message) ||
    /business_trip_rates_no_overlap|23P01|exclusion/i.test(message)
  ) {
    return "Период действия ставки пересекается с существующими ставками для данного объекта";
  }
  if (
    /row-level security|42501|permission denied|violates row-level security/i.test(
      message
    )
  ) {
    return "Нет права менять суточные.";
  }
  return message || "Не удалось сохранить суточные";
}
