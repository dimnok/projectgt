"use client";

import { ChevronDownIcon } from "lucide-react";

import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import {
  DropdownMenu,
  DropdownMenuCheckboxItem,
  DropdownMenuContent,
  DropdownMenuGroup,
  DropdownMenuTrigger,
} from "@/components/ui/dropdown-menu";

export type MultiSelectOption = {
  key: string;
  label: string;
};

type TimesheetMultiSelectProps = {
  title: string;
  options: MultiSelectOption[];
  selectedKeys: string[];
  onChange: (keys: string[]) => void;
  disabled?: boolean;
};

export function TimesheetMultiSelect({
  title,
  options,
  selectedKeys,
  onChange,
  disabled = false,
}: TimesheetMultiSelectProps) {
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
        <span>{title}</span>
        {selectedKeys.length > 0 ? (
          <Badge
            variant="secondary"
            className="h-5 px-1.5 rounded-full text-[11px] font-semibold"
          >
            {selectedKeys.length}
          </Badge>
        ) : null}
        <ChevronDownIcon data-icon="inline-end" className="size-3.5 opacity-60" />
      </DropdownMenuTrigger>
      <DropdownMenuContent
        className="min-w-56 max-h-72 overflow-y-auto rounded-xl p-1 shadow-md border-border/70"
        align="start"
      >
        <DropdownMenuGroup>
          {options.map((option) => (
            <DropdownMenuCheckboxItem
              key={option.key}
              checked={selectedKeys.includes(option.key)}
              className="text-xs sm:text-[13px] py-1.5 rounded-lg"
              onCheckedChange={(checked) => {
                if (checked) {
                  onChange([...selectedKeys, option.key]);
                  return;
                }
                onChange(selectedKeys.filter((k) => k !== option.key));
              }}
            >
              {option.label}
            </DropdownMenuCheckboxItem>
          ))}
        </DropdownMenuGroup>
      </DropdownMenuContent>
    </DropdownMenu>
  );
}
