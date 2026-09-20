"use client";

import { ChevronLeftIcon, ChevronRightIcon } from "lucide-react";

import { Button } from "@/components/ui/button";
import { cn } from "@/lib/utils";

const PAYROLL_CONTROL =
  "h-9 rounded-lg border border-input bg-card px-3 text-xs hover:bg-muted/40 sm:text-sm";

type PayrollPeriodSwitcherProps = {
  monthLabel: string;
  isCurrentMonth: boolean;
  onPrevMonth: () => void;
  onNextMonth: () => void;
  /** Режим «всё время»: доступен только на вкладках-списках. */
  allTime?: boolean;
  onAllTimeChange?: (value: boolean) => void;
  disabled?: boolean;
};

/**
 * Период одним контролом: месяц стрелками и, для списков, режим «Всё время».
 * Так выпадающие фильтры стоят сразу после периода на всех вкладках.
 */
export function PayrollPeriodSwitcher({
  monthLabel,
  isCurrentMonth,
  onPrevMonth,
  onNextMonth,
  allTime = false,
  onAllTimeChange,
  disabled = false,
}: PayrollPeriodSwitcherProps) {
  const monthDisabled = disabled || allTime;

  return (
    <div className={cn(PAYROLL_CONTROL, "flex w-fit items-center gap-1 p-0.5")}>
      <Button
        type="button"
        variant="ghost"
        size="icon"
        onClick={onPrevMonth}
        disabled={monthDisabled}
        className="size-7 rounded-md text-muted-foreground hover:text-foreground"
        title="Предыдущий месяц"
        aria-label="Предыдущий месяц"
      >
        <ChevronLeftIcon className="size-4" />
      </Button>

      <span
        className={cn(
          "min-w-28 text-center text-xs font-semibold capitalize tracking-tight sm:text-sm",
          allTime ? "text-muted-foreground" : "text-foreground"
        )}
      >
        {monthLabel}
      </span>

      <Button
        type="button"
        variant="ghost"
        size="icon"
        onClick={onNextMonth}
        disabled={monthDisabled || isCurrentMonth}
        className="size-7 rounded-md text-muted-foreground hover:text-foreground"
        title="Следующий месяц"
        aria-label="Следующий месяц"
      >
        <ChevronRightIcon className="size-4" />
      </Button>

      {onAllTimeChange ? (
        <>
          <span className="mx-0.5 h-5 w-px shrink-0 bg-border" aria-hidden />
          <Button
            type="button"
            variant="ghost"
            size="sm"
            disabled={disabled}
            aria-pressed={allTime}
            onClick={() => onAllTimeChange(!allTime)}
            className={cn(
              "h-8 rounded-md px-2.5 text-xs font-semibold sm:text-[13px]",
              allTime
                ? "bg-primary text-primary-foreground hover:bg-primary/90"
                : "text-muted-foreground hover:text-foreground"
            )}
            title="Показать записи за всё время"
          >
            Всё время
          </Button>
        </>
      ) : null}
    </div>
  );
}
