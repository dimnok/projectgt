import { getActiveCompanyId } from "@/lib/supabase/company";
import { getRequiredClient } from "@/lib/supabase/client";
import type { CompanyBankAccount, CompanyBankAccountDraft } from "@/features/company/types/company.types";
import {
  BANK_ACCOUNT_SELECT,
  mapBankAccountRow,
  toBankAccountPayload,
} from "@/features/company/utils/company-bank-account";

async function unsetOtherPrimaryAccounts(
  companyId: string,
  excludeId?: string
): Promise<void> {
  let query = getRequiredClient()
    .from("company_bank_accounts")
    .update({ is_primary: false })
    .eq("company_id", companyId)
    .eq("is_primary", true);

  if (excludeId) {
    query = query.neq("id", excludeId);
  }

  const { error } = await query;
  if (error) {
    throw new Error(error.message);
  }
}

/** Добавляет счёт компании. Если он основной — снимает флаг у остальных. */
export async function createCompanyBankAccount(
  draft: CompanyBankAccountDraft
): Promise<CompanyBankAccount> {
  const client = getRequiredClient();
  const companyId = await getActiveCompanyId();

  if (draft.isPrimary) {
    await unsetOtherPrimaryAccounts(companyId);
  }

  const { data, error } = await client
    .from("company_bank_accounts")
    .insert(toBankAccountPayload(companyId, draft))
    .select(BANK_ACCOUNT_SELECT)
    .single();

  if (error) {
    throw new Error(error.message);
  }

  return mapBankAccountRow(data);
}

/** Обновляет счёт компании. */
export async function updateCompanyBankAccount(
  accountId: string,
  draft: CompanyBankAccountDraft
): Promise<CompanyBankAccount> {
  const client = getRequiredClient();
  const companyId = await getActiveCompanyId();

  if (draft.isPrimary) {
    await unsetOtherPrimaryAccounts(companyId, accountId);
  }

  const { data, error } = await client
    .from("company_bank_accounts")
    .update(toBankAccountPayload(companyId, draft))
    .eq("id", accountId)
    .eq("company_id", companyId)
    .select(BANK_ACCOUNT_SELECT)
    .single();

  if (error) {
    throw new Error(error.message);
  }

  return mapBankAccountRow(data);
}
