"use client";

import { useMemo, useState } from "react";
import { PlusIcon } from "lucide-react";
import { toast } from "sonner";

import { EmptyState } from "@/components/shared/empty-state";
import { ErrorState } from "@/components/shared/error-state";
import { Button } from "@/components/ui/button";
import { Spinner } from "@/components/ui/spinner";
import { useContractors } from "@/features/contractors/hooks/use-contractors";
import { useContracts } from "@/features/contracts/hooks/use-contracts";
import { useObjects } from "@/features/objects/hooks/use-objects";
import { sortContractorsByName } from "@/features/contractors/utils/contractor.utils";
import { sortObjectsByName } from "@/features/objects/utils/object.utils";
import type { SettlementListQuery } from "@/features/settlements/api/settlement-list";
import {
  useCreateSettlement,
  useSettlementsInfinitePage,
  useSettlementsSummary,
  useUpdateSettlement,
} from "@/features/settlements/hooks/use-settlements";
import type {
  Settlement,
  SettlementDraft,
  SettlementPaymentStatus,
  SettlementPickItem,
} from "@/features/settlements/types/settlement.types";
import {
  SETTLEMENT_PAYMENT_STATUSES,
  settlementPaymentStatusLabel,
} from "@/features/settlements/utils/payment-status";
import { formatCurrency } from "@/features/settlements/utils/settlement.utils";
import { SettlementDetailsMobile } from "@/features/settlements/ui/mobile/settlement-details-mobile";
import { SettlementsMobileList } from "@/features/settlements/ui/mobile/settlements-mobile-list";
import { SettlementFormSheet } from "@/features/settlements/ui/mobile/settlement-form-sheet";
import { SettlementCardsSkeleton } from "@/features/settlements/ui/shared/settlement-skeletons";
import { useDebouncedValue } from "@/hooks/use-debounced-value";
import { usePermissions } from "@/hooks/use-permissions";
import { AppSearchField, useAppSearch } from "@/layouts/desktop/app-search";
import { MobileAppBar } from "@/layouts/mobile/mobile-app-bar";
import { cn } from "@/lib/utils";

type StatusFilter = SettlementPaymentStatus | "all";

/**
 * Реестр счетов на телефоне: шапка с кнопкой нового счёта, поиск, лента
 * фильтров по статусу, карточки и итоги внизу.
 *
 * Логика общая с компьютером — те же хуки, права и окна.
 */
