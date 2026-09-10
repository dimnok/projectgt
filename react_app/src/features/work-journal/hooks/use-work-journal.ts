"use client";

import { useQuery } from "@tanstack/react-query";
import { useEffect, useMemo } from "react";

import { getObjectIdsWithWorks } from "@/features/work-journal/api/get-object-ids-with-works";
import { getWorkItemFilters } from "@/features/work-journal/api/get-work-item-filters";
import { searchWorkItems } from "@/features/work-journal/api/search-work-items";
import { useDebouncedValue } from "@/features/work-journal/hooks/use-debounced-value";
import { useObjects } from "@/features/objects/hooks/use-objects";
import type { WorkJournalFilters } from "@/features/work-journal/types/work-journal.types";
import {
  pruneSelected,
  sameStringList,
} from "@/features/work-journal/utils/work-journal.utils";

const SEARCH_DEBOUNCE_MS = 500;

export function useWorkJournalObjects() {
  const objectsQuery = useObjects();
  const idsQuery = useQuery({
    queryKey: ["work-journal", "object-ids"],
    queryFn: getObjectIdsWithWorks,
  });

  const objects = useMemo(() => {
    const all = objectsQuery.data ?? [];
    const ids = idsQuery.data;
    if (idsQuery.isError || !ids) {
      return all;
    }
    const allowed = new Set(ids);
    return all.filter((object) => allowed.has(object.id));
  }, [idsQuery.data, idsQuery.isError, objectsQuery.data]);

  return {
    objects,
    isLoading: objectsQuery.isLoading || idsQuery.isLoading,
    isError: objectsQuery.isError,
    error: objectsQuery.error,
  };
}

export function useWorkJournalSearch(
  filters: WorkJournalFilters,
  page: number
) {
  const searchQuery = useDebouncedValue(filters.searchQuery, SEARCH_DEBOUNCE_MS);

  return useQuery({
    queryKey: [
      "work-journal",
      "search",
      filters.objectId,
      filters.dateRange?.from ?? null,
      filters.dateRange?.to ?? null,
      searchQuery,
      filters.systems,
      filters.sections,
      filters.floors,
      page,
    ],
    queryFn: () =>
      searchWorkItems({
        objectId: filters.objectId!,
        startDate: filters.dateRange?.from ?? null,
        endDate: filters.dateRange?.to ?? null,
        searchQuery,
        systemFilters: filters.systems,
        sectionFilters: filters.sections,
        floorFilters: filters.floors,
        page,
      }),
    enabled: Boolean(filters.objectId),
  });
}

export function useWorkJournalFilterValues(
  filters: WorkJournalFilters,
  onPrune: (next: Pick<WorkJournalFilters, "systems" | "sections" | "floors">) => void
) {
  const searchQuery = useDebouncedValue(filters.searchQuery, SEARCH_DEBOUNCE_MS);

  const query = useQuery({
    queryKey: [
      "work-journal",
      "filters",
      filters.objectId,
      filters.dateRange?.from ?? null,
      filters.dateRange?.to ?? null,
      searchQuery,
      filters.systems,
      filters.sections,
    ],
    queryFn: () =>
      getWorkItemFilters({
        objectId: filters.objectId!,
        startDate: filters.dateRange?.from ?? null,
        endDate: filters.dateRange?.to ?? null,
        systemFilters: filters.systems,
        sectionFilters: filters.sections,
        searchQuery,
      }),
    enabled: Boolean(filters.objectId),
  });

  useEffect(() => {
    const available = query.data;
    if (!available) {
      return;
    }

    const systems = pruneSelected(filters.systems, available.systems);
    const sections = pruneSelected(filters.sections, available.sections);
    const floors = pruneSelected(filters.floors, available.floors);

    if (
      sameStringList(systems, filters.systems) &&
      sameStringList(sections, filters.sections) &&
      sameStringList(floors, filters.floors)
    ) {
      return;
    }

    onPrune({ systems, sections, floors });
  }, [
    filters.floors,
    filters.sections,
    filters.systems,
    onPrune,
    query.data,
  ]);

  return query;
}
