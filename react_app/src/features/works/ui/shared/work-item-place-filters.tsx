"use client";

import {
  Select,
  SelectContent,
  SelectGroup,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import type { WorkItemPlaceFilter } from "@/features/works/utils/work.utils";

type FilterOption = {
  value: string;
  label: string;
};

type WorkItemPlaceFiltersProps = {
  system: string | null;
  section: string | null;
  floor: string | null;
  systems: string[];
  sections: string[];
  floors: string[];
  disabled?: boolean;
  onChange: (next: WorkItemPlaceFilter) => void;
};

export function WorkItemPlaceFilters({
  system,
  section,
  floor,
  systems,
  sections,
  floors,
  disabled = false,
  onChange,
}: WorkItemPlaceFiltersProps) {
  return (
    <div className="flex min-w-0 flex-1 flex-wrap items-center gap-2">
      <PlaceSelect
        id="work-items-system"
        label="Система"
        allLabel="Все системы"
        value={system}
        options={systems}
        disabled={disabled}
        onValueChange={(next) =>
          onChange({ system: next, section: null, floor: null })
        }
      />
      <PlaceSelect
        id="work-items-section"
        label="Участок"
        allLabel="Все участки"
        value={section}
        options={sections}
        disabled={disabled}
        onValueChange={(next) =>
          onChange({ system, section: next, floor: null })
        }
      />
      <PlaceSelect
        id="work-items-floor"
        label="Этаж"
        allLabel="Все этажи"
        value={floor}
        options={floors}
        disabled={disabled}
        onValueChange={(next) =>
          onChange({ system, section, floor: next })
        }
      />
    </div>
  );
}

function PlaceSelect({
  id,
  label,
  allLabel,
  value,
  options,
  disabled,
  onValueChange,
}: {
  id: string;
  label: string;
  allLabel: string;
  value: string | null;
  options: string[];
  disabled?: boolean;
  onValueChange: (value: string | null) => void;
}) {
  const items: FilterOption[] = [
    { value: "all", label: allLabel },
    ...options.map((option) => ({ value: option, label: option })),
  ];
  const selected = value && options.includes(value) ? value : "all";

  return (
    <Select
      value={selected}
      items={items}
      disabled={disabled}
        onValueChange={(next) => {
          if (typeof next === "string") {
            onValueChange(next === "all" ? null : next);
          }
        }}
    >
      <SelectTrigger
        id={id}
        size="sm"
        aria-label={label}
        className="h-8 min-w-28 max-w-40 bg-background px-2.5 text-xs"
      >
        <SelectValue placeholder={allLabel} />
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
