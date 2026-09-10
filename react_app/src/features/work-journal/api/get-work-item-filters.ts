import { getRequiredClient } from "@/lib/supabase/client";
import { emptyToNull } from "@/features/work-journal/utils/work-journal.utils";
import type { WorkJournalFilterValues } from "@/features/work-journal/types/work-journal.types";

type FilterRpcRow = {
  systems?: string[] | null;
  sections?: string[] | null;
  floors?: string[] | null;
};

/**
 * Cascade filter values for the selected object. Same RPC as Flutter.
 */
export async function getWorkItemFilters(params: {
  objectId: string;
  startDate?: string | null;
  endDate?: string | null;
  systemFilters?: string[];
  sectionFilters?: string[];
  searchQuery?: string | null;
}): Promise<WorkJournalFilterValues> {
  const client = getRequiredClient();

  const { data, error } = await client.rpc("get_work_items_available_filters", {
    p_object_id: params.objectId,
    p_start_date: params.startDate ?? null,
    p_end_date: params.endDate ?? null,
    p_system_filters: emptyToNull(params.systemFilters),
    p_section_filters: emptyToNull(params.sectionFilters),
    p_search_query: params.searchQuery?.trim() || null,
  });

  if (error) {
    throw new Error(error.message);
  }

  const row = Array.isArray(data) ? (data[0] as FilterRpcRow | undefined) : undefined;
  const systems = [...(row?.systems ?? [])].filter(Boolean).sort((a, b) => a.localeCompare(b, "ru"));
  const sections = [...(row?.sections ?? [])].filter(Boolean).sort((a, b) => a.localeCompare(b, "ru"));
  const floors = [...(row?.floors ?? [])].filter(Boolean).sort((a, b) => a.localeCompare(b, "ru"));

  return { systems, sections, floors };
}
