"use client";

import { useMemo, useState } from "react";
import { ChevronLeftIcon, ChevronRightIcon } from "lucide-react";
import { toast } from "sonner";

import { EmptyState } from "@/components/shared/empty-state";
import { ErrorState } from "@/components/shared/error-state";
import { Button } from "@/components/ui/button";
import { useContractors } from "@/features/contractors/hooks/use-contractors";
import { sortContractorsByName } from "@/features/contractors/utils/contractor.utils";
import { useContracts } from "@/features/contracts/hooks/use-contracts";
import {
  CASH_FLOW_PAGE_SIZE,
  type CashFlowListQuery,
  type CashFlowSort,
} from "@/features/cash-flow/api/cash-flow-list";
import {
  useCashFlowCategories,
  useCashFlowMonthlyAnalytics,
  useCashFlowPage,
  useCashFlowSummary,
  useCreateCashFlowTransaction,
  useDeleteCashFlowTransaction,
  useUpdateCashFlowTransaction,
} from "@/features/cash-flow/hooks/use-cash-flow";
import type {
  CashFlowDraft,
  CashFlowPickItem,
  CashFlowTransaction,
} from "@/features/cash-flow/types/cash-flow.types";
import { CashFlowAnalytics } from "@/features/cash-flow/ui/desktop/cash-flow-analytics";
import { CashFlowFilters } from "@/features/cash-flow/ui/desktop/cash-flow-filters";
import { CashFlowKpi } from "@/features/cash-flow/ui/desktop/cash-flow-kpi";
import { CashFlowList } from "@/features/cash-flow/ui/desktop/cash-flow-list";
import { CashFlowCategoriesDialog } from "@/features/cash-flow/ui/shared/cash-flow-categories-dialog";
import { CashFlowConfirmDialog } from "@/features/cash-flow/ui/shared/cash-flow-confirm-dialog";
import { CashFlowFormDialog } from "@/features/cash-flow/ui/shared/cash-flow-form-dialog";
import {
  CashFlowKpiSkeleton,
  CashFlowTableSkeleton,
} from "@/features/cash-flow/ui/shared/cash-flow-skeletons";
import {
  emptyCashFlowFilters,
  hasActiveCashFlowFilters,
} from "@/features/cash-flow/utils/filters";
import { useObjects } from "@/features/objects/hooks/use-objects";
import { sortObjectsByName } from "@/features/objects/utils/object.utils";
import { useDebouncedValue } from "@/hooks/use-debounced-value";
import { usePermissions } from "@/hooks/use-permissions";
import { useAppSearch } from "@/layouts/desktop/app-search";
import { cn } from "@/lib/utils";

/**
 * Реестр ДДС на компьютере: показатели за период, отчёт по месяцам, фильтры
 * и таблица операций — всё на одном экране.
 *
 * Поиск, фильтры, сортировку, итоги и аналитику считает база — браузер
 * показывает готовые страницы и не вычитывает операции за год целиком.
 */
