"use client";

import { ChevronDownIcon } from "lucide-react";

import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import {
  DropdownMenu,
  DropdownMenuCheckboxItem,
  DropdownMenuContent,
  DropdownMenuGroup,
  DropdownMenuLabel,
  DropdownMenuSeparator,
  DropdownMenuTrigger,
} from "@/components/ui/dropdown-menu";
import type {
  TimesheetEmployeeListScope,
  TimesheetOpenShiftFilterScope,
} from "@/features/timesheet/types/timesheet.types";

type TimesheetScopeDropdownProps = {
  listScope: TimesheetEmployeeListScope;
  openShiftScope: TimesheetOpenShiftFilterScope;
  periodContainsToday: boolean;
  onListScopeChange: (scope: TimesheetEmployeeListScope) => void;
  onOpenShiftScopeChange: (scope: TimesheetOpenShiftFilterScope) => void;
  disabled?: boolean;
};

export function TimesheetScopeDropdown({
  listScope,
  openShiftScope,
  periodContainsToday,
  onListScopeChange,
  onOpenShiftScopeChange,
  disabled = false,
}: TimesheetScopeDropdownProps) {
  const isFiltered =
    listScope !== "all" || (periodContainsToday && openShiftScope !== "all");

  const getTriggerLabel = () => {
    if (periodContainsToday && openShiftScope === "inOpenShift") {
      return "В смене";
    }
    if (periodContainsToday && openShiftScope === "notInOpenShift") {
      return "Не в смене";
    }
    if (listScope === "withHours") {
      return "С часами";
    }
    if (listScope === "withoutHours") {
      return "Без часов";
    }
    return "Состав";
  };

  return (
    <DropdownMenu>
      <DropdownMenuTrigger
        render={
          <Button
            type="button"
            variant="outline"
            size="sm"
            disabled={disabled}
            className="h-9 rounded-xl border-border/70 bg-card px-3 text-xs sm:text-[13px] font-medium hover:bg-muted/30 transition-colors shadow-2xs"
          />
        }
      >
        <span>{getTriggerLabel()}</span>
        {isFiltered ? (
          <Badge
            variant="secondary"
            className="h-5 px-1.5 rounded-full text-[11px] font-semibold"
          >
            ✓
          </Badge>
        ) : null}
        <ChevronDownIcon data-icon="inline-end" className="size-3.5 opacity-60" />
      </DropdownMenuTrigger>

      <DropdownMenuContent
        className="min-w-56 rounded-xl p-1 shadow-md border-border/70"
        align="start"
      >
        <DropdownMenuGroup>
          <DropdownMenuLabel className="px-2 py-1 text-[11px] font-semibold text-muted-foreground uppercase tracking-wider">
            Часы за период
          </DropdownMenuLabel>
          <DropdownMenuCheckboxItem
            checked={listScope === "all"}
            className="text-xs sm:text-[13px] py-1.5 rounded-lg"
            onCheckedChange={() => onListScopeChange("all")}
          >
            Все сотрудники
          </DropdownMenuCheckboxItem>
          <DropdownMenuCheckboxItem
            checked={listScope === "withHours"}
            className="text-xs sm:text-[13px] py-1.5 rounded-lg"
            onCheckedChange={() => onListScopeChange("withHours")}
          >
            С часами
          </DropdownMenuCheckboxItem>
          <DropdownMenuCheckboxItem
            checked={listScope === "withoutHours"}
            className="text-xs sm:text-[13px] py-1.5 rounded-lg"
            onCheckedChange={() => onListScopeChange("withoutHours")}
          >
            Без часов
          </DropdownMenuCheckboxItem>
        </DropdownMenuGroup>

        {periodContainsToday ? (
          <>
            <DropdownMenuSeparator className="my-1 border-border/60" />
            <DropdownMenuGroup>
              <DropdownMenuLabel className="px-2 py-1 text-[11px] font-semibold text-muted-foreground uppercase tracking-wider">
                Смена сегодня
              </DropdownMenuLabel>
              <DropdownMenuCheckboxItem
                checked={openShiftScope === "all"}
                className="text-xs sm:text-[13px] py-1.5 rounded-lg"
                onCheckedChange={() => onOpenShiftScopeChange("all")}
              >
                Все
              </DropdownMenuCheckboxItem>
              <DropdownMenuCheckboxItem
                checked={openShiftScope === "inOpenShift"}
                className="text-xs sm:text-[13px] py-1.5 rounded-lg"
                onCheckedChange={() => onOpenShiftScopeChange("inOpenShift")}
              >
                В открытой смене сегодня
              </DropdownMenuCheckboxItem>
              <DropdownMenuCheckboxItem
                checked={openShiftScope === "notInOpenShift"}
                className="text-xs sm:text-[13px] py-1.5 rounded-lg"
                onCheckedChange={() => onOpenShiftScopeChange("notInOpenShift")}
              >
                Не в смене сегодня
              </DropdownMenuCheckboxItem>
            </DropdownMenuGroup>
          </>
        ) : null}
      </DropdownMenuContent>
    </DropdownMenu>
  );
}
