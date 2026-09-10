"use client";

import { ChevronDownIcon, SearchIcon, XIcon } from "lucide-react";

import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import {
  DropdownMenu,
  DropdownMenuCheckboxItem,
  DropdownMenuContent,
  DropdownMenuGroup,
  DropdownMenuTrigger,
} from "@/components/ui/dropdown-menu";
import {
  InputGroup,
  InputGroupAddon,
  InputGroupButton,
  InputGroupInput,
} from "@/components/ui/input-group";
import {
  Select,
  SelectContent,
  SelectGroup,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import type { SiteObject } from "@/features/objects/types/object.types";
import type { WorkJournalFilterValues } from "@/features/work-journal/types/work-journal.types";

type WorkJournalFiltersBarProps = {
  objects: SiteObject[];
  objectId: string | null;
  searchQuery: string;
  systems: string[];
  sections: string[];
  floors: string[];
  filterValues: WorkJournalFilterValues | undefined;
  onObjectChange: (objectId: string | null) => void;
  onSearchChange: (value: string) => void;
  onSystemsChange: (values: string[]) => void;
  onSectionsChange: (values: string[]) => void;
  onFloorsChange: (values: string[]) => void;
};

type FilterOption = {
  value: string;
  label: string;
};

export function WorkJournalFiltersBar({
  objects,
  objectId,
  searchQuery,
  systems,
  sections,
  floors,
  filterValues,
  onObjectChange,
  onSearchChange,
  onSystemsChange,
  onSectionsChange,
  onFloorsChange,
}: WorkJournalFiltersBarProps) {
  const objectItems: FilterOption[] = objects.map((object) => ({
    value: object.id,
    label: object.name,
  }));

  return (
    <div className="flex min-w-0 flex-1 flex-wrap items-center gap-x-3 gap-y-2 lg:gap-x-4">
      <div className="flex min-w-0 items-center gap-2">
        <label
          htmlFor="work-journal-object"
          className="shrink-0 text-xs sm:text-sm font-medium text-muted-foreground select-none"
        >
          Объект
        </label>
        <Select
          value={objectId}
          items={objectItems}
          disabled={objects.length === 0}
          onValueChange={(next) => {
            if (typeof next === "string") {
              onObjectChange(next);
            }
          }}
        >
          <SelectTrigger
            id="work-journal-object"
            className="h-9 w-44 sm:w-52 lg:w-56 rounded-lg bg-card px-3 text-xs sm:text-sm hover:bg-muted/40"
          >
            <SelectValue placeholder="Выберите объект" />
          </SelectTrigger>
          <SelectContent align="start">
            <SelectGroup>
              {objectItems.map((item) => (
                <SelectItem key={item.value} value={item.value}>
                  {item.label}
                </SelectItem>
              ))}
            </SelectGroup>
          </SelectContent>
        </Select>
      </div>

      {objectId && (filterValues?.systems.length ?? 0) > 0 ? (
        <MultiFilter
          label="Система"
          options={filterValues?.systems ?? []}
          selected={systems}
          onChange={onSystemsChange}
        />
      ) : null}

      {objectId && (filterValues?.sections.length ?? 0) > 0 ? (
        <MultiFilter
          label="Участок"
          options={filterValues?.sections ?? []}
          selected={sections}
          onChange={onSectionsChange}
        />
      ) : null}

      {objectId && (filterValues?.floors.length ?? 0) > 0 ? (
        <MultiFilter
          label="Этаж"
          options={filterValues?.floors ?? []}
          selected={floors}
          onChange={onFloorsChange}
        />
      ) : null}

      <div className="relative flex min-w-56 flex-1 items-center sm:max-w-sm md:max-w-md lg:max-w-lg">
        <InputGroup className="h-9 w-full rounded-lg bg-card text-xs sm:text-sm hover:bg-muted/40">
          <InputGroupAddon>
            <SearchIcon className="size-4 text-muted-foreground" />
          </InputGroupAddon>
          <InputGroupInput
            type="text"
            value={searchQuery}
            placeholder="Поиск по наименованию работ..."
            aria-label="Поиск по наименованию работ"
            disabled={!objectId}
            className="text-xs sm:text-sm placeholder:text-muted-foreground [&::-webkit-search-cancel-button]:appearance-none [&::-webkit-search-cancel-button]:hidden [&::-webkit-search-decoration]:hidden"
            onChange={(event) => onSearchChange(event.target.value)}
          />
          {searchQuery ? (
            <InputGroupAddon align="inline-end">
              <InputGroupButton
                size="icon-sm"
                variant="ghost"
                aria-label="Очистить поиск"
                onClick={() => onSearchChange("")}
              >
                <XIcon className="size-3.5 text-muted-foreground" />
              </InputGroupButton>
            </InputGroupAddon>
          ) : null}
        </InputGroup>
      </div>
    </div>
  );
}

function MultiFilter({
  label,
  options,
  selected,
  onChange,
}: {
  label: string;
  options: string[];
  selected: string[];
  onChange: (values: string[]) => void;
}) {
  return (
    <DropdownMenu>
      <DropdownMenuTrigger
        render={
          <Button
            type="button"
            variant="outline"
            size="sm"
            className="h-9 rounded-lg bg-card px-3 text-xs sm:text-sm hover:bg-muted/40"
          />
        }
      >
        <span>{label}</span>
        {selected.length > 0 ? (
          <Badge variant="secondary">{selected.length}</Badge>
        ) : null}
        <ChevronDownIcon data-icon="inline-end" />
      </DropdownMenuTrigger>
      <DropdownMenuContent className="min-w-56" align="start">
        <DropdownMenuGroup>
          {options.map((option) => (
            <DropdownMenuCheckboxItem
              key={option}
              checked={selected.includes(option)}
              onCheckedChange={(checked) => {
                if (checked) {
                  onChange([...selected, option]);
                  return;
                }
                onChange(selected.filter((value) => value !== option));
              }}
            >
              {option}
            </DropdownMenuCheckboxItem>
          ))}
        </DropdownMenuGroup>
      </DropdownMenuContent>
    </DropdownMenu>
  );
}
