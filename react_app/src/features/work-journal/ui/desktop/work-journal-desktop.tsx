"use client";

import { Building2Icon, ClipboardListIcon, DownloadIcon, Loader2Icon } from "lucide-react";
import { useCallback, useMemo, useState } from "react";
import { toast } from "sonner";

import { EmptyState } from "@/components/shared/empty-state";
import { ErrorState } from "@/components/shared/error-state";
import { Loading } from "@/components/shared/loading";
import { Button } from "@/components/ui/button";
import { Spinner } from "@/components/ui/spinner";
import { searchAllWorkItems } from "@/features/work-journal/api/search-work-items";
import { useDebouncedValue } from "@/hooks/use-debounced-value";
import {
  useWorkJournalFilterValues,
  useWorkJournalObjects,
  useWorkJournalSearch,
} from "@/features/work-journal/hooks/use-work-journal";
import type {
  WorkJournalFilters,
  WorkJournalRow,
} from "@/features/work-journal/types/work-journal.types";
import { WorkJournalDateRangePicker } from "@/features/work-journal/ui/desktop/work-journal-date-range";
import { WorkJournalFiltersBar } from "@/features/work-journal/ui/desktop/work-journal-filters";
import { WorkJournalPagination } from "@/features/work-journal/ui/desktop/work-journal-pagination";
import { WorkJournalTable } from "@/features/work-journal/ui/desktop/work-journal-table";
import { WorkJournalColumnsMenu } from "@/features/work-journal/ui/shared/work-journal-columns-menu";
import {
  WorkJournalShiftDialog,
  type WorkJournalShiftTarget,
} from "@/features/work-journal/ui/shared/work-journal-shift-dialog";
import { exportWorkJournalToExcel } from "@/features/work-journal/utils/export-work-journal-excel";
import { usePermissions } from "@/hooks/use-permissions";

const EMPTY_FILTERS: WorkJournalFilters = {
  objectId: null,
  dateRange: null,
  searchQuery: "",
  systems: [],
  sections: [],
  floors: [],
};

