"use client";

import { PlusIcon, SearchIcon, XIcon } from "lucide-react";

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
  SettlementFilters,
  SettlementOperationType,
  SettlementPaymentStatus,
  SettlementPickItem,
} from "@/features/settlements/types/settlement.types";
import {
  SETTLEMENT_OPERATION_TYPE_OPTIONS,
  isSettlementOperationType,
} from "@/features/settlements/utils/operation-type";
import {
  SETTLEMENT_PAYMENT_STATUSES,
  isSettlementPaymentStatus,
  settlementPaymentStatusLabel,
} from "@/features/settlements/utils/payment-status";
import { useAppSearch } from "@/layouts/desktop/app-search";

/** Вариант выпадающего списка фильтра. */
type FilterOption = { value: string; label: string };

type SettlementsFiltersProps = {
  filters: SettlementFilters;
  onChange: (filters: SettlementFilters) => void;
  /** Сброс страницы при смене поиска. */
  onSearchChange?: () => void;
  contractorOptions: SettlementPickItem[];
  objectOptions: SettlementPickItem[];
  contractOptions: SettlementPickItem[];
  hasActiveFilters: boolean;
  onReset: () => void;
  canCreate: boolean;
  onCreate: () => void;
};

/**
 * Фильтры реестра на компьютере: тип, статус оплаты, контрагент, объект,
 * договор, поиск, сброс и кнопка нового счёта.
 */
export function SettlementsFilters({
  filters,
  onChange,
  onSearchChange,
  contractorOptions,
  objectOptions,
  contractOptions,
  hasActiveFilters,
  onReset,
  canCreate,
  onCreate,
}: SettlementsFiltersProps) {
  const { query, setQuery } = useAppSearch();

  const typeItems: FilterOption[] = [
    { value: "all", label: "Все типы" },
    ...SETTLEMENT_OPERATION_TYPE_OPTIONS,
  ];
  const statusItems: FilterOption[] = [
    { value: "all", label: "Все статусы" },
    ...SETTLEMENT_PAYMENT_STATUSES.map((status) => ({
      value: status,
      label: settlementPaymentStatusLabel(status),
    })),
  ];

  return (
    <div className="flex min-w-0 flex-1 flex-wrap items-center gap-x-3 gap-y-2 lg:gap-x-4">
      <FilterSelect
        id="settlements-type"
        label="Тип"
        value={filters.operationType}
        items={typeItems}
        onValueChange={(value) => {
          if (value === "all" || isSettlementOperationType(value)) {
            onChange({
              ...filters,
              operationType: value as SettlementOperationType | "all",
            });
          }
        }}
      />
      <FilterSelect
        id="settlements-status"
        label="Оплата"
        value={filters.paymentStatus}
        items={statusItems}
        onValueChange={(value) => {
          if (value === "all" || isSettlementPaymentStatus(value)) {
            onChange({
              ...filters,
              paymentStatus: value as SettlementPaymentStatus | "all",
            });
          }
        }}
      />
      <EntitySelect
        id="settlements-contractor"
        label="Контрагент"
        allLabel="Все контрагенты"
        value={filters.contractorId}
        options={contractorOptions}
        onChange={(value) => onChange({ ...filters, contractorId: value })}
      />
      <EntitySelect
        id="settlements-object"
        label="Объект"
        allLabel="Все объекты"
        value={filters.objectId}
        options={objectOptions}
        onChange={(value) =>
          onChange({
            ...filters,
            objectId: value,
            ...(value === "" ? { contractId: "" } : {}),
          })
        }
      />
      <EntitySelect
        id="settlements-contract"
        label="Договор"
        allLabel="Все договоры"
        value={filters.contractId}
        options={contractOptions}
        onChange={(value) => onChange({ ...filters, contractId: value })}
      />

      <div className="relative flex min-w-56 flex-1 items-center sm:max-w-sm md:max-w-md lg:max-w-lg xl:max-w-xl">
        <InputGroup className="h-9 w-full rounded-lg bg-card text-xs sm:text-sm hover:bg-muted/40">
          <InputGroupAddon>
            <SearchIcon className="size-4 text-muted-foreground" />
          </InputGroupAddon>
          <InputGroupInput
            type="text"
            value={query}
            placeholder="Поиск по счёту, акту, договору…"
            aria-label="Поиск по взаиморасчётам"
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
        {canCreate ? (
          <Button
            type="button"
            size="sm"
            className="gap-1.5"
            onClick={onCreate}
          >
            <PlusIcon className="size-3.5 shrink-0" />
            <span>Счёт</span>
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
    : (items[0]?.value ?? "all");

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
        className="h-9 w-40 rounded-lg bg-card px-3 text-xs hover:bg-muted/40 sm:w-48 sm:text-sm"
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

/** Фильтр по справочнику: контрагент, объект или договор. «all» — без фильтра. */
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
  options: SettlementPickItem[];
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
