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
  badgeClass?: string;
};

type TimesheetMultiSelectProps = {
  title: string;
  placeholder?: string;
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
            className="h-9 rounded-lg bg-card px-3 text-xs sm:text-sm hover:bg-muted/40"
          />
        }
      >
        <span>{title}</span>
        {selectedKeys.length > 0 ? (
          <Badge variant="secondary">{selectedKeys.length}</Badge>
        ) : null}
        <ChevronDownIcon data-icon="inline-end" />
      </DropdownMenuTrigger>
      <DropdownMenuContent className="min-w-56 max-h-72 overflow-y-auto" align="start">
        <DropdownMenuGroup>
          {options.map((option) => (
            <DropdownMenuCheckboxItem
              key={option.key}
              checked={selectedKeys.includes(option.key)}
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
