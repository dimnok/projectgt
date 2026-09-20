import { getActiveCompanyId } from "@/lib/supabase/company";
import { getRequiredClient } from "@/lib/supabase/client";
import type { CompanyBankAccount } from "@/features/company/types/company.types";
import {
  BANK_ACCOUNT_SELECT,
  mapBankAccountRow,
} from "@/features/company/utils/company-bank-account";

/** Банковские счета активной компании. Основной счёт — первым. */
export async function getCompanyBankAccounts(): Promise<CompanyBankAccount[]> {
  const client = getRequiredClient();
  const companyId = await getActiveCompanyId();

  const { data, error } = await client
    .from("company_bank_accounts")
    .select(BANK_ACCOUNT_SELECT)
    .eq("company_id", companyId)
    .order("is_primary", { ascending: false });

  if (error) {
    throw new Error(error.message);
  }

  return (data ?? []).map(mapBankAccountRow);
}
