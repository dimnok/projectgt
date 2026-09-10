import { getActiveCompanyId } from "@/lib/supabase/company";
import { getRequiredClient } from "@/lib/supabase/client";
import { assertCanWriteWorkItems } from "@/features/works/api/get-work-membership";
import { workItemLineTotal } from "@/features/works/utils/work.utils";
import { createId } from "@/lib/utils";

export type AddWorkItemDraft = {
  estimateId: string;
  name: string;
  unit: string;
  price: number;
  quantity: number;
  section: string;
  floor: string;
  system: string;
  subsystem: string;
  contractorId: string | null;
  specialistsCount: number | null;
};

/**
 * Inserts work items in one request, same as Flutter `addWorkItems`.
 * Header totals are recalculated by DB trigger `update_work_aggregates`.
 */
export async function addWorkItems(
  workId: string,
  drafts: AddWorkItemDraft[]
): Promise<void> {
  if (!workId) {
    throw new Error("Не указана смена");
  }
  if (drafts.length === 0) {
    return;
  }

  const client = getRequiredClient();
  const companyId = await getActiveCompanyId();
  await assertCanWriteWorkItems(workId);
  const now = new Date().toISOString();

  const payload = drafts.map((draft) => {
    const quantity = draft.quantity;
    return {
      id: createId(),
      company_id: companyId,
      work_id: workId,
      section: draft.section,
      floor: draft.floor,
      estimate_id: draft.estimateId,
      name: draft.name,
      system: draft.system,
      subsystem: draft.subsystem,
      unit: draft.unit,
      quantity,
      price: draft.price,
      total: workItemLineTotal(draft.price, quantity),
      created_at: now,
      updated_at: now,
      contract_act_id: null,
      contractor_id: draft.contractorId,
      specialists_count: draft.specialistsCount,
    };
  });

  const { error } = await client.from("work_items").insert(payload);
  if (error) {
    throw new Error(error.message);
  }
}
