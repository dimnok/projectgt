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

/** Вариант списка с несколькими значениями. */
export type CashFlowMultiSelectOption = {
  key: string;
  label: string;
};

type CashFlowMultiSelectProps = {
  title: string;
  options: CashFlowMultiSelectOption[];
  selectedKeys: string[];
  onChange: (keys: string[]) => void;
  disabled?: boolean;
};

/**
 * Фильтр с несколькими значениями: договоры и тип операции.
 *
 * Число выбранных значений видно на кнопке — иначе свёрнутый список ничего
 * не сообщает о фильтре.
 */
export function CashFlowMultiSelect({
  title,
  options,
  selectedKeys,
  onChange,
  disabled = false,
}: CashFlowMultiSelectProps) {
  return (
    <DropdownMenu>
      <DropdownMenuTrigger
        render={
          <Button
            type="button"
            variant="outline"
            size="sm"
            disabled={disabled || options.length === 0}
            className="h-9 rounded-lg bg-card px-3 text-xs font-normal hover:bg-muted/40 sm:text-sm"
          />
        }
      >
        <span>{title}</span>
        {selectedKeys.length > 0 ? (
          <Badge variant="secondary" className="h-5 px-1.5 text-[11px]">
            {selectedKeys.length}
          </Badge>
        ) : null}
        <ChevronDownIcon data-icon="inline-end" className="size-3.5 opacity-60" />
      </DropdownMenuTrigger>
      <DropdownMenuContent align="start" className="max-h-72 min-w-56 overflow-y-auto">
        <DropdownMenuGroup>
          {options.map((option) => (
            <DropdownMenuCheckboxItem
              key={option.key}
              checked={selectedKeys.includes(option.key)}
              onCheckedChange={(checked) =>
                onChange(
                  checked
                    ? [...selectedKeys, option.key]
                    : selectedKeys.filter((key) => key !== option.key)
                )
              }
            >
              {option.label}
            </DropdownMenuCheckboxItem>
          ))}
        </DropdownMenuGroup>
      </DropdownMenuContent>
    </DropdownMenu>
  );
}
