/**
 * Общая логика сортировки таблиц по клику на заголовок.
 *
 * Модули (ФОТ, ДДС, реестр счетов, пользователи, сметы) хранят состояние
 * сортировки сами, а правило клика, подсказки и атрибут доступности берут
 * отсюда — чтобы поведение во всех таблицах было одинаковым.
 */

/** Направление сортировки колонки. */
export type SortDirection = "asc" | "desc";

/** Текущая сортировка таблицы: колонка и направление. `null` — исходный порядок. */
export type TableSort<TKey extends string = string> = {
  key: TKey;
  direction: SortDirection;
} | null;

/**
 * Порядок сортировки после клика по заголовку.
 *
 * Первый клик задаёт первое направление колонки (`first`), второй — обратное,
 * третий возвращает исходный порядок (`null`).
 */
export function nextTableSort<TKey extends string>(
  key: TKey,
  sort: TableSort<TKey>,
  first: SortDirection = "asc"
): TableSort<TKey> {
  if (sort?.key !== key) {
    return { key, direction: first };
  }
  if (sort.direction === first) {
    return { key, direction: first === "desc" ? "asc" : "desc" };
  }
  return null;
}

/** Подсказка к заголовку: что произойдёт по клику. */
export function tableSortTitle<TKey extends string>(
  key: TKey,
  sort: TableSort<TKey>,
  first: SortDirection = "asc"
): string {
  if (sort?.key !== key) {
    return `Сортировать по ${first === "asc" ? "возрастанию" : "убыванию"}`;
  }
  return nextTableSort(key, sort, first) === null
    ? "Вернуть исходный порядок"
    : "Развернуть порядок";
}

/** Значение атрибута `aria-sort` для заголовка колонки. */
export function tableSortAriaSort<TKey extends string>(
  key: TKey,
  sort: TableSort<TKey>
): "ascending" | "descending" | "none" {
  if (sort?.key !== key) {
    return "none";
  }
  return sort.direction === "asc" ? "ascending" : "descending";
}
