import { describe, expect, it } from "vitest";

import type { CashFlowListRow } from "@/types/database.types";
import type { CashFlowTransaction } from "@/features/cash-flow/types/cash-flow.types";
import {
  cashFlowCategoryDeleteError,
  cashFlowDraftToPayload,
  cashFlowToDraft,
  cashFlowWriteError,
  formatCompactCurrency,
  formatRuDate,
  mapCashFlowCategoryRow,
  mapCashFlowRow,
  parseAmount,
} from "@/features/cash-flow/utils/cash-flow.utils";

function row(overrides: Partial<CashFlowListRow> = {}): CashFlowListRow {
  return {
    id: "c1",
    date: "2026-09-14",
    type: "expense",
    amount: "1500.00",
    object_id: null,
    contract_id: null,
    contractor_id: null,
    category_id: null,
    comment: null,
    contractor_name: null,
    contractor_inn: null,
    operation_hash: null,
    created_at: null,
    created_by: null,
    object_name: null,
    contractor_short_name: null,
    contract_number: null,
    category_name: null,
    created_by_name: null,
    ...overrides,
  };
}

function transaction(
  overrides: Partial<CashFlowTransaction> = {}
): CashFlowTransaction {
  return {
    id: "c1",
    date: "2026-09-14",
    type: "expense",
    amount: 1500,
    categoryId: null,
    categoryName: "",
    objectId: null,
    objectName: "",
    contractId: null,
    contractNumber: "",
    contractorId: null,
    contractorName: "",
    contractorInn: "",
    comment: "",
    operationHash: null,
    ...overrides,
  };
}

describe("parseAmount", () => {
  it("принимает пробелы и запятую", () => {
    expect(parseAmount("1 234,56")).toBeCloseTo(1234.56);
    expect(parseAmount("1\u00A0234,56")).toBeCloseTo(1234.56);
  });

  it("пустая строка — ноль, мусор — null", () => {
    expect(parseAmount("")).toBe(0);
    expect(parseAmount("abc")).toBeNull();
  });
});

describe("formatCompactCurrency", () => {
  it("миллионы и тысячи сокращаются, дробная часть — через запятую", () => {
    expect(formatCompactCurrency(1_500_000)).toBe("1,5 млн ₽");
    expect(formatCompactCurrency(2_000_000)).toBe("2 млн ₽");
    expect(formatCompactCurrency(240_000)).toBe("240 тыс. ₽");
    expect(formatCompactCurrency(950)).toBe("950 ₽");
    expect(formatCompactCurrency(0)).toBe("0 ₽");
  });

  it("минус выносится перед числом", () => {
    expect(formatCompactCurrency(-1_500_000)).toBe("−1,5 млн ₽");
    expect(formatCompactCurrency(-950)).toBe("−950 ₽");
  });
});

describe("formatRuDate", () => {
  it("дата из базы — русский формат", () => {
    expect(formatRuDate("2026-09-19")).toBe("19.09.2026");
  });

  it("пустая дата — прочерк", () => {
    expect(formatRuDate(null)).toBe("—");
  });
});

describe("mapCashFlowRow", () => {
  it("контрагент берётся из справочника, а без него — из выписки", () => {
    const fromDirectory = mapCashFlowRow(
      row({ contractor_short_name: "ООО Ромашка", contractor_name: "РОМАШКА" })
    );
    expect(fromDirectory.contractorName).toBe("ООО Ромашка");

    const fromStatement = mapCashFlowRow(
      row({ contractor_name: "ИП Иванов", contractor_inn: "770123456789" })
    );
    expect(fromStatement.contractorName).toBe("ИП Иванов");
    expect(fromStatement.contractorInn).toBe("770123456789");
  });

  it("неизвестный тип операции считается расходом", () => {
    expect(mapCashFlowRow(row({ type: "both" })).type).toBe("expense");
  });

  it("сумма и связи приводятся к интерфейсу", () => {
    const mapped = mapCashFlowRow(
      row({
        amount: 2500.5,
        type: "income",
        category_id: "cat1",
        category_name: "Аванс",
        object_id: "obj1",
        object_name: "ЖК Северный",
        contract_id: "doc1",
        contract_number: "12/26",
        comment: "Оплата по счёту",
      })
    );

    expect(mapped.amount).toBe(2500.5);
    expect(mapped.type).toBe("income");
    expect(mapped.categoryId).toBe("cat1");
    expect(mapped.categoryName).toBe("Аванс");
    expect(mapped.objectName).toBe("ЖК Северный");
    expect(mapped.contractNumber).toBe("12/26");
    expect(mapped.comment).toBe("Оплата по счёту");
  });
});

describe("mapCashFlowCategoryRow", () => {
  it("статья приводится к интерфейсу", () => {
    expect(
      mapCashFlowCategoryRow({
        id: "cat1",
        company_id: "company",
        name: " Аренда ",
        type: "expense",
      })
    ).toEqual({ id: "cat1", name: "Аренда", type: "expense" });
  });
});

describe("cashFlowToDraft", () => {
  it("сумма показывается с копейками, пустые связи — пустыми строками", () => {
    const draft = cashFlowToDraft(
      transaction({ amount: 1234.5, categoryId: "cat1" })
    );

    expect(draft.amount).toBe("1\u00A0234,50");
    expect(draft.categoryId).toBe("cat1");
    expect(draft.contractorId).toBe("");
    expect(draft.date).toBe("2026-09-14");
  });
});

describe("cashFlowDraftToPayload", () => {
  it("пустые связи уходят как null, сумма округляется до копеек", () => {
    const payload = cashFlowDraftToPayload({
      type: "income",
      date: "2026-09-14",
      amount: "1 234,567",
      categoryId: "",
      objectId: "obj1",
      contractorId: "",
      contractId: "",
      comment: "  Оплата  ",
    });

    expect(payload).toEqual({
      date: "2026-09-14",
      type: "income",
      amount: 1234.57,
      category_id: null,
      object_id: "obj1",
      contract_id: null,
      contractor_id: null,
      comment: "Оплата",
    });
  });

  it("пустой комментарий не сохраняется", () => {
    const payload = cashFlowDraftToPayload({
      type: "expense",
      date: "2026-09-14",
      amount: "10",
      categoryId: "",
      objectId: "",
      contractorId: "",
      contractId: "",
      comment: "   ",
    });

    expect(payload.comment).toBeNull();
  });
});

describe("cashFlowWriteError", () => {
  it("дубликат хеша операции переводится в понятный текст", () => {
    const error = cashFlowWriteError({
      code: "23505",
      message: 'duplicate key value violates unique constraint "idx_cash_flow_operation_hash"',
    });
    expect(error.message).toBe("Такая операция уже есть в реестре");
  });

  it("прочие ошибки остаются текстом базы", () => {
    expect(cashFlowWriteError({ message: "connection reset" }).message).toBe(
      "connection reset"
    );
  });
});

describe("cashFlowCategoryDeleteError", () => {
  it("используемая статья объясняется словами", () => {
    const error = cashFlowCategoryDeleteError({
      code: "23503",
      message: "update or delete on table violates foreign key constraint",
    });
    expect(error.message).toContain("используется в операциях");
  });

  it("прочие ошибки остаются текстом базы", () => {
    expect(cashFlowCategoryDeleteError({ message: "нет сети" }).message).toBe(
      "нет сети"
    );
  });
});
