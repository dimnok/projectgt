import { describe, expect, it } from "vitest";

import { computeSettlementVat } from "@/features/settlements/utils/vat";

describe("computeSettlementVat", () => {
  it("НДС в сумме: выделяет базу из суммы с налогом", () => {
    expect(computeSettlementVat(122000, 22, true)).toEqual({
      base: 100000,
      vat: 22000,
      total: 122000,
    });
  });

  it("НДС сверху: начисляет налог на сумму", () => {
    expect(computeSettlementVat(100000, 22, false)).toEqual({
      base: 100000,
      vat: 22000,
      total: 122000,
    });
  });

  it("ставка 0% не начисляет налог", () => {
    expect(computeSettlementVat(1000, 0, true)).toEqual({
      base: 1000,
      vat: 0,
      total: 1000,
    });
  });

  it("без суммы возвращает нули", () => {
    expect(computeSettlementVat(0, 22, true)).toEqual({
      base: 0,
      vat: 0,
      total: 0,
    });
  });

  it("ставка 10%", () => {
    expect(computeSettlementVat(1100, 10, true)).toEqual({
      base: 1000,
      vat: 100,
      total: 1100,
    });
  });
});
