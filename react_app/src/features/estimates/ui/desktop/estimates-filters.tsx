"use client";

import { SearchIcon, XIcon } from "lucide-react";

import {
  Select,
  SelectContent,
  SelectGroup,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import {
  InputGroup,
  InputGroupAddon,
  InputGroupButton,
  InputGroupInput,
} from "@/components/ui/input-group";
import type {
  EstimateContractGroup,
  EstimateFile,
  EstimateObjectGroup,
} from "@/features/estimates/types/estimate.types";
import { useAppSearch } from "@/layouts/desktop/app-search";

type FilterOption = {
  value: string;
  label: string;
};

type EstimatesFiltersProps = {
  objects: EstimateObjectGroup[];
  contracts: EstimateContractGroup[];
  files: EstimateFile[];
  objectKey: string | null;
  contractKey: string | null;
  fileKey: string | null;
  onObjectChange: (key: string | null) => void;
  onContractChange: (key: string | null) => void;
  onFileChange: (key: string | null) => void;
};

export function EstimatesFilters({
  objects,
  contracts,
  files,
  objectKey,
  contractKey,
  fileKey,
  onObjectChange,
  onContractChange,
  onFileChange,
}: EstimatesFiltersProps) {
  const { query, setQuery } = useAppSearch();

  const objectItems: FilterOption[] = [
    { value: "all", label: "Все объекты" },
    ...objects.map((group) => ({
      value: group.key,
      label: group.objectName,
    })),
  ];

  const contractItems: FilterOption[] = [
    { value: "all", label: "Все договоры" },
    ...contracts.map((group) => ({
      value: group.key,
      label: group.contractNumber,
    })),
  ];

  const fileItems: FilterOption[] = [
    { value: "all", label: "Все сметы" },
    ...files.map((file) => ({
      value: file.key,
      label: file.estimateTitle || "Без названия",
    })),
  ];

  const isObjectSelected = Boolean(objectKey && objectKey !== "all");
  const isContractSelected = Boolean(contractKey && contractKey !== "all");

  return (
    <div className="flex min-w-0 flex-1 flex-wrap items-center gap-x-3 gap-y-2 lg:gap-x-4">
      <FilterSelect
        id="estimates-object"
        label="Объект"
        value={objectKey ?? "all"}
        items={objectItems}
        disabled={objects.length === 0}
        onValueChange={(val) => onObjectChange(val === "all" ? null : val)}
      />
      <FilterSelect
        id="estimates-contract"
        label="Договор"
        value={isObjectSelected ? (contractKey ?? "all") : "all"}
        items={contractItems}
        disabled={!isObjectSelected || contracts.length === 0}
        onValueChange={(val) => onContractChange(val === "all" ? null : val)}
      />
      <FilterSelect
        id="estimates-file"
        label="Смета"
        value={isContractSelected ? (fileKey ?? "all") : "all"}
        items={fileItems}
        disabled={!isContractSelected || files.length === 0}
        onValueChange={(val) => onFileChange(val === "all" ? null : val)}
      />
      <div className="relative flex min-w-56 flex-1 items-center sm:max-w-sm md:max-w-md lg:max-w-lg xl:max-w-xl">
        <InputGroup className="h-9 w-full rounded-lg bg-card text-xs sm:text-sm hover:bg-muted/40">
          <InputGroupAddon>
            <SearchIcon className="size-4 text-muted-foreground" />
          </InputGroupAddon>
          <InputGroupInput
            type="text"
            value={query}
            placeholder="Поиск по наименованию, артикулу..."
            aria-label="Поиск по наименованию и артикулу"
            className="text-xs sm:text-sm placeholder:text-muted-foreground [&::-webkit-search-cancel-button]:appearance-none [&::-webkit-search-cancel-button]:hidden [&::-webkit-search-decoration]:hidden"
            onChange={(event) => setQuery(event.target.value)}
          />
          {query ? (
            <InputGroupAddon align="inline-end">
              <InputGroupButton
                size="icon-sm"
                variant="ghost"
                aria-label="Очистить поиск"
                onClick={() => setQuery("")}
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

function FilterSelect({
  id,
  label,
  value,
  items,
  disabled = false,
  onValueChange,
}: {
  id: string;
  label: string;
  value: string;
  items: FilterOption[];
  disabled?: boolean;
  onValueChange: (value: string) => void;
}) {
  const selected = items.some((item) => item.value === value)
    ? value
    : (items[0]?.value ?? "all");

  return (
    <div className="flex min-w-0 items-center gap-2">
      <label
        htmlFor={id}
        className="shrink-0 text-xs sm:text-sm font-medium text-muted-foreground select-none"
      >
        {label}
      </label>
      <Select
        value={selected || null}
        items={items}
        disabled={disabled}
        onValueChange={(next) => {
          if (typeof next === "string") {
            onValueChange(next);
          }
        }}
      >
        <SelectTrigger
          id={id}
          className="h-9 w-44 sm:w-52 lg:w-56 rounded-lg bg-card px-3 text-xs sm:text-sm hover:bg-muted/40"
        >
          <SelectValue />
        </SelectTrigger>
        <SelectContent align="start">
          <SelectGroup>
            {items.map((item) => (
              <SelectItem key={item.value} value={item.value}>
                {item.label}
              </SelectItem>
            ))}
          </SelectGroup>
        </SelectContent>
      </Select>
    </div>
  );
}
