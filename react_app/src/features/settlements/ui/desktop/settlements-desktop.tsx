"use client";

import { useMemo, useState } from "react";
import { ChevronLeftIcon, ChevronRightIcon } from "lucide-react";
import { toast } from "sonner";

import { EmptyState } from "@/components/shared/empty-state";
import { ErrorState } from "@/components/shared/error-state";
import { Button } from "@/components/ui/button";
import { useContractors } from "@/features/contractors/hooks/use-contractors";
import { useContracts } from "@/features/contracts/hooks/use-contracts";
import { useObjects } from "@/features/objects/hooks/use-objects";
import { sortContractorsByName } from "@/features/contractors/utils/contractor.utils";
import { sortObjectsByName } from "@/features/objects/utils/object.utils";
import {
  SETTLEMENT_PAGE_SIZE,
  type SettlementListQuery,
  type SettlementSort,
} from "@/features/settlements/api/settlement-list";
import {
  useCreateSettlement,
  useSettlementsPage,
  useSettlementsSummary,
  useUpdateSettlement,
} from "@/features/settlements/hooks/use-settlements";
import type {
  Settlement,
  SettlementDraft,
  SettlementPickItem,
} from "@/features/settlements/types/settlement.types";
import {
  emptySettlementFilters,
  hasActiveSettlementFilters,
} from "@/features/settlements/utils/filters";
import { SettlementsFilters } from "@/features/settlements/ui/desktop/settlements-filters";
import { SettlementsKpi } from "@/features/settlements/ui/desktop/settlements-kpi";
import { SettlementsList } from "@/features/settlements/ui/desktop/settlements-list";
import { SettlementDetailsDialog } from "@/features/settlements/ui/shared/settlement-details-dialog";
import { SettlementFormDialog } from "@/features/settlements/ui/shared/settlement-form-dialog";
import { SettlementsKpiSkeleton, SettlementsTableSkeleton } from "@/features/settlements/ui/shared/settlement-skeletons";
import { useDebouncedValue } from "@/hooks/use-debounced-value";
import { usePermissions } from "@/hooks/use-permissions";
import { useAppSearch } from "@/layouts/desktop/app-search";
import { cn } from "@/lib/utils";

/**
 * Реестр счетов на компьютере: показатели, фильтры, таблица и постраничная
 * навигация. Логика общая с телефоном — те же хуки, права и окна.
 */
