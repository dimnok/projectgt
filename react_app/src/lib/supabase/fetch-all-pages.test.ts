import { describe, expect, it, vi } from "vitest";

import { fetchAllPages } from "@/lib/supabase/fetch-all-pages";

const POSTGREST_PAGE_SIZE = 1000;

function buildRows(count: number): { id: number }[] {
  return Array.from({ length: count }, (_, index) => ({ id: index }));
}

describe("fetchAllPages", () => {
  it("добирает строки после полной страницы и обходит лимит PostgREST", async () => {
    const all = buildRows(POSTGREST_PAGE_SIZE + 156);
    const fetchPage = vi.fn(async (from: number, to: number) => ({
      data: all.slice(from, to + 1),
      error: null,
    }));

    const rows = await fetchAllPages<{ id: number }>(fetchPage);

    expect(rows).toHaveLength(all.length);
    expect(rows[0]).toEqual({ id: 0 });
    expect(rows.at(-1)).toEqual({ id: all.length - 1 });
    expect(fetchPage).toHaveBeenCalledTimes(2);
    expect(fetchPage).toHaveBeenNthCalledWith(1, 0, POSTGREST_PAGE_SIZE - 1);
    expect(fetchPage).toHaveBeenNthCalledWith(
      2,
      POSTGREST_PAGE_SIZE,
      POSTGREST_PAGE_SIZE * 2 - 1
    );
  });

  it("останавливается после неполной страницы", async () => {
    const all = buildRows(42);
    const fetchPage = vi.fn(async (from: number, to: number) => ({
      data: all.slice(from, to + 1),
      error: null,
    }));

    const rows = await fetchAllPages<{ id: number }>(fetchPage);

    expect(rows).toHaveLength(42);
    expect(fetchPage).toHaveBeenCalledTimes(1);
  });

  it("возвращает пустой массив, когда строк нет", async () => {
    const fetchPage = vi.fn(async () => ({ data: [], error: null }));

    await expect(fetchAllPages(fetchPage)).resolves.toEqual([]);
    expect(fetchPage).toHaveBeenCalledTimes(1);
  });

  it("пробрасывает ошибку запроса", async () => {
    const fetchPage = vi.fn(async () => ({
      data: null,
      error: { message: "boom" },
    }));

    await expect(fetchAllPages(fetchPage)).rejects.toThrow("boom");
  });
});
