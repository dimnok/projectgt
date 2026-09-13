"use client";

import { CalendarIcon, UsersIcon } from "lucide-react";
import React, { memo, useMemo } from "react";

import { Button } from "@/components/ui/button";
import {
  Tooltip,
  TooltipContent,
  TooltipTrigger,
} from "@/components/ui/tooltip";
import type { Employee } from "@/features/employees/types/employee.types";
import type {
  DayCellData,
  TimesheetGridRow,
  TimesheetObjectOption,
} from "@/features/timesheet/types/timesheet.types";
import {
  formatHours,
  type DayHeaderInfo,
} from "@/features/timesheet/utils/timesheet-date";
import { cn } from "@/lib/utils";

type TimesheetGridProps = {
  rows: TimesheetGridRow[];
  daysHeader: DayHeaderInfo[];
  dayTotals: number[];
  grandTotalHours: number;
  objectOptions: TimesheetObjectOption[];
  selectedEmployeeIds: Set<string>;
  onToggleSelectEmployee: (employeeId: string) => void;
  onSelectAll: (ids: string[]) => void;
  onClearSelection: () => void;
  onOpenAttendance?: (employee: Employee) => void;
  onOpenEmployeeDetails?: (employee: Employee) => void;
  isLoading?: boolean;
};

type RowItemProps = {
  row: TimesheetGridRow;
  isSelected: boolean;
  objectNameMap: Map<string, string>;
  onToggleSelect: (id: string) => void;
  onOpenAttendance?: (employee: Employee) => void;
  onOpenEmployeeDetails?: (employee: Employee) => void;
};

// Memoized individual row for zero-lag interaction
const TimesheetGridRowItem = memo(function TimesheetGridRowItem({
  row,
  isSelected,
  objectNameMap,
  onToggleSelect,
  onOpenAttendance,
  onOpenEmployeeDetails,
}: RowItemProps) {
  return (
    <tr
      className={cn(
        "group h-10 transition-colors border-b border-border/40",
        isSelected ? "bg-muted/70" : "hover:bg-muted/20"
      )}
    >
      {/* Checkbox cell (sticky left 0) */}
      <td
        className={cn(
          "sticky left-0 z-20 w-8 min-w-8 max-w-8 h-10 pl-2.5 pr-1 text-center align-middle transition-colors border-b border-border/40",
          isSelected ? "bg-muted" : "bg-card group-hover:bg-muted/70"
        )}
      >
        <input
          type="checkbox"
          checked={isSelected}
          onChange={() => onToggleSelect(row.employee.id)}
          aria-label={`Выбрать ${row.fullName}`}
          className="size-4 rounded border-border/80 text-primary accent-primary cursor-pointer align-middle transition-all"
        />
      </td>

      {/* Employee cell (sticky left 8) */}
      <td
        className={cn(
          "sticky left-8 z-20 w-80 min-w-80 max-w-80 h-10 pl-2 pr-2.5 py-1 align-middle border-r border-b border-border/70 shadow-[3px_0_8px_-2px_rgba(0,0,0,0.08)] dark:shadow-[3px_0_8px_-2px_rgba(0,0,0,0.4)] transition-colors",
          isSelected ? "bg-muted" : "bg-card group-hover:bg-muted/70"
        )}
      >
        <div className="flex items-center justify-between gap-1.5 min-w-0">
          <div className="min-w-0 flex-1">
            <button
              type="button"
              onClick={() => onOpenEmployeeDetails?.(row.employee)}
              className={cn(
                "block text-left truncate font-medium text-foreground text-[12px] sm:text-[13px] leading-tight tracking-tight hover:underline focus:outline-none transition-colors",
                onOpenEmployeeDetails && "hover:text-primary cursor-pointer"
              )}
              title={row.fullName}
            >
              {row.fullName}
            </button>
            {row.position ? (
              <span
                className="block truncate text-[10px] text-muted-foreground/75 leading-tight mt-0.5"
                title={row.position}
              >
                {row.position}
              </span>
            ) : null}
          </div>

          {onOpenAttendance ? (
            <Button
              type="button"
              variant="ghost"
              size="icon"
              onClick={() => onOpenAttendance(row.employee)}
              className="h-6 w-6 opacity-0 group-hover:opacity-100 hover:bg-primary/10 hover:text-primary shrink-0 transition-opacity rounded-md text-muted-foreground"
              title="Проставить часы посещаемости"
              aria-label="Проставить часы"
            >
              <CalendarIcon className="size-3.5" />
            </Button>
          ) : null}
        </div>
      </td>

      {/* Square day cells */}
      {row.days.map((day) => (
        <TimesheetDayCell
          key={`${row.employee.id}-${day.date}`}
          day={day}
          objectNameMap={objectNameMap}
        />
      ))}

      {/* Row total hours cell (sticky right 0) */}
      <td
        className={cn(
          "sticky right-0 z-20 w-16 min-w-16 max-w-16 h-10 px-2 text-center font-bold tabular-nums align-middle border-l border-b border-border/70 shadow-[-3px_0_8px_-2px_rgba(0,0,0,0.08)] dark:shadow-[-3px_0_8px_-2px_rgba(0,0,0,0.4)] text-[12px] transition-colors",
          row.totalHours > 0
            ? "text-foreground font-semibold"
            : "text-muted-foreground/25",
          isSelected ? "bg-muted" : "bg-card group-hover:bg-muted/70"
        )}
      >
        {row.totalHours > 0 ? formatHours(row.totalHours) : ""}
      </td>
    </tr>
  );
});

