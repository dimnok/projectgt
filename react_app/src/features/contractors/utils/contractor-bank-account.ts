import type {
  ContractorBankAccount,
  ContractorBankAccountDraft,
} from "@/features/contractors/types/contractor.types";
import type { ContractorBankAccountsRow } from "@/types/database.types";

export const BANK_ACCOUNT_SELECT =
  "id, company_id, contractor_id, bank_name, bank_city, bik, corr_account, account_number, is_primary";

export function digitsOnly(value: string, maxLength: number): string {
  return value.replace(/\D/g, "").slice(0, maxLength);
}

export function mapBankAccountRow(
  row: ContractorBankAccountsRow
): ContractorBankAccount {
  return {
    id: row.id,
    companyId: row.company_id ?? "",
    contractorId: row.contractor_id,
    bankName: row.bank_name.trim(),
    bankCity: row.bank_city?.trim() || null,
    bik: row.bik?.trim() || null,
    corrAccount: row.corr_account?.trim() || null,
    accountNumber: row.account_number.trim(),
    isPrimary: Boolean(row.is_primary),
  };
}

export function toBankAccountPayload(draft: ContractorBankAccountDraft) {
  return {
    bank_name: draft.bankName.trim(),
    bik: digitsOnly(draft.bik, 9) || null,
    account_number: digitsOnly(draft.accountNumber, 20),
    corr_account: digitsOnly(draft.corrAccount, 20) || null,
    is_primary: draft.isPrimary,
  };
}
