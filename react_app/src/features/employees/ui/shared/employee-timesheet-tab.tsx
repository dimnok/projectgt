"use client";

import { useMemo, useState } from "react";
import {
  ChevronLeftIcon,
  ChevronRightIcon,
  ClockIcon,
} from "lucide-react";
import { useQuery } from "@tanstack/react-query";

import { Button } from "@/components/ui/button";
import { Spinner } from "@/components/ui/spinner";
import {
  Tooltip,
  TooltipContent,
  TooltipTrigger,
} from "@/components/ui/tooltip";
import {
  getEmployeeTimesheetMonth,
  type TimesheetDayObjectSlice,
  type TimesheetDaySummary,
} from "@/features/employees/api/get-employee-timesheet";
import type { Employee } from "@/features/employees/types/employee.types";
import { formatRuDate } from "@/features/employees/utils/employee.utils";
import { cn } from "@/lib/utils";

type EmployeeTimesheetTabProps = {
  employee: Employee;
  objectNamesById: Map<string, string>;
};

export type ObjectColor = {
  id: string;
  name: string;
  dot: string;
  bgLight: string;
  border: string;
  hoverBorder: string;
  text: string;
  barColor: string;
  badgeClass: string;
};

const OBJECT_PALETTE: ObjectColor[] = [
  {
    id: "blue",
    name: "Синий",
    dot: "bg-blue-500",
    bgLight: "bg-blue-500/10 dark:bg-blue-500/20",
    border: "border-blue-500/40",
    hoverBorder: "hover:border-blue-500",
    text: "text-blue-700 dark:text-blue-300",
    barColor: "bg-blue-500",
    badgeClass: "bg-blue-500/15 text-blue-700 dark:text-blue-300 border-blue-500/30",
  },
  {
    id: "emerald",
    name: "Изумрудный",
    dot: "bg-emerald-500",
    bgLight: "bg-emerald-500/10 dark:bg-emerald-500/20",
    border: "border-emerald-500/40",
    hoverBorder: "hover:border-emerald-500",
    text: "text-emerald-700 dark:text-emerald-300",
    barColor: "bg-emerald-500",
    badgeClass: "bg-emerald-500/15 text-emerald-700 dark:text-emerald-300 border-emerald-500/30",
  },
  {
    id: "amber",
    name: "Янтарный",
    dot: "bg-amber-500",
    bgLight: "bg-amber-500/10 dark:bg-amber-500/20",
    border: "border-amber-500/40",
    hoverBorder: "hover:border-amber-500",
    text: "text-amber-700 dark:text-amber-300",
    barColor: "bg-amber-500",
    badgeClass: "bg-amber-500/15 text-amber-700 dark:text-amber-300 border-amber-500/30",
  },
  {
    id: "purple",
    name: "Фиолетовый",
    dot: "bg-purple-500",
    bgLight: "bg-purple-500/10 dark:bg-purple-500/20",
    border: "border-purple-500/40",
    hoverBorder: "hover:border-purple-500",
    text: "text-purple-700 dark:text-purple-300",
    barColor: "bg-purple-500",
    badgeClass: "bg-purple-500/15 text-purple-700 dark:text-purple-300 border-purple-500/30",
  },
  {
    id: "cyan",
    name: "Бирюзовый",
    dot: "bg-cyan-500",
    bgLight: "bg-cyan-500/10 dark:bg-cyan-500/20",
    border: "border-cyan-500/40",
    hoverBorder: "hover:border-cyan-500",
    text: "text-cyan-700 dark:text-cyan-300",
    barColor: "bg-cyan-500",
    badgeClass: "bg-cyan-500/15 text-cyan-700 dark:text-cyan-300 border-cyan-500/30",
  },
  {
    id: "rose",
    name: "Коралловый",
    dot: "bg-rose-500",
    bgLight: "bg-rose-500/10 dark:bg-rose-500/20",
    border: "border-rose-500/40",
    hoverBorder: "hover:border-rose-500",
    text: "text-rose-700 dark:text-rose-300",
    barColor: "bg-rose-500",
    badgeClass: "bg-rose-500/15 text-rose-700 dark:text-rose-300 border-rose-500/30",
  },
  {
    id: "indigo",
    name: "Индиго",
    dot: "bg-indigo-500",
    bgLight: "bg-indigo-500/10 dark:bg-indigo-500/20",
    border: "border-indigo-500/40",
    hoverBorder: "hover:border-indigo-500",
    text: "text-indigo-700 dark:text-indigo-300",
    barColor: "bg-indigo-500",
    badgeClass: "bg-indigo-500/15 text-indigo-700 dark:text-indigo-300 border-indigo-500/30",
  },
  {
    id: "lime",
    name: "Лаймовый",
    dot: "bg-lime-500",
    bgLight: "bg-lime-500/10 dark:bg-lime-500/20",
    border: "border-lime-500/40",
    hoverBorder: "hover:border-lime-500",
    text: "text-lime-700 dark:text-lime-300",
    barColor: "bg-lime-500",
    badgeClass: "bg-lime-500/15 text-lime-700 dark:text-lime-300 border-lime-500/30",
  },
];

