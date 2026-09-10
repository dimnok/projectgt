import { getActiveCompanyId } from "@/lib/supabase/company";
import { getRequiredClient } from "@/lib/supabase/client";
import { toNumber } from "@/features/estimates/utils/estimate.utils";
import type { EstimateCompletionHistoryEntry } from "@/features/estimates/types/estimate.types";

function resolveOpenedByName(profiles: unknown): string {
  if (!profiles || typeof profiles !== "object") return "Не указан";
  const p = profiles as { short_name?: string | null; full_name?: string | null };
  const shortName = p.short_name?.trim();
  if (shortName) return shortName;
  const fullName = p.full_name?.trim();
  if (fullName) return fullName;
  return "Не указан";
}

type WorkItemRaw = {
  id: string;
  quantity: unknown;
  section: string | null;
  floor: string | null;
  works?:
    | {
        date?: string | null;
        profiles?: { short_name?: string | null; full_name?: string | null } | null;
      }
    | Array<{
        date?: string | null;
        profiles?: { short_name?: string | null; full_name?: string | null } | null;
      }>
    | null;
};

/**
 * Loads completion history entries for a specific estimate item.
 * Direct read from work_items + works + profiles (same as Flutter).
 */
export async function getEstimateItemHistory(
  estimateId: string
): Promise<EstimateCompletionHistoryEntry[]> {
  if (!estimateId) {
    return [];
  }

  const client = getRequiredClient();
  const companyId = await getActiveCompanyId();

  const { data, error } = await client
    .from("work_items")
    .select(
      "id, quantity, section, floor, works!inner(date, profiles!opened_by(short_name, full_name))"
    )
    .eq("estimate_id", estimateId)
    .eq("company_id", companyId)
    .order("date", { referencedTable: "works", ascending: false });

  if (error) {
    throw new Error(error.message);
  }

  if (!data || !Array.isArray(data)) {
    return [];
  }

  const rows = data as unknown as WorkItemRaw[];

  return rows.map((row) => {
    const worksObj = Array.isArray(row.works) ? row.works[0] : row.works;
    return {
      id: String(row.id),
      date: worksObj?.date ? String(worksObj.date) : "",
      quantity: toNumber(row.quantity),
      section: row.section ? String(row.section).trim() : "—",
      floor: row.floor ? String(row.floor).trim() : "—",
      openedByName: resolveOpenedByName(worksObj?.profiles),
    };
  });
}
