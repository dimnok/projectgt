import { getActiveCompanyId } from "@/lib/supabase/company";
import { getRequiredClient } from "@/lib/supabase/client";
import {
  BANK_ACCOUNT_SELECT,
  mapBankAccountRow,
} from "@/features/contractors/utils/contractor-bank-account";
import type { ContractorBankAccount } from "@/features/contractors/types/contractor.types";
import type { ContractorBankAccountsRow } from "@/types/database.types";

/**
 * Loads bank accounts for a contractor in the active company.
 * Primary accounts come first, matching Flutter.
 */
export async function getContractorBankAccounts(
  contractorId: string
): Promise<ContractorBankAccount[]> {
  const client = getRequiredClient();
  const companyId = await getActiveCompanyId();

  const { data, error } = await client
    .from("contractor_bank_accounts")
    .select(BANK_ACCOUNT_SELECT)
    .eq("contractor_id", contractorId)
    .eq("company_id", companyId)
    .order("is_primary", { ascending: false });

  if (error) {
    throw new Error(error.message);
  }

  return ((data ?? []) as ContractorBankAccountsRow[]).map(mapBankAccountRow);
}
