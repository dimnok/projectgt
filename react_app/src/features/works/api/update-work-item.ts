import { getActiveCompanyId } from "@/lib/supabase/company";
import { getRequiredClient } from "@/lib/supabase/client";
import { assertCanWriteWorkItems } from "@/features/works/api/get-work-membership";
import { workItemLineTotal } from "@/features/works/utils/work.utils";

export type UpdateWorkItemDraft = {
  itemId: string;
  workId: string;
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
 * Updates one shift work item. Same fields as Flutter `updateWorkItem`.
 * Header totals are recalculated by DB trigger `update_work_aggregates`.
 */
export async function updateWorkItem(draft: UpdateWorkItemDraft): Promise<void> {
  const client = getRequiredClient();
  const companyId = await getActiveCompanyId();

  const { data, error: fetchError } = await client
    .from("work_items")
    .select("work_id, contract_act_id")
    .eq("id", draft.itemId)
    .eq("company_id", companyId)
    .maybeSingle();

  if (fetchError) {
    throw new Error(fetchError.message);
  }
  if (!data) {
    throw new Error("Позиция не найдена");
  }
  if (data.contract_act_id) {
    throw new Error("Позиция уже в акте, менять её нельзя");
  }
  if (data.work_id !== draft.workId) {
    throw new Error("Позиция не относится к этой смене");
  }

  await assertCanWriteWorkItems(draft.workId);

  const quantity = draft.quantity;
  if (quantity < 0) {
    throw new Error("Количество не может быть отрицательным");
  }

  const { error } = await client
    .from("work_items")
    .update({
      section: draft.section,
      floor: draft.floor,
      system: draft.system,
      subsystem: draft.subsystem,
      estimate_id: draft.estimateId,
      name: draft.name,
      unit: draft.unit,
      price: draft.price,
      quantity,
      total: workItemLineTotal(draft.price, quantity),
      contractor_id: draft.contractorId,
      specialists_count: draft.contractorId ? draft.specialistsCount : null,
      updated_at: new Date().toISOString(),
    })
    .eq("id", draft.itemId)
    .eq("company_id", companyId);

  if (error) {
    throw new Error(error.message);
  }
}
