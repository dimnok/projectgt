import type { CashFlowFilters } from "@/features/cash-flow/types/cash-flow.types";

/** Сколько прошлых лет показывать в списке периодов. */
const YEARS_BACK = 3;

/** Сколько будущих лет показывать в списке периодов. */
const YEARS_FORWARD = 2;

/** Пустые фильтры реестра для указанного года. */
export function emptyCashFlowFilters(year: number): CashFlowFilters {
  return {
    search: "",
    year,
    objectId: "",
    contractorId: "",
    contractIds: [],
    types: [],
  };
}

/**
 * Есть хотя бы один активный срез.
 *
 * Год считается периодом, а не срезом: он всегда задан и не сбрасывается.
 */
export function hasActiveCashFlowFilters(filters: CashFlowFilters): boolean {
  return (
    filters.search.trim() !== "" ||
    filters.objectId !== "" ||
    filters.contractorId !== "" ||
    filters.contractIds.length > 0 ||
    filters.types.length > 0
  );
}

/** Границы года для выборки: `ГГГГ-01-01` и `ГГГГ-12-31`. */
export function yearPeriod(year: number): {
  startDate: string;
  endDate: string;
} {
  return { startDate: `${year}-01-01`, endDate: `${year}-12-31` };
}

/** Годы для списка периодов: прошлые, текущий и следующие. */
export function cashFlowYearOptions(now = new Date()): number[] {
  const first = now.getFullYear() - YEARS_BACK;
  return Array.from(
    { length: YEARS_BACK + YEARS_FORWARD + 1 },
    (_, index) => first + index
  );
}
