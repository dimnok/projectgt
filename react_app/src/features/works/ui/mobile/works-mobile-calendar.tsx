"use client";

import {
  useCallback,
  useMemo,
  useRef,
  type TouchEvent,
} from "react";
import {
  ChevronDownIcon,
  ChevronLeftIcon,
  ChevronRightIcon,
} from "lucide-react";

import { Button } from "@/components/ui/button";
import {
  defaultDayInMonth,
  formatMonthYear,
  parseLocalDate,
  shiftMonthKey,
  toDateKey,
  toMonthKey,
} from "@/features/works/utils/work.utils";
import { cn } from "@/lib/utils";

type WorksMobileCalendarProps = {
  month: string;
  selectedDate: string;
  shiftDates: string[];
  open: boolean;
  onOpenChange: (open: boolean) => void;
  onMonthChange: (month: string) => void;
  onSelectDate: (date: string) => void;
};

const ROW_HEIGHT = 40;
const ROW_GAP = 4;
const ROW_STEP = ROW_HEIGHT + ROW_GAP;
const WEEKDAY_LABELS = ["Пн", "Вт", "Ср", "Чт", "Пт", "Сб", "Вс"] as const;

function shiftDateByDays(dateKey: string, days: number): string {
  const date = parseLocalDate(dateKey);
  date.setDate(date.getDate() + days);
  return toDateKey(date);
}

function getMonthWeeks(monthKey: string): string[][] {
  const [year, monthIndex] = monthKey.split("-").map(Number);
  const firstDay = new Date(year, monthIndex - 1, 1);
  const dayOfWeek = firstDay.getDay(); // 0 is Sun, 1 is Mon, ..., 6 is Sat
  const mondayOffset = dayOfWeek === 0 ? -6 : 1 - dayOfWeek;

  const current = new Date(year, monthIndex - 1, 1 + mondayOffset);
  const weeks: string[][] = [];

  for (let w = 0; w < 6; w++) {
    const week: string[] = [];
    let hasDayInMonth = false;
    for (let d = 0; d < 7; d++) {
      const key = toDateKey(current);
      if (key.slice(0, 7) === monthKey) {
        hasDayInMonth = true;
      }
      week.push(key);
      current.setDate(current.getDate() + 1);
    }
    if (hasDayInMonth || weeks.length === 0) {
      weeks.push(week);
    } else {
      break;
    }
  }

  return weeks;
}

type CalendarDayCellProps = {
  date: string;
  month: string;
  selectedDate: string;
  today: string;
  hasShift: boolean;
  onSelectDate: (date: string) => void;
};

function CalendarDayCell({
  date,
  month,
  selectedDate,
  today,
  hasShift,
  onSelectDate,
}: CalendarDayCellProps) {
  const inMonth = date.slice(0, 7) === month;
  const isSelected = date === selectedDate;
  const isToday = date === today;
  const dayNum = Number(date.slice(8, 10));

  return (
    <button
      type="button"
      onClick={() => onSelectDate(date)}
      aria-label={date}
      aria-pressed={isSelected}
      className="group relative flex h-10 w-full items-center justify-center p-0.5 outline-hidden"
    >
      <span
        className={cn(
          "relative flex size-9 items-center justify-center rounded-xl text-sm transition-all duration-150",
          isSelected
            ? "bg-primary text-primary-foreground font-semibold shadow-xs scale-100"
            : isToday
              ? "ring-1 ring-primary/40 font-semibold text-foreground"
              : inMonth
                ? "font-medium text-foreground hover:bg-muted/60 active:scale-95"
                : "text-muted-foreground/35 hover:text-muted-foreground/60 active:scale-95"
        )}
      >
        <span>{dayNum}</span>
        {hasShift ? (
          <span
            className={cn(
              "absolute bottom-1 left-1/2 size-1 -translate-x-1/2 rounded-full",
              isSelected ? "bg-primary-foreground" : "bg-foreground"
            )}
          />
        ) : null}
      </span>
    </button>
  );
}

