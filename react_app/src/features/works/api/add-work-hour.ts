import { getActiveCompanyId } from "@/lib/supabase/company";
import { getRequiredClient } from "@/lib/supabase/client";
import { createId } from "@/lib/utils";
import { assertCanWriteWorkItems } from "@/features/works/api/get-work-membership";

export type AddWorkHourDraft = {
  employeeId: string;
  hours: number;
  comment: string | null;
};

/**
 * Adds one employee to a shift. Same table as Flutter `addWorkHour`.
 * Hours may be 0 — they can be filled later.
 */
export async function addWorkHour(
  workId: string,
  draft: AddWorkHourDraft
): Promise<void> {
  if (!workId) {
    throw new Error("Не указана смена");
  }
  if (!draft.employeeId) {
    throw new Error("Выберите сотрудника");
  }
  if (draft.hours < 0) {
    throw new Error("Часы не могут быть отрицательными");
  }

  const client = getRequiredClient();
  const companyId = await getActiveCompanyId();
  await assertCanWriteWorkItems(workId);

  const { data: existing, error: existingError } = await client
    .from("work_hours")
    .select("id")
    .eq("work_id", workId)
    .eq("employee_id", draft.employeeId)
    .eq("company_id", companyId)
    .maybeSingle();

  if (existingError) {
    throw new Error(existingError.message);
  }
  if (existing) {
    throw new Error("Этот сотрудник уже в смене");
  }

  const now = new Date().toISOString();
  const { error } = await client.from("work_hours").insert({
    id: createId(),
    company_id: companyId,
    work_id: workId,
    employee_id: draft.employeeId,
    hours: draft.hours,
    comment: draft.comment,
    created_at: now,
    updated_at: now,
  });

  if (error) {
    throw new Error(error.message);
  }
}
