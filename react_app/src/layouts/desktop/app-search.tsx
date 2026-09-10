"use client";

import { createContext, use, useMemo, useState, type ReactNode } from "react";
import { SearchIcon } from "lucide-react";

import {
  InputGroup,
  InputGroupAddon,
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
};

/**
 * Shared search input. Compact screens show it under the summary;
 * wide screens keep it in the header.
 */
export function AppSearchField({ className }: AppSearchFieldProps) {
  const { query, setQuery } = useAppSearch();

  return (
    <InputGroup
      className={cn("w-full bg-background rounded-lg", className)}
    >
      <InputGroupAddon>
        <SearchIcon />
      </InputGroupAddon>
      <InputGroupInput
        type="search"
        value={query}
        placeholder="Поиск..."
        aria-label="Поиск"
        onChange={(event) => setQuery(event.target.value)}
      />
    </InputGroup>
  );
}
