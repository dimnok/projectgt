"use client";

import { MobileSheet } from "@/components/shared/mobile-sheet-chrome";
import { CompanyRequisitesForm } from "@/features/company/ui/shared/company-requisites-form";
import type {
  CompanyDraft,
  CompanyProfile,
} from "@/features/company/types/company.types";

type CompanyRequisitesSheetProps = {
  open: boolean;
  company: CompanyProfile;
  isSaving: boolean;
  onOpenChange: (open: boolean) => void;
  onSubmit: (draft: CompanyDraft) => void;
};

/**
 * Редактирование реквизитов компании на телефоне: окно снизу.
 *
 * Форма общая с настольным окном; здесь — только мобильное окно.
 */
export function CompanyRequisitesSheet({
  open,
  company,
  isSaving,
  onOpenChange,
  onSubmit,
}: CompanyRequisitesSheetProps) {
  return (
    <MobileSheet open={open} onOpenChange={onOpenChange}>
      {open ? (
        <CompanyRequisitesForm
          key={company.id}
          layout="sheet"
          company={company}
          isSaving={isSaving}
          onCancel={() => onOpenChange(false)}
          onSubmit={onSubmit}
        />
      ) : null}
    </MobileSheet>
  );
}
