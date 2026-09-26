"use client";

import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";
import { CompanyBankAccountForm } from "@/features/company/ui/shared/company-bank-account-form";
import type {
  CompanyBankAccount,
  CompanyBankAccountDraft,
} from "@/features/company/types/company.types";

type CompanyBankAccountFormDialogProps = {
  open: boolean;
  account?: CompanyBankAccount | null;
  isSaving: boolean;
  onOpenChange: (open: boolean) => void;
  onSubmit: (draft: CompanyBankAccountDraft) => void;
};

/** Счёт компании: настольное окно. */
export function CompanyBankAccountFormDialog({
  open,
  account,
  isSaving,
  onOpenChange,
  onSubmit,
}: CompanyBankAccountFormDialogProps) {
  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="max-h-[min(90vh,40rem)] overflow-y-auto sm:max-w-lg">
        <DialogHeader>
          <DialogTitle>
            {account ? "Редактирование счёта" : "Новый счёт"}
          </DialogTitle>
          <DialogDescription>
            Название банка, БИК, расчётный и корреспондентский счёт.
          </DialogDescription>
        </DialogHeader>
        {open ? (
          <CompanyBankAccountForm
            key={account?.id ?? "new"}
            layout="dialog"
            account={account ?? null}
            isSaving={isSaving}
            onCancel={() => onOpenChange(false)}
            onSubmit={onSubmit}
          />
        ) : null}
      </DialogContent>
    </Dialog>
  );
}
