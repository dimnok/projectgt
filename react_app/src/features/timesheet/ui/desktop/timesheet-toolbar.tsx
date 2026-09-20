"use client";

import {
  ChevronLeftIcon,
  ChevronRightIcon,
  DownloadIcon,
  Loader2Icon,
  SearchIcon,
  XIcon,
} from "lucide-react";

import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import {
  InputGroup,
  InputGroupAddon,
  InputGroupButton,
  InputGroupInput,
} from "@/components/ui/input-group";
import type {
  TimesheetEmployeeListScope,
  TimesheetObjectOption,
  TimesheetOpenShiftFilterScope,
} from "@/features/timesheet/types/timesheet.types";
import { TimesheetMultiSelect } from "@/features/timesheet/ui/shared/timesheet-multi-select";
import { TimesheetScopeDropdown } from "@/features/timesheet/ui/shared/timesheet-scope-dropdown";
import {
  getMonthLabel,
  isCurrentMonth,
} from "@/features/timesheet/utils/timesheet-date";

type TimesheetToolbarProps = {
  year: number;
  month: number;
  searchQuery: string;
  onSearchChange: (q: string) => void;
  onPrevMonth: () => void;
  onNextMonth: () => void;
  objectOptions: TimesheetObjectOption[];
  selectedObjectIds: string[];
  onSelectedObjectIdsChange: (ids: string[]) => void;
  positionOptions: { key: string; label: string }[];
  selectedPositionKeys: string[];
  onSelectedPositionKeysChange: (keys: string[]) => void;
  listScope: TimesheetEmployeeListScope;
  openShiftScope: TimesheetOpenShiftFilterScope;
  periodContainsToday: boolean;
  onListScopeChange: (scope: TimesheetEmployeeListScope) => void;
  onOpenShiftScopeChange: (scope: TimesheetOpenShiftFilterScope) => void;
  selectedCount: number;
  onExportExcel: () => void;
  canExport?: boolean;
  isExporting?: boolean;
  isLoading?: boolean;
};

export function TimesheetToolbar({
  year,
  month,
  searchQuery,
  onSearchChange,
  onPrevMonth,
  onNextMonth,
  objectOptions,
  selectedObjectIds,
  onSelectedObjectIdsChange,
  positionOptions,
  selectedPositionKeys,
  onSelectedPositionKeysChange,
  listScope,
  openShiftScope,
  periodContainsToday,
  onListScopeChange,
  onOpenShiftScopeChange,
  selectedCount,
  onExportExcel,
  canExport = false,
  isExporting = false,
  isLoading = false,
}: TimesheetToolbarProps) {
  const monthLabel = getMonthLabel(year, month);
  const isCurrent = isCurrentMonth(year, month);
  const isNextDisabled = isCurrent || isLoading;

  return (
    <div className="flex flex-wrap items-center justify-between gap-2.5 rounded-2xl border border-border/70 bg-card p-2.5 shadow-2xs">
      {/* Left side: month switcher and filters */}
      <div className="flex flex-wrap items-center gap-2">
        {/* Month switcher */}
        <div className="flex items-center rounded-xl border border-border/80 bg-muted/30 p-0.5 shadow-2xs">
          <Button
            type="button"
            variant="ghost"
            size="icon"
            onClick={onPrevMonth}
            disabled={isLoading}
            className="h-8 w-8 text-muted-foreground hover:text-foreground rounded-lg transition-colors"
            title="Предыдущий месяц"
            aria-label="Предыдущий месяц"
          >
            <ChevronLeftIcon className="h-4 w-4" />
          </Button>

          <span className="min-w-32 text-center text-xs sm:text-[13px] font-semibold select-none px-2 capitalize tracking-tight text-foreground">
            {monthLabel}
          </span>

          <Button
            type="button"
            variant="ghost"
            size="icon"
            onClick={onNextMonth}
            disabled={isNextDisabled}
            className="h-8 w-8 text-muted-foreground hover:text-foreground rounded-lg transition-colors"
            title="Следующий месяц"
            aria-label="Следующий месяц"
          >
            <ChevronRightIcon className="h-4 w-4" />
          </Button>
        </div>

        {/* Search by name */}
        <div className="relative flex w-60 sm:w-72 md:w-80 lg:w-96 items-center">
          <InputGroup className="h-9 w-full rounded-xl border border-border/70 bg-muted/20 text-[13px] sm:text-sm hover:bg-muted/30 focus-within:ring-1 focus-within:ring-primary/40 focus-within:bg-card transition-all">
            <InputGroupAddon>
              <SearchIcon className="size-4 text-muted-foreground/60" />
            </InputGroupAddon>
            <InputGroupInput
              type="text"
              value={searchQuery}
              placeholder="Поиск по ФИО..."
              aria-label="Поиск по ФИО"
              className="text-[13px] sm:text-sm placeholder:text-muted-foreground/60 [&::-webkit-search-cancel-button]:appearance-none [&::-webkit-search-cancel-button]:hidden [&::-webkit-search-decoration]:hidden"
              onChange={(event) => onSearchChange(event.target.value)}
            />
            {searchQuery ? (
              <InputGroupAddon align="inline-end">
                <InputGroupButton
                  size="icon-sm"
                  variant="ghost"
                  aria-label="Очистить поиск"
                  onClick={() => onSearchChange("")}
                >
                  <XIcon className="size-3.5 text-muted-foreground/80" />
                </InputGroupButton>
              </InputGroupAddon>
            ) : null}
          </InputGroup>
        </div>

        {/* Objects filter */}
        <TimesheetMultiSelect
          title="Объекты"
          options={objectOptions.map((o) => ({ key: o.id, label: o.name }))}
          selectedKeys={selectedObjectIds}
          onChange={onSelectedObjectIdsChange}
          disabled={isLoading || objectOptions.length === 0}
        />

        {/* Positions filter */}
        <TimesheetMultiSelect
          title="Должности"
          options={positionOptions}
          selectedKeys={selectedPositionKeys}
          onChange={onSelectedPositionKeysChange}
          disabled={isLoading}
        />

        {/* Scope dropdown ("Состав") */}
        <TimesheetScopeDropdown
          listScope={listScope}
          openShiftScope={openShiftScope}
          periodContainsToday={periodContainsToday}
          onListScopeChange={onListScopeChange}
          onOpenShiftScopeChange={onOpenShiftScopeChange}
          disabled={isLoading}
        />
      </div>

      {/* Right side: Excel export button */}
      {canExport ? (
        <div className="flex items-center gap-2 ml-auto">
          <Button
            type="button"
            size="sm"
            onClick={onExportExcel}
            disabled={isLoading || isExporting}
            className="gap-1.5 border-emerald-600/30 bg-emerald-600 text-white hover:bg-emerald-700 active:bg-emerald-800 disabled:pointer-events-none disabled:opacity-50 dark:border-emerald-500/30 dark:bg-emerald-600 dark:hover:bg-emerald-500 cursor-pointer"
            title={isExporting ? "Формирование файла..." : "Экспорт в Excel"}
          >
            {isExporting ? (
              <Loader2Icon className="size-3.5 shrink-0 animate-spin" />
            ) : (
              <DownloadIcon className="size-3.5 shrink-0" />
            )}
            <span>{isExporting ? "Формирование..." : "Excel"}</span>
            {selectedCount > 0 ? (
              <Badge
                variant="secondary"
                className="ml-0.5 h-5 rounded-full bg-white/20 text-white px-1.5 text-[11px] font-bold"
              >
                {selectedCount}
              </Badge>
            ) : null}
          </Button>
        </div>
      ) : null}
    </div>
  );
}
