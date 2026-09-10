import { getActiveCompanyId } from "@/lib/supabase/company";
import { getRequiredClient } from "@/lib/supabase/client";
import type { EstimateItemEditHistoryEntry } from "@/features/estimates/types/estimate.types";

function resolveAuthorName(profiles: unknown): string {
  if (!profiles || typeof profiles !== "object") return "Не указан";
  const p = profiles as { short_name?: string | null; full_name?: string | null };
  const shortName = p.short_name?.trim();
  if (shortName) return shortName;
  const fullName = p.full_name?.trim();
  if (fullName) return fullName;
  return "Не указан";
}

type EditHistoryRaw = {
  id: string;
  created_at: string;
  action: string;
  changes: Record<string, { from?: unknown; to?: unknown }> | null;
  author?:
    | { short_name?: string | null; full_name?: string | null }
    | Array<{ short_name?: string | null; full_name?: string | null }>
    | null;
};

/**
 * Loads manual edit history for a specific estimate position from `estimate_item_history`.
 */
export async function getEstimateItemEditHistory(
  estimateId: string
): Promise<EstimateItemEditHistoryEntry[]> {
  if (!estimateId) {
    return [];
  }

  const client = getRequiredClient();
  const companyId = await getActiveCompanyId();

  const { data, error } = await client
    .from("estimate_item_history")
    .select(
      "id, created_at, action, changes, author:profiles!estimate_item_history_user_id_fkey(short_name, full_name)"
    )
    .eq("estimate_id", estimateId)
    .eq("company_id", companyId)
    .order("created_at", { ascending: false });

  if (error) {
    throw new Error(error.message);
  }

  if (!data || !Array.isArray(data)) {
    return [];
  }

  const rows = data as unknown as EditHistoryRaw[];

  return rows.map((row) => {
    const authorObj = Array.isArray(row.author) ? row.author[0] : row.author;
    const rawChanges = row.changes && typeof row.changes === "object" ? row.changes : {};
    return {
      id: String(row.id),
      createdAt: String(row.created_at),
      action: String(row.action || "updated"),
      userName: resolveAuthorName(authorObj),
      changes: rawChanges,
    };
  });
}