export function CashFlowDesktop() {
  const { query } = useAppSearch();
  const search = useDebouncedValue(query, 300);
  const { can } = usePermissions();

  const { data: objectsData } = useObjects();
  const { data: contractorsData } = useContractors();
  const { data: contractsData } = useContracts();
  const categoriesQuery = useCashFlowCategories();
  const createTransaction = useCreateCashFlowTransaction();
  const updateTransaction = useUpdateCashFlowTransaction();
  const deleteTransaction = useDeleteCashFlowTransaction();

  const [filters, setFilters] = useState(() =>
    emptyCashFlowFilters(new Date().getFullYear())
  );
  const [sort, setSort] = useState<CashFlowSort>(null);
  const [page, setPage] = useState(0);
  const [editor, setEditor] = useState<CashFlowTransaction | null | undefined>(
    undefined
  );
  const [deleteTarget, setDeleteTarget] =
    useState<CashFlowTransaction | null>(null);
  const [isCategoriesOpen, setIsCategoriesOpen] = useState(false);

  const listQuery = useMemo<CashFlowListQuery>(
    () => ({
      search,
      year: filters.year,
      objectId: filters.objectId,
      contractorId: filters.contractorId,
      contractIds: filters.contractIds,
      types: filters.types,
      sort,
      page,
      pageSize: CASH_FLOW_PAGE_SIZE,
    }),
    [search, filters, sort, page]
  );

  const pageQuery = useCashFlowPage(listQuery);
  const kpiQuery = useCashFlowSummary(listQuery);
  const analyticsQuery = useCashFlowMonthlyAnalytics(listQuery);

  const transactions = pageQuery.data?.items ?? [];
  const total = pageQuery.data?.total ?? 0;
  const pageCount = Math.max(1, Math.ceil(total / CASH_FLOW_PAGE_SIZE));
  const currentPage = Math.min(page, pageCount - 1);
  const firstIndex = total === 0 ? 0 : currentPage * CASH_FLOW_PAGE_SIZE + 1;
  const lastIndex = Math.min(total, (currentPage + 1) * CASH_FLOW_PAGE_SIZE);

  const objectItems = useMemo<CashFlowPickItem[]>(
    () =>
      sortObjectsByName(objectsData ?? []).map((object) => ({
        id: object.id,
        label: object.name,
      })),
    [objectsData]
  );
  const contractorItems = useMemo<CashFlowPickItem[]>(
    () =>
      sortContractorsByName(contractorsData ?? []).map((contractor) => ({
        id: contractor.id,
        label: contractor.shortName || contractor.fullName,
      })),
    [contractorsData]
  );
  const contractItems = useMemo<CashFlowPickItem[]>(
    () =>
      (contractsData ?? []).map((contract) => ({
        id: contract.id,
        label: `№${contract.number}`,
      })),
    [contractsData]
  );

  const canCreate = can("cash_flow", "create");
  const canUpdate = can("cash_flow", "update");
  const canDelete = can("cash_flow", "delete");
  const isEditorOpen = editor !== undefined;
  const filtersActive = hasActiveCashFlowFilters({ ...filters, search });
  const isInitialLoading = pageQuery.isLoading && !pageQuery.data;

  /** Операция за другой год: показываем нужный период, иначе её не видно. */
  function showPeriodOf(draft: CashFlowDraft) {
    const year = Number(draft.date.slice(0, 4));
    if (Number.isFinite(year) && year !== filters.year) {
      setFilters((current) => ({ ...current, year }));
      setPage(0);
    }
  }

  function handleCreate(draft: CashFlowDraft) {
    createTransaction.mutate(draft, {
      onSuccess: () => {
        setEditor(undefined);
        showPeriodOf(draft);
        toast.success("Операция добавлена");
      },
      onError: (error) =>
        toast.error(
          error instanceof Error ? error.message : "Не удалось добавить операцию"
        ),
    });
  }

  function handleUpdate(draft: CashFlowDraft) {
    if (!editor) {
      return;
    }
    updateTransaction.mutate(
      { id: editor.id, draft },
      {
        onSuccess: () => {
          setEditor(undefined);
          showPeriodOf(draft);
          toast.success("Изменения сохранены");
        },
        onError: (error) =>
          toast.error(
            error instanceof Error
              ? error.message
              : "Не удалось сохранить операцию"
          ),
      }
    );
  }

  function handleDelete() {
    if (!deleteTarget) {
      return;
    }
    deleteTransaction.mutate(deleteTarget.id, {
      onSuccess: () => {
        setDeleteTarget(null);
        setEditor(undefined);
        toast.success("Операция удалена");
      },
      onError: (error) => {
        setDeleteTarget(null);
        toast.error(
          error instanceof Error ? error.message : "Не удалось удалить операцию"
        );
      },
    });
  }

  return (
    <>
      <div
        data-fill-viewport
        className="shadow-float flex h-full min-h-0 min-w-0 w-full flex-1 flex-col overflow-hidden rounded-xl bg-card ring-1 ring-foreground/10"
      >
        {/* Показатели за период */}
        <div className="shrink-0">
          {kpiQuery.isLoading && !kpiQuery.data ? (
            <CashFlowKpiSkeleton />
          ) : (
            <CashFlowKpi
              summary={
                kpiQuery.data ?? {
                  count: 0,
                  income: 0,
                  expense: 0,
                  balance: 0,
                }
              }
            />
          )}
        </div>

        {/* Фильтры и поиск */}
        <div className="flex shrink-0 flex-wrap items-center justify-between gap-3 border-b border-border/80 bg-muted/30 px-4 py-2.5 sm:px-5">
          <CashFlowFilters
            filters={{ ...filters, search }}
            onChange={(next) => {
              setFilters(next);
              setPage(0);
            }}
            onSearchChange={() => setPage(0)}
            objectOptions={objectItems}
            contractorOptions={contractorItems}
            contractOptions={contractItems}
            hasActiveFilters={filtersActive}
            onReset={() => {
              setFilters(emptyCashFlowFilters(filters.year));
              setSort(null);
              setPage(0);
            }}
            canCreate={canCreate}
            onCreate={() => setEditor(null)}
            onOpenCategories={() => setIsCategoriesOpen(true)}
          />
        </div>

        {/* Отчёт по месяцам — на том же экране, что и операции */}
        <CashFlowAnalytics
          months={analyticsQuery.data ?? []}
          isLoading={analyticsQuery.isLoading}
          error={analyticsQuery.error}
        />

        {/* Реестр операций */}
        <div className="flex min-h-0 min-w-0 flex-1 flex-col overflow-hidden">
          {isInitialLoading ? (
            <CashFlowTableSkeleton />
          ) : pageQuery.isError ? (
            <div className="flex h-full items-center justify-center p-6">
              <ErrorState
                message={
                  pageQuery.error instanceof Error
                    ? pageQuery.error.message
                    : "Не удалось загрузить операции"
                }
              />
            </div>
          ) : transactions.length === 0 ? (
            <div className="flex h-full items-center justify-center p-6">
              <EmptyState
                title={
                  total === 0 && !filtersActive
                    ? "Операций нет"
                    : "Ничего не найдено"
                }
                description={
                  total === 0 && !filtersActive
                    ? "Добавьте первую операцию за период."
                    : "Измените период, фильтры или поиск."
                }
              />
            </div>
          ) : (
            <CashFlowList
              transactions={transactions}
              sort={sort}
              onSortChange={(next) => {
                setSort(next);
                setPage(0);
              }}
              canUpdate={canUpdate}
              onSelect={setEditor}
            />
          )}
        </div>

        {/* Постраничная навигация */}
        {total > 0 ? (
          <div
            className={cn(
              "flex shrink-0 flex-wrap items-center justify-between gap-3 border-t border-border/80 px-4 py-2 text-sm sm:px-5",
              pageQuery.isFetching && "opacity-70"
            )}
          >
            <span className="text-muted-foreground">
              Показано {firstIndex}–{lastIndex} из {total}
            </span>
            <div className="flex items-center gap-2">
              <Button
                type="button"
                variant="outline"
                size="sm"
                disabled={currentPage <= 0 || pageQuery.isFetching}
                onClick={() => setPage((current) => Math.max(0, current - 1))}
              >
                <ChevronLeftIcon />
                Назад
              </Button>
              <span className="text-muted-foreground tabular-nums">
                стр. {currentPage + 1} из {pageCount}
              </span>
              <Button
                type="button"
                variant="outline"
                size="sm"
                disabled={currentPage >= pageCount - 1 || pageQuery.isFetching}
                onClick={() => setPage((current) => current + 1)}
              >
                Вперёд
                <ChevronRightIcon />
              </Button>
            </div>
          </div>
        ) : null}
      </div>

      <CashFlowFormDialog
        open={isEditorOpen}
        transaction={editor}
        categories={categoriesQuery.data ?? []}
        objects={objectItems}
        contractors={contractorItems}
        contracts={contractsData ?? []}
        isSaving={createTransaction.isPending || updateTransaction.isPending}
        canDelete={canDelete}
        onOpenChange={(open) => {
          if (!open) {
            setEditor(undefined);
          }
        }}
        onSubmit={editor ? handleUpdate : handleCreate}
        onDelete={() => {
          if (editor) {
            setDeleteTarget(editor);
          }
        }}
      />

      <CashFlowCategoriesDialog
        open={isCategoriesOpen}
        categories={categoriesQuery.data ?? []}
        canCreate={canCreate}
        canUpdate={canUpdate}
        canDelete={canDelete}
        onOpenChange={setIsCategoriesOpen}
      />

      <CashFlowConfirmDialog
        open={deleteTarget !== null}
        title="Удаление операции"
        description="Операция будет удалена. Если она создана из банковской выписки, строка вернётся в список необработанных, а оплата по счёту взаиморасчётов удалится."
        isPending={deleteTransaction.isPending}
        onOpenChange={(open) => {
          if (!open) {
            setDeleteTarget(null);
          }
        }}
        onConfirm={handleDelete}
      />
    </>
  );
}
