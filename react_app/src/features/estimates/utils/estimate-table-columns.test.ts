import { describe, expect, it } from "vitest";

import {
  ESTIMATE_COLUMNS,
  ESTIMATE_EXECUTION_COLUMNS,
  resolveEstimateColumns,
  type EstimatePlanColumnId,
} from "@/features/estimates/utils/estimate-table-columns";

const noHidden: ReadonlySet<EstimatePlanColumnId> = new Set();
const ids = (hidden: ReadonlySet<EstimatePlanColumnId>, showExecution = false) =>
  resolveEstimateColumns(hidden, showExecution).map((column) => column.id);

describe("resolveEstimateColumns", () => {
  it("по умолчанию показывает все обычные колонки и не показывает выполнение", () => {
    expect(ids(noHidden)).toEqual(ESTIMATE_COLUMNS.map((column) => column.id));
  });

  it("добавляет колонки выполнения только при showExecution", () => {
    expect(ids(noHidden, true)).toEqual([
      ...ESTIMATE_COLUMNS.map((column) => column.id),
      ...ESTIMATE_EXECUTION_COLUMNS.map((column) => column.id),
    ]);
  });

  it("скрытая «Сумма» убирает «Сумму вып.» и «Ост. сумму»", () => {
    const visible = ids(new Set<EstimatePlanColumnId>(["total"]), true);

    expect(visible).not.toContain("total");
    expect(visible).not.toContain("completedTotal");
    expect(visible).not.toContain("remainingTotal");
  });

  it("скрытая «Сумма» не трогает колонки выполнения по количеству", () => {
    const visible = ids(new Set<EstimatePlanColumnId>(["total"]), true);

    expect(visible).toContain("completedQuantity");
    expect(visible).toContain("remainingQuantity");
  });

  it("скрытые колонки выполнения не влияют на обычные колонки", () => {
    expect(ids(new Set<EstimatePlanColumnId>(["total"]))).toEqual(
      ESTIMATE_COLUMNS.filter((column) => column.id !== "total").map(
        (column) => column.id
      )
    );
  });
});
