import { describe, expect, it } from "vitest";

import {
  emptySettlementFilters,
  hasActiveSettlementFilters,
} from "@/features/settlements/utils/filters";

describe("emptySettlementFilters", () => {
  it("пустые фильтры не активны", () => {
    expect(hasActiveSettlementFilters(emptySettlementFilters())).toBe(false);
  });
});

describe("hasActiveSettlementFilters", () => {
  it("поиск делает фильтры активными", () => {
    expect(
      hasActiveSettlementFilters({
        ...emptySettlementFilters(),
        search: "сч-1",
      })
    ).toBe(true);
  });

  it("тип, статус и связанные сущности учитываются", () => {
    expect(
      hasActiveSettlementFilters({
        ...emptySettlementFilters(),
        operationType: "act",
      })
    ).toBe(true);
    expect(
      hasActiveSettlementFilters({
        ...emptySettlementFilters(),
        paymentStatus: "paid",
      })
    ).toBe(true);
    expect(
      hasActiveSettlementFilters({
        ...emptySettlementFilters(),
        contractorId: "k1",
      })
    ).toBe(true);
  });
});
