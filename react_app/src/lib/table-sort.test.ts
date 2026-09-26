import { describe, expect, it } from "vitest";

import {
  nextTableSort,
  tableSortAriaSort,
  tableSortTitle,
  type TableSort,
} from "@/lib/table-sort";

type Key = "name" | "amount";

describe("nextTableSort", () => {
  it("первый клик задаёт первое направление колонки", () => {
    expect(nextTableSort<Key>("amount", null, "desc")).toEqual({
      key: "amount",
      direction: "desc",
    });
    expect(nextTableSort<Key>("name", null)).toEqual({
      key: "name",
      direction: "asc",
    });
  });

  it("второй клик разворачивает, третий возвращает исходный порядок", () => {
    const first = nextTableSort<Key>("name", null, "asc");
    const second = nextTableSort<Key>("name", first, "asc");

    expect(second).toEqual({ key: "name", direction: "desc" });
    expect(nextTableSort<Key>("name", second, "asc")).toBeNull();
  });

  it("переход на другую колонку начинает с её первого направления", () => {
    const current: TableSort<Key> = { key: "amount", direction: "desc" };

    expect(nextTableSort<Key>("name", current, "asc")).toEqual({
      key: "name",
      direction: "asc",
    });
  });
});

describe("tableSortTitle", () => {
  it("подсказывает первое направление, пока колонка не отсортирована", () => {
    expect(tableSortTitle<Key>("name", null, "asc")).toBe(
      "Сортировать по возрастанию"
    );
    expect(tableSortTitle<Key>("amount", null, "desc")).toBe(
      "Сортировать по убыванию"
    );
  });

  it("подсказывает разворот и возврат исходного порядка", () => {
    expect(tableSortTitle<Key>("name", { key: "name", direction: "asc" })).toBe(
      "Развернуть порядок"
    );
    expect(tableSortTitle<Key>("name", { key: "name", direction: "desc" })).toBe(
      "Вернуть исходный порядок"
    );
  });
});

describe("tableSortAriaSort", () => {
  it("отражает состояние сортировки колонки", () => {
    expect(tableSortAriaSort<Key>("name", null)).toBe("none");
    expect(tableSortAriaSort<Key>("amount", null)).toBe("none");
    expect(
      tableSortAriaSort<Key>("name", { key: "name", direction: "asc" })
    ).toBe("ascending");
    expect(
      tableSortAriaSort<Key>("name", { key: "name", direction: "desc" })
    ).toBe("descending");
  });
});
