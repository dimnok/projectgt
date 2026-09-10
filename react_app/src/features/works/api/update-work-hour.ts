import { getActiveCompanyId } from "@/lib/supabase/company";
import { getRequiredClient } from "@/lib/supabase/client";
import { assertCanWriteWorkItems } from "@/features/works/api/get-work-membership";

export type UpdateWorkHourDraft = {
  hourId: string;
  workId: string;
  hours: number;
  comment: string | null;
};

/**
 * Updates hours and comment. Employee on the row cannot be changed.
 * Same fields as Flutter `updateWorkHour`.
 */
export async function updateWorkHour(draft: UpdateWorkHourDraft): Promise<void> {
  if (draft.hours < 0) {
    throw new Error("Часы не могут быть отрицательными");
  }

  const client = getRequiredClient();
  const companyId = await getActiveCompanyId();

  const { data, error: fetchError } = await client
    .from("work_hours")
    .select("work_id")
    .eq("id", draft.hourId)
    .eq("company_id", companyId)
    .maybeSingle();

  if (fetchError) {
    throw new Error(fetchError.message);
  }
  if (!data) {
    throw new Error("Запись не найдена");
  }
  if (data.work_id !== draft.workId) {
    throw new Error("Запись не относится к этой смене");
  }

  await assertCanWriteWorkItems(draft.workId);

  const { error } = await client
    .from("work_hours")
    .update({
      hours: draft.hours,
      comment: draft.comment,
      updated_at: new Date().toISOString(),
    })
    .eq("id", draft.hourId)
    .eq("company_id", companyId);

  if (error) {
    throw new Error(error.message);
  }
}
