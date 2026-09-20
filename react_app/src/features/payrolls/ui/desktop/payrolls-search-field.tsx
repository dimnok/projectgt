"use client";

import { SearchIcon, XIcon } from "lucide-react";

import {
  InputGroup,
  InputGroupAddon,
  InputGroupButton,
  InputGroupInput,
} from "@/components/ui/input-group";

type PayrollSearchFieldProps = {
  value: string;
  onChange: (query: string) => void;
  disabled?: boolean;
};

/** Поиск по ФИО в панели фильтров модуля ФОТ. */
export function PayrollSearchField({
  value,
  onChange,
  disabled = false,
}: PayrollSearchFieldProps) {
  return (
    <div className="relative flex min-w-56 flex-1 items-center sm:max-w-sm md:max-w-md lg:max-w-lg xl:max-w-xl">
      <InputGroup className="h-9 w-full rounded-lg bg-card text-xs hover:bg-muted/40 sm:text-sm">
        <InputGroupAddon>
          <SearchIcon className="size-4 text-muted-foreground" />
        </InputGroupAddon>
        <InputGroupInput
          type="text"
          value={value}
          disabled={disabled}
          placeholder="Поиск по ФИО..."
          aria-label="Поиск по ФИО"
          className="text-xs placeholder:text-muted-foreground sm:text-sm [&::-webkit-search-cancel-button]:appearance-none [&::-webkit-search-cancel-button]:hidden [&::-webkit-search-decoration]:hidden"
          onChange={(event) => onChange(event.target.value)}
        />
        {value ? (
          <InputGroupAddon align="inline-end">
            <InputGroupButton
              size="icon-sm"
              variant="ghost"
              aria-label="Очистить поиск"
              onClick={() => onChange("")}
            >
              <XIcon className="size-3.5 text-muted-foreground" />
            </InputGroupButton>
          </InputGroupAddon>
        ) : null}
      </InputGroup>
    </div>
  );
}