export function SettlementsDesktop() {
  const { query } = useAppSearch();
  const search = useDebouncedValue(query, 300);
  const { can } = usePermissions();

  const { data: contractorsData } = useContractors();
  const { data: objectsData } = useObjects();
  const { data: contractsData } = useContracts();
  const createSettlement = useCreateSettlement();
  const updateSettlement = useUpdateSettlement();

  const [filters, setFilters] = useState(emptySettlementFilters);
  const [sort, setSort] = useState<SettlementSort>(null);
  const [page, setPage] = useState(0);
  const [selected, setSelected] = useState<Settlement | null>(null);
  const [editor, setEditor] = useState<Settlement | null | undefined>(
    undefined
  );

  const listQuery = useMemo<SettlementListQuery>(
    () => ({
      search,
      operationType: filters.operationType,
      paymentStatus: filters.paymentStatus,
      contractorId: filters.contractorId,
      objectId: filters.objectId,
      contractId: filters.contractId,
      sort,
      page,
      pageSize: SETTLEMENT_PAGE_SIZE,
    }),
    [search, filters, sort, page]
  );

  // Итоги ходят с теми же фильтрами: сортировку и страницу они игнорируют.
  const pageQuery = useSettlementsPage(listQuery);
  const kpiQuery = useSettlementsSummary(listQuery);

  const settlements = pageQuery.data?.items ?? [];
  const total = pageQuery.data?.total ?? 0;
  const pageCount = Math.max(1, Math.ceil(total / SETTLEMENT_PAGE_SIZE));
  const currentPage = Math.min(page, pageCount - 1);
  const firstIndex = total === 0 ? 0 : currentPage * SETTLEMENT_PAGE_SIZE + 1;
  const lastIndex = Math.min(total, (currentPage + 1) * SETTLEMENT_PAGE_SIZE);

  const contractorItems = useMemo<SettlementPickItem[]>(
    () =>
      sortContractorsByName(contractorsData ?? []).map((contractor) => ({
        id: contractor.id,
        label: contractor.shortName || contractor.fullName,
      })),
    [contractorsData]
  );
  const objectItems = useMemo<SettlementPickItem[]>(
    () =>
      sortObjectsByName(objectsData ?? []).map((object) => ({
        id: object.id,
        label: object.name,
      })),
    [objectsData]
  );
  const contractItems = useMemo<SettlementPickItem[]>(
    () =>
      (contractsData ?? []).map((contract) => ({
        id: contract.id,
        label: contract.number,
      })),
    [contractsData]
  );

  const isEditorOpen = editor !== undefined;
  const filtersActive =
    hasActiveSettlementFilters({ ...filters, search }) || sort !== null;

  function handleCreate(draft: SettlementDraft) {
    createSettlement.mutate(draft, {
      onSuccess: (created) => {
        setEditor(undefined);
        setSelected(created);
        toast.success("Счёт создан");
      },
      onError: (mutationError) =>
        toast.error(
          mutationError instanceof Error
            ? mutationError.message
            : "Не удалось создать счёт"
        ),
    });
  }

  function handleUpdate(draft: SettlementDraft) {
    if (!editor) return;
    updateSettlement.mutate(
      { settlement: editor, draft },
      {
        onSuccess: (updated) => {
          setEditor(undefined);
          setSelected(updated);
          toast.success("Изменения сохранены");
        },
        onError: (mutationError) =>
          toast.error(
            mutationError instanceof Error
              ? mutationError.message
              : "Не удалось сохранить счёт"
          ),
      }
    );
  }

  const isInitialLoading = pageQuery.isLoading && !pageQuery.data;

  return (
    <>
      <div
        data-fill-viewport
        className="shadow-float flex h-full min-h-0 min-w-0 w-full flex-1 flex-col overflow-hidden rounded-xl bg-card ring-1 ring-foreground/10"
      >
        {/* KPI сверху */}
        <div className="shrink-0">
          {kpiQuery.isLoading && !kpiQuery.data ? (
            <SettlementsKpiSkeleton />
          ) : (
            <SettlementsKpi
              summary={
                kpiQuery.data ?? {
                  count: 0,
                  totalAmount: 0,
                  totalPaid: 0,
                  totalDebt: 0,
                  byStatus: {},
                }
              }
            />
          )}
        </div>

        {/* Фильтры и поиск сверху */}
        <div className="flex shrink-0 flex-wrap items-center justify-between gap-3 border-b border-border/80 bg-muted/30 px-4 py-2.5 sm:px-5">
          <SettlementsFilters
            filters={{ ...filters, search }}
            onChange={(next) => {
              setFilters(next);
              setPage(0);
            }}
            onSearchChange={() => setPage(0)}
            contractorOptions={contractorItems}
            objectOptions={objectItems}
            contractOptions={contractItems}
            hasActiveFilters={filtersActive}
            onReset={() => {
              setFilters(emptySettlementFilters());
              setSort(null);
              setPage(0);
            }}
            canCreate={can("settlements", "create")}
            onCreate={() => {
              setSelected(null);
              setEditor(null);
            }}
          />
        </div>

        {/* Таблица во всю ширину карточки */}
        <div className="flex min-h-0 min-w-0 flex-1 flex-col overflow-hidden rounded-b-xl [clip-path:inset(0_round_0_0_var(--radius-xl)_var(--radius-xl))]">
          {isInitialLoading ? (
            <SettlementsTableSkeleton />
          ) : pageQuery.isError ? (
            <div className="flex h-full items-center justify-center p-6">
              <ErrorState
                message={
                  pageQuery.error instanceof Error
                    ? pageQuery.error.message
                    : "Не удалось загрузить счета"
                }
              />
            </div>
          ) : settlements.length === 0 ? (
            <div className="flex h-full items-center justify-center p-6">
              <EmptyState
                title={total === 0 && !filtersActive ? "Счетов нет" : "Ничего не найдено"}
                description={
                  total === 0 && !filtersActive
                    ? "Создайте первый счёт."
                    : "Измените фильтры или поиск."
                }
              />
            </div>
          ) : (
            <SettlementsList
              settlements={settlements}
              selectedId={selected?.id ?? null}
              onSelect={setSelected}
              sort={sort}
              onSortChange={(next) => {
                setSort(next);
                setPage(0);
              }}
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

      <SettlementDetailsDialog
        settlement={selected}
        canUpdate={can("settlements", "update")}
        canDelete={can("settlements", "delete")}
        onOpenChange={(open) => {
          if (!open) setSelected(null);
        }}
        onEdit={(settlement) => {
          setEditor(settlement);
          setSelected(null);
        }}
        onDeleted={() => setSelected(null)}
      />

      <SettlementFormDialog
        open={isEditorOpen}
        settlement={editor}
        contractors={contractorItems}
        objects={objectItems}
        contracts={contractsData ?? []}
        isSaving={createSettlement.isPending || updateSettlement.isPending}
        onOpenChange={(open) => {
          if (!open) setEditor(undefined);
        }}
        onSubmit={editor ? handleUpdate : handleCreate}
      />
    </>
  );
}
