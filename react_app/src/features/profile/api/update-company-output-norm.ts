import { getRequiredClient } from "@/lib/supabase/client";
import { getActiveCompanyId } from "@/lib/supabase/company";

/**
 * Saves the company minimum output rate (₽ per person-hour).
 * Empty value clears the plan. Only the company owner can update (RLS).
 */
export async function updateCompanyMinOutputPerPersonHour(
  value: number | null
): Promise<void> {
  const client = getRequiredClient();
  const companyId = await getActiveCompanyId();

  if (value !== null && (!Number.isFinite(value) || value < 0)) {
    throw new Error("Укажите неотрицательную сумму в рублях");
  }

  const { error } = await client
    .from("companies")
    .update({
      min_output_per_person_hour: value,
      updated_at: new Date().toISOString(),
    })
    .eq("id", companyId);

  if (error) {
    if (error.code === "42501" || /policy|permission/i.test(error.message)) {
      throw new Error("Изменить норму может только владелец организации");
    }
    throw new Error(error.message);
  }
}
