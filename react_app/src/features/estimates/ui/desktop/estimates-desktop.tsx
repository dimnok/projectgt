"use client";

import { useMemo, useState } from "react";
import { useQueryClient } from "@tanstack/react-query";
import { toast } from "sonner";
import { DownloadIcon, Loader2Icon, PlusIcon } from "lucide-react";

import { Button } from "@/components/ui/button";
import { EmptyState } from "@/components/shared/empty-state";
import { ErrorState } from "@/components/shared/error-state";
import { Loading } from "@/components/shared/loading";
import { EstimateColumnsMenu } from "@/features/estimates/ui/shared/estimate-columns-menu";
import { EstimateExecutionToggle } from "@/features/estimates/ui/shared/estimate-execution-toggle";
import { EstimateOverrunsToggle } from "@/features/estimates/ui/shared/estimate-overruns-toggle";
import { EstimateFilePanel } from "@/features/estimates/ui/shared/estimate-file-panel";
import { EstimatesFilters } from "@/features/estimates/ui/desktop/estimates-filters";
import { EstimatesKpi } from "@/features/estimates/ui/desktop/estimates-kpi";
import { createEstimateItem } from "@/features/estimates/api/create-estimate-item";
import { updateEstimateItem } from "@/features/estimates/api/update-estimate-item";
import { deleteEstimateItem } from "@/features/estimates/api/delete-estimate";
import {
  EstimateItemFormDialog,
  type EstimateItemFormData,
} from "@/features/estimates/ui/shared/estimate-item-form-dialog";
import { EstimateItemDeleteDialog } from "@/features/estimates/ui/shared/estimate-item-delete-dialog";
import { useEstimateGroups } from "@/features/estimates/hooks/use-estimate-groups";
import { useEstimateItems } from "@/features/estimates/hooks/use-estimate-items";
import { useEstimateCompletion } from "@/features/estimates/hooks/use-estimate-completion";
import {
  filterEstimateItemsByOverrun,
  isEstimateOverrun,
} from "@/features/estimates/utils/estimate-execution";
import { exportEstimateToExcel } from "@/features/estimates/utils/export-estimate-excel";
import {
  filterEstimateItems,
  groupEstimateFiles,
  resolveEstimateSelection,
} from "@/features/estimates/utils/estimate.utils";
import { useAppSearch } from "@/layouts/desktop/app-search";
import { usePermissions } from "@/hooks/use-permissions";
import type { EstimateFileQuery, EstimateItem } from "@/features/estimates/types/estimate.types";

