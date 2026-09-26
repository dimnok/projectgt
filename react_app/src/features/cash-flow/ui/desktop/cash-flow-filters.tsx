"use client";

import { useMemo } from "react";
import { ListIcon, PlusIcon, SearchIcon, XIcon } from "lucide-react";

import { Button } from "@/components/ui/button";
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
import type {
  CashFlowFilters,
  CashFlowPickItem,
  CashFlowType,
} from "@/features/cash-flow/types/cash-flow.types";
import { CashFlowMultiSelect } from "@/features/cash-flow/ui/shared/cash-flow-multi-select";
import { cashFlowYearOptions } from "@/features/cash-flow/utils/filters";
import {
  CASH_FLOW_TYPE_OPTIONS,
  isCashFlowType,
} from "@/features/cash-flow/utils/operation-type";
import { useAppSearch } from "@/layouts/desktop/app-search";

/** Вариант выпадающего списка фильтра. */
type FilterOption = { value: string; label: string };

type CashFlowFiltersProps = {
  filters: CashFlowFilters;
  onChange: (filters: CashFlowFilters) => void;
  /** Сброс страницы при смене поиска. */
  onSearchChange?: () => void;
  objectOptions: CashFlowPickItem[];
  contractorOptions: CashFlowPickItem[];
  contractOptions: CashFlowPickItem[];
  hasActiveFilters: boolean;
  onReset: () => void;
  canCreate: boolean;
  onCreate: () => void;
  onOpenCategories: () => void;
};

/**
 * Фильтры реестра ДДС: период, объект, контрагент, договоры, тип операции,
 * поиск, сброс и кнопки «Статьи ДДС» и «Операция».
 */
export function CashFlowFilters({
  filters,
  onChange,
  onSearchChange,
  objectOptions,
  contractorOptions,
  contractOptions,
  hasActiveFilters,
  onReset,
  canCreate,
  onCreate,
  onOpenCategories,
}: CashFlowFiltersProps) {
  const { query, setQuery } = useAppSearch();

  const yearItems = useMemo<FilterOption[]>(
    () =>
      cashFlowYearOptions().map((year) => ({
        value: String(year),
        label: String(year),
      })),
    []
  );

  return (
    <div className="flex min-w-0 flex-1 flex-wrap items-center gap-x-3 gap-y-2 lg:gap-x-4">
      <FilterSelect
        id="cash-flow-period"
        label="Период"
        value={String(filters.year)}
        items={yearItems}
        onValueChange={(value) =>
          onChange({ ...filters, year: Number(value) })
        }
      />
      <EntitySelect
        id="cash-flow-object"
        label="Объект"
        allLabel="Все объекты"
        value={filters.objectId}
        options={objectOptions}
        onChange={(value) => onChange({ ...filters, objectId: value })}
      />
      <EntitySelect
        id="cash-flow-contractor"
        label="Контрагент"
        allLabel="Все контрагенты"
        value={filters.contractorId}
        options={contractorOptions}
        onChange={(value) => onChange({ ...filters, contractorId: value })}
      />
      <CashFlowMultiSelect
        title="Договоры"
        options={contractOptions.map((option) => ({
          key: option.id,
          label: option.label,
        }))}
        selectedKeys={filters.contractIds}
        onChange={(keys) => onChange({ ...filters, contractIds: keys })}
      />
      <CashFlowMultiSelect
        title="Тип операции"
        options={CASH_FLOW_TYPE_OPTIONS.map((option) => ({
          key: option.value,
          label: option.label,
        }))}
        selectedKeys={filters.types}
        onChange={(keys) =>
          onChange({
            ...filters,
            types: keys.filter((key): key is CashFlowType => isCashFlowType(key)),
          })
        }
      />

      <div className="relative flex min-w-56 flex-1 items-center sm:max-w-sm md:max-w-md lg:max-w-lg xl:max-w-xl">
        <InputGroup className="h-9 w-full rounded-lg bg-card text-xs sm:text-sm hover:bg-muted/40">
          <InputGroupAddon>
            <SearchIcon className="size-4 text-muted-foreground" />
          </InputGroupAddon>
          <InputGroupInput
            type="text"
            value={query}
            placeholder="Поиск по статье, контрагенту, объекту, договору…"
            aria-label="Поиск по операциям"
            className="text-xs sm:text-sm placeholder:text-muted-foreground [&::-webkit-search-cancel-button]:appearance-none [&::-webkit-search-cancel-button]:hidden [&::-webkit-search-decoration]:hidden"
            onChange={(event) => {
              setQuery(event.target.value);
              onSearchChange?.();
            }}
          />
          {query ? (
            <InputGroupAddon align="inline-end">
              <InputGroupButton
                size="icon-sm"
                variant="ghost"
                aria-label="Очистить поиск"
                onClick={() => {
                  setQuery("");
                  onSearchChange?.();
                }}
              >
                <XIcon className="size-3.5 text-muted-foreground" />
              </InputGroupButton>
            </InputGroupAddon>
          ) : null}
        </InputGroup>
      </div>

      <div className="flex items-center gap-2">
        {hasActiveFilters ? (
          <Button
            type="button"
            size="sm"
            variant="ghost"
            className="gap-1.5"
            onClick={() => {
              setQuery("");
              onReset();
            }}
          >
            <XIcon className="size-3.5 shrink-0" />
            <span>Сбросить</span>
          </Button>
        ) : null}
        <Button
          type="button"
          size="sm"
          variant="outline"
          className="gap-1.5"
          onClick={onOpenCategories}
        >
          <ListIcon className="size-3.5 shrink-0" />
          <span>Статьи ДДС</span>
        </Button>
        {canCreate ? (
          <Button
            type="button"
            size="sm"
            className="gap-1.5"
            onClick={onCreate}
          >
            <PlusIcon className="size-3.5 shrink-0" />
            <span>Операция</span>
          </Button>
        ) : null}
      </div>
    </div>
  );
}

/** Выпадающий список фильтра; значение вне списка откатывается к первому. */
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
    : (items[0]?.value ?? "");

  return (
    <Select
      value={selected}
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
        aria-label={label}
        className="h-9 w-32 rounded-lg bg-card px-3 text-xs hover:bg-muted/40 sm:w-36 sm:text-sm"
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
  );
}

/** Фильтр по справочнику: контрагент или объект. «all» — без фильтра. */
function EntitySelect({
  id,
  label,
  allLabel,
  value,
  options,
  onChange,
}: {
  id: string;
  label: string;
  allLabel: string;
  value: string;
  options: CashFlowPickItem[];
  onChange: (value: string) => void;
}) {
  const items: FilterOption[] = [
    { value: "all", label: allLabel },
    ...options.map((option) => ({ value: option.id, label: option.label })),
  ];

  return (
    <FilterSelect
      id={id}
      label={label}
      value={value || "all"}
      items={items}
      onValueChange={(next) => onChange(next === "all" ? "" : next)}
    />
  );
}
