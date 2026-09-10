import { getActiveCompanyId } from "@/lib/supabase/company";
import { getRequiredClient } from "@/lib/supabase/client";

export type DeleteEstimateFileInput = {
  contractId: string;
  estimateTitle: string;
};

/**
 * Deletes all positions of a specific estimate file belonging to a contract.
 */
export async function deleteEstimateFile(input: DeleteEstimateFileInput): Promise<number> {
  const { contractId, estimateTitle } = input;
  if (!contractId || !estimateTitle) {
    throw new Error("Не указан договор или название сметы");
  }

  const client = getRequiredClient();
  const companyId = await getActiveCompanyId();

  // Удаляем строки таблицы estimates с заданными параметрами
  const { error, count } = await client
    .from("estimates")
    .delete({ count: "exact" })
    .eq("company_id", companyId)
    .eq("contract_id", contractId)
    .eq("estimate_title", estimateTitle);

  if (error) {
    throw new Error(error.message || "Не удалось удалить смету");
  }

  return count ?? 0;
}

/**
 * Deletes a single estimate item by ID.
 */
export async function deleteEstimateItem(id: string): Promise<void> {
  if (!id) return;

  const client = getRequiredClient();
  const companyId = await getActiveCompanyId();

  const { error } = await client
    .from("estimates")
    .delete()
    .eq("company_id", companyId)
    .eq("id", id);

  if (error) {
    throw new Error(error.message || "Не удалось удалить позицию сметы");
  }
}
