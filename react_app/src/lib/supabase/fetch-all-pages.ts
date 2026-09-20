/** Дефолтный max-rows PostgREST: без `.range()` ответ обрезается на 1000 строк. */
const POSTGREST_PAGE_SIZE = 1000;

type PageResult = {
  data: unknown;
  error: { message: string } | null;
};

/**
 * Загружает все строки выборки, обходя лимит PostgREST повторными запросами.
 *
 * Типы ответа Supabase в проекте не сгенерированы, поэтому форма строки задаётся
 * select-строкой запроса и приводится к `T` осознанно — в одном месте на модуль.
 * Сортировка запроса должна быть детерминированной, иначе страницы пересекутся.
 */
export async function fetchAllPages<T>(
  fetchPage: (from: number, to: number) => PromiseLike<PageResult>
): Promise<T[]> {
  const rows: T[] = [];
  let offset = 0;

  for (;;) {
    const { data, error } = await fetchPage(
      offset,
      offset + POSTGREST_PAGE_SIZE - 1
    );
    if (error) {
      throw new Error(error.message);
    }

    const batch = (data ?? []) as T[];
    rows.push(...batch);
    if (batch.length < POSTGREST_PAGE_SIZE) {
      return rows;
    }
    offset += POSTGREST_PAGE_SIZE;
  }
}
