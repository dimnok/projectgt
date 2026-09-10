"use client";

import { useState, type FormEvent } from "react";

import { Button } from "@/components/ui/button";
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";
import {
  Field,
  FieldContent,
  FieldDescription,
  FieldError,
  FieldGroup,
  FieldLabel,
} from "@/components/ui/field";
import { Input } from "@/components/ui/input";
import { Spinner } from "@/components/ui/spinner";
import { Switch } from "@/components/ui/switch";
import type {
  ContractorBankAccount,
  ContractorBankAccountDraft,
} from "@/features/contractors/types/contractor.types";
import { digitsOnly } from "@/features/contractors/utils/contractor-bank-account";

type ContractorBankAccountFormDialogProps = {
  open: boolean;
  account?: ContractorBankAccount | null;
  isSaving: boolean;
  onOpenChange: (open: boolean) => void;
  onSubmit: (draft: ContractorBankAccountDraft) => void;
};

type FormErrors = Partial<
  Record<"bankName" | "bik" | "accountNumber" | "corrAccount", string>
>;

function toDraft(
  account?: ContractorBankAccount | null
): ContractorBankAccountDraft {
  return {
    bankName: account?.bankName ?? "",
    bik: digitsOnly(account?.bik ?? "", 9),
    accountNumber: digitsOnly(account?.accountNumber ?? "", 20),
    corrAccount: digitsOnly(account?.corrAccount ?? "", 20),
    isPrimary: account?.isPrimary ?? false,
  };
}

export function ContractorBankAccountFormDialog({
  open,
  account,
  isSaving,
  onOpenChange,
  onSubmit,
}: ContractorBankAccountFormDialogProps) {
  const isNew = !account;

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="max-h-[min(90vh,40rem)] overflow-y-auto sm:max-w-lg">
        <DialogHeader>
          <DialogTitle>{isNew ? "Новый счёт" : "Редактирование счёта"}</DialogTitle>
          <DialogDescription>
            Название банка, БИК, номер счёта и корреспондентский счёт.
          </DialogDescription>
        </DialogHeader>
        <BankAccountForm
          key={account?.id ?? "new"}
          account={account}
          isSaving={isSaving}
          onCancel={() => onOpenChange(false)}
          onSubmit={onSubmit}
        />
      </DialogContent>
    </Dialog>
  );
}

function BankAccountForm({
  account,
  isSaving,
  onCancel,
  onSubmit,
}: {
  account?: ContractorBankAccount | null;
  isSaving: boolean;
  onCancel: () => void;
  onSubmit: (draft: ContractorBankAccountDraft) => void;
}) {
  const [draft, setDraft] = useState<ContractorBankAccountDraft>(() =>
    toDraft(account)
  );
  const [errors, setErrors] = useState<FormErrors>({});
  const isNew = !account;

  function update<K extends keyof ContractorBankAccountDraft>(
    key: K,
    value: ContractorBankAccountDraft[K]
  ) {
    setDraft((current) => ({ ...current, [key]: value }));
  }

  function validate(): FormErrors {
    const nextErrors: FormErrors = {};
    if (!draft.bankName.trim()) {
      nextErrors.bankName = "Введите название банка";
    }
    if (draft.bik.length !== 9) {
      nextErrors.bik = "БИК должен быть 9 цифр";
    }
    if (draft.accountNumber.length !== 20) {
      nextErrors.accountNumber = "Номер счёта должен быть 20 цифр";
    }
    if (draft.corrAccount.length !== 20) {
      nextErrors.corrAccount = "Корр. счёт должен быть 20 цифр";
    }
    return nextErrors;
  }

  function handleSubmit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    const nextErrors = validate();
    setErrors(nextErrors);
    if (Object.keys(nextErrors).length > 0) {
      return;
    }
    onSubmit(draft);
  }

  return (
    <form className="flex flex-col gap-4" onSubmit={handleSubmit}>
      <FieldGroup>
        <Field data-invalid={Boolean(errors.bankName)}>
          <FieldLabel htmlFor="bank-name">Название банка</FieldLabel>
          <Input
            id="bank-name"
            value={draft.bankName}
            disabled={isSaving}
            aria-invalid={Boolean(errors.bankName)}
            onChange={(event) => update("bankName", event.target.value)}
          />
          <FieldError>{errors.bankName}</FieldError>
        </Field>
        <Field data-invalid={Boolean(errors.bik)}>
          <FieldLabel htmlFor="bank-bik">БИК</FieldLabel>
          <Input
            id="bank-bik"
            value={draft.bik}
            disabled={isSaving}
            inputMode="numeric"
            autoComplete="off"
            aria-invalid={Boolean(errors.bik)}
            placeholder="9 цифр"
            onChange={(event) =>
              update("bik", digitsOnly(event.target.value, 9))
            }
          />
          <FieldError>{errors.bik}</FieldError>
        </Field>
        <Field data-invalid={Boolean(errors.accountNumber)}>
          <FieldLabel htmlFor="bank-account-number">Номер счёта</FieldLabel>
          <Input
            id="bank-account-number"
            value={draft.accountNumber}
            disabled={isSaving}
            inputMode="numeric"
            autoComplete="off"
            aria-invalid={Boolean(errors.accountNumber)}
            placeholder="20 цифр"
            onChange={(event) =>
              update("accountNumber", digitsOnly(event.target.value, 20))
            }
          />
          <FieldError>{errors.accountNumber}</FieldError>
        </Field>
        <Field data-invalid={Boolean(errors.corrAccount)}>
          <FieldLabel htmlFor="bank-corr-account">Корр. счёт</FieldLabel>
          <Input
            id="bank-corr-account"
            value={draft.corrAccount}
            disabled={isSaving}
            inputMode="numeric"
            autoComplete="off"
            aria-invalid={Boolean(errors.corrAccount)}
            placeholder="20 цифр"
            onChange={(event) =>
              update("corrAccount", digitsOnly(event.target.value, 20))
            }
          />
          <FieldError>{errors.corrAccount}</FieldError>
        </Field>
        <Field orientation="horizontal">
          <FieldContent>
            <FieldLabel htmlFor="bank-primary">Счёт по умолчанию</FieldLabel>
            <FieldDescription>
              У контрагента может быть только один основной счёт
            </FieldDescription>
          </FieldContent>
          <Switch
            id="bank-primary"
            checked={draft.isPrimary}
            disabled={isSaving}
            onCheckedChange={(checked) => update("isPrimary", checked)}
          />
        </Field>
      </FieldGroup>
      <div className="flex justify-end gap-2">
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
          {isNew ? "Добавить" : "Сохранить"}
        </Button>
      </div>
    </form>
  );
}