const MONTH_NAMES = [
  "Январь",
  "Февраль",
  "Март",
  "Апрель",
  "Май",
  "Июнь",
  "Июль",
  "Август",
  "Сентябрь",
  "Октябрь",
  "Ноябрь",
  "Декабрь",
];

const WEEKDAY_NAMES = ["Пн", "Вт", "Ср", "Чт", "Пт", "Сб", "Вс"];

function formatTimesheetHours(hours: number) {
  return Number.isInteger(hours) ? String(hours) : hours.toFixed(1);
}

function TimesheetObjectBar({
  slices,
  totalHours,
  objectColorMap,
  className,
}: {
  slices: TimesheetDayObjectSlice[];
  totalHours: number;
  objectColorMap: Map<string, ObjectColor>;
  className?: string;
}) {
  if (slices.length === 0) return null;

  return (
    <span className={cn("flex overflow-hidden rounded-full", className)}>
      {slices.map((slice) => {
        const color = objectColorMap.get(slice.objectId) ?? OBJECT_PALETTE[0];
        const flexGrow = Math.max(
          1,
          Math.round((slice.hours / (totalHours || 1)) * 100)
        );
        return (
          <span
            key={slice.objectId}
            style={{ flexGrow }}
            className={cn("h-full", color.barColor)}
          />
        );
      })}
    </span>
  );
}

function TimesheetDayCell({
  dayNum,
  isWeekend,
  hasHours,
  hasComments,
  hours,
  slices,
  objectColorMap,
}: {
  dayNum: number;
  isWeekend: boolean;
  hasHours: boolean;
  hasComments: boolean;
  hours: number;
  slices: TimesheetDayObjectSlice[];
  objectColorMap: Map<string, ObjectColor>;
}) {
  return (
    <div
      className={cn(
        "relative flex min-h-[4.5rem] flex-col rounded-lg px-2 py-1.5 text-left",
        hasHours
          ? "border border-border bg-muted shadow-xs group-hover:bg-accent"
          : cn(
              "border border-transparent",
              isWeekend ? "bg-muted/35" : "bg-transparent"
            )
      )}
    >
      {hasHours ? (
        <TimesheetObjectBar
          slices={slices}
          totalHours={hours}
          objectColorMap={objectColorMap}
          className="absolute inset-y-1.5 left-1.5 w-1"
        />
      ) : null}

      <div className={cn("flex items-start justify-between", hasHours && "pl-2.5")}>
        <span
          className={cn(
            "text-xs font-medium tabular-nums",
            isWeekend
              ? "text-destructive"
              : hasHours
                ? "text-foreground/70"
                : "text-muted-foreground"
          )}
        >
          {dayNum}
        </span>
        {hasComments ? (
          <span className="mt-0.5 size-1.5 shrink-0 rounded-full bg-foreground/55" />
        ) : null}
      </div>

      <div className={cn("mt-auto", hasHours && "pl-2.5")}>
        {hasHours ? (
          <p className="text-[15px] font-semibold leading-none tabular-nums tracking-tight text-foreground">
            {formatTimesheetHours(hours)}
            <span className="ml-0.5 text-[11px] font-medium text-muted-foreground">
              ч
            </span>
          </p>
        ) : null}
      </div>
    </div>
  );
}

