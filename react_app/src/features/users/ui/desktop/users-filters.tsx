"use client";

import type { CompanyUserLinkFilter } from "@/features/users/types/user.types";
import { cn } from "@/lib/utils";

const LINK_FILTER_ITEMS: { value: CompanyUserLinkFilter; label: string }[] = [
  { value: "all", label: "Все" },
  { value: "linked", label: "С карточкой" },
  { value: "unlinked", label: "Без карточки" },
];

type UsersFiltersProps = {
  link: CompanyUserLinkFilter;
  onLinkChange: (value: CompanyUserLinkFilter) => void;
};

/** Segmented control for the users toolbar. */
export function UsersFilters({ link, onLinkChange }: UsersFiltersProps) {
  return (
    <div
      role="group"
      aria-label="Фильтр привязки к сотруднику"
      className="flex shrink-0 items-center gap-0.5 rounded-lg bg-muted/40 p-0.5 ring-1 ring-foreground/5"
    >
      {LINK_FILTER_ITEMS.map((item) => {
        const isActive = link === item.value;

        return (
          <button
            key={item.value}
            type="button"
            aria-pressed={isActive}
            onClick={() => onLinkChange(item.value)}
            className={cn(
              "cursor-pointer rounded-md px-2.5 py-1.5 text-xs font-medium transition-colors",
              isActive
                ? "bg-card text-foreground shadow-xs"
                : "text-muted-foreground hover:text-foreground"
            )}
          >
            {item.label}
          </button>
        );
      })}
    </div>
  );
}
