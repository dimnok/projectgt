"use client";

import { useMemo, useRef, type MouseEvent, type TouchEvent } from "react";
import { ChevronLeftIcon, ChevronRightIcon } from "lucide-react";
import { ru } from "react-day-picker/locale";

import { Button } from "@/components/ui/button";
import { Calendar, CalendarDayButton } from "@/components/ui/calendar";
import {
  Collapsible,
  CollapsibleContent,
} from "@/components/ui/collapsible";
import {
  defaultDayInMonth,
  formatMonthYear,
  monthStartDate,
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

const PANEL_CLASS =
  "h-[var(--collapsible-panel-height)] overflow-hidden transition-[height] duration-500 ease-[cubic-bezier(0.22,1,0.36,1)] motion-reduce:transition-none data-ending-style:h-0 data-starting-style:h-0 [&[hidden]:not([hidden='until-found'])]:hidden";
const PAN_PX = 36;
const WEEKDAY_LABELS = ["Пн", "Вт", "Ср", "Чт", "Пт", "Сб", "Вс"];

function weekDateKeys(selectedDate: string): string[] {
  const date = parseLocalDate(selectedDate);
  const day = date.getDay();
  const offset = day === 0 ? -6 : 1 - day;
  const monday = new Date(date.getFullYear(), date.getMonth(), date.getDate() + offset);
  return Array.from({ length: 7 }, (_, index) => {
    const next = new Date(monday);
    next.setDate(monday.getDate() + index);
    return toDateKey(next);
  });
}

function shiftWeek(selectedDate: string, weeks: number): string {
  const date = parseLocalDate(selectedDate);
  date.setDate(date.getDate() + weeks * 7);
  return toDateKey(date);
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
  const monthDate = monthStartDate(month);
  const selected = parseLocalDate(selectedDate);
  const today = toDateKey(new Date());
  const hasShiftSet = useMemo(() => new Set(shiftDates), [shiftDates]);
  const weekDates = useMemo(() => weekDateKeys(selectedDate), [selectedDate]);
  const panStartRef = useRef<{ x: number; y: number } | null>(null);
  const skipClickRef = useRef(false);

  function goToday() {
    onMonthChange(toMonthKey(today));
    onSelectDate(today);
  }

  function handleNav(direction: -1 | 1) {
    const next = shiftMonthKey(month, direction);
    onMonthChange(next);
    onSelectDate(defaultDayInMonth(next));
  }

  function handleSelectDate(date: string) {
    onSelectDate(date);
    onMonthChange(date.slice(0, 7));
  }

  function handlePanStart(event: TouchEvent<HTMLDivElement>) {
    const target = event.target;
    if (target instanceof Element && target.closest("[data-cal-nav]")) {
      panStartRef.current = null;
      return;
    }
    const touch = event.touches[0];
    panStartRef.current = touch
      ? { x: touch.clientX, y: touch.clientY }
      : null;
  }

  function handlePanEnd(event: TouchEvent<HTMLDivElement>) {
    const start = panStartRef.current;
    panStartRef.current = null;
    if (!start) {
      return;
    }
    const end = event.changedTouches[0];
    if (!end) {
      return;
    }
    const dx = end.clientX - start.x;
    const dy = end.clientY - start.y;
    const absX = Math.abs(dx);
    const absY = Math.abs(dy);

    if (!open && absX >= PAN_PX && absX > absY) {
      skipClickRef.current = true;
      handleSelectDate(shiftWeek(selectedDate, dx < 0 ? 1 : -1));
      return;
    }
    if (open && dy <= -PAN_PX && absY > absX) {
      onOpenChange(false);
      return;
    }
    if (!open && dy >= PAN_PX && absY > absX) {
      onOpenChange(true);
    }
  }

  function handleClickCapture(event: MouseEvent<HTMLDivElement>) {
    if (!skipClickRef.current) {
      return;
    }
    skipClickRef.current = false;
    event.preventDefault();
    event.stopPropagation();
  }

  return (
    <div
      className={cn(
        "flex flex-col bg-background px-4 [--cell-radius:var(--radius-md)]",
        open ? "pt-2" : "pt-1"
      )}
      onTouchStart={handlePanStart}
      onTouchEnd={handlePanEnd}
      onClickCapture={handleClickCapture}
    >
      {open ? (
        <div className="flex h-9 items-center gap-2">
          <p className="min-w-0 flex-1 truncate font-heading text-sm font-semibold tracking-tight">
            {formatMonthYear(month)}
          </p>
          <div className="flex shrink-0 items-center gap-1" data-cal-nav>
            <Button
              type="button"
              variant="outline"
              size="icon-sm"
              aria-label="Предыдущий месяц"
              onClick={() => handleNav(-1)}
            >
              <ChevronLeftIcon />
            </Button>
            <Button
              type="button"
              variant="ghost"
              size="sm"
              onClick={goToday}
              className="px-2 text-xs"
            >
              Сегодня
            </Button>
            <Button
              type="button"
              variant="outline"
              size="icon-sm"
              aria-label="Следующий месяц"
              onClick={() => handleNav(1)}
            >
              <ChevronRightIcon />
            </Button>
          </div>
        </div>
      ) : null}

      <div className={cn("grid grid-cols-7 px-px", open ? "mt-1" : "mt-0")}>
        {WEEKDAY_LABELS.map((label, index) => (
          <span
            key={label}
            className={cn(
              "text-center",
              index >= 5 ? "text-destructive" : "text-muted-foreground",
              open ? "text-[0.8rem]" : "text-[0.65rem] leading-none"
            )}
          >
            {label}
          </span>
        ))}
      </div>

      <div className="grid overflow-hidden">
        <div
          className={cn(
            "min-w-0 self-start [grid-area:1/1]",
            open ? "invisible pointer-events-none" : "relative z-10"
          )}
          aria-hidden={open}
        >
          <div className="grid grid-cols-7 px-px">
            {weekDates.map((date) => {
              const inMonth = date.slice(0, 7) === month;
              const hasShift = hasShiftSet.has(date);
              const isSelected = date === selectedDate;
              const isToday = date === today;
              return (
                <button
                  key={date}
                  type="button"
                  aria-pressed={isSelected}
                  onClick={() => handleSelectDate(date)}
                  className="flex h-8 w-full items-center justify-center"
                >
                  <span
                    className={cn(
                      "relative flex size-8 items-center justify-center rounded-full text-sm",
                      !inMonth && "text-muted-foreground",
                      isSelected && "ring-1 ring-inset ring-foreground/70",
                      isToday && !isSelected && "font-medium"
                    )}
                  >
                    {Number(date.slice(8, 10))}
                    {hasShift ? (
                      <span className="absolute bottom-0.5 left-1/2 size-1 -translate-x-1/2 rounded-full bg-foreground" />
                    ) : null}
                  </span>
                </button>
              );
            })}
          </div>
        </div>

        <Collapsible
          open={open}
          className={cn(
            "min-w-0 self-start [grid-area:1/1]",
            open ? "relative z-10" : "pointer-events-none"
          )}
        >
          <CollapsibleContent className={PANEL_CLASS}>
            <Calendar
              mode="single"
              required
              locale={ru}
              weekStartsOn={1}
              showOutsideDays={false}
              hideNavigation
              hideWeekdays
              month={monthDate}
              onMonthChange={(next) => {
                const key = toMonthKey(toDateKey(next));
                onMonthChange(key);
                onSelectDate(defaultDayInMonth(key));
              }}
              selected={selected}
              onSelect={(next) => {
                if (!next) {
                  return;
                }
                handleSelectDate(toDateKey(next));
              }}
              modifiers={{
                hasShift: shiftDates.map((date) => parseLocalDate(date)),
              }}
              className={cn(
                "w-full bg-transparent p-0 [--cell-size:--spacing(7)]",
                "[&_button[data-selected-single=true]]:bg-transparent [&_button[data-selected-single=true]]:text-foreground [&_button[data-selected-single=true]]:ring-1 [&_button[data-selected-single=true]]:ring-inset [&_button[data-selected-single=true]]:ring-foreground/70"
              )}
              classNames={{
                month_caption: "hidden",
                nav: "hidden",
                month: "flex w-full flex-col gap-1",
                today: "bg-transparent",
                week: "mt-0.5 flex w-full px-px",
              }}
              components={{
                MonthCaption: () => <></>,
                Nav: () => <></>,
                DayButton: (props) => {
                  const key = toDateKey(props.day.date);
                  const hasShift = hasShiftSet.has(key);
                  return (
                    <CalendarDayButton
                      locale={ru}
                      {...props}
                      className={cn(
                        "rounded-(--cell-radius)",
                        hasShift &&
                          "after:absolute after:bottom-0.5 after:left-1/2 after:size-1 after:-translate-x-1/2 after:rounded-full after:bg-foreground"
                      )}
                    />
                  );
                },
              }}
            />
          </CollapsibleContent>
        </Collapsible>
      </div>

      <button
        type="button"
        aria-expanded={open}
        aria-label={open ? "Свернуть календарь" : "Развернуть календарь"}
        onClick={() => onOpenChange(!open)}
        className={cn(
          "flex w-full items-center justify-center",
          open ? "min-h-8" : "min-h-5"
        )}
      >
        <span className="h-1.5 w-12 rounded-full bg-muted-foreground/40" />
      </button>
    </div>
  );
}