type DayCellProps = {
  day: DayCellData;
  objectNameMap: Map<string, string>;
};

const TimesheetDayCell = memo(function TimesheetDayCell({
  day,
  objectNameMap,
}: DayCellProps) {
  const hasHours = day.totalHours > 0;
  const hasManualEntry = day.entries.some((e) => e.isManualEntry);

  const comments = useMemo(() => {
    const list: { objectName: string; text: string }[] = [];
    const seen = new Set<string>();
    for (const entry of day.entries) {
      const text = entry.comment?.trim();
      if (text) {
        const objName = objectNameMap.get(entry.objectId) ?? "Объект";
        const key = `${objName}:::${text}`;
        if (!seen.has(key)) {
          seen.add(key);
          list.push({ objectName: objName, text });
        }
      }
    }
    return list;
  }, [day.entries, objectNameMap]);

  const hasComment = comments.length > 0;
  const hasOpenShiftHint = Boolean(
    day.isInTodayOpenShift && day.todayOpenShiftHint
  );
  const hasNote = hasComment || hasOpenShiftHint;

  const cellContent = (
    <div
      className={cn(
        "relative flex size-10 items-center justify-center cursor-default select-none text-[12px] tabular-nums",
        hasHours
          ? "font-medium text-foreground"
          : "text-muted-foreground/20 hover:bg-muted/20"
      )}
    >
      {hasHours ? (
        hasManualEntry ? (
          <span className="inline-flex items-center justify-center size-7 rounded-md border border-border/80 bg-background text-[11px] font-semibold text-foreground shadow-2xs tabular-nums">
            {formatHours(day.totalHours)}
          </span>
        ) : (
          <span className="font-medium">{formatHours(day.totalHours)}</span>
        )
      ) : null}

      {/* Today open shift indicator */}
      {day.isInTodayOpenShift ? (
        <span
          className="absolute top-1 right-1 size-1.5 rounded-full bg-amber-500 ring-1 ring-background"
          title="В открытой смене сегодня"
        />
      ) : null}

      {/* Comment indicator dot */}
      {hasComment && !day.isInTodayOpenShift ? (
        <span
          className="absolute top-1 right-1 size-1.5 rounded-full bg-primary/70 ring-1 ring-background"
          title="Есть примечание"
        />
      ) : null}
    </div>
  );

  return (
    <td
      className={cn(
        "w-10 min-w-10 max-w-10 h-10 p-0 text-center align-middle border-r border-b border-border/40 transition-colors",
        day.isToday && "bg-primary/[0.02] dark:bg-primary/[0.04]"
      )}
    >
      {hasNote ? (
        <Tooltip>
          <TooltipTrigger render={cellContent} />
          <TooltipContent
            side="top"
            className="text-xs p-2.5 max-w-xs space-y-1.5 shadow-md border border-border/60"
          >
            {hasOpenShiftHint ? (
              <div className="text-amber-400 font-medium text-[11px] flex items-center gap-1.5">
                <span>⚡</span>
                <span>{day.todayOpenShiftHint}</span>
              </div>
            ) : null}

            {comments.map((c, idx) => (
              <div key={idx} className="text-xs leading-relaxed flex flex-col gap-0.5">
                <span className="font-semibold text-background/70 text-[10px] uppercase tracking-wider">
                  {c.objectName}
                </span>
                <span className="text-background font-medium text-[12px] whitespace-pre-wrap">
                  {c.text}
                </span>
              </div>
            ))}
          </TooltipContent>
        </Tooltip>
      ) : (
        cellContent
      )}
    </td>
  );
});

