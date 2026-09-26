import { describe, expect, it } from "vitest";

import type {
  EstimateCompletion,
  EstimateItem,
} from "@/features/estimates/types/estimate.types";
import { sortEstimateItemsByColumn } from "@/features/estimates/utils/estimate-table-sort";

function item(overrides: Partial<EstimateItem> = {}): EstimateItem {
  return {
    id: "id",
    companyId: "company",
    system: "Система 1",
    subsystem: "Подсистема 1",
    number: "1",
    name: "Позиция",
    article: "",
    manufacturer: "",
    unit: "шт",
    quantity: 10,
    price: 100,
    total: 1000,
    ...overrides,
  };
}

const noCompletion = new Map<string, EstimateCompletion>();

const ids = (items: EstimateItem[]) => items.map((entry) => entry.id);

describe("sortEstimateItemsByColumn", () => {
  it("без сортировки порядок не меняется", () => {
    const items = [item({ id: "b" }), item({ id: "a" })];

    expect(sortEstimateItemsByColumn(items, null, noCompletion)).toBe(items);
  });

  it("сортирует текст по алфавиту в обе стороны", () => {
    const items = [
      item({ id: "b", name: "Бетон" }),
      item({ id: "a", name: "Арматура" }),
    ];

    expect(
      ids(
        sortEstimateItemsByColumn(
          items,
          { key: "name", direction: "asc" },
          noCompletion
        )
      )
    ).toEqual(["a", "b"]);
    expect(
      ids(
        sortEstimateItemsByColumn(
          items,
          { key: "name", direction: "desc" },
          noCompletion
        )
      )
    ).toEqual(["b", "a"]);
  });

  it("сортирует суммы как числа", () => {
    const items = [
      item({ id: "small", total: 900 }),
      item({ id: "big", total: 12000 }),
    ];

    expect(
      ids(
        sortEstimateItemsByColumn(
          items,
          { key: "total", direction: "desc" },
          noCompletion
        )
      )
    ).toEqual(["big", "small"]);
  });

  it("сортирует № как документ: 2 перед 10", () => {
    const items = [
      item({ id: "ten", number: "10" }),
      item({ id: "two", number: "2" }),
    ];

    expect(
      ids(
        sortEstimateItemsByColumn(
          items,
          { key: "number", direction: "asc" },
          noCompletion
        )
      )
    ).toEqual(["two", "ten"]);
  });

  it("колонки выполнения считает по цене сметы и факту работ", () => {
    const items = [
      item({ id: "few", price: 100, quantity: 10 }),
      item({ id: "many", price: 100, quantity: 10 }),
    ];
    const completion = new Map<string, EstimateCompletion>([
      ["few", { estimateId: "few", completedQuantity: 1, remainingQuantity: 9 }],
      ["many", { estimateId: "many", completedQuantity: 8, remainingQuantity: 2 }],
    ]);

    expect(
      ids(
        sortEstimateItemsByColumn(
          items,
          { key: "completedTotal", direction: "desc" },
          completion
        )
      )
    ).toEqual(["many", "few"]);
    expect(
      ids(
        sortEstimateItemsByColumn(
          items,
          { key: "remainingQuantity", direction: "asc" },
          completion
        )
      )
    ).toEqual(["many", "few"]);
  });

  it("равные значения идут в исходном порядке", () => {
    const items = [
      item({ id: "second", system: "Система 2", total: 500 }),
      item({ id: "first", system: "Система 1", total: 500 }),
    ];

    expect(
      ids(
        sortEstimateItemsByColumn(
          items,
          { key: "total", direction: "desc" },
          noCompletion
        )
      )
    ).toEqual(["first", "second"]);
  });
});
