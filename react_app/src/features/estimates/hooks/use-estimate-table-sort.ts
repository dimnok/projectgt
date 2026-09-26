"use client";

import { useMemo, useState } from "react";

import { useEstimateTableLayout } from "@/features/estimates/hooks/use-estimate-table-layout";
import type { EstimateTableSort } from "@/features/estimates/types/estimate.types";

/**
 * Сортировка таблицы смет: выбор колонки и направления.
 *
 * Держится, пока открыт экран (после обновления страницы — исходный порядок).
 * Если отсортированную колонку скрыли в настройках вида или выключили блок
 * выполнения, сортировка сбрасывается: порядок строк и стрелка в шапке всегда
 * соответствуют видимым колонкам, и выгрузка в Excel совпадает с экраном.
 */
export function useEstimateTableSort(showExecution = false) {
  const [sort, setSort] = useState<EstimateTableSort>(null);
  const { visibleColumns } = useEstimateTableLayout(showExecution);

  const activeSort = useMemo(
    () =>
      sort && visibleColumns.some((column) => column.id === sort.key)
        ? sort
        : null,
    [sort, visibleColumns]
  );

  return { sort: activeSort, setSort };
}