export function SettlementsMobile() {
  const { query } = useAppSearch();
  const search = useDebouncedValue(query, 300);
  const { can } = usePermissions();

  const [statusFilter, setStatusFilter] = useState<StatusFilter>("all");
  const [selectedId, setSelectedId] = useState<string | null>(null);
  const [formOpen, setFormOpen] = useState(false);
  const [editing, setEditing] = useState<Settlement | null>(null);

  // Справочники нужны только в окне счёта: на телефоне фильтры — по статусу,
  // поэтому до открытия окна эти списки не грузим.
  const { data: contractorsData } = useContractors({ enabled: formOpen });
  const { data: objectsData } = useObjects({ enabled: formOpen });
  const { data: contractsData } = useContracts({ enabled: formOpen });
  const createSettlement = useCreateSettlement();
  const updateSettlement = useUpdateSettlement();

  // Список и итоги ходят с одними и теми же фильтрами.
  const filters = useMemo<SettlementListQuery>(
    () => ({ search, paymentStatus: statusFilter }),
    [search, statusFilter]
  );

  const pageQuery = useSettlementsInfinitePage(filters);
  const kpiQuery = useSettlementsSummary(filters);

  const settlements = useMemo(
    () => (pageQuery.data?.pages ?? []).flatMap((page) => page.items),
    [pageQuery.data]
  );
  const total = pageQuery.data?.pages[0]?.total ?? 0;
  const hasMore = Boolean(pageQuery.hasNextPage);

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

  const canCreate = can("settlements", "create");
  const isInitialLoading = pageQuery.isLoading && !pageQuery.data;

  function handleSubmit(draft: SettlementDraft) {
    if (editing) {
      updateSettlement.mutate(
        { settlement: editing, draft },
        {
          onSuccess: () => {
            setFormOpen(false);
            setEditing(null);
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
      return;
    }
    createSettlement.mutate(draft, {
      onSuccess: (created) => {
        setFormOpen(false);
        setSelectedId(created.id);
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

  if (selectedId) {
    return (
      <SettlementDetailsMobile
        settlementId={selectedId}
        onBack={() => setSelectedId(null)}
        onEdit={(settlement) => {
          setSelectedId(null);
          setEditing(settlement);
          setFormOpen(true);
        }}
        onDeleted={() => setSelectedId(null)}
      />
    );
  }

  const statusFilters: { value: StatusFilter; label: string }[] = [
    { value: "all", label: "Все" },
    ...SETTLEMENT_PAYMENT_STATUSES.map((status) => ({
      value: status as StatusFilter,
      label: settlementPaymentStatusLabel(status),
    })),
  ];

  const summary = kpiQuery.data;

  return (
    <div
      data-fill-viewport
      className="-m-4 flex h-full min-h-0 min-w-0 flex-1 flex-col overflow-hidden bg-background"
    >
      <header className="shrink-0 border-b bg-background">
        <MobileAppBar
          title="Взаиморасчёты"
          className="border-b-0"
          trailing={
            canCreate ? (
              <Button
                type="button"
                size="icon"
                className="rounded-full"
                aria-label="Новый счёт"
                onClick={() => {
                  setEditing(null);
                  setFormOpen(true);
                }}
              >
                <PlusIcon />
              </Button>
            ) : undefined
          }
        />
        <div className="flex flex-col gap-2.5 px-4 pb-3">
          <AppSearchField
            placeholder="Поиск по счёту, акту, договору…"
            aria-label="Поиск по взаиморасчётам"
          />
          <div className="-mx-4 flex gap-1.5 overflow-x-auto px-4 pb-1 [scrollbar-width:none] [&::-webkit-scrollbar]:hidden">
            {statusFilters.map((item) => (
              <Button
                key={item.value}
                type="button"
                size="sm"
                variant={statusFilter === item.value ? "default" : "outline"}
                className="shrink-0 rounded-full"
                onClick={() => setStatusFilter(item.value)}
              >
                {item.label}
              </Button>
            ))}
          </div>
        </div>
      </header>

      <div className="min-h-0 min-w-0 flex-1 overflow-y-auto overscroll-contain px-4 pt-3 pb-2">
        {isInitialLoading ? (
          <SettlementCardsSkeleton />
        ) : pageQuery.isError ? (
          <ErrorState
            message={
              pageQuery.error instanceof Error
                ? pageQuery.error.message
                : "Не удалось загрузить счета"
            }
          />
        ) : settlements.length === 0 ? (
          <EmptyState
            title={total === 0 ? "Счетов нет" : "Ничего не найдено"}
            description={
              total === 0
                ? "Создайте первый счёт."
                : "Измените фильтр или поиск."
            }
          />
        ) : (
          <>
            <SettlementsMobileList
              settlements={settlements}
              onSelect={(settlement) => setSelectedId(settlement.id)}
            />
            {hasMore ? (
              <div className="flex justify-center py-3">
                <Button
                  type="button"
                  variant="outline"
                  size="sm"
                  disabled={pageQuery.isFetchingNextPage}
                  onClick={() => void pageQuery.fetchNextPage()}
                >
                  {pageQuery.isFetchingNextPage ? (
                    <Spinner data-icon="inline-start" />
                  ) : null}
                  Показать ещё
                </Button>
              </div>
            ) : null}
          </>
        )}
      </div>

      {total > 0 && summary ? (
        <div className="bg-background shrink-0 border-t px-4 pt-2 pb-[max(0.5rem,env(safe-area-inset-bottom))]">
          <div className="flex items-center justify-between text-center">
            <div className="flex-1">
              <p className="text-muted-foreground text-[10px] uppercase">
                К оплате
              </p>
              <p className="text-sm font-bold tabular-nums">
                {formatCurrency(summary.totalAmount)}
              </p>
            </div>
            <div className="flex-1">
              <p className="text-muted-foreground text-[10px] uppercase">
                Оплачено
              </p>
              <p className="text-sm font-bold tabular-nums">
                {formatCurrency(summary.totalPaid)}
              </p>
            </div>
            <div className="flex-1">
              <p className="text-muted-foreground text-[10px] uppercase">
                Остаток
              </p>
              <p
                className={cn(
                  "text-sm font-bold tabular-nums",
                  summary.totalDebt > 0 && "text-destructive"
                )}
              >
                {formatCurrency(summary.totalDebt)}
              </p>
            </div>
          </div>
        </div>
      ) : null}

      <SettlementFormSheet
        open={formOpen}
        settlement={editing}
        contractors={contractorItems}
        objects={objectItems}
        contracts={contractsData ?? []}
        isSaving={createSettlement.isPending || updateSettlement.isPending}
        onOpenChange={(open) => {
          setFormOpen(open);
          if (!open) setEditing(null);
        }}
        onSubmit={handleSubmit}
      />
    </div>
  );
}
