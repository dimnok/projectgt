import { getActiveCompanyId } from "@/lib/supabase/company";
import { getRequiredClient } from "@/lib/supabase/client";

/** Удаляет счёт компании. */
export async function deleteCompanyBankAccount(accountId: string): Promise<void> {
  const companyId = await getActiveCompanyId();

  const { error } = await getRequiredClient()
    .from("company_bank_accounts")
    .delete()
    .eq("id", accountId)
    .eq("company_id", companyId);

  if (error) {
    throw new Error(error.message);
  }
}
