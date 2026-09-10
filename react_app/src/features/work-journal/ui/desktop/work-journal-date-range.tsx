"use client";

import { useState } from "react";
import { CalendarIcon } from "lucide-react";
import { isSameDay } from "date-fns";
import { ru } from "date-fns/locale";
import type { DateRange } from "react-day-picker";

import { Button } from "@/components/ui/button";
import { Calendar } from "@/components/ui/calendar";
import {
  Popover,
  PopoverContent,
  PopoverTrigger,
} from "@/components/ui/popover";
import type { WorkJournalDateRange } from "@/features/work-journal/types/work-journal.types";
import {
  dateRangeToPicker,
  formatDateRangeLabel,
  pickerToDateRange,
} from "@/features/work-journal/utils/work-journal.utils";
import { cn } from "@/lib/utils";

type WorkJournalDateRangePickerProps = {
  value: WorkJournalDateRange | null;
  onChange: (value: WorkJournalDateRange | null) => void;
  size?: "icon-sm" | "icon-lg";
};

export function WorkJournalDateRangePicker({
  value,
  onChange,
  size = "icon-sm",
}: WorkJournalDateRangePickerProps) {
  const [open, setOpen] = useState(false);
  const [draft, setDraft] = useState<DateRange | undefined>(
    dateRangeToPicker(value)
  );

  function commitRange(range: DateRange | undefined) {
    const complete = pickerToDateRange(
      range?.from
        ? { from: range.from, to: range.to ?? range.from }
        : undefined
    );
    if (complete) {
      onChange(complete);
    }
  }

  function handleOpenChange(next: boolean) {
    if (!next && draft?.from) {
      commitRange(draft);
    }

    setOpen(next);
    if (next) {
      setDraft(dateRangeToPicker(value));
    }
  }

  function handleSelect(next: DateRange | undefined) {
    setDraft(next);

    if (!next?.from || !next.to) {
      return;
    }

    if (isSameDay(next.from, next.to)) {
      return;
    }

    commitRange(next);
    setOpen(false);
  }

  const label = value ? formatDateRangeLabel(value) : "Выбрать период";

  return (
    <Popover open={open} onOpenChange={handleOpenChange}>
      <PopoverTrigger
        render={
          <Button
            type="button"
            variant="outline"
            size={size}
            className={cn(
              "bg-card hover:bg-muted/40",
              value && "border-primary bg-primary/10 text-foreground"
            )}
            aria-label={label}
            title={label}
          />
        }
      >
        <CalendarIcon />
      </PopoverTrigger>
      <PopoverContent
        side="bottom"
        align="end"
        className="w-fit p-2 sm:w-fit"
      >
          <Calendar
            mode="range"
            locale={ru}
            numberOfMonths={2}
            selected={draft}
            onSelect={handleSelect}
            defaultMonth={draft?.from ?? dateRangeToPicker(value)?.from}
          />
          {value || draft?.from ? (
            <div className="flex justify-end border-t border-border/80 pt-2">
              <Button
                type="button"
                variant="ghost"
                size="sm"
                onClick={() => {
                  setDraft(undefined);
                  onChange(null);
                  setOpen(false);
                }}
              >
                Сбросить период
              </Button>
            </div>
          ) : null}
        </PopoverContent>
    </Popover>
  );
}
