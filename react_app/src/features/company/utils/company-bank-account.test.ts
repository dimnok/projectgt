import { describe, expect, it } from "vitest";

import type { CompanyBankAccountDraft } from "@/features/company/types/company.types";
import {
  bankAccountBlurError,
  isBankAccountFieldKey,
  validateBankAccountDraft,
} from "@/features/company/utils/company-bank-account";

const validDraft: CompanyBankAccountDraft = {
  bankName: "ПАО Сбербанк",
  bankCity: "Москва",
  accountNumber: "40702810000000000001",
  corrAccount: "30101810400000000225",
  bik: "044525225",
  isPrimary: true,
};

describe("bankAccountBlurError", () => {
  it("проверяет формат заполненного поля", () => {
    expect(bankAccountBlurError("accountNumber", validDraft.accountNumber)).toBe("");
    expect(bankAccountBlurError("accountNumber", "40702810")).toBe(
      "Расчётный счёт — 20 цифр"
    );
    expect(bankAccountBlurError("bik", "044525")).toBe("БИК — 9 цифр");
    expect(bankAccountBlurError("corrAccount", "301018")).toBe(
      "Корр. счёт — 20 цифр"
    );
  });

  it("не ругается на пустое значение — обязательность проверяет сохранение", () => {
    expect(bankAccountBlurError("bankName", "")).toBe("");
    expect(bankAccountBlurError("accountNumber", "")).toBe("");
    expect(bankAccountBlurError("bik", "")).toBe("");
  });
});

describe("isBankAccountFieldKey", () => {
  it("отличает проверяемые поля от остальных", () => {
    expect(isBankAccountFieldKey("bankName")).toBe(true);
    expect(isBankAccountFieldKey("bik")).toBe(true);
    expect(isBankAccountFieldKey("bankCity")).toBe(false);
    expect(isBankAccountFieldKey("isPrimary")).toBe(false);
  });
});

describe("validateBankAccountDraft", () => {
  it("принимает корректный счёт", () => {
    expect(validateBankAccountDraft(validDraft)).toEqual({});
  });

  it("требует наименование банка и расчётный счёт", () => {
    const errors = validateBankAccountDraft({
      ...validDraft,
      bankName: " ",
      accountNumber: "",
    });

    expect(errors.bankName).toBe("Введите наименование банка");
    expect(errors.accountNumber).toBe("Введите расчётный счёт");
  });

  it("проверяет длину БИК и корреспондентского счёта", () => {
    const errors = validateBankAccountDraft({
      ...validDraft,
      bik: "0445",
      corrAccount: "301018",
    });

    expect(errors.bik).toBe("БИК — 9 цифр");
    expect(errors.corrAccount).toBe("Корр. счёт — 20 цифр");
  });
});