export function WorksMobileCalendar({
  month,
  selectedDate,
  shiftDates,
  open,
  onOpenChange,
  onMonthChange,
  onSelectDate,
}: WorksMobileCalendarProps) {
  const today = toDateKey(new Date());
  const hasShiftSet = useMemo(() => new Set(shiftDates), [shiftDates]);
  const weeks = useMemo(() => getMonthWeeks(month), [month]);

  const activeWeekIndex = useMemo(() => {
    const index = weeks.findIndex((week) => week.includes(selectedDate));
    if (index !== -1) {
      return index;
    }
    const fallback = defaultDayInMonth(month);
    const fallbackIndex = weeks.findIndex((week) => week.includes(fallback));
    return fallbackIndex !== -1 ? fallbackIndex : 0;
  }, [weeks, selectedDate, month]);

  const touchStartRef = useRef<{
    x: number;
    y: number;
    time: number;
  } | null>(null);

  const handleDateSelect = useCallback(
    (date: string) => {
      onSelectDate(date);
      const dateMonth = date.slice(0, 7);
      if (dateMonth !== month) {
        onMonthChange(dateMonth);
      }
    },
    [month, onMonthChange, onSelectDate]
  );

  const handlePrev = useCallback(() => {
    if (open) {
      const nextMonth = shiftMonthKey(month, -1);
      onMonthChange(nextMonth);
      onSelectDate(defaultDayInMonth(nextMonth));
    } else {
      const prevDate = shiftDateByDays(selectedDate, -7);
      const dateMonth = prevDate.slice(0, 7);
      if (dateMonth !== month) {
        onMonthChange(dateMonth);
      }
      onSelectDate(prevDate);
    }
  }, [month, open, onMonthChange, onSelectDate, selectedDate]);

  const handleNext = useCallback(() => {
    if (open) {
      const nextMonth = shiftMonthKey(month, 1);
      onMonthChange(nextMonth);
      onSelectDate(defaultDayInMonth(nextMonth));
    } else {
      const nextDate = shiftDateByDays(selectedDate, 7);
      const dateMonth = nextDate.slice(0, 7);
      if (dateMonth !== month) {
        onMonthChange(dateMonth);
      }
      onSelectDate(nextDate);
    }
  }, [month, open, onMonthChange, onSelectDate, selectedDate]);

  const handleGoToday = useCallback(() => {
    const todayKey = toDateKey(new Date());
    const todayMonth = toMonthKey(todayKey);
    if (todayMonth !== month) {
      onMonthChange(todayMonth);
    }
    onSelectDate(todayKey);
  }, [month, onMonthChange, onSelectDate]);

  function handleTouchStart(e: TouchEvent<HTMLDivElement>) {
    if (e.touches.length !== 1) {
      return;
    }
    touchStartRef.current = {
      x: e.touches[0].clientX,
      y: e.touches[0].clientY,
      time: Date.now(),
    };
  }

  function handleTouchEnd(e: TouchEvent<HTMLDivElement>) {
    const start = touchStartRef.current;
    touchStartRef.current = null;
    if (!start || e.changedTouches.length !== 1) {
      return;
    }

    const touch = e.changedTouches[0];
    const dx = touch.clientX - start.x;
    const dy = touch.clientY - start.y;
    const absX = Math.abs(dx);
    const absY = Math.abs(dy);
    const elapsed = Date.now() - start.time;

    // Reject slow drags or tiny movements
    if (elapsed > 600 || Math.max(absX, absY) < 36) {
      return;
    }

    // Vertical gestures (swipe up to collapse, swipe down to expand)
    if (absY > absX * 1.2) {
      if (dy < -36 && open) {
        onOpenChange(false);
      } else if (dy > 36 && !open) {
        onOpenChange(true);
      }
      return;
    }

    // Horizontal gestures (swipe left for next, swipe right for prev)
    if (absX > absY * 1.2) {
      if (dx < -36) {
        handleNext();
      } else if (dx > 36) {
        handlePrev();
      }
    }
  }

  const containerHeight = open ? weeks.length * ROW_STEP - ROW_GAP : ROW_HEIGHT;

  return (
    <div
      className="flex flex-col bg-background select-none px-3 pt-1 pb-0.5"
      onTouchStart={handleTouchStart}
      onTouchEnd={handleTouchEnd}
    >
      {/* Header bar: Month title & toggle on left, navigation controls on right */}
      <div className="flex h-10 items-center justify-between px-1">
        <button
          type="button"
          onClick={() => onOpenChange(!open)}
          className="group flex items-center gap-1.5 rounded-lg py-1 px-1.5 -ml-1 text-foreground hover:bg-muted/50 active:scale-98 transition-all"
          aria-expanded={open}
          aria-label={open ? "Свернуть календарь" : "Развернуть календарь"}
        >
          <span className="font-heading text-base font-semibold tracking-tight">
            {formatMonthYear(month)}
          </span>
          <ChevronDownIcon
            className={cn(
              "size-4 text-muted-foreground transition-transform duration-200",
              open && "rotate-180"
            )}
          />
        </button>

        <div className="flex items-center gap-0.5">
          <Button
            type="button"
            variant="ghost"
            size="icon-sm"
            className="size-7 rounded-lg text-muted-foreground hover:text-foreground"
            aria-label={open ? "Предыдущий месяц" : "Предыдущая неделя"}
            onClick={handlePrev}
          >
            <ChevronLeftIcon className="size-4" />
          </Button>
          <Button
            type="button"
            variant="ghost"
            size="sm"
            className="h-7 px-2 text-xs font-medium rounded-lg text-muted-foreground hover:text-foreground"
            onClick={handleGoToday}
          >
            Сегодня
          </Button>
          <Button
            type="button"
            variant="ghost"
            size="icon-sm"
            className="size-7 rounded-lg text-muted-foreground hover:text-foreground"
            aria-label={open ? "Следующий месяц" : "Следующая неделя"}
            onClick={handleNext}
          >
            <ChevronRightIcon className="size-4" />
          </Button>
        </div>
      </div>

      {/* Weekday labels row: Stationary, aligned with day columns */}
      <div className="grid grid-cols-7 text-center">
        {WEEKDAY_LABELS.map((label, idx) => (
          <span
            key={label}
            className={cn(
              "text-[0.72rem] font-medium leading-6 select-none",
              idx >= 5 ? "text-muted-foreground/75" : "text-muted-foreground"
            )}
          >
            {label}
          </span>
        ))}
      </div>

      {/* Accordion Days Grid: Smooth GPU-accelerated transition */}
      <div
        className="relative overflow-hidden transition-[height] duration-[260ms] ease-[cubic-bezier(0.16,1,0.3,1)] motion-reduce:transition-none"
        style={{ height: `${containerHeight}px` }}
      >
        <div className="flex flex-col gap-1">
          {weeks.map((week, index) => {
            const isSelectedWeek = index === activeWeekIndex;

            let translateY = 0;
            let opacity = 1;
            let pointerEvents: "auto" | "none" = "auto";

            if (!open) {
              if (isSelectedWeek) {
                translateY = -activeWeekIndex * ROW_STEP;
                opacity = 1;
                pointerEvents = "auto";
              } else if (index < activeWeekIndex) {
                translateY = -activeWeekIndex * ROW_STEP - 10;
                opacity = 0;
                pointerEvents = "none";
              } else {
                translateY = -activeWeekIndex * ROW_STEP + 10;
                opacity = 0;
                pointerEvents = "none";
              }
            }

            return (
              <div
                key={week[0]}
                className="grid grid-cols-7 transition-[transform,opacity] duration-[260ms] ease-[cubic-bezier(0.16,1,0.3,1)] motion-reduce:transition-none"
                style={{
                  transform: `translate3d(0, ${translateY}px, 0)`,
                  opacity,
                  pointerEvents,
                }}
              >
                {week.map((date) => (
                  <CalendarDayCell
                    key={date}
                    date={date}
                    month={month}
                    selectedDate={selectedDate}
                    today={today}
                    hasShift={hasShiftSet.has(date)}
                    onSelectDate={handleDateSelect}
                  />
                ))}
              </div>
            );
          })}
        </div>
      </div>

      {/* Bottom puller handle */}
      <div className="flex items-center justify-center py-1">
        <button
          type="button"
          aria-expanded={open}
          aria-label={open ? "Свернуть календарь" : "Развернуть календарь"}
          onClick={() => onOpenChange(!open)}
          className="group flex h-4 w-16 items-center justify-center rounded-full hover:bg-muted/40 transition-colors"
        >
          <span
            className={cn(
              "h-1 rounded-full transition-all duration-200",
              open
                ? "w-8 bg-muted-foreground/35 group-hover:bg-muted-foreground/55"
                : "w-10 bg-muted-foreground/25 group-hover:bg-muted-foreground/45"
            )}
          />
        </button>
      </div>
    </div>
  );
}
