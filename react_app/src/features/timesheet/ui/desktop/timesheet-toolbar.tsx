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
  const isNextDisabled = isCurrentMonth(year, month) || isLoading;

  return (
    <div className="flex flex-wrap items-center justify-between gap-2.5 rounded-xl border border-border/70 bg-card/60 p-2.5 shadow-sm backdrop-blur-sm sm:gap-3">
      {/* Left side: month switcher and filters */}
      <div className="flex flex-wrap items-center gap-2">
        {/* Month switcher */}
        <div className="flex items-center rounded-lg border border-input bg-card p-0.5 shadow-xs">
          <Button
            type="button"
            variant="ghost"
            size="icon"
            onClick={onPrevMonth}
            disabled={isLoading}
            className="h-8 w-8 text-muted-foreground hover:text-foreground"
            title="Предыдущий месяц"
          >
            <ChevronLeftIcon className="h-4 w-4" />
          </Button>

          <span className="min-w-28 text-center text-xs font-semibold sm:text-sm select-none px-1.5">
            {monthLabel}
          </span>

          <Button
            type="button"
            variant="ghost"
            size="icon"
            onClick={onNextMonth}
            disabled={isNextDisabled}
            className="h-8 w-8 text-muted-foreground hover:text-foreground"
            title="Следующий месяц"
          >
            <ChevronRightIcon className="h-4 w-4" />
          </Button>
        </div>

        {/* Search by name */}
        <div className="relative flex min-w-44 flex-1 items-center sm:max-w-xs md:max-w-sm">
          <InputGroup className="h-9 w-full rounded-lg bg-card text-xs sm:text-sm hover:bg-muted/40">
            <InputGroupAddon>
              <SearchIcon className="size-4 text-muted-foreground" />
            </InputGroupAddon>
            <InputGroupInput
              type="text"
              value={searchQuery}
              placeholder="Поиск по ФИО..."
              aria-label="Поиск по ФИО"
              className="text-xs sm:text-sm placeholder:text-muted-foreground [&::-webkit-search-cancel-button]:appearance-none [&::-webkit-search-cancel-button]:hidden [&::-webkit-search-decoration]:hidden"
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
                  <XIcon className="size-3.5 text-muted-foreground" />
                </InputGroupButton>
              </InputGroupAddon>
            ) : null}
          </InputGroup>
        </div>

        {/* Objects filter */}
        <TimesheetMultiSelect
          title="Объекты"
          placeholder="Поиск объекта..."
          options={objectOptions.map((o) => ({ key: o.id, label: o.name }))}
          selectedKeys={selectedObjectIds}
          onChange={onSelectedObjectIdsChange}
          disabled={isLoading}
        />

        {/* Positions filter */}
        <TimesheetMultiSelect
          title="Должности"
          placeholder="Поиск должности..."
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

      {/* Right side: Excel export */}
      {canExport ? (
      <div className="flex items-center gap-2 ml-auto">
        <Button
          type="button"
          size="sm"
          onClick={onExportExcel}
          disabled={isLoading || isExporting}
          className="h-9 gap-1.5 bg-emerald-600 hover:bg-emerald-700 text-white font-medium text-xs sm:text-sm shadow-xs"
        >
          {isExporting ? (
            <Loader2Icon className="h-4 w-4 animate-spin" />
          ) : (
            <DownloadIcon className="h-4 w-4" />
          )}
          <span>Скачать табель</span>
          {selectedCount > 0 ? (
            <Badge
              variant="secondary"
              className="ml-1 h-5 rounded-full bg-white/20 text-white px-1.5 text-[11px] font-semibold"
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