function TimesheetDayHint({
  day,
  objectNamesById,
  objectColorMap,
}: {
  day: TimesheetDaySummary;
  objectNamesById: Map<string, string>;
  objectColorMap: Map<string, ObjectColor>;
}) {
  const source =
    day.shiftHours > 0 && day.manualHours > 0
      ? `смена ${day.shiftHours} ч · ручной ${day.manualHours} ч`
      : day.shiftHours > 0
        ? "смена"
        : day.manualHours > 0
          ? "ручной ввод"
          : null;

  return (
    <>
      <p className="font-semibold">
        {formatRuDate(day.date)} · {day.totalHours} ч
      </p>
      {day.objectSlices.length > 0 ? (
        <ul className="flex flex-col gap-0.5">
          {day.objectSlices.map((slice) => {
            const color =
              objectColorMap.get(slice.objectId) ?? OBJECT_PALETTE[0];
            const name = objectNamesById.get(slice.objectId) || "Объект";
            return (
              <li
                key={slice.objectId}
                className="flex items-center gap-1.5"
              >
                <span
                  className={cn("size-1.5 shrink-0 rounded-full", color.dot)}
                />
                <span className="min-w-0 flex-1 truncate">{name}</span>
                <span className="shrink-0 font-medium tabular-nums">
                  {slice.hours} ч
                </span>
              </li>
            );
          })}
        </ul>
      ) : null}
      {source ? <p className="opacity-70">{source}</p> : null}
      {day.comments.map((comment, index) => (
        <p key={index} className="opacity-80">
          {comment.text}
        </p>
      ))}
    </>
  );
}

