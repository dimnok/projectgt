"use client";

import { CalendarIcon, UsersIcon } from "lucide-react";

import { Button } from "@/components/ui/button";
import {
  Tooltip,
  TooltipContent,
  TooltipTrigger,
} from "@/components/ui/tooltip";
import type { Employee } from "@/features/employees/types/employee.types";
import type {
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
  objectColorMap?: Map<string, string>;
  objectOptions: TimesheetObjectOption[];
  selectedEmployeeIds: Set<string>;
  onToggleSelectEmployee: (employeeId: string) => void;
  onSelectAll: (ids: string[]) => void;
  onClearSelection: () => void;
  onOpenAttendance?: (employee: Employee) => void;
  onOpenEmployeeDetails?: (employee: Employee) => void;
  isLoading?: boolean;
};

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
  const allVisibleIds = rows.map((r) => r.employee.id);
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

  const objectNameMap = new Map<string, string>();
  for (const o of objectOptions) {
    objectNameMap.set(o.id, o.name);
  }

  if (rows.length === 0 && !isLoading) {
    return (
      <div className="flex min-h-[360px] flex-col items-center justify-center rounded-xl border border-dashed border-border p-8 text-center bg-card/40">
        <UsersIcon className="h-10 w-10 text-muted-foreground/40 mb-3" />
        <h3 className="text-base font-semibold text-foreground">
          Нет записей для отображения
        </h3>
        <p className="mt-1 text-xs sm:text-sm text-muted-foreground max-w-sm">
          Попробуйте изменить период, сбросить фильтры или ввести поисковый запрос
        </p>
      </div>
    );
  }

  return (
    <div className="relative w-full rounded-xl border border-border bg-card shadow-xs [clip-path:inset(0_round_var(--radius-xl))]">
      <div className="relative max-h-[calc(100vh-14rem)] overflow-auto [clip-path:inset(0_round_calc(var(--radius-xl)-1px))]">
        <table className="w-full border-separate border-spacing-0 text-sm">
          {/* Header */}
          <thead className="sticky top-0 z-30">
            <tr>
              {/* Checkbox col (top-left corner) */}
              <th
                className="sticky top-0 left-0 z-40 w-10 min-w-10 bg-muted px-2 py-2 text-center align-middle border-r border-b border-border"
              >
                <input
                  type="checkbox"
                  checked={isAllSelected}
                  ref={(input) => {
                    if (input) input.indeterminate = isSomeSelected;
                  }}
                  onChange={handleHeaderCheckbox}
                  className="h-4 w-4 rounded border-input text-primary focus:ring-primary/20 cursor-pointer"
                />
              </th>

              {/* Employee col */}
              <th
                className="sticky top-0 left-10 z-40 w-60 min-w-60 bg-muted px-3 py-2 text-left text-sm font-semibold text-foreground align-middle border-r border-b border-border shadow-[2px_0_5px_-2px_rgba(0,0,0,0.1)]"
              >
                Сотрудник
              </th>

              {/* Days header: weekend dates highlighted in red */}
              {daysHeader.map((d) => (
                <th
                  key={`day-${d.date}`}
                  className={cn(
                    "w-10 min-w-10 px-0.5 py-1.5 text-center align-middle border-r border-b border-border transition-colors",
                    d.isWeekend
                      ? "bg-destructive/10 dark:bg-destructive/20"
                      : "bg-muted",
                    d.isToday && "ring-1 ring-inset ring-primary/40"
                  )}
                >
                  <div className="flex flex-col items-center justify-center gap-0.5 leading-none">
                    <span
                      className={cn(
                        "text-xs font-bold leading-none",
                        d.isWeekend ? "text-destructive" : "text-foreground",
                        d.isToday && "text-primary font-extrabold"
                      )}
                    >
                      {d.dayNumber}
                    </span>
                    <span
                      className={cn(
                        "text-[10px] font-semibold leading-none",
                        d.isWeekend
                          ? "text-destructive/80 font-bold"
                          : "text-muted-foreground",
                        d.isToday && "text-primary font-bold"
                      )}
                    >
                      {d.weekdayName}
                    </span>
                  </div>
                </th>
              ))}

              {/* Total col (top-right corner) */}
              <th
                className="sticky top-0 right-0 z-40 w-14 min-w-14 bg-muted px-2 py-2 text-center text-xs font-bold text-foreground align-middle border-l border-b border-border shadow-[-2px_0_5px_-2px_rgba(0,0,0,0.1)]"
              >
                Итого
              </th>
            </tr>
          </thead>

          {/* Body */}
          <tbody>
            {rows.map((row) => {
              const isSelected = selectedEmployeeIds.has(row.employee.id);

              return (
                <tr
                  key={row.employee.id}
                  className={cn(
                    "group transition-colors hover:bg-muted/40",
                    isSelected && "bg-primary/5"
                  )}
                >
                  {/* Checkbox cell */}
                  <td
                    className={cn(
                      "sticky left-0 z-20 w-10 min-w-10 bg-card px-2 py-1 text-center align-middle border-r border-b border-border group-hover:bg-muted/40",
                      isSelected && "bg-primary/5 group-hover:bg-primary/10"
                    )}
                  >
                    <input
                      type="checkbox"
                      checked={isSelected}
                      onChange={() => onToggleSelectEmployee(row.employee.id)}
                      className="h-4 w-4 rounded border-input text-primary focus:ring-primary/20 cursor-pointer"
                    />
                  </td>

                  {/* Employee name & actions cell */}
                  <td
                    className={cn(
                      "sticky left-10 z-20 w-60 min-w-60 bg-card px-3 py-1 align-middle border-r border-b border-border shadow-[2px_0_5px_-2px_rgba(0,0,0,0.1)] group-hover:bg-muted/40",
                      isSelected && "bg-primary/5 group-hover:bg-primary/10"
                    )}
                  >
                    <div className="flex items-center justify-between gap-2 min-w-0">
                      <div className="min-w-0 flex-1">
                        <span
                          onClick={() => onOpenEmployeeDetails?.(row.employee)}
                          className={cn(
                            "block truncate font-medium text-foreground text-sm leading-snug",
                            onOpenEmployeeDetails &&
                              "cursor-pointer hover:text-primary hover:underline"
                          )}
                          title={row.fullName}
                        >
                          {row.fullName}
                        </span>
                        {row.position ? (
                          <span
                            className="block truncate text-xs text-muted-foreground leading-snug"
                            title={row.position}
                          >
                            {row.position}
                          </span>
                        ) : null}
                      </div>

                      {/* Attendance edit button */}
                      {onOpenAttendance ? (
                      <Button
                        type="button"
                        variant="ghost"
                        size="icon"
                        onClick={() => onOpenAttendance(row.employee)}
                        className="h-6 w-6 opacity-70 group-hover:opacity-100 hover:bg-primary/10 hover:text-primary shrink-0 transition-opacity"
                        title="Проставить часы посещаемости"
                      >
                        <CalendarIcon className="h-3.5 w-3.5" />
                      </Button>
                      ) : null}
                    </div>
                  </td>

                  {/* Day cells */}
                  {row.days.map((day) => {
                    const hasHours = day.totalHours > 0;
                    const hasManualEntry = day.entries.some((e) => e.isManualEntry);

                    // Collect unique non-empty comments
                    const comments: { objectName: string; text: string }[] = [];
                    const seenComments = new Set<string>();
                    for (const entry of day.entries) {
                      const text = entry.comment?.trim();
                      if (text && !seenComments.has(text)) {
                        seenComments.add(text);
                        const objName =
                          entry.objectName ||
                          objectNameMap.get(entry.objectId) ||
                          "Объект";
                        comments.push({ objectName: objName, text });
                      }
                    }

                    const hasComment = comments.length > 0;
                    const hasOpenShiftHint = Boolean(
                      day.isInTodayOpenShift && day.todayOpenShiftHint
                    );
                    const hasNote = hasComment || hasOpenShiftHint;

                    const cellBody = (
                      <div
                        className={cn(
                          "relative flex h-8 w-full items-center justify-center cursor-default transition-transform select-none text-xs",
                          hasHours
                            ? "font-semibold text-foreground"
                            : "text-muted-foreground/25 hover:bg-muted/20"
                        )}
                      >
                        {hasHours ? (
                          hasManualEntry ? (
                            <span className="inline-flex items-center justify-center rounded border border-foreground/30 px-1 py-0.5 leading-none font-semibold">
                              {formatHours(day.totalHours)}
                            </span>
                          ) : (
                            formatHours(day.totalHours)
                          )
                        ) : (
                          ""
                        )}

                        {/* Today open shift asterisk badge */}
                        {day.isInTodayOpenShift ? (
                          <span
                            className={cn(
                              "absolute top-0.5 right-0.5 text-[11px] font-bold text-amber-500 leading-none"
                            )}
                          >
                            *
                          </span>
                        ) : null}

                        {/* Small dot indicator if there is a comment */}
                        {hasComment && !day.isInTodayOpenShift ? (
                          <span className="absolute top-1 right-1 h-1.5 w-1.5 rounded-full bg-primary/80" />
                        ) : null}
                      </div>
                    );

                    return (
                      <td
                        key={`${row.employee.id}-${day.date}`}
                        className={cn(
                          "relative w-10 min-w-10 p-0 text-center align-middle border-r border-b border-border transition-colors",
                          day.isWeekend && "bg-muted/35 dark:bg-muted/20",
                          day.isToday && "ring-1 ring-inset ring-primary/40"
                        )}
                      >
                        {hasNote ? (
                          <Tooltip>
                            <TooltipTrigger render={cellBody} />

                            <TooltipContent side="top" className="text-xs p-2 max-w-xs space-y-1">
                              {hasOpenShiftHint ? (
                                <div className="text-amber-500 font-medium text-[11px]">
                                  ⚡ {day.todayOpenShiftHint}
                                </div>
                              ) : null}

                              {comments.map((c, idx) => (
                                <div key={idx} className="text-xs leading-relaxed">
                                  <span className="font-semibold text-muted-foreground mr-1.5">
                                    {c.objectName}:
                                  </span>
                                  <span className="text-foreground">{c.text}</span>
                                </div>
                              ))}
                            </TooltipContent>
                          </Tooltip>
                        ) : (
                          cellBody
                        )}
                      </td>
                    );
                  })}

                  {/* Total cell */}
                  <td
                    className={cn(
                      "sticky right-0 z-20 w-14 min-w-14 bg-card px-1 py-1 text-center font-bold align-middle border-l border-b border-border shadow-[-2px_0_5px_-2px_rgba(0,0,0,0.1)] group-hover:bg-muted/40 text-xs",
                      row.totalHours > 0
                        ? "text-foreground font-semibold"
                        : "text-muted-foreground/40",
                      isSelected && "bg-primary/5 group-hover:bg-primary/10"
                    )}
                  >
                    {row.totalHours > 0 ? formatHours(row.totalHours) : ""}
                  </td>
                </tr>
              );
            })}
          </tbody>

          {/* Footer: totals per day */}
          <tfoot className="sticky bottom-0 z-30">
            <tr>
              {/* Bottom-left corner */}
              <td
                colSpan={2}
                className="sticky bottom-0 left-0 z-40 bg-muted px-3 py-1.5 font-bold text-foreground text-right border-t border-r border-border shadow-[2px_0_5px_-2px_rgba(0,0,0,0.1)] text-xs"
              >
                Итого
              </td>

              {dayTotals.map((tot, idx) => {
                const dayHead = daysHeader[idx];
                return (
                  <td
                    key={`total-${idx}`}
                    className={cn(
                      "w-10 min-w-10 bg-muted px-0.5 py-1.5 text-center font-bold text-xs border-t border-r border-border text-foreground/80",
                      dayHead?.isWeekend && "bg-muted/70 dark:bg-muted/40"
                    )}
                  >
                    {tot > 0 ? formatHours(tot) : ""}
                  </td>
                );
              })}

              {/* Bottom-right corner */}
              <td
                className="sticky bottom-0 right-0 z-40 w-14 min-w-14 bg-muted px-1 py-1.5 text-center font-extrabold text-xs border-t border-l border-border shadow-[-2px_0_5px_-2px_rgba(0,0,0,0.1)] text-foreground"
              >
                {grandTotalHours > 0 ? formatHours(grandTotalHours) : ""}
              </td>
            </tr>
          </tfoot>
        </table>
      </div>
    </div>
  );
}
