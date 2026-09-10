import { getActiveCompanyId } from "@/lib/supabase/company";
import { getRequiredClient } from "@/lib/supabase/client";
import { contractWriteError } from "@/features/contracts/utils/contract.utils";

/**
 * Deletes a contract from the active company.
 */
export async function deleteContract(id: string): Promise<void> {
  const client = getRequiredClient();
  const companyId = await getActiveCompanyId();

  const { error } = await client
    .from("contracts")
    .delete()
    .eq("id", id)
    .eq("company_id", companyId);

  if (error) {
    throw contractWriteError(error);
  }
}
