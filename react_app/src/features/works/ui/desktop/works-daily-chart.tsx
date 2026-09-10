"use client";

import {
  ActivityIcon,
  BarChart3Icon,
  CalendarDaysIcon,
  TrendingUpIcon,
} from "lucide-react";

import { Badge } from "@/components/ui/badge";
import { Skeleton } from "@/components/ui/skeleton";
import {
  Tooltip,
  TooltipContent,
  TooltipTrigger,
} from "@/components/ui/tooltip";
import type { Work } from "@/features/works/types/work.types";
import {
  detailedDailyStats,
  formatCurrency,
  formatDayFullRu,
  isTodayInMonth,
} from "@/features/works/utils/work.utils";
import { cn } from "@/lib/utils";

type WorksDailyChartProps = {
  month: string;
  works: Work[];
  objectId?: string | null;
  isLoading: boolean;
};

export function WorksDailyChart({
  month,
  works,
  objectId,
  isLoading,
}: WorksDailyChartProps) {
  if (isLoading) {
    return <Skeleton className="h-64 w-full rounded-xl" />;
  }

  const dailyStats = detailedDailyStats(works, month, objectId);
  const activeStats = dailyStats.filter((item) => item.totalAmount > 0);

  const maxAmount =
    activeStats.length > 0
      ? Math.max(...activeStats.map((item) => item.totalAmount))
      : 0;

  const peakDay =
    maxAmount > 0
      ? dailyStats.find((item) => item.totalAmount === maxAmount)
      : null;

  const totalMonthVolume = dailyStats.reduce(
    (sum, item) => sum + item.totalAmount,
    0
  );
  const activeDaysCount = activeStats.length;
  const avgDailyAmount =
    activeDaysCount > 0 ? totalMonthVolume / activeDaysCount : 0;

  return (
    <div className="flex flex-col gap-4 rounded-xl bg-card p-4 ring-1 ring-foreground/10 shadow-float sm:p-5">
      {/* Chart Header */}
      <div className="flex flex-wrap items-center justify-between gap-3 border-b pb-3">
        <div className="flex items-center gap-2">
          <span className="flex size-7 items-center justify-center rounded-md bg-muted text-foreground/80">
            <BarChart3Icon className="size-4" />
          </span>
          <div>
            <h3 className="font-heading text-sm font-semibold tracking-tight text-foreground">
              Динамика выработки
            </h3>
            <p className="text-xs text-muted-foreground">
              Ежедневный объем за месяц
            </p>
          </div>
        </div>

        {/* Quick Highlights */}
        {activeDaysCount > 0 ? (
          <div className="flex flex-wrap items-center gap-2 text-xs">
            {peakDay ? (
              <Badge
                variant="secondary"
                className="gap-1 font-normal text-muted-foreground"
              >
                <TrendingUpIcon className="size-3 text-foreground" />
                <span>
                  Пик:{" "}
                  <strong className="font-medium text-foreground">
                    {peakDay.day} число
                  </strong>{" "}
                  ({formatCurrency(peakDay.totalAmount)})
                </span>
              </Badge>
            ) : null}

            <Badge
              variant="outline"
              className="gap-1 font-normal text-muted-foreground"
            >
              <ActivityIcon className="size-3 text-foreground" />
              <span>
                Среднее:{" "}
                <strong className="font-medium text-foreground">
                  {formatCurrency(avgDailyAmount)}
                </strong>
                /день
              </span>
            </Badge>

            <Badge
              variant="outline"
              className="gap-1 font-normal text-muted-foreground"
            >
              <CalendarDaysIcon className="size-3 text-foreground" />
              <span>
                {activeDaysCount} из {dailyStats.length} дн.
              </span>
            </Badge>
          </div>
        ) : null}
      </div>

      {/* Chart Canvas */}
      {activeDaysCount === 0 ? (
        <div className="flex h-44 flex-col items-center justify-center gap-2 rounded-lg border border-dashed border-border/80 bg-muted/20 text-center">
          <CalendarDaysIcon className="size-8 text-muted-foreground/50" />
          <p className="text-sm font-medium text-muted-foreground">
            За выбранный период смен с выработкой нет
          </p>
        </div>
      ) : (
        <div className="flex h-52 flex-col justify-end pt-2">
          <div className="relative flex min-h-0 flex-1 items-end justify-between gap-0.5 sm:gap-1">
            {/* Subtle Horizontal Reference Grid */}
            <div className="pointer-events-none absolute inset-x-0 top-0 border-b border-border/40" />
            <div className="pointer-events-none absolute inset-x-0 top-1/2 border-b border-dashed border-border/30" />

            {dailyStats.map((item) => {
              const heightPercent =
                maxAmount > 0
                  ? Math.max(
                      Math.round((item.totalAmount / maxAmount) * 100),
                      item.totalAmount > 0 ? 5 : 0
                    )
                  : 0;
              const isPeak =
                item.totalAmount > 0 && item.totalAmount === maxAmount;
              const isToday = isTodayInMonth(month, item.day);
              const hasWork = item.totalAmount > 0;

              return (
                <Tooltip key={item.day}>
                  <TooltipTrigger
                    render={
                      <button
                        type="button"
                        className="group/bar relative flex h-full min-w-0 flex-1 flex-col items-center justify-end outline-none focus-visible:ring-1 focus-visible:ring-ring"
                        aria-label={`${item.day} число: ${formatCurrency(item.totalAmount)}`}
                      />
                    }
                  >
                    {/* Bar track container */}
                    <div className="flex h-full w-full min-w-0 flex-1 flex-col items-center justify-end rounded-t-sm bg-muted/20 p-0.5 transition-colors group-hover/bar:bg-muted/50">
                      {hasWork ? (
                        <div
                          className={cn(
                            "w-full max-w-3.5 rounded-t-sm transition-all duration-300 sm:max-w-4.5",
                            isPeak
                              ? "bg-foreground shadow-xs"
                              : "bg-primary/80 group-hover/bar:bg-primary"
                          )}
                          style={{ height: `${heightPercent}%` }}
                        />
                      ) : (
                        <div className="h-0.5 w-1 rounded-full bg-border" />
                      )}
                    </div>

                    {/* Day number */}
                    <div className="mt-1.5 flex h-4 items-center justify-center">
                      <span
                        className={cn(
                          "tabular-nums text-[10px] leading-none transition-colors",
                          isToday
                            ? "flex size-4 items-center justify-center rounded-full bg-primary font-bold text-primary-foreground"
                            : hasWork
                              ? "font-medium text-foreground"
                              : "text-muted-foreground/60"
                        )}
                      >
                        {item.day}
                      </span>
                    </div>
                  </TooltipTrigger>

                  <TooltipContent
                    side="top"
                    arrow={false}
                    className="w-64 max-w-xs flex-col items-stretch gap-2 rounded-xl border border-border bg-popover p-3 text-popover-foreground shadow-float"
                  >
                    <div className="flex items-center justify-between gap-2 border-b border-border/70 pb-1.5">
                      <p className="text-xs font-semibold capitalize text-foreground">
                        {formatDayFullRu(item.dateStr)}
                      </p>
                      {isToday ? (
                        <Badge
                          variant="secondary"
                          className="h-4 px-1.5 text-[10px]"
                        >
                          Сегодня
                        </Badge>
                      ) : isPeak ? (
                        <Badge
                          variant="default"
                          className="h-4 px-1.5 text-[10px]"
                        >
                          Пик
                        </Badge>
                      ) : null}
                    </div>

                    {hasWork ? (
                      <div className="flex flex-col gap-1.5">
                        <div className="flex items-baseline justify-between gap-3">
                          <span className="text-xs text-muted-foreground">
                            Выработка:
                          </span>
                          <span className="font-heading text-sm font-semibold tabular-nums text-foreground">
                            {formatCurrency(item.totalAmount)}
                          </span>
                        </div>

                        {item.subAmount > 0 ? (
                          <div className="flex items-center justify-between gap-3 text-[11px] text-muted-foreground">
                            <span>Свои силы / Подряд:</span>
                            <span className="tabular-nums font-medium text-foreground">
                              {formatCurrency(item.ownAmount)} /{" "}
                              {formatCurrency(item.subAmount)}
                            </span>
                          </div>
                        ) : null}

                        <div className="flex items-center justify-between gap-3 text-[11px] text-muted-foreground">
                          <span>Смен:</span>
                          <span className="tabular-nums font-medium text-foreground">
                            {item.worksCount}
                            {item.openCount > 0 ? (
                              <span className="font-normal text-success">
                                {" "}
                                ({item.openCount} в работе)
                              </span>
                            ) : null}
                          </span>
                        </div>

                        {item.employeesCount > 0 ? (
                          <div className="flex items-center justify-between gap-3 text-[11px] text-muted-foreground">
                            <span>Специалистов:</span>
                            <span className="tabular-nums font-medium text-foreground">
                              {item.employeesCount} чел.
                            </span>
                          </div>
                        ) : null}

                        {item.objectNames.length > 0 ? (
                          <div className="border-t border-border/50 pt-1.5 text-[11px] text-muted-foreground">
                            <span className="line-clamp-2 text-foreground/80">
                              {item.objectNames.join(", ")}
                            </span>
                          </div>
                        ) : null}
                      </div>
                    ) : (
                      <p className="text-xs text-muted-foreground">
                        Нет смен в этот день
                      </p>
                    )}
                  </TooltipContent>
                </Tooltip>
              );
            })}
          </div>
        </div>
      )}
    </div>
  );
}
