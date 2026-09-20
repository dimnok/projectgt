import { describe, expect, it } from "vitest";

import type { Settlement } from "@/features/settlements/types/settlement.types";
import type {
  SettlementOperationJoinRow,
  SettlementOperationsListRow,
} from "@/types/database.types";
import {
  emptySettlementDraft,
  formatRuDate,
  mapSettlementListRow,
  mapSettlementRow,
  parseAmount,
  settlementDraftToPayload,
  settlementRemaining,
  settlementToDraft,
  sumSettlements,
} from "@/features/settlements/utils/settlement.utils";

function makeSettlement(overrides: Partial<Settlement> = {}): Settlement {
  return {
    id: "s1",
    operationType: "act",
    objectId: "o1",
    objectName: "Объект",
    contractorId: "k1",
    contractorName: "Контрагент",
    contractId: "d1",
    contractNumber: "217-3",
    actNumber: "А-1",
    actDate: null,
    invoiceNumber: "сч-1",
    invoiceDate: "2026-09-19",
    amount: 100000,
    isVatIncluded: true,
    vatRate: 22,
    vatAmount: 22000,
    advanceRetention: 0,
    warrantyRetention: 0,
    totalToPay: 122000,
    paidAmount: 0,
    paymentStatus: "unpaid",
    purpose: null,
    note: null,
    ...overrides,
  };
}

describe("parseAmount", () => {
  it("понимает запятую, пробелы и точку", () => {
    expect(parseAmount("1 234,56")).toBe(1234.56);
    expect(parseAmount("1234.56")).toBe(1234.56);
    expect(parseAmount("")).toBe(0);
    expect(parseAmount("abc")).toBeNull();
  });
});

describe("formatRuDate", () => {
  it("форматирует дату и пустое значение", () => {
    expect(formatRuDate("2026-09-19")).toBe("19.09.2026");
    expect(formatRuDate(null)).toBe("—");
  });
});

describe("mapSettlementRow", () => {
  function makeJoinRow(
    overrides: Record<string, unknown> = {}
  ): SettlementOperationJoinRow {
    return {
      id: "s1",
      company_id: "c1",
      operation_type: "advance",
      object_id: "o1",
      contractor_id: "k1",
      contract_id: "d1",
      period_from: null,
      period_to: null,
      act_number: null,
      act_date: null,
      invoice_number: "5",
      invoice_date: "2026-01-02",
      amount: "1000.50",
      is_vat_included: false,
      vat_rate: null,
      vat_amount: "0",
      advance_retention: "0",
      warranty_retention: "0",
      total_to_pay: "1000.50",
      paid_amount: "0",
      payment_status: "unpaid",
      purpose: null,
      note: null,
      created_at: null,
      created_by: null,
      objects: { name: "Объект" },
      contractors: { short_name: "Ромашка" },
      contracts: { number: "217-3" },
      ...overrides,
    } as unknown as SettlementOperationJoinRow;
  }

  it("читает строку со связями и числами-строками", () => {
    const settlement = mapSettlementRow(makeJoinRow());

    expect(settlement.operationType).toBe("advance");
    expect(settlement.amount).toBe(1000.5);
    expect(settlement.vatRate).toBeNull();
    expect(settlement.paymentStatus).toBe("unpaid");
    expect(settlement.contractorName).toBe("Ромашка");
    expect(settlement.objectName).toBe("Объект");
    expect(settlement.contractNumber).toBe("217-3");
  });

  it("статус берёт из базы, а неизвестное значение считает неоплаченным", () => {
    expect(
      mapSettlementRow(makeJoinRow({ payment_status: "partial" }))
        .paymentStatus
    ).toBe("partial");
    expect(
      mapSettlementRow(makeJoinRow({ payment_status: "pending" })).paymentStatus
    ).toBe("unpaid");
  });
});

