import { describe, expect, it } from "vitest";

import type { CashFlowMonthAnalytics } from "@/features/cash-flow/types/cash-flow.types";
import {
  analyticsCategoryNames,
  analyticsCategoryTotal,
  analyticsTotals,
  categoryLabel,
  formatMonthLabel,
  formatMonthShort,
  mapCashFlowMonthRow,
  monthCategoryAmount,
} from "@/features/cash-flow/utils/analytics";

function month(
  overrides: Partial<CashFlowMonthAnalytics> = {}
): CashFlowMonthAnalytics {
  return {
    month: "2026-01-01",
    income: 0,
    expense: 0,
    balance: 0,
    incomeByCategory: {},
    expenseByCategory: {},
    ...overrides,
  };
}

describe("formatMonthLabel", () => {
  it("подпись месяца — короткое название и год", () => {
    expect(formatMonthLabel("2026-01-01")).toBe("янв. 2026");
  });

  it("непонятное значение возвращается как есть", () => {
    expect(formatMonthLabel("мусор")).toBe("мусор");
  });
});

describe("formatMonthShort", () => {
  it("короткая подпись — только месяц, без года", () => {
    expect(formatMonthShort("2026-01-01")).toBe("янв.");
    expect(formatMonthShort("2026-09-01")).toBe("сент.");
  });

  it("непонятное значение возвращается как есть", () => {
    expect(formatMonthShort("мусор")).toBe("мусор");
  });
});

describe("categoryLabel", () => {
  it("операция без статьи подписывается словами", () => {
    expect(categoryLabel("")).toBe("Без статьи");
    expect(categoryLabel("Аренда")).toBe("Аренда");
  });
});

describe("mapCashFlowMonthRow", () => {
  it("суммы приводятся к числам, сальдо считается", () => {
    const mapped = mapCashFlowMonthRow({
      month: "2026-02-01",
      income: "1000.50",
      expense: 200,
      income_by_category: { Аванс: "1000.50" },
      expense_by_category: null,
    });

    expect(mapped.income).toBe(1000.5);
    expect(mapped.expense).toBe(200);
    expect(mapped.balance).toBeCloseTo(800.5);
    expect(mapped.incomeByCategory).toEqual({ Аванс: 1000.5 });
    expect(mapped.expenseByCategory).toEqual({});
  });
});

describe("analyticsCategoryNames", () => {
  it("собирает статьи всех месяцев по алфавиту подписей", () => {
    const names = analyticsCategoryNames(
      [
        month({ incomeByCategory: { Материалы: 10, Аванс: 20 } }),
        month({ month: "2026-02-01", incomeByCategory: { "": 5, Аренда: 1 } }),
      ],
      "income"
    );

    // Пустое название показывается как «Без статьи» и сортируется по подписи:
    // Аванс → Аренда → Без статьи → Материалы.
    expect(names).toEqual(["Аванс", "Аренда", "", "Материалы"]);
  });

  it("берёт разбивку нужного типа операции", () => {
    const source = [
      month({
        incomeByCategory: { Аванс: 20 },
        expenseByCategory: { Аренда: 7 },
      }),
    ];

    expect(analyticsCategoryNames(source, "income")).toEqual(["Аванс"]);
    expect(analyticsCategoryNames(source, "expense")).toEqual(["Аренда"]);
  });

  it("без операций статей нет", () => {
    expect(analyticsCategoryNames([], "income")).toEqual([]);
  });
});

describe("monthCategoryAmount", () => {
  it("берёт сумму статьи месяца, отсутствующая статья — ноль", () => {
    const source = month({ expenseByCategory: { Аренда: 7 } });

    expect(monthCategoryAmount(source, "expense", "Аренда")).toBe(7);
    expect(monthCategoryAmount(source, "expense", "Налоги")).toBe(0);
    expect(monthCategoryAmount(source, "income", "Аренда")).toBe(0);
  });
});

describe("analyticsTotals", () => {
  it("итоги складываются по месяцам", () => {
    const totals = analyticsTotals([
      month({ income: 100, expense: 40 }),
      month({ month: "2026-02-01", income: 50, expense: 70 }),
    ]);

    expect(totals.income).toBe(150);
    expect(totals.expense).toBe(110);
    expect(totals.balance).toBe(40);
  });

  it("пустой список даёт нули", () => {
    expect(analyticsTotals([])).toEqual({ income: 0, expense: 0, balance: 0 });
  });
});

describe("analyticsCategoryTotal", () => {
  it("итог статьи складывается по месяцам", () => {
    const months = [
      month({ incomeByCategory: { Аванс: 10, "": 1 } }),
      month({ month: "2026-02-01", incomeByCategory: { Аванс: 5 } }),
    ];

    expect(analyticsCategoryTotal(months, "income", "Аванс")).toBe(15);
    expect(analyticsCategoryTotal(months, "income", "")).toBe(1);
    expect(analyticsCategoryTotal(months, "expense", "Аванс")).toBe(0);
  });
});
