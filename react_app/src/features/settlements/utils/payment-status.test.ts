import { describe, expect, it } from "vitest";

import {
  isSettlementPaymentStatus,
  settlementPaymentStatusLabel,
} from "@/features/settlements/utils/payment-status";

describe("isSettlementPaymentStatus", () => {
  it("принимает известные статусы и отвергает чужие значения", () => {
    expect(isSettlementPaymentStatus("unpaid")).toBe(true);
    expect(isSettlementPaymentStatus("overpaid")).toBe(true);
    expect(isSettlementPaymentStatus("")).toBe(false);
    expect(isSettlementPaymentStatus("pending")).toBe(false);
  });
});

describe("settlementPaymentStatusLabel", () => {
  it("даёт человекочитаемые подписи", () => {
    expect(settlementPaymentStatusLabel("unpaid")).toBe("Не оплачен");
    expect(settlementPaymentStatusLabel("partial")).toBe("Частично");
    expect(settlementPaymentStatusLabel("paid")).toBe("Оплачен");
    expect(settlementPaymentStatusLabel("overpaid")).toBe("Переплата");
  });
});
