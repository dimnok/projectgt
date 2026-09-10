"use client";

import { ChevronLeftIcon, ChevronRightIcon } from "lucide-react";
import { ru } from "react-day-picker/locale";

import { Button } from "@/components/ui/button";
import { Calendar, CalendarDayButton } from "@/components/ui/calendar";
import { Card, CardContent } from "@/components/ui/card";
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

type WorksCalendarProps = {
  month: string;
  selectedDate: string;
  shiftDates: string[];
  onMonthChange: (month: string) => void;
  onSelectDate: (date: string) => void;
  compact?: boolean;
};

export function WorksCalendar({
  month,
  selectedDate,
  shiftDates,
  onMonthChange,
  onSelectDate,
  compact = false,
}: WorksCalendarProps) {
  const monthDate = monthStartDate(month);
  const selected = parseLocalDate(selectedDate);
  const today = toDateKey(new Date());
  const hasShiftSet = new Set(shiftDates);

  function goToday() {
    const current = toMonthKey(today);
    onMonthChange(current);
    onSelectDate(today);
  }

  return (
    <Card size={compact ? "sm" : "default"} className="overflow-visible shadow-float">
      <CardContent className={cn("flex flex-col", compact ? "gap-1.5" : "gap-3")}>
        <div className="flex items-center justify-between gap-2">
          <p
            className={cn(
              "font-heading font-semibold tracking-tight",
              compact ? "text-sm" : "text-base"
            )}
          >
            {formatMonthYear(month)}
          </p>
          <div className="flex items-center gap-1">
            <Button
              type="button"
              variant="outline"
              size="icon-sm"
              aria-label="Предыдущий месяц"
              onClick={() => {
                const next = shiftMonthKey(month, -1);
                onMonthChange(next);
                onSelectDate(defaultDayInMonth(next));
              }}
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
              onClick={() => {
                const next = shiftMonthKey(month, 1);
                onMonthChange(next);
                onSelectDate(defaultDayInMonth(next));
              }}
            >
              <ChevronRightIcon />
            </Button>
          </div>
        </div>

        <Calendar
          mode="single"
          locale={ru}
          weekStartsOn={1}
          showOutsideDays={false}
          hideNavigation
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
            onSelectDate(toDateKey(next));
          }}
          modifiers={{
            hasShift: shiftDates.map((date) => parseLocalDate(date)),
          }}
          formatters={{
            formatWeekdayName: (date) =>
              date
                .toLocaleDateString("ru-RU", { weekday: "short" })
                .replace(".", "")
                .slice(0, 2)
                .replace(/^./, (char) => char.toUpperCase()),
          }}
          className={cn(
            "w-full bg-transparent p-0",
            compact ? "[--cell-size:--spacing(7)]" : "[--cell-size:--spacing(8)]",
            "[&_button[data-selected-single=true]]:bg-transparent [&_button[data-selected-single=true]]:text-foreground [&_button[data-selected-single=true]]:ring-1 [&_button[data-selected-single=true]]:ring-foreground/70"
          )}
          classNames={{
            month_caption: "hidden",
            nav: "hidden",
            month: cn("flex w-full flex-col", compact ? "gap-1" : "gap-2"),
            today: "bg-transparent",
            ...(compact ? { week: "mt-0.5 flex w-full" } : {}),
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
                    hasShift &&
                      (compact
                        ? "after:absolute after:bottom-0.5 after:left-1/2 after:size-1 after:-translate-x-1/2 after:rounded-full after:bg-foreground"
                        : "after:absolute after:bottom-1 after:left-1/2 after:size-1 after:-translate-x-1/2 after:rounded-full after:bg-foreground")
                  )}
                />
              );
            },
          }}
        />
      </CardContent>
    </Card>
  );
}
