"use client";

import { MobileSheet } from "@/components/shared/mobile-sheet-chrome";
import { CompanyBankAccountForm } from "@/features/company/ui/shared/company-bank-account-form";
import type {
  CompanyBankAccount,
  CompanyBankAccountDraft,
} from "@/features/company/types/company.types";

type CompanyBankAccountSheetProps = {
  open: boolean;
  account?: CompanyBankAccount | null;
  isSaving: boolean;
  onOpenChange: (open: boolean) => void;
  onSubmit: (draft: CompanyBankAccountDraft) => void;
};

/**
 * Создание и правка счёта на телефоне: окно снизу.
 *
 * Форма общая с настольным окном; здесь — только мобильное окно.
 */
export function CompanyBankAccountSheet({
  open,
  account,
  isSaving,
  onOpenChange,
  onSubmit,
}: CompanyBankAccountSheetProps) {
  return (
    <MobileSheet open={open} onOpenChange={onOpenChange}>
      {open ? (
        <CompanyBankAccountForm
          key={account?.id ?? "new"}
          layout="sheet"
          account={account ?? null}
          isSaving={isSaving}
          onCancel={() => onOpenChange(false)}
          onSubmit={onSubmit}
        />
      ) : null}
    </MobileSheet>
  );
}
