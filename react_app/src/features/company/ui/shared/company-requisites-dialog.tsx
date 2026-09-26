"use client";

import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";
import { CompanyRequisitesForm } from "@/features/company/ui/shared/company-requisites-form";
import type {
  CompanyDraft,
  CompanyProfile,
} from "@/features/company/types/company.types";

type CompanyRequisitesDialogProps = {
  open: boolean;
  company: CompanyProfile;
  isSaving: boolean;
  onOpenChange: (open: boolean) => void;
  onSubmit: (draft: CompanyDraft) => void;
};

/** Редактирование реквизитов компании: настольное окно. */
export function CompanyRequisitesDialog({
  open,
  company,
  isSaving,
  onOpenChange,
  onSubmit,
}: CompanyRequisitesDialogProps) {
  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="max-h-[min(92vh,52rem)] overflow-y-auto sm:max-w-2xl">
        <DialogHeader>
          <DialogTitle>Реквизиты компании</DialogTitle>
          <DialogDescription>
            Изменения сохраняются в карточку организации.
          </DialogDescription>
        </DialogHeader>
        {open ? (
          <CompanyRequisitesForm
            key={company.id}
            layout="dialog"
            company={company}
            isSaving={isSaving}
            onCancel={() => onOpenChange(false)}
            onSubmit={onSubmit}
          />
        ) : null}
      </DialogContent>
    </Dialog>
  );
}