export function EmployeeTimesheetTab({
  employee,
  objectNamesById,
}: EmployeeTimesheetTabProps) {
  const now = new Date();
  const [currentYear, setCurrentYear] = useState(now.getFullYear());
  const [currentMonth, setCurrentMonth] = useState(now.getMonth() + 1); // 1-12

  const { data, isLoading, isError, error } = useQuery({
    queryKey: [
      "employee-timesheet",
      employee.id,
      currentYear,
      currentMonth,
    ],
    queryFn: () =>
      getEmployeeTimesheetMonth({
        employeeId: employee.id,
        year: currentYear,
        month: currentMonth,
      }),
  });

  // Карта цветов для каждого объекта
  const objectColorMap = useMemo(() => {
    const map = new Map<string, ObjectColor>();
    if (!data?.objectTotals) return map;
    data.objectTotals.forEach((item, index) => {
      map.set(item.objectId, OBJECT_PALETTE[index % OBJECT_PALETTE.length]);
    });
    return map;
  }, [data]);

  const prevMonth = () => {
    if (currentMonth === 1) {
      setCurrentMonth(12);
      setCurrentYear((y) => y - 1);
    } else {
      setCurrentMonth((m) => m - 1);
    }
  };

  const nextMonth = () => {
    if (
      currentYear > now.getFullYear() ||
      (currentYear === now.getFullYear() && currentMonth >= now.getMonth() + 1)
    ) {
      return;
    }
    if (currentMonth === 12) {
      setCurrentMonth(1);
      setCurrentYear((y) => y + 1);
    } else {
      setCurrentMonth((m) => m + 1);
    }
  };

  const isCurrentOrFuture =
    currentYear > now.getFullYear() ||
    (currentYear === now.getFullYear() && currentMonth >= now.getMonth() + 1);

  const daysInMonth = new Date(currentYear, currentMonth, 0).getDate();

  const dayLookup = useMemo(() => {
    const map = new Map<number, (typeof data.days)[0]>();
    if (data?.days) {
      for (const d of data.days) {
        const dayNum = parseInt(d.date.split("-")[2], 10);
        map.set(dayNum, d);
      }
    }
    return map;
  }, [data]);

  return (
    <div className="flex flex-col gap-6">
      {!employee.includeInTimesheet ? (
        <div className="flex items-center gap-2.5 rounded-xl border border-amber-500/30 bg-amber-500/10 px-4 py-3 text-xs text-amber-800 dark:text-amber-300">
          <ClockIcon className="size-4 shrink-0 text-amber-600 dark:text-amber-400" />
          <span>
            Сотрудник отмечен как «Не учитывается в табеле», однако фактически
            отработанные смены и часы отображаются в полном объёме.
          </span>
        </div>
      ) : null}

      {/* Переключатель месяца и сводка */}
      <div className="flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between">
        <div className="flex items-center gap-2">
          <Button
            type="button"
            variant="outline"
            size="icon-sm"
            onClick={prevMonth}
            aria-label="Предыдущий месяц"
          >
            <ChevronLeftIcon className="size-4" />
          </Button>

          <span className="min-w-36 text-center text-sm font-semibold tracking-tight text-foreground">
            {MONTH_NAMES[currentMonth - 1]} {currentYear}
          </span>

          <Button
            type="button"
            variant="outline"
            size="icon-sm"
            disabled={isCurrentOrFuture}
            onClick={nextMonth}
            aria-label="Следующий месяц"
          >
            <ChevronRightIcon className="size-4" />
          </Button>
        </div>

        {/* Карточки KPI за месяц */}
        <div className="flex items-center gap-3">
          <div className="flex items-center gap-2 rounded-xl border border-border/80 bg-card px-3.5 py-2">
            <span className="text-xs text-muted-foreground">Отработано:</span>
            <span className="text-base font-bold text-foreground">
              {data ? data.totalHours.toFixed(1) : "0"} ч.
            </span>
          </div>

          <div className="flex items-center gap-2 rounded-xl border border-border/80 bg-card px-3.5 py-2">
            <span className="text-xs text-muted-foreground">Дней с часами:</span>
            <span className="text-base font-bold text-foreground">
              {data ? data.totalDays : "0"}
            </span>
          </div>
        </div>
      </div>

      {isLoading ? (
        <div className="flex min-h-48 items-center justify-center">
          <Spinner className="size-6 text-primary" />
        </div>
      ) : isError ? (
        <div className="rounded-xl border border-destructive/30 bg-destructive/5 p-4 text-center text-sm text-destructive">
          {error instanceof Error ? error.message : "Не удалось загрузить табель"}
        </div>
      ) : (
        <div className="flex flex-col gap-4">
          <div className="rounded-2xl border border-border/70 bg-background p-3">
            <div className="grid grid-cols-7 gap-1.5">
              {WEEKDAY_NAMES.map((name, weekdayIndex) => (
                <div
                  key={name}
                  className={cn(
                    "pb-1.5 text-center text-xs font-medium",
                    weekdayIndex >= 5
                      ? "text-destructive"
                      : "text-muted-foreground"
                  )}
                >
                  {name}
                </div>
              ))}

              {Array.from({
                length:
                  (new Date(currentYear, currentMonth - 1, 1).getDay() + 6) % 7,
              }).map((_, i) => (
                <div key={`empty-${i}`} className="min-h-[4.5rem]" />
              ))}

              {Array.from({ length: daysInMonth }).map((_, index) => {
                const dayNum = index + 1;
                const dayData = dayLookup.get(dayNum);
                const hasHours = Boolean(dayData && dayData.totalHours > 0);
                const hasComments = Boolean(
                  dayData && dayData.comments.length > 0
                );
                const slices = dayData?.objectSlices ?? [];
                const hours = dayData?.totalHours ?? 0;
                const isWeekend = (() => {
                  const dayOfWeek = new Date(
                    currentYear,
                    currentMonth - 1,
                    dayNum
                  ).getDay();
                  return dayOfWeek === 0 || dayOfWeek === 6;
                })();

                const cell = (
                  <TimesheetDayCell
                    dayNum={dayNum}
                    isWeekend={isWeekend}
                    hasHours={hasHours}
                    hasComments={hasComments}
                    hours={hours}
                    slices={slices}
                    objectColorMap={objectColorMap}
                  />
                );

                if (!hasHours || !dayData) {
                  return <div key={dayNum}>{cell}</div>;
                }

                return (
                  <Tooltip key={dayNum}>
                    <TooltipTrigger
                      render={
                        <button
                          type="button"
                          aria-label={`${dayNum} число, ${formatTimesheetHours(hours)} ч`}
                          className="group w-full rounded-lg text-left outline-none focus-visible:ring-2 focus-visible:ring-ring"
                        />
                      }
                    >
                      {cell}
                    </TooltipTrigger>
                    <TooltipContent
                      side="top"
                      className="max-w-56 flex-col items-stretch gap-1 px-2.5 py-1.5 text-[12px] leading-snug"
                    >
                      <TimesheetDayHint
                        day={dayData}
                        objectNamesById={objectNamesById}
                        objectColorMap={objectColorMap}
                      />
                    </TooltipContent>
                  </Tooltip>
                );
              })}
            </div>
          </div>

          {data && data.objectTotals.length > 0 ? (
            <div className="flex flex-wrap items-center gap-x-4 gap-y-2 px-1">
              {data.objectTotals.map((item) => {
                const color =
                  objectColorMap.get(item.objectId) ?? OBJECT_PALETTE[0];
                const objectName =
                  objectNamesById.get(item.objectId) || "Объект";
                const percent =
                  data.totalHours > 0
                    ? Math.round((item.hours / data.totalHours) * 100)
                    : 0;

                return (
                  <div
                    key={item.objectId}
                    className="flex items-center gap-2 text-xs"
                  >
                    <span
                      className={cn("size-2 shrink-0 rounded-full", color.dot)}
                    />
                    <span className="text-foreground">{objectName}</span>
                    <span className="text-muted-foreground tabular-nums">
                      {item.hours.toFixed(1)} ч · {percent}%
                    </span>
                  </div>
                );
              })}
            </div>
          ) : null}
        </div>
      )}
    </div>
  );
}
