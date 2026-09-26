"use client";

import { useMemo } from "react";

import { EmptyState } from "@/components/shared/empty-state";
import { ErrorState } from "@/components/shared/error-state";
import { Loading } from "@/components/shared/loading";
import { EstimateItemsTable } from "@/features/estimates/ui/desktop/estimate-items-table";
import { useEstimateCompletion } from "@/features/estimates/hooks/use-estimate-completion";
import { useEstimateItems } from "@/features/estimates/hooks/use-estimate-items";
import { filterEstimateItemsByOverrun } from "@/features/estimates/utils/estimate-execution";
import { filterEstimateItems } from "@/features/estimates/utils/estimate.utils";
import { useAppSearch } from "@/layouts/desktop/app-search";
import type {
  EstimateContractGroup,
  EstimateFile,
  EstimateFileQuery,
  EstimateItem,
  EstimateObjectGroup,
  EstimateTableSort,
} from "@/features/estimates/types/estimate.types";
import { sortEstimateItemsByColumn } from "@/features/estimates/utils/estimate-table-sort";

type EstimateFilePanelProps = {
  objectGroup: EstimateObjectGroup | null;
  contractGroup: EstimateContractGroup | null;
  file: EstimateFile | null;
  showExecution?: boolean;
  showOverrunsOnly?: boolean;
  /** Текущая сортировка таблицы. */
  sort?: EstimateTableSort;
  onSortChange?: (next: EstimateTableSort) => void;
  onEdit?: (item: EstimateItem) => void;
  onDelete?: (item: EstimateItem) => void;
};

export function EstimateFilePanel({
  objectGroup,
  contractGroup,
  file,
  showExecution = false,
  showOverrunsOnly = false,
  sort = null,
  onSortChange,
  onEdit,
  onDelete,
}: EstimateFilePanelProps) {
  const { query } = useAppSearch();
  const fileQuery: EstimateFileQuery | null = contractGroup
    ? {
        objectId: objectGroup?.objectId ?? null,
        contractId: contractGroup.contractId,
        estimateTitle: file?.estimateTitle ?? null,
      }
    : null;

  const { data, isLoading, isError, error } = useEstimateItems(fileQuery);
  const itemIds = useMemo(() => (data ?? []).map((item) => item.id), [data]);
  const {
    completionById,
    isLoading: isCompletionLoading,
    isError: isCompletionError,
    error: completionError,
  } = useEstimateCompletion(
    itemIds,
    (showExecution || showOverrunsOnly) && fileQuery !== null
  );

  const filteredItems = useMemo(() => {
    let items = filterEstimateItems(data ?? [], query);
    if (showOverrunsOnly) {
      items = filterEstimateItemsByOverrun(items, completionById);
    }
    return items;
  }, [data, query, showOverrunsOnly, completionById]);

  const rows = useMemo(
    () => sortEstimateItemsByColumn(filteredItems, sort, completionById),
    [filteredItems, sort, completionById]
  );

  if (!objectGroup) {
    return (
      <div className="flex h-full min-h-0 flex-1 items-center justify-center p-6">
        <EmptyState
          title="Выберите объект и договор"
          description="Чтобы увидеть позиции смет, выберите объект и договор в фильтрах выше."
        />
      </div>
    );
  }

  if (!contractGroup) {
    return (
      <div className="flex h-full min-h-0 flex-1 items-center justify-center p-6">
        <EmptyState
          title="Выберите договор"
          description={`Выберите договор по объекту «${objectGroup.objectName}», чтобы увидеть список позиций.`}
        />
      </div>
    );
  }

  if (isLoading || (showOverrunsOnly && isCompletionLoading && completionById.size === 0)) {
    return (
      <div className="flex h-full min-h-0 flex-1 flex-col justify-center p-6">
        <Loading />
      </div>
    );
  }

  if (isError) {
    return (
      <div className="flex h-full min-h-0 flex-1 items-center justify-center p-6">
        <ErrorState
          message={
            error instanceof Error
              ? error.message
              : "Не удалось загрузить позиции"
          }
        />
      </div>
    );
  }

  if ((data?.length ?? 0) === 0) {
    return (
      <div className="flex h-full min-h-0 flex-1 items-center justify-center p-6">
        <EmptyState
          title="Позиций нет"
          description={
            file
              ? `В смете «${file.estimateTitle}» нет видимых строк.`
              : `В сметах договора № ${contractGroup.contractNumber} нет видимых строк.`
          }
        />
      </div>
    );
  }

  if (filteredItems.length === 0) {
    if (showOverrunsOnly) {
      return (
        <div className="flex h-full min-h-0 flex-1 items-center justify-center p-6">
          <EmptyState
            title="Превышений не обнаружено"
            description={
              query.trim().length > 0
                ? `По запросу «${query.trim()}» позиций с превышением выполнения над сметой не найдено.`
                : file
                  ? `В смете «${file.estimateTitle}» нет позиций с превышением выполнения над сметой.`
                  : `В сметах договора № ${contractGroup.contractNumber} нет позиций с превышением выполнения над сметой.`
            }
          />
        </div>
      );
    }

    if (query.trim().length > 0) {
      return (
        <div className="flex h-full min-h-0 flex-1 items-center justify-center p-6">
          <EmptyState
            title="Ничего не найдено"
            description={`По запросу «${query.trim()}» позиций по наименованию или артикулу не найдено.`}
          />
        </div>
      );
    }
  }

  return (
    <div className="flex min-h-0 min-w-0 flex-1 flex-col overflow-hidden rounded-b-xl">
      {showExecution && isCompletionError ? (
        <div className="shrink-0 px-4 py-2 sm:px-5">
          <ErrorState
            title="Не удалось загрузить выполнение"
            message={
              completionError instanceof Error
                ? completionError.message
                : "Позиции сметы показаны без факта работ"
            }
          />
        </div>
      ) : null}
      <EstimateItemsTable
        items={rows}
        showExecution={showExecution}
        completionById={completionById}
        isCompletionLoading={isCompletionLoading}
        sort={sort}
        onSortChange={onSortChange}
        onEdit={onEdit}
        onDelete={onDelete}
      />
    </div>
  );
}
