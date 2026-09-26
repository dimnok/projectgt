import { describe, expect, it } from "vitest";

import {
  cashFlowYearOptions,
  emptyCashFlowFilters,
  hasActiveCashFlowFilters,
  yearPeriod,
} from "@/features/cash-flow/utils/filters";

describe("emptyCashFlowFilters", () => {
  it("пустые фильтры не активны", () => {
    expect(hasActiveCashFlowFilters(emptyCashFlowFilters(2026))).toBe(false);
  });

  it("год попадает в фильтры", () => {
    expect(emptyCashFlowFilters(2026).year).toBe(2026);
  });
});

describe("hasActiveCashFlowFilters", () => {
  it("поиск делает фильтры активными", () => {
    expect(
      hasActiveCashFlowFilters({
        ...emptyCashFlowFilters(2026),
        search: "аренда",
      })
    ).toBe(true);
  });

  it("срезы и списки учитываются", () => {
    expect(
      hasActiveCashFlowFilters({
        ...emptyCashFlowFilters(2026),
        objectId: "o1",
      })
    ).toBe(true);
    expect(
      hasActiveCashFlowFilters({
        ...emptyCashFlowFilters(2026),
        contractorId: "k1",
      })
    ).toBe(true);
    expect(
      hasActiveCashFlowFilters({
        ...emptyCashFlowFilters(2026),
        contractIds: ["d1"],
      })
    ).toBe(true);
    expect(
      hasActiveCashFlowFilters({
        ...emptyCashFlowFilters(2026),
        types: ["income"],
      })
    ).toBe(true);
  });

  it("пробелы в поиске фильтром не считаются", () => {
    expect(
      hasActiveCashFlowFilters({
        ...emptyCashFlowFilters(2026),
        search: "   ",
      })
    ).toBe(false);
  });
});

describe("yearPeriod", () => {
  it("границы года — первое и последнее число", () => {
    expect(yearPeriod(2026)).toEqual({
      startDate: "2026-01-01",
      endDate: "2026-12-31",
    });
  });
});

describe("cashFlowYearOptions", () => {
  it("шесть лет: три назад, текущий и два вперёд", () => {
    const options = cashFlowYearOptions(new Date(2026, 8, 23));
    expect(options).toEqual([2023, 2024, 2025, 2026, 2027, 2028]);
  });
});
