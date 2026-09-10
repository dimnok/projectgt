"use client";

import { useMemo, useState } from "react";
import { useQueryClient } from "@tanstack/react-query";
import { toast } from "sonner";
import {
  FileSpreadsheetIcon,
  Trash2Icon,
  DownloadIcon,
  PlusIcon,
  CalculatorIcon,
  SearchIcon,
  XIcon,
} from "lucide-react";

import { Button } from "@/components/ui/button";
import { EmptyState } from "@/components/shared/empty-state";
import { Loading } from "@/components/shared/loading";
import { ErrorState } from "@/components/shared/error-state";
import {
  InputGroup,
  InputGroupAddon,
  InputGroupButton,
  InputGroupInput,
} from "@/components/ui/input-group";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import { EstimateItemsTable } from "@/features/estimates/ui/desktop/estimate-items-table";
import { EstimateColumnsMenu } from "@/features/estimates/ui/shared/estimate-columns-menu";
import { EstimateExecutionToggle } from "@/features/estimates/ui/shared/estimate-execution-toggle";
import { EstimateOverrunsToggle } from "@/features/estimates/ui/shared/estimate-overruns-toggle";
import { ImportEstimateDialog } from "@/features/estimates/ui/shared/import-estimate-dialog";
import { EstimateFileDeleteDialog } from "@/features/estimates/ui/shared/estimate-file-delete-dialog";
import { useEstimateGroups } from "@/features/estimates/hooks/use-estimate-groups";
import { useEstimateItems } from "@/features/estimates/hooks/use-estimate-items";
import { useEstimateCompletion } from "@/features/estimates/hooks/use-estimate-completion";
import { deleteEstimateFile } from "@/features/estimates/api/delete-estimate";
import { exportEstimateToExcel } from "@/features/estimates/utils/export-estimate-excel";
import {
  filterEstimateItemsByOverrun,
  isEstimateOverrun,
} from "@/features/estimates/utils/estimate-execution";
import {
  filterEstimateItems,
  formatCurrency,
} from "@/features/estimates/utils/estimate.utils";
import { usePermissions } from "@/hooks/use-permissions";
import { createEstimateItem } from "@/features/estimates/api/create-estimate-item";
import { updateEstimateItem } from "@/features/estimates/api/update-estimate-item";
import { deleteEstimateItem } from "@/features/estimates/api/delete-estimate";
import {
  EstimateItemFormDialog,
  type EstimateItemFormData,
} from "@/features/estimates/ui/shared/estimate-item-form-dialog";
import { EstimateItemDeleteDialog } from "@/features/estimates/ui/shared/estimate-item-delete-dialog";
import type { Contract } from "@/features/contracts/types/contract.types";
import type { EstimateFile, EstimateItem } from "@/features/estimates/types/estimate.types";

type ContractEstimatesTabProps = {
  contract: Contract;
};

