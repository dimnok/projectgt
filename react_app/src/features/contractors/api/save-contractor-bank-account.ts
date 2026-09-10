import { getActiveCompanyId } from "@/lib/supabase/company";
import { getRequiredClient } from "@/lib/supabase/client";
import {
  BANK_ACCOUNT_SELECT,
  mapBankAccountRow,
  toBankAccountPayload,
} from "@/features/contractors/utils/contractor-bank-account";
import type {
  ContractorBankAccount,
  ContractorBankAccountDraft,
} from "@/features/contractors/types/contractor.types";
import type { ContractorBankAccountsRow } from "@/types/database.types";

async function unsetOtherPrimaryAccounts(
  contractorId: string,
  companyId: string,
  excludeId?: string
) {
  let query = getRequiredClient()
    .from("contractor_bank_accounts")
    .update({ is_primary: false })
    .eq("contractor_id", contractorId)
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

/**
 * Creates a bank account for a contractor.
 * If the account is primary, other accounts of this contractor are unset.
 */
export async function createContractorBankAccount(
  contractorId: string,
  draft: ContractorBankAccountDraft
): Promise<ContractorBankAccount> {
  const client = getRequiredClient();
  const companyId = await getActiveCompanyId();

  if (draft.isPrimary) {
    await unsetOtherPrimaryAccounts(contractorId, companyId);
  }

  const { data, error } = await client
    .from("contractor_bank_accounts")
    .insert({
      company_id: companyId,
      contractor_id: contractorId,
      ...toBankAccountPayload(draft),
    })
    .select(BANK_ACCOUNT_SELECT)
    .maybeSingle();

  if (error) {
    throw new Error(error.message);
  }

  if (!data) {
    throw new Error("Не удалось добавить счёт");
  }

  return mapBankAccountRow(data as ContractorBankAccountsRow);
}

/**
 * Updates a bank account. If it becomes primary, other accounts are unset.
 */
export async function updateContractorBankAccount(
  account: ContractorBankAccount,
  draft: ContractorBankAccountDraft
): Promise<ContractorBankAccount> {
  const client = getRequiredClient();
  const companyId = await getActiveCompanyId();

  if (draft.isPrimary) {
    await unsetOtherPrimaryAccounts(account.contractorId, companyId, account.id);
  }

  const { data, error } = await client
    .from("contractor_bank_accounts")
    .update(toBankAccountPayload(draft))
    .eq("id", account.id)
    .eq("company_id", companyId)
    .select(BANK_ACCOUNT_SELECT)
    .maybeSingle();

  if (error) {
    throw new Error(error.message);
  }

  if (!data) {
    throw new Error("Счёт не найден");
  }

  return mapBankAccountRow(data as ContractorBankAccountsRow);
}

/**
 * Deletes a contractor bank account.
 */
export async function deleteContractorBankAccount(id: string): Promise<void> {
  const client = getRequiredClient();
  const companyId = await getActiveCompanyId();

  const { error } = await client
    .from("contractor_bank_accounts")
    .delete()
    .eq("id", id)
    .eq("company_id", companyId);

  if (error) {
    throw new Error(error.message);
  }
}