export function TimesheetGrid({
  rows,
  daysHeader,
  dayTotals,
  grandTotalHours,
  objectOptions,
  selectedEmployeeIds,
  onToggleSelectEmployee,
  onSelectAll,
  onClearSelection,
  onOpenAttendance,
  onOpenEmployeeDetails,
  isLoading = false,
}: TimesheetGridProps) {
  const allVisibleIds = useMemo(() => rows.map((r) => r.employee.id), [rows]);

  const isAllSelected =
    allVisibleIds.length > 0 &&
    allVisibleIds.every((id) => selectedEmployeeIds.has(id));

  const isSomeSelected =
    !isAllSelected && allVisibleIds.some((id) => selectedEmployeeIds.has(id));

  const handleHeaderCheckbox = () => {
    if (isAllSelected) {
      onClearSelection();
    } else {
      onSelectAll(allVisibleIds);
    }
  };

  const objectNameMap = useMemo(() => {
    const map = new Map<string, string>();
    for (const o of objectOptions) {
      map.set(o.id, o.name);
    }
    return map;
  }, [objectOptions]);

  if (rows.length === 0 && !isLoading) {
    return (
      <div className="flex min-h-[360px] flex-col items-center justify-center rounded-2xl border border-dashed border-border/80 p-8 text-center bg-card/40">
        <div className="flex size-12 items-center justify-center rounded-2xl bg-muted/50 mb-3 text-muted-foreground">
          <UsersIcon className="size-6" />
        </div>
        <h3 className="text-sm font-semibold text-foreground tracking-tight">
          Нет записей для отображения
        </h3>
        <p className="mt-1 text-xs text-muted-foreground max-w-sm">
          Попробуйте изменить период, сбросить фильтры или ввести поисковый запрос
        </p>
      </div>
    );
  }

  return (
    <div className="relative w-full h-full min-h-0 flex flex-col rounded-2xl border border-border/70 bg-card shadow-xs overflow-hidden [clip-path:inset(0_round_var(--radius-2xl))]">
      <div className="relative flex-1 min-h-0 overflow-auto scrollbar-thin [clip-path:inset(0_round_calc(var(--radius-2xl)-1px))]">
        <table className="w-full border-separate border-spacing-0 text-sm">
          {/* Header */}
          <thead className="sticky top-0 z-40">
            <tr className="border-b border-border/70">
              {/* Checkbox column (sticky top-left corner) */}
              <th className="sticky top-0 left-0 z-50 w-8 min-w-8 max-w-8 h-11 bg-muted pl-2.5 pr-1 text-center align-middle border-b border-border/70 rounded-tl-2xl">
                <input
                  type="checkbox"
                  checked={isAllSelected}
                  ref={(input) => {
                    if (input) input.indeterminate = isSomeSelected;
                  }}
                  onChange={handleHeaderCheckbox}
                  aria-label="Выбрать всех сотрудников"
                  className="size-4 rounded border-border/80 text-primary accent-primary cursor-pointer align-middle transition-all"
                />
              </th>

              {/* Employee column (sticky left 8) */}
              <th className="sticky top-0 left-8 z-50 w-80 min-w-80 max-w-80 h-11 bg-muted pl-2 pr-3 text-left text-[11px] font-semibold uppercase tracking-wider text-muted-foreground align-middle border-r border-b border-border/70 shadow-[3px_0_8px_-2px_rgba(0,0,0,0.04)] dark:shadow-[3px_0_8px_-2px_rgba(0,0,0,0.2)]">
                Сотрудник
              </th>

              {/* Square day headers */}
              {daysHeader.map((d) => (
                <th
                  key={`day-${d.date}`}
                  className={cn(
                    "sticky top-0 z-40 w-10 min-w-10 max-w-10 h-11 p-0 text-center align-middle border-r border-b border-border/70 transition-colors bg-muted",
                    d.isWeekend && "bg-muted/80 dark:bg-muted/40",
                    d.isToday && "bg-primary/[0.04]"
                  )}
                >
                  <div className="flex size-10 mx-auto flex-col items-center justify-center gap-0.5 leading-none">
                    {d.isToday ? (
                      <span className="size-5 rounded-full bg-primary text-primary-foreground font-bold inline-flex items-center justify-center text-[11px] shadow-2xs tabular-nums">
                        {d.dayNumber}
                      </span>
                    ) : (
                      <span
                        className={cn(
                          "text-[12px] font-semibold leading-none tabular-nums",
                          d.isWeekend
                            ? "text-rose-500/90 dark:text-rose-400 font-semibold"
                            : "text-foreground/90"
                        )}
                      >
                        {d.dayNumber}
                      </span>
                    )}

                    <span
                      className={cn(
                        "text-[10px] font-medium leading-none uppercase tracking-tight",
                        d.isWeekend
                          ? "text-rose-500/70 dark:text-rose-400/80 font-semibold"
                          : "text-muted-foreground/60",
                        d.isToday && "text-primary font-bold"
                      )}
                    >
                      {d.weekdayName}
                    </span>
                  </div>
                </th>
              ))}

              {/* Total column (sticky top-right corner) */}
              <th className="sticky top-0 right-0 z-50 w-16 min-w-16 max-w-16 h-11 bg-muted px-2 text-center text-[11px] font-bold uppercase tracking-wider text-muted-foreground align-middle border-l border-b border-border/70 shadow-[-3px_0_8px_-2px_rgba(0,0,0,0.04)] dark:shadow-[-3px_0_8px_-2px_rgba(0,0,0,0.2)] rounded-tr-2xl">
                Итого
              </th>
            </tr>
          </thead>

          {/* Body */}
          <tbody>
            {rows.map((row) => (
              <TimesheetGridRowItem
                key={row.employee.id}
                row={row}
                isSelected={selectedEmployeeIds.has(row.employee.id)}
                objectNameMap={objectNameMap}
                onToggleSelect={onToggleSelectEmployee}
                onOpenAttendance={onOpenAttendance}
                onOpenEmployeeDetails={onOpenEmployeeDetails}
              />
            ))}
          </tbody>

          {/* Footer totals */}
          <tfoot className="sticky bottom-0 z-40">
            <tr className="border-t border-border/80 bg-muted font-semibold text-foreground h-10">
              {/* Bottom-left corner */}
              <td
                colSpan={2}
                className="sticky bottom-0 left-0 z-50 bg-muted px-3.5 h-10 font-bold text-foreground text-right border-r border-border/70 shadow-[3px_0_8px_-2px_rgba(0,0,0,0.04)] dark:shadow-[3px_0_8px_-2px_rgba(0,0,0,0.2)] text-[11px] uppercase tracking-wider text-muted-foreground align-middle rounded-bl-2xl"
              >
                Итого
              </td>

              {dayTotals.map((tot, idx) => (
                <td
                  key={`total-${idx}`}
                  className="sticky bottom-0 z-40 w-10 min-w-10 max-w-10 h-10 p-0 text-center font-bold text-[12px] tabular-nums text-foreground/90 align-middle border-r border-border/70 bg-muted"
                >
                  <div className="flex size-10 mx-auto items-center justify-center">
                    {tot > 0 ? formatHours(tot) : ""}
                  </div>
                </td>
              ))}

              {/* Bottom-right corner */}
              <td className="sticky bottom-0 right-0 z-50 w-16 min-w-16 max-w-16 h-10 bg-muted px-2 text-center font-extrabold text-[12px] tabular-nums border-l border-border/70 shadow-[-3px_0_8px_-2px_rgba(0,0,0,0.04)] dark:shadow-[-3px_0_8px_-2px_rgba(0,0,0,0.2)] text-primary align-middle rounded-br-2xl">
                {grandTotalHours > 0 ? formatHours(grandTotalHours) : ""}
              </td>
            </tr>
          </tfoot>
        </table>
      </div>
    </div>
  );
}