export function WorkJournalDesktop() {
  const { can } = usePermissions();
  const canExport = can("export", "export");
  const [filters, setFilters] = useState<WorkJournalFilters>(EMPTY_FILTERS);
  const [page, setPage] = useState(1);
  const [isExporting, setIsExporting] = useState(false);
  const [shiftTarget, setShiftTarget] = useState<WorkJournalShiftTarget | null>(
    null
  );
  const { objects, isLoading: isObjectsLoading, isError, error } =
    useWorkJournalObjects();

  const handlePrune = useCallback(
    (next: Pick<WorkJournalFilters, "systems" | "sections" | "floors">) => {
      setFilters((current) => ({ ...current, ...next }));
    },
    []
  );

  const filterValuesQuery = useWorkJournalFilterValues(filters, handlePrune);
  const searchQuery = useWorkJournalSearch(filters, page);
  const debouncedSearch = useDebouncedValue(filters.searchQuery, 500);

  const selectedObjectName = useMemo(
    () => objects.find((object) => object.id === filters.objectId)?.name ?? null,
    [filters.objectId, objects]
  );

  function updateFilters(patch: Partial<WorkJournalFilters>) {
    setFilters((current) => ({ ...current, ...patch }));
    setPage(1);
  }

  function handleDateClick(row: WorkJournalRow) {
    if (!row.workId) {
      toast.error("У этой строки нет смены");
      return;
    }
    setShiftTarget({ workId: row.workId, workItemId: row.workItemId });
  }

  function handleNameShiftClick(name: string) {
    const next = name.trim();
    if (!next) {
      return;
    }
    updateFilters({ searchQuery: next });
  }

  async function handleExportExcel() {
    if (!filters.objectId) {
      toast.info("Сначала выберите объект для выгрузки");
      return;
    }
    if (!searchQuery.data || searchQuery.data.totalCount === 0) {
      toast.warning("Нет строк для выгрузки");
      return;
    }

    try {
      setIsExporting(true);
      const items = await searchAllWorkItems({
        objectId: filters.objectId,
        startDate: filters.dateRange?.from ?? null,
        endDate: filters.dateRange?.to ?? null,
        searchQuery: debouncedSearch,
        systemFilters: filters.systems,
        sectionFilters: filters.sections,
        floorFilters: filters.floors,
      });
      if (items.length === 0) {
        toast.warning("Нет строк для выгрузки");
        return;
      }
      await exportWorkJournalToExcel({
        items,
        objectName: selectedObjectName ?? undefined,
        dateFrom: filters.dateRange?.from ?? null,
        dateTo: filters.dateRange?.to ?? null,
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

  if (isObjectsLoading) {
    return <Loading />;
  }

  if (isError) {
    return (
      <ErrorState
        message={error instanceof Error ? error.message : "Неизвестная ошибка"}
      />
    );
  }

  if (objects.length === 0) {
    return (
      <div
        data-fill-viewport
        className="flex h-full min-h-0 min-w-0 w-full flex-1 flex-col items-center justify-center overflow-hidden rounded-xl bg-card p-6 ring-1 ring-foreground/10 shadow-float"
      >
        <EmptyState
          icon={Building2Icon}
          title="Нет объектов со сменами"
          description="Журнал показывает выполненные работы. Сначала откройте смены на объектах."
        />
      </div>
    );
  }

  const pageData = searchQuery.data;
  const hasRows = Boolean(pageData && pageData.items.length > 0);
  const isSearchLoading = searchQuery.isLoading || (searchQuery.isFetching && !pageData);

  return (
    <div
      data-fill-viewport
      className="flex h-full min-h-0 min-w-0 w-full flex-1 flex-col overflow-hidden rounded-xl bg-card ring-1 ring-foreground/10 shadow-float"
    >
      <div className="flex shrink-0 flex-wrap items-center justify-between gap-3 border-b border-border/80 bg-muted/30 px-4 py-2.5 sm:px-5">
        <WorkJournalFiltersBar
          objects={objects}
          objectId={filters.objectId}
          searchQuery={filters.searchQuery}
          systems={filters.systems}
          sections={filters.sections}
          floors={filters.floors}
          filterValues={filterValuesQuery.data}
          onObjectChange={(objectId) =>
            updateFilters({
              objectId,
              searchQuery: "",
              systems: [],
              sections: [],
              floors: [],
            })
          }
          onSearchChange={(searchQuery) => updateFilters({ searchQuery })}
          onSystemsChange={(systems) => updateFilters({ systems })}
          onSectionsChange={(sections) => updateFilters({ sections })}
          onFloorsChange={(floors) => updateFilters({ floors })}
        />
        <div className="flex items-center gap-2">
          {canExport ? (
          <Button
            type="button"
            size="sm"
            onClick={handleExportExcel}
            disabled={
              !filters.objectId ||
              isExporting ||
              !pageData ||
              pageData.totalCount === 0
            }
            className="gap-1.5 border-emerald-600/30 bg-emerald-600 text-white hover:bg-emerald-700 active:bg-emerald-800 disabled:pointer-events-none disabled:opacity-50 dark:border-emerald-500/30 dark:bg-emerald-600 dark:hover:bg-emerald-500 cursor-pointer"
            title={
              !filters.objectId
                ? "Выберите объект для экспорта в Excel"
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
          ) : null}
          <WorkJournalDateRangePicker
            value={filters.dateRange}
            onChange={(dateRange) => updateFilters({ dateRange })}
            size="icon-sm"
          />
          <WorkJournalColumnsMenu size="icon-sm" />
        </div>
      </div>

      <div className="flex min-h-0 min-w-0 flex-1 flex-col overflow-hidden">
        {!filters.objectId ? (
          <div className="flex min-h-0 flex-1 items-center justify-center p-6">
            <EmptyState
              icon={Building2Icon}
              title="Выберите объект"
              description="Таблица покажет выполненные работы по выбранному объекту. Период можно задать дополнительно."
            />
          </div>
        ) : isSearchLoading ? (
          <div className="flex min-h-0 flex-1 items-center justify-center">
            <Spinner className="size-6" />
          </div>
        ) : searchQuery.isError ? (
          <div className="flex min-h-0 flex-1 items-center justify-center p-6">
            <ErrorState
              message={
                searchQuery.error instanceof Error
                  ? searchQuery.error.message
                  : "Не удалось загрузить журнал"
              }
            />
          </div>
        ) : !hasRows || !pageData ? (
          <div className="flex min-h-0 flex-1 items-center justify-center p-6">
            <EmptyState
              icon={ClipboardListIcon}
              title="Ничего не найдено"
              description={
                selectedObjectName
                  ? `По объекту «${selectedObjectName}» нет строк с текущими фильтрами.`
                  : "Попробуйте выбрать другой объект или изменить фильтры."
              }
            />
          </div>
        ) : (
          <WorkJournalTable
            page={pageData}
            onDateClick={handleDateClick}
            onNameShiftClick={handleNameShiftClick}
          />
        )}
      </div>

      {filters.objectId && pageData && pageData.totalPages > 1 ? (
        <WorkJournalPagination
          currentPage={pageData.currentPage}
          totalPages={pageData.totalPages}
          totalCount={pageData.totalCount}
          isBusy={searchQuery.isFetching}
          onPageChange={setPage}
        />
      ) : null}

      <WorkJournalShiftDialog
        target={shiftTarget}
        onOpenChange={(open) => {
          if (!open) {
            setShiftTarget(null);
          }
        }}
      />
    </div>
  );
}
