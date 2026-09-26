import type { CompanyBankAccount, CompanyBankAccountDraft } from "@/features/company/types/company.types";
import { digitsOnly } from "@/features/company/utils/company.utils";

type BankAccountRow = {
  id: string;
  company_id: string;
  bank_name: string | null;
  bank_city: string | null;
  account_number: string | null;
  corr_account: string | null;
  bik: string | null;
  is_primary: boolean | null;
};

export const BANK_ACCOUNT_SELECT =
  "id, company_id, bank_name, bank_city, account_number, corr_account, bik, is_primary";

function asString(value: unknown): string | null {
  if (typeof value !== "string") {
    return null;
  }
  const trimmed = value.trim();
  return trimmed ? trimmed : null;
}

export function mapBankAccountRow(row: BankAccountRow): CompanyBankAccount {
  return {
    id: row.id,
    companyId: row.company_id,
    bankName: asString(row.bank_name) ?? "",
    bankCity: asString(row.bank_city),
    accountNumber: asString(row.account_number) ?? "",
    corrAccount: asString(row.corr_account),
    bik: asString(row.bik),
    isPrimary: row.is_primary === true,
  };
}

export function toBankAccountPayload(
  companyId: string,
  draft: CompanyBankAccountDraft
) {
  return {
    company_id: companyId,
    bank_name: draft.bankName.trim(),
    bank_city: draft.bankCity.trim() || null,
    account_number: digitsOnly(draft.accountNumber, 20),
    corr_account: digitsOnly(draft.corrAccount, 20) || null,
    bik: digitsOnly(draft.bik, 9) || null,
    is_primary: draft.isPrimary,
  };
}

export function toBankAccountDraft(
  account?: CompanyBankAccount | null
): CompanyBankAccountDraft {
  return {
    bankName: account?.bankName ?? "",
    bankCity: account?.bankCity ?? "",
    accountNumber: digitsOnly(account?.accountNumber ?? "", 20),
    corrAccount: digitsOnly(account?.corrAccount ?? "", 20),
    bik: digitsOnly(account?.bik ?? "", 9),
    isPrimary: account?.isPrimary ?? false,
  };
}

/** Проверки одного поля счёта: те же сообщения, что и при сохранении. */
export const bankAccountFieldValidators = {
  bankName: (value: string) =>
    value.trim() ? null : "Введите наименование банка",
  accountNumber: (value: string) => {
    const digits = digitsOnly(value);
    if (!digits) {
      return "Введите расчётный счёт";
    }
    return digits.length === 20 ? null : "Расчётный счёт — 20 цифр";
  },
  bik: (value: string) => {
    const digits = digitsOnly(value);
    return digits && digits.length !== 9 ? "БИК — 9 цифр" : null;
  },
  corrAccount: (value: string) => {
    const digits = digitsOnly(value);
    return digits && digits.length !== 20 ? "Корр. счёт — 20 цифр" : null;
  },
} as const;

export type BankAccountFieldKey = keyof typeof bankAccountFieldValidators;

export function isBankAccountFieldKey(
  key: string
): key is BankAccountFieldKey {
  return key in bankAccountFieldValidators;
}

/** Ошибки счёта при сохранении. */
export function validateBankAccountDraft(
  draft: CompanyBankAccountDraft
): Record<string, string> {
  const errors: Record<string, string> = {};

  for (const key of Object.keys(
    bankAccountFieldValidators
  ) as BankAccountFieldKey[]) {
    const error = bankAccountFieldValidators[key](draft[key]);
    if (error) {
      errors[key] = error;
    }
  }

  return errors;
}

/**
 * Проверка одного поля счёта при уходе из него. Пустое значение не считаем
 * ошибкой — обязательность проверяется при сохранении.
 */
export function bankAccountBlurError(
  key: BankAccountFieldKey,
  value: string
): string {
  return value.trim() ? (bankAccountFieldValidators[key](value) ?? "") : "";
}