export function ContractEstimatesTab({ contract }: ContractEstimatesTabProps) {
  const queryClient = useQueryClient();
  const permissions = usePermissions();

  const canCreate = permissions.can("estimates", "create");
  const canUpdate = permissions.can("estimates", "update");
  const canDelete = permissions.can("estimates", "delete");

  // Состояния фильтров и модалок
  const [selectedTitle, setSelectedTitle] = useState<string>("all");
  const [searchQuery, setSearchQuery] = useState("");
  const [showExecution, setShowExecution] = useState(false);
  const [showOverrunsOnly, setShowOverrunsOnly] = useState(false);
  const [isImportOpen, setIsImportOpen] = useState(false);
  const [fileToDelete, setFileToDelete] = useState<EstimateFile | null>(null);
  const [isDeleting, setIsDeleting] = useState(false);
  const [isExporting, setIsExporting] = useState(false);

  // Состояния для добавления/редактирования/удаления позиций
  const [isItemFormOpen, setIsItemFormOpen] = useState(false);
  const [editingItem, setEditingItem] = useState<EstimateItem | null>(null);
  const [isItemSaving, setIsItemSaving] = useState(false);
  const [itemToDelete, setItemToDelete] = useState<EstimateItem | null>(null);
  const [isItemDeleting, setIsItemDeleting] = useState(false);

  // 1. Загружаем сметы компании и фильтруем по этому договору
  const { data: allGroups, isLoading: isGroupsLoading, isError: isGroupsError, error: groupsError } = useEstimateGroups();

  const contractFiles = useMemo(() => {
    if (!allGroups) return [];
    return allGroups.filter((g) => g.contractId === contract.id);
  }, [allGroups, contract.id]);

  const existingTitles = useMemo(() => {
    return contractFiles.map((f) => f.estimateTitle).filter(Boolean);
  }, [contractFiles]);

  const selectedFile = useMemo(() => {
    if (selectedTitle === "all") return null;
    return contractFiles.find((f) => f.estimateTitle === selectedTitle) ?? null;
  }, [contractFiles, selectedTitle]);

  // 2. Запрос позиций сметы/смет договора
  const fileQuery = useMemo(() => {
    return {
      objectId: contract.objectId,
      contractId: contract.id,
      estimateTitle: selectedTitle === "all" ? null : selectedTitle,
    };
  }, [contract.objectId, contract.id, selectedTitle]);

  const {
    data: items,
    isLoading: isItemsLoading,
    isError: isItemsError,
    error: itemsError,
  } = useEstimateItems(fileQuery);

  const itemIds = useMemo(() => (items ?? []).map((it) => it.id), [items]);

  // 3. Загрузка выполнения
  const { completionById, isLoading: isCompletionLoading } = useEstimateCompletion(
    itemIds,
    showExecution || showOverrunsOnly
  );

  // Подсчет превышений
  const overrunCount = useMemo(() => {
    if (!items || items.length === 0 || completionById.size === 0) return 0;
    let count = 0;
    for (const item of items) {
      if (isEstimateOverrun(item, completionById.get(item.id))) {
        count++;
      }
    }
    return count;
  }, [items, completionById]);

  const isOverrunsActive = showOverrunsOnly && overrunCount > 0;

  const displayItems = useMemo(() => {
    if (!items) return [];
    let result = items;
    if (searchQuery.trim()) {
      result = filterEstimateItems(result, searchQuery);
    }
    if (isOverrunsActive) {
      result = filterEstimateItemsByOverrun(result, completionById);
    }
    return result;
  }, [items, searchQuery, isOverrunsActive, completionById]);

  // Расчет сводных данных по договору
  const totalContractEstimatesAmount = useMemo(() => {
    return contractFiles.reduce((sum, f) => sum + f.total, 0);
  }, [contractFiles]);

  // Удаление сметы
  async function handleDeleteConfirm() {
    if (!fileToDelete) return;

    try {
      setIsDeleting(true);
      await deleteEstimateFile({
        contractId: contract.id,
        estimateTitle: fileToDelete.estimateTitle,
      });

      toast.success(`Смета «${fileToDelete.estimateTitle}» успешно удалена`);
      setFileToDelete(null);
      if (selectedTitle === fileToDelete.estimateTitle) {
        setSelectedTitle("all");
      }
      // Инвалидируем кэш
      queryClient.invalidateQueries({ queryKey: ["estimates"] });
    } catch (err) {
      toast.error(
        err instanceof Error ? err.message : "Не удалось удалить смету"
      );
    } finally {
      setIsDeleting(false);
    }
  }

  // Экспорт в Excel
  async function handleExportExcel() {
    if (!displayItems || displayItems.length === 0) {
      toast.warning("Нет позиций для экспорта");
      return;
    }

    try {
      setIsExporting(true);
      await exportEstimateToExcel({
        items: displayItems,
        completionById,
        objectName: contract.objectName,
        contractNumber: contract.number,
        estimateTitle: selectedFile?.estimateTitle || "Все сметы",
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

  function handleCreateItem() {
    setEditingItem(null);
    setIsItemFormOpen(true);
  }

  function handleEditItem(item: EstimateItem) {
    setEditingItem(item);
    setIsItemFormOpen(true);
  }

  async function handleItemFormSubmit(formData: EstimateItemFormData) {
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
          objectId: contract.objectId,
          contractId: contract.id,
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

  if (isGroupsLoading) {
    return <Loading />;
  }

  if (isGroupsError) {
    return (
      <ErrorState
        message={
          groupsError instanceof Error
            ? groupsError.message
            : "Не удалось загрузить сметы договора"
        }
      />
    );
  }

  return (
    <div className="flex h-full min-h-0 flex-1 flex-col overflow-hidden">
      {/* 1. Верхняя панель: выбор сметы, KPI и кнопки действий */}
      <div className="flex shrink-0 flex-wrap items-center justify-between gap-3 border-b border-border/70 px-4 py-2 sm:px-5">
        {/* Селектор сметы */}
        <div className="flex items-center gap-2">
          <Select
            value={selectedTitle}
            onValueChange={(val) => {
              setSelectedTitle(val ?? "all");
              setShowOverrunsOnly(false);
            }}
          >
            <SelectTrigger className="w-56 sm:w-64 bg-card">
              <SelectValue>
                {selectedTitle === "all"
                  ? "Все сметы"
                  : selectedTitle}
              </SelectValue>
            </SelectTrigger>
            <SelectContent align="start">
              <SelectItem value="all">
                <span>Все сметы ({contractFiles.length})</span>
              </SelectItem>
              {contractFiles.map((f) => (
                <SelectItem key={f.key} value={f.estimateTitle}>
                  <span className="truncate">{f.estimateTitle}</span>
                </SelectItem>
              ))}
            </SelectContent>
          </Select>

          {/* Кнопка удаления выбранной сметы */}
          {selectedFile && canDelete ? (
            <Button
              type="button"
              variant="outline"
              size="icon-sm"
              onClick={() => setFileToDelete(selectedFile)}
              title={`Удалить смету «${selectedFile.estimateTitle}»`}
              className="text-destructive hover:bg-destructive/10 hover:text-destructive cursor-pointer shrink-0"
            >
              <Trash2Icon className="size-3.5" />
            </Button>
          ) : null}

          {/* Кнопка импорта */}
          {canCreate ? (
            <Button
              type="button"
              size="sm"
              onClick={() => setIsImportOpen(true)}
              className="gap-1.5 cursor-pointer"
            >
              <PlusIcon className="size-3.5 shrink-0" />
              <span>Смета</span>
            </Button>
          ) : null}

          {/* Поле поиска по позициям сметы */}
          <div className="relative flex w-48 sm:w-60 md:w-72 items-center">
            <InputGroup className="h-7 w-full rounded-lg bg-card text-xs hover:bg-muted/40">
              <InputGroupAddon>
                <SearchIcon className="size-3.5 text-muted-foreground" />
              </InputGroupAddon>
              <InputGroupInput
                type="text"
                value={searchQuery}
                placeholder="Поиск по наименованию, артикулу..."
                aria-label="Поиск по наименованию и артикулу"
                className="h-7 text-xs placeholder:text-muted-foreground [&::-webkit-search-cancel-button]:appearance-none [&::-webkit-search-cancel-button]:hidden [&::-webkit-search-decoration]:hidden"
                onChange={(event) => setSearchQuery(event.target.value)}
              />
              {searchQuery ? (
                <InputGroupAddon align="inline-end">
                  <InputGroupButton
                    size="icon-xs"
                    variant="ghost"
                    aria-label="Очистить поиск"
                    onClick={() => setSearchQuery("")}
                  >
                    <XIcon className="size-3 text-muted-foreground" />
                  </InputGroupButton>
                </InputGroupAddon>
              ) : null}
            </InputGroup>
          </div>
        </div>

        {/* Сводка / KPI */}
        <div className="hidden xl:flex items-center gap-4 text-xs text-muted-foreground">
          <div className="flex items-center gap-1.5">
            <CalculatorIcon className="size-3.5 text-primary" />
            <span>Сумма смет:</span>
            <span className="font-semibold text-foreground tabular-nums">
              {formatCurrency(
                selectedFile ? selectedFile.total : totalContractEstimatesAmount
              )}
            </span>
          </div>
        </div>

        {/* Кнопки действий: Импорт, Выгрузка, Колонки */}
        <div className="flex items-center gap-2">
          <EstimateExecutionToggle
            pressed={showExecution}
            size="sm"
            onPressedChange={setShowExecution}
          />

          {overrunCount > 0 ? (
            <EstimateOverrunsToggle
              pressed={isOverrunsActive}
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

          {/* Кнопка Excel */}
          <Button
            type="button"
            size="sm"
            onClick={handleExportExcel}
            disabled={!displayItems || displayItems.length === 0 || isExporting}
            className="gap-1.5 border-emerald-600/30 bg-emerald-600 text-white hover:bg-emerald-700 active:bg-emerald-800 dark:border-emerald-500/30 dark:bg-emerald-600 dark:hover:bg-emerald-500 cursor-pointer"
            title="Экспорт в Excel"
          >
            <DownloadIcon className="size-3.5 shrink-0" />
            <span>Excel</span>
          </Button>

          {/* Кнопка добавления позиции */}
          {canCreate ? (
            <Button
              type="button"
              variant="outline"
              size="sm"
              onClick={handleCreateItem}
              className="gap-1.5 cursor-pointer"
            >
              <PlusIcon className="size-3.5 shrink-0" />
              <span>Позиция</span>
            </Button>
          ) : null}

          <EstimateColumnsMenu size="icon-sm" />
        </div>
      </div>

      {/* 2. Содержимое вкладки: таблица или пустые состояния */}
      <div className="flex min-h-0 min-w-0 flex-1 flex-col overflow-hidden">
        {contractFiles.length === 0 ? (
          <div className="flex h-full min-h-0 flex-1 flex-col items-center justify-center gap-3 p-6">
            <EmptyState
              title="По договору нет смет"
              description="Загрузите сметный расчет из файла Excel (.xlsx) с помощью кнопки ниже."
              icon={FileSpreadsheetIcon}
            />
            {canCreate ? (
              <Button
                type="button"
                onClick={() => setIsImportOpen(true)}
                className="gap-1.5 cursor-pointer"
              >
                <PlusIcon className="size-4 shrink-0" />
                <span>Загрузить смету (.xlsx)</span>
              </Button>
            ) : null}
          </div>
        ) : isItemsLoading ? (
          <div className="flex h-full min-h-0 flex-1 items-center justify-center p-6">
            <Loading />
          </div>
        ) : isItemsError ? (
          <div className="flex h-full min-h-0 flex-1 items-center justify-center p-6">
            <ErrorState
              message={
                itemsError instanceof Error
                  ? itemsError.message
                  : "Ошибка загрузки позиций сметы"
              }
            />
          </div>
        ) : displayItems.length === 0 ? (
          <div className="flex h-full min-h-0 flex-1 items-center justify-center p-6">
            <EmptyState
              title={
                searchQuery.trim()
                  ? "Ничего не найдено"
                  : showOverrunsOnly
                    ? "Превышений не найдено"
                    : "Позиции не найдены"
              }
              description={
                searchQuery.trim()
                  ? `По запросу «${searchQuery.trim()}» позиций по наименованию или артикулу не найдено.`
                  : showOverrunsOnly
                    ? "В выбранной смете нет позиций с превышением выполнения над планом."
                    : "В смете отсутствуют позиции."
              }
            />
          </div>
        ) : (
          <EstimateItemsTable
            items={displayItems}
            showExecution={showExecution}
            completionById={completionById}
            isCompletionLoading={isCompletionLoading}
            dense
            onEdit={canUpdate ? handleEditItem : undefined}
            onDelete={canDelete ? handleDeleteItem : undefined}
          />
        )}
      </div>

      {/* Модальное окно импорта сметы */}
      <ImportEstimateDialog
        open={isImportOpen}
        contractId={contract.id}
        contractNumber={contract.number}
        objectId={contract.objectId}
        existingTitles={existingTitles}
        onOpenChange={setIsImportOpen}
        onSuccess={() => {
          queryClient.invalidateQueries({ queryKey: ["estimates"] });
        }}
      />

      {/* Модальное окно создания / редактирования позиции */}
      <EstimateItemFormDialog
        open={isItemFormOpen}
        item={editingItem}
        defaultEstimateTitle={selectedFile?.estimateTitle || (existingTitles.length === 1 ? existingTitles[0] : "")}
        availableEstimateTitles={existingTitles}
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

      {/* Диалог подтверждения удаления сметы */}
      <EstimateFileDeleteDialog
        file={fileToDelete}
        isDeleting={isDeleting}
        onOpenChange={(open) => {
          if (!open) setFileToDelete(null);
        }}
        onConfirm={handleDeleteConfirm}
      />
    </div>
  );
}
