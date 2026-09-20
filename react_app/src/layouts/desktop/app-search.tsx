"use client";

import { createContext, use, useMemo, useState, type ReactNode } from "react";
import { SearchIcon, XIcon } from "lucide-react";

import {
  InputGroup,
  InputGroupAddon,
  InputGroupButton,
  InputGroupInput,
} from "@/components/ui/input-group";
import { cn } from "@/lib/utils";

type AppSearchContextValue = {
  query: string;
  setQuery: (value: string) => void;
};

const AppSearchContext = createContext<AppSearchContextValue | null>(null);

export function AppSearchProvider({ children }: { children: ReactNode }) {
  const [query, setQuery] = useState("");
  const value = useMemo(() => ({ query, setQuery }), [query]);

  return (
    <AppSearchContext.Provider value={value}>
      {children}
    </AppSearchContext.Provider>
  );
}

export function useAppSearch() {
  const value = use(AppSearchContext);
  if (!value) {
    throw new Error("useAppSearch must be used within AppSearchProvider");
  }
  return value;
}

type AppSearchFieldProps = {
  className?: string;
  placeholder?: string;
  "aria-label"?: string;
  /** Compact header field vs. aside field above filters. */
  variant?: "header" | "aside";
};

/**
 * Shared search input. Header keeps a compact field; list screens
 * place the aside variant above filters in the right column.
 */
export function AppSearchField({
  className,
  placeholder = "Поиск...",
  "aria-label": ariaLabel = "Поиск",
  variant = "header",
}: AppSearchFieldProps) {
  const { query, setQuery } = useAppSearch();
  const isAside = variant === "aside";

  return (
    <InputGroup
      className={cn(
        "w-full bg-background rounded-lg",
        isAside &&
          "h-11 rounded-xl border-transparent bg-card text-sm shadow-float ring-1 ring-foreground/10 hover:bg-muted/25 focus-within:bg-card",
        className
      )}
    >
      <InputGroupAddon>
        <SearchIcon
          className={cn(
            isAside && "size-4 text-muted-foreground/70"
          )}
        />
      </InputGroupAddon>
      <InputGroupInput
        type="search"
        value={query}
        placeholder={placeholder}
        aria-label={ariaLabel}
        className={cn(
          "[&::-webkit-search-cancel-button]:appearance-none [&::-webkit-search-cancel-button]:hidden [&::-webkit-search-decoration]:hidden",
          isAside && "text-sm placeholder:text-muted-foreground/60"
        )}
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
            <XIcon className="size-3.5 text-muted-foreground/80" />
          </InputGroupButton>
        </InputGroupAddon>
      ) : null}
    </InputGroup>
  );
}
