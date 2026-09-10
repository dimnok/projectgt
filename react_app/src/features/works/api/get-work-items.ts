import { getActiveCompanyId } from "@/lib/supabase/company";
import { getRequiredClient } from "@/lib/supabase/client";
import type { WorkItem, WorkItemsRow } from "@/features/works/types/work.types";
import {
  resolveContractorName,
  toNumber,
  unwrapRelation,
} from "@/features/works/utils/work.utils";

const WORK_ITEM_SELECT = [
  "id",
  "work_id",
  "section",
  "floor",
  "system",
  "subsystem",
  "estimate_id",
  "name",
  "unit",
  "quantity",
  "price",
  "total",
  "contractor_id",
  "specialists_count",
  "contract_act_id",
  "estimates!estimate_id(number)",
  "contractors!contractor_id(short_name, full_name)",
].join(", ");

/**
 * Loads work items of a shift.
 * Estimate number comes from JOIN, same as Flutter `fetchWorkItems`.
 */
export async function getWorkItems(workId: string): Promise<WorkItem[]> {
  const client = getRequiredClient();
  const companyId = await getActiveCompanyId();

  const { data, error } = await client
    .from("work_items")
    .select(WORK_ITEM_SELECT)
    .eq("work_id", workId)
    .eq("company_id", companyId)
    .order("created_at");

  if (error) {
    throw new Error(error.message);
  }

  return ((data ?? []) as unknown as WorkItemsRow[]).map((row) => {
    const estimate = unwrapRelation(row.estimates);
    const contractor = unwrapRelation(row.contractors);
    const number = estimate?.number == null ? null : String(estimate.number);

    return {
      id: row.id,
      workId: row.work_id,
      section: row.section,
      floor: row.floor,
      system: row.system,
      subsystem: row.subsystem,
      estimateId: row.estimate_id,
      number,
      name: row.name,
      unit: row.unit,
      quantity: toNumber(row.quantity),
      price: toNumber(row.price),
      total: toNumber(row.total),
      contractorId: row.contractor_id,
      contractorName: resolveContractorName(contractor),
      specialistsCount:
        row.specialists_count == null ? null : toNumber(row.specialists_count),
      contractActId: row.contract_act_id,
    };
  });
}