export function EstimatesDesktop() {
  const queryClient = useQueryClient();
  const permissions = usePermissions();
  const canCreate = permissions.can("estimates", "create");
  const canUpdate = permissions.can("estimates", "update");
  const canDelete = permissions.can("estimates", "delete");

  const { data, isLoading, isError, error } = useEstimateGroups();
  const { query } = useAppSearch();
  const [objectKey, setObjectKey] = useState<string | null>(null);
  const [contractKey, setContractKey] = useState<string | null>(null);
  const [fileKey, setFileKey] = useState<string | null>(null);
  const [showExecution, setShowExecution] = useState(false);
  const [showOverrunsOnly, setShowOverrunsOnly] = useState(false);
  const [isExporting, setIsExporting] = useState(false);

  // Состояния добавления / редактирования / удаления позиций
  const [isItemFormOpen, setIsItemFormOpen] = useState(false);
  const [editingItem, setEditingItem] = useState<EstimateItem | null>(null);
  const [isItemSaving, setIsItemSaving] = useState(false);
  const [itemToDelete, setItemToDelete] = useState<EstimateItem | null>(null);
  const [isItemDeleting, setIsItemDeleting] = useState(false);

  const rawFiles = useMemo(() => data ?? [], [data]);
  const groups = useMemo(() => groupEstimateFiles(rawFiles), [rawFiles]);
  const selection = resolveEstimateSelection(
    groups,
    objectKey,
    contractKey,
    fileKey
  );

  const objectGroup = selection.objectGroup;
  const contractGroup = selection.contractGroup;

  const fileQuery: EstimateFileQuery | null = useMemo(() => {
    if (!contractGroup) return null;
    return {
      objectId: objectGroup?.objectId ?? null,
      contractId: contractGroup.contractId,
      estimateTitle: selection.file?.estimateTitle ?? null,
    };
  }, [contractGroup, objectGroup, selection.file]);

  const { data: itemsData } = useEstimateItems(fileQuery);
  const itemIds = useMemo(
    () => (itemsData ?? []).map((item) => item.id),
    [itemsData]
  );
  const { completionById, isLoading: isCompletionLoading } = useEstimateCompletion(
    itemIds,
    fileQuery !== null
  );

  const overrunCount = useMemo(() => {
    if (!itemsData || itemsData.length === 0 || completionById.size === 0) {
      return 0;
    }
    let count = 0;
    for (const item of itemsData) {
      if (isEstimateOverrun(item, completionById.get(item.id))) {
        count++;
      }
    }
    return count;
  }, [itemsData, completionById]);

  const isOverrunsActive = showOverrunsOnly && overrunCount > 0;

  const filteredItems = useMemo(() => {
    let items = filterEstimateItems(itemsData ?? [], query);
    if (isOverrunsActive) {
      items = filterEstimateItemsByOverrun(items, completionById);
    }
    return items;
  }, [itemsData, query, isOverrunsActive, completionById]);

  async function handleExportExcel() {
    if (!contractGroup) {
      toast.info("Сначала выберите объект и договор для выгрузки");
      return;
    }
    if (filteredItems.length === 0) {
      toast.warning("Нет позиций для выгрузки");
      return;
    }

    try {
      setIsExporting(true);
      await exportEstimateToExcel({
        items: filteredItems,
        completionById,
        objectName: objectGroup?.objectName,
        contractNumber: contractGroup.contractNumber,
        estimateTitle: selection.file?.estimateTitle,
      });
      toast.success("Excel-файл успешно сохранён");
    } catch (err) {
      toast.error(
        err instanceof Error ? err.message : "Не удалось сформировать Excel"
      );
    } finally {
      setIsExporting(false);
    }
  }

  const availableTitles = useMemo(
    () => (contractGroup?.files ?? []).map((f) => f.estimateTitle).filter(Boolean),
    [contractGroup]
  );

  function handleCreateItem() {
    setEditingItem(null);
    setIsItemFormOpen(true);
  }

  function handleEditItem(item: EstimateItem) {
    setEditingItem(item);
    setIsItemFormOpen(true);
  }

  async function handleItemFormSubmit(formData: EstimateItemFormData) {
    if (!contractGroup) return;
    try {
      setIsItemSaving(true);
      if (editingItem) {
        await updateEstimateItem({
          id: editingItem.id,
          system: formData.system,
          subsystem: formData.subsystem,
          number: formData.number,
          name: formData.name,
          article: formData.article,
          manufacturer: formData.manufacturer,
          unit: formData.unit,
          quantity: formData.quantity,
          price: formData.price,
        });
        toast.success("Позиция сметы успешно обновлена");
      } else {
        await createEstimateItem({
          objectId: objectGroup?.objectId ?? null,
          contractId: contractGroup.contractId,
          estimateTitle: formData.estimateTitle,
          system: formData.system,
          subsystem: formData.subsystem,
          number: formData.number,
          name: formData.name,
          article: formData.article,
          manufacturer: formData.manufacturer,
          unit: formData.unit,
          quantity: formData.quantity,
          price: formData.price,
        });
        toast.success("Новая позиция добавлена в смету");
      }
      setIsItemFormOpen(false);
      setEditingItem(null);
      queryClient.invalidateQueries({ queryKey: ["estimates"] });
    } catch (err) {
      toast.error(
        err instanceof Error ? err.message : "Ошибка при сохранении позиции"
      );
    } finally {
      setIsItemSaving(false);
    }
  }

  function handleDeleteItem(item: EstimateItem) {
    setItemToDelete(item);
  }

  async function handleConfirmDeleteItem() {
    if (!itemToDelete) return;
    try {
      setIsItemDeleting(true);
      await deleteEstimateItem(itemToDelete.id);
      toast.success("Позиция сметы удалена");
      setItemToDelete(null);
      queryClient.invalidateQueries({ queryKey: ["estimates"] });
    } catch (err) {
      toast.error(
        err instanceof Error ? err.message : "Не удалось удалить позицию"
      );
    } finally {
      setIsItemDeleting(false);
    }
  }

  if (isLoading) {
    return <Loading />;
  }

  if (isError) {
    return (
      <ErrorState
        message={error instanceof Error ? error.message : "Неизвестная ошибка"}
      />
    );
  }

  if (rawFiles.length === 0) {
    return (
      <div
        data-fill-viewport
        className="flex h-full min-h-0 min-w-0 w-full flex-1 flex-col items-center justify-center overflow-hidden rounded-xl bg-card p-6 ring-1 ring-foreground/10 shadow-float"
      >
        <EmptyState
          title="Смет нет"
          description="В компании пока нет загруженных смет."
        />
      </div>
    );
  }

  const isExcelDisabled = !contractGroup || filteredItems.length === 0 || isExporting || isCompletionLoading;

  return (
    <div
      data-fill-viewport
      className="flex h-full min-h-0 min-w-0 w-full flex-1 flex-col overflow-hidden rounded-xl bg-card ring-1 ring-foreground/10 shadow-float"
    >
      {/* 1. Блок ключевых KPI показателей */}
      <div className="shrink-0">
        <EstimatesKpi
          file={selection.file}
          contractGroup={contractGroup}
          objectGroup={objectGroup}
          allFiles={rawFiles}
        />
      </div>

      {/* 2. Блок фильтров с поиском и настройкой колонок */}
      <div className="flex shrink-0 flex-wrap items-center justify-between gap-3 border-b border-border/80 bg-muted/30 px-4 py-2.5 sm:px-5">
        <EstimatesFilters
          objects={groups}
          contracts={objectGroup?.contracts ?? []}
          files={contractGroup?.files ?? []}
          objectKey={objectGroup?.key ?? null}
          contractKey={contractGroup?.key ?? null}
          fileKey={selection.file?.key ?? null}
          onObjectChange={(key) => {
            setObjectKey(key);
            setContractKey(null);
            setFileKey(null);
            setShowOverrunsOnly(false);
          }}
          onContractChange={(key) => {
            setContractKey(key);
            setFileKey(null);
            setShowOverrunsOnly(false);
          }}
          onFileChange={(key) => {
            setFileKey(key);
            setShowOverrunsOnly(false);
          }}
        />
        <div className="flex items-center gap-2">
          <EstimateColumnsMenu size="icon-sm" />
        </div>
      </div>

      {/* 2.1. Панель действий сметы */}
      <div className="flex shrink-0 items-center justify-end gap-2 border-b border-border/80 bg-background px-4 py-1.5 sm:px-5">
        <EstimateExecutionToggle
          pressed={showExecution}
          disabled={!contractGroup}
          size="sm"
          onPressedChange={setShowExecution}
        />
        {overrunCount > 0 ? (
          <EstimateOverrunsToggle
            pressed={isOverrunsActive}
            disabled={!contractGroup}
            count={overrunCount}
            size="sm"
            onPressedChange={(pressed) => {
              setShowOverrunsOnly(pressed);
              if (pressed && !showExecution) {
                setShowExecution(true);
              }
            }}
          />
        ) : null}
        {/* Кнопка добавления позиции */}
        {canCreate ? (
          <Button
            type="button"
            size="sm"
            variant="outline"
            disabled={!contractGroup}
            onClick={handleCreateItem}
            className="gap-1.5 cursor-pointer"
            title={
              !contractGroup
                ? "Выберите договор для добавления позиции"
                : "Добавить позицию в смету"
            }
          >
            <PlusIcon className="size-3.5 shrink-0" />
            <span>Позиция</span>
          </Button>
        ) : null}

        <Button
          type="button"
          size="sm"
          onClick={handleExportExcel}
          disabled={isExcelDisabled}
          className="gap-1.5 border-emerald-600/30 bg-emerald-600 text-white hover:bg-emerald-700 active:bg-emerald-800 disabled:pointer-events-none disabled:opacity-50 dark:border-emerald-500/30 dark:bg-emerald-600 dark:hover:bg-emerald-500 cursor-pointer"
          title={
            !contractGroup
              ? "Выберите объект и договор для экспорта в Excel"
              : isExporting
                ? "Формирование файла..."
                : "Экспорт в Excel"
          }
        >
          {isExporting ? (
            <Loader2Icon className="size-3.5 shrink-0 animate-spin" />
          ) : (
            <DownloadIcon className="size-3.5 shrink-0" />
          )}
          <span>{isExporting ? "Формирование..." : "Excel"}</span>
        </Button>
      </div>

      {/* 3. Таблица позиций сметы */}
      <div className="flex min-h-0 min-w-0 flex-1 flex-col overflow-hidden rounded-b-xl [clip-path:inset(0_round_0_0_var(--radius-xl)_var(--radius-xl))]">
        <EstimateFilePanel
          objectGroup={objectGroup}
          contractGroup={contractGroup}
          file={selection.file}
          showExecution={showExecution}
          showOverrunsOnly={isOverrunsActive}
        />
      </div>

      {/* Модальное окно создания / редактирования позиции */}
      <EstimateItemFormDialog
        open={isItemFormOpen}
        item={editingItem}
        defaultEstimateTitle={
          selection.file?.estimateTitle ||
          (availableTitles.length === 1 ? availableTitles[0] : "")
        }
        availableEstimateTitles={availableTitles}
        isSaving={isItemSaving}
        onOpenChange={(open) => {
          setIsItemFormOpen(open);
          if (!open) setEditingItem(null);
        }}
        onSubmit={handleItemFormSubmit}
      />

      {/* Диалог подтверждения удаления позиции */}
      <EstimateItemDeleteDialog
        item={itemToDelete}
        isDeleting={isItemDeleting}
        onOpenChange={(open) => {
          if (!open) setItemToDelete(null);
        }}
        onConfirm={handleConfirmDeleteItem}
      />
    </div>
  );
}
