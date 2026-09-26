"use client";

import { useState, type FormEvent } from "react";

import {
  MobileSheetBody,
  MobileSheetChrome,
} from "@/components/shared/mobile-sheet-chrome";
import { Button } from "@/components/ui/button";
import { DialogFooter } from "@/components/ui/dialog";
import {
  Field,
  FieldError,
  FieldGroup,
  FieldLabel,
} from "@/components/ui/field";
import { Input } from "@/components/ui/input";
import { Spinner } from "@/components/ui/spinner";
import { Switch } from "@/components/ui/switch";
import type {
  CompanyBankAccount,
  CompanyBankAccountDraft,
} from "@/features/company/types/company.types";
import {
  bankAccountBlurError,
  isBankAccountFieldKey,
  toBankAccountDraft,
  validateBankAccountDraft,
  type BankAccountFieldKey,
} from "@/features/company/utils/company-bank-account";
import { digitsOnly } from "@/features/company/utils/company.utils";

type CompanyBankAccountFormProps = {
  layout: "dialog" | "sheet";
  account: CompanyBankAccount | null;
  isSaving: boolean;
  onCancel: () => void;
  onSubmit: (draft: CompanyBankAccountDraft) => void;
};

/**
 * Счёт компании: общая форма для настольного окна и мобильного окна снизу.
 *
 * Поля проверяются при уходе из них, а при сохранении — все сразу.
 */
export function CompanyBankAccountForm({
  layout,
  account,
  isSaving,
  onCancel,
  onSubmit,
}: CompanyBankAccountFormProps) {
  const [draft, setDraft] = useState<CompanyBankAccountDraft>(() =>
    toBankAccountDraft(account)
  );
  const [errors, setErrors] = useState<Record<string, string>>({});

  function set<K extends keyof CompanyBankAccountDraft>(
    key: K,
    value: CompanyBankAccountDraft[K]
  ) {
    setDraft((prev) => ({ ...prev, [key]: value }));

    if (typeof value !== "string" || !isBankAccountFieldKey(key)) {
      return;
    }
    // Пока ошибка не исправлена, проверяем поле на каждый ввод: сообщение
    // исчезает сразу, как только значение стало верным.
    if (errors[key]) {
      setErrors((prev) => ({
        ...prev,
        [key]: bankAccountBlurError(key, value),
      }));
    }
  }

  function handleBlur(key: BankAccountFieldKey) {
    setErrors((prev) => ({
      ...prev,
      [key]: bankAccountBlurError(key, draft[key]),
    }));
  }

  function submitDraft() {
    const found = validateBankAccountDraft(draft);
    setErrors(found);
    if (Object.keys(found).length > 0) {
      return;
    }
    onSubmit(draft);
  }

  function handleSubmit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    submitDraft();
  }

  const fields = (
    <>
      <Field data-invalid={Boolean(errors.bankName)}>
        <FieldLabel htmlFor="bank-name">Наименование банка</FieldLabel>
        <Input
          id="bank-name"
          value={draft.bankName}
          disabled={isSaving}
          aria-invalid={Boolean(errors.bankName)}
          onChange={(event) => set("bankName", event.target.value)}
          onBlur={() => handleBlur("bankName")}
        />
        <FieldError>{errors.bankName}</FieldError>
      </Field>
      <Field>
        <FieldLabel htmlFor="bank-city">Город банка</FieldLabel>
        <Input
          id="bank-city"
          value={draft.bankCity}
          disabled={isSaving}
          onChange={(event) => set("bankCity", event.target.value)}
        />
      </Field>
      <Field data-invalid={Boolean(errors.accountNumber)}>
        <FieldLabel htmlFor="bank-account">Расчётный счёт</FieldLabel>
        <Input
          id="bank-account"
          value={draft.accountNumber}
          inputMode="numeric"
          disabled={isSaving}
          aria-invalid={Boolean(errors.accountNumber)}
          onChange={(event) =>
            set("accountNumber", digitsOnly(event.target.value, 20))
          }
          onBlur={() => handleBlur("accountNumber")}
        />
        <FieldError>{errors.accountNumber}</FieldError>
      </Field>
      <Field data-invalid={Boolean(errors.corrAccount)}>
        <FieldLabel htmlFor="bank-corr">Корреспондентский счёт</FieldLabel>
        <Input
          id="bank-corr"
          value={draft.corrAccount}
          inputMode="numeric"
          disabled={isSaving}
          aria-invalid={Boolean(errors.corrAccount)}
          onChange={(event) =>
            set("corrAccount", digitsOnly(event.target.value, 20))
          }
          onBlur={() => handleBlur("corrAccount")}
        />
        <FieldError>{errors.corrAccount}</FieldError>
      </Field>
      <Field data-invalid={Boolean(errors.bik)}>
        <FieldLabel htmlFor="bank-bik">БИК</FieldLabel>
        <Input
          id="bank-bik"
          value={draft.bik}
          inputMode="numeric"
          disabled={isSaving}
          aria-invalid={Boolean(errors.bik)}
          onChange={(event) => set("bik", digitsOnly(event.target.value, 9))}
          onBlur={() => handleBlur("bik")}
        />
        <FieldError>{errors.bik}</FieldError>
      </Field>
      <div className="flex items-center justify-between gap-3 rounded-lg border p-3">
        <div>
          <p className="text-sm font-medium">Основной счёт</p>
          <p className="text-xs text-muted-foreground">
            У компании может быть только один основной счёт.
          </p>
        </div>
        <Switch
          checked={draft.isPrimary}
          disabled={isSaving}
          onCheckedChange={(checked) => set("isPrimary", checked)}
        />
      </div>
    </>
  );

  if (layout === "sheet") {
    return (
      <>
        <MobileSheetChrome
          title={account ? "Редактирование счёта" : "Новый счёт"}
          description="Название банка, БИК, расчётный и корреспондентский счёт."
          confirmLabel="Сохранить"
          confirmPending={isSaving}
          onConfirm={submitDraft}
        />
        <MobileSheetBody>
          <FieldGroup>{fields}</FieldGroup>
        </MobileSheetBody>
      </>
    );
  }

  return (
    <form className="flex flex-col gap-4" onSubmit={handleSubmit}>
      <FieldGroup>{fields}</FieldGroup>
      <DialogFooter>
        <Button
          type="button"
          variant="outline"
          disabled={isSaving}
          onClick={onCancel}
        >
          Отмена
        </Button>
        <Button type="submit" disabled={isSaving}>
          {isSaving ? <Spinner data-icon="inline-start" /> : null}
          Сохранить
        </Button>
      </DialogFooter>
    </form>
  );
}