describe("mapSettlementListRow", () => {
  function makeListRow(
    overrides: Partial<SettlementOperationsListRow> = {}
  ): SettlementOperationsListRow {
    return {
      id: "s1",
      company_id: "c1",
      operation_type: "advance",
      object_id: "o1",
      contractor_id: "k1",
      contract_id: "d1",
      period_from: null,
      period_to: null,
      act_number: null,
      act_date: null,
      invoice_number: "5",
      invoice_date: "2026-01-02",
      amount: "1000.50",
      is_vat_included: false,
      vat_rate: null,
      vat_amount: "0",
      advance_retention: "0",
      warranty_retention: "0",
      total_to_pay: "1000.50",
      paid_amount: "0",
      payment_status: "unpaid",
      purpose: null,
      note: null,
      created_at: null,
      created_by: null,
      object_name: "Объект",
      contractor_name: "Ромашка",
      contract_number: "217-3",
      ...overrides,
    } as unknown as SettlementOperationsListRow;
  }

  it("читает плоскую строку реестра: названия приходят отдельными колонками", () => {
    const settlement = mapSettlementListRow(makeListRow());

    expect(settlement.operationType).toBe("advance");
    expect(settlement.amount).toBe(1000.5);
    expect(settlement.totalToPay).toBe(1000.5);
    expect(settlement.objectName).toBe("Объект");
    expect(settlement.contractorName).toBe("Ромашка");
    expect(settlement.contractNumber).toBe("217-3");
  });

  it("пустые названия превращает в пустые строки, а не в текст null", () => {
    const settlement = mapSettlementListRow(
      makeListRow({
        object_name: null,
        contractor_name: null,
        contract_number: null,
      })
    );

    expect(settlement.objectName).toBe("");
    expect(settlement.contractorName).toBe("");
    expect(settlement.contractNumber).toBe("");
  });
});

describe("settlementRemaining и sumSettlements", () => {
  it("считает остаток и итоги", () => {
    const paid = makeSettlement({ totalToPay: 1000, paidAmount: 400 });
    const overpaid = makeSettlement({ id: "s2", totalToPay: 1000, paidAmount: 1500 });
    expect(settlementRemaining(paid)).toBe(600);
    expect(settlementRemaining(overpaid)).toBe(-500);

    const totals = sumSettlements([paid, overpaid]);
    expect(totals.totalAmount).toBe(2000);
    expect(totals.totalPaid).toBe(1900);
    expect(totals.totalDebt).toBe(600);
  });
});

describe("settlementToDraft", () => {
  it("сохраняет ставку 0% (экспорт) как включённый НДС", () => {
    const draft = settlementToDraft(makeSettlement({ vatRate: 0, vatAmount: 0 }));
    expect(draft.isVatEnabled).toBe(true);
    expect(draft.vatRate).toBe("0");
  });

  it("без НДС отключает переключатель", () => {
    const draft = settlementToDraft(makeSettlement({ vatRate: null, vatAmount: 0 }));
    expect(draft.isVatEnabled).toBe(false);
  });

  it("возвращает сумму с НДС, когда налог включён", () => {
    const draft = settlementToDraft(makeSettlement());
    expect(draft.amount.replace(/\u00A0|\u202F/g, " ")).toBe("122 000,00");
  });
});

describe("settlementDraftToPayload", () => {
  it("акт с НДС в сумме: выделяет базу и налог", () => {
    const draft = {
      ...emptySettlementDraft(),
      objectId: "o1",
      contractorId: "k1",
      contractId: "d1",
      operationType: "act" as const,
      actNumber: "А-7",
      invoiceNumber: "сч-14",
      invoiceDate: "2026-09-19",
      amount: "122000",
      isVatEnabled: true,
      vatRate: "22",
      isVatIncluded: true,
    };

    const payload = settlementDraftToPayload(draft);
    expect(payload.amount).toBe(100000);
    expect(payload.vat_amount).toBe(22000);
    expect(payload.vat_rate).toBe(22);
    expect(payload.act_number).toBe("А-7");
  });

  it("не акт: очищает номер и дату акта, обнуляет удержания", () => {
    const draft = {
      ...emptySettlementDraft(),
      objectId: "o1",
      contractorId: "k1",
      contractId: "d1",
      operationType: "other" as const,
      actNumber: "А-7",
      invoiceNumber: "10",
      amount: "1000",
      isVatEnabled: false,
    };

    const payload = settlementDraftToPayload(draft, {
      ...makeSettlement(),
      actDate: "2026-01-01",
      advanceRetention: 500,
      warrantyRetention: 300,
    });
    expect(payload.act_number).toBeNull();
    expect(payload.act_date).toBeNull();
    expect(payload.advance_retention).toBe(0);
    expect(payload.warranty_retention).toBe(0);
    expect(payload.vat_rate).toBeNull();
  });
});
