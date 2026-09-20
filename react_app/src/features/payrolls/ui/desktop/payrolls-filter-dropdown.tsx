"use client";

import { ChevronDownIcon } from "lucide-react";

import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import {
  DropdownMenu,
  DropdownMenuCheckboxItem,
  DropdownMenuContent,
  DropdownMenuGroup,
  DropdownMenuRadioGroup,
  DropdownMenuRadioItem,
  DropdownMenuTrigger,
} from "@/components/ui/dropdown-menu";

type PayrollFilterOption = {
  key: string;
  label: string;
};

type PayrollFilterDropdownProps = {
  title: string;
  options: PayrollFilterOption[];
  selectedKeys: string[];
  onChange: (keys: string[]) => void;
  /** Объекты — выбор нескольких, статус — одного. */
  multiple?: boolean;
  disabled?: boolean;
};

/**
 * Единый выпадающий фильтр вкладки ФОТ: «Объекты» и «Статус» выглядят одинаково.
 * В бейдже — число выбранных объектов или текущий статус.
 */
export function PayrollFilterDropdown({
  title,
  options,
  selectedKeys,
  onChange,
  multiple = false,
  disabled = false,
}: PayrollFilterDropdownProps) {
  const badge = multiple
    ? selectedKeys.length > 0
      ? String(selectedKeys.length)
      : null
    : (options.find((option) => option.key === selectedKeys[0])?.label ??
      options[0]?.label ??
      null);

  return (
    <DropdownMenu>
      <DropdownMenuTrigger
        render={
          <Button
            type="button"
            variant="outline"
            size="sm"
            disabled={disabled}
            className="h-9 rounded-lg border-input bg-card px-3 text-xs font-normal hover:bg-muted/40 sm:text-sm"
          />
        }
      >
        <span>{title}</span>
        {badge ? (
          <Badge
            variant="secondary"
            className="h-5 rounded-full px-1.5 text-[11px] font-semibold"
          >
            {badge}
          </Badge>
        ) : null}
        <ChevronDownIcon data-icon="inline-end" className="size-3.5 opacity-60" />
      </DropdownMenuTrigger>
      <DropdownMenuContent
        className="max-h-72 min-w-56 overflow-y-auto rounded-xl border-border/70 p-1 shadow-md"
        align="start"
      >
        {multiple ? (
          <DropdownMenuGroup>
            {options.map((option) => (
              <DropdownMenuCheckboxItem
                key={option.key}
                checked={selectedKeys.includes(option.key)}
                className="rounded-lg py-1.5 text-xs sm:text-[13px]"
                onCheckedChange={(checked) => {
                  onChange(
                    checked
                      ? [...selectedKeys, option.key]
                      : selectedKeys.filter((key) => key !== option.key)
                  );
                }}
              >
                {option.label}
              </DropdownMenuCheckboxItem>
            ))}
          </DropdownMenuGroup>
        ) : (
          <DropdownMenuRadioGroup
            value={selectedKeys[0] ?? ""}
            onValueChange={(value) => {
              if (typeof value === "string") {
                onChange([value]);
              }
            }}
          >
            {options.map((option) => (
              <DropdownMenuRadioItem
                key={option.key}
                value={option.key}
                closeOnClick
                className="rounded-lg py-1.5 text-xs sm:text-[13px]"
              >
                {option.label}
              </DropdownMenuRadioItem>
            ))}
          </DropdownMenuRadioGroup>
        )}
      </DropdownMenuContent>
    </DropdownMenu>
  );
}
