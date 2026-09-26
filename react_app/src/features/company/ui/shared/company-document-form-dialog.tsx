"use client";

import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";
import { CompanyDocumentForm } from "@/features/company/ui/shared/company-document-form";
import type {
  CompanyDocument,
  CompanyDocumentDraft,
} from "@/features/company/types/company.types";

type CompanyDocumentFormDialogProps = {
  open: boolean;
  document?: CompanyDocument | null;
  isSaving: boolean;
  onOpenChange: (open: boolean) => void;
  onSubmit: (draft: CompanyDocumentDraft) => void;
};

/** Документ компании: настольное окно. */
export function CompanyDocumentFormDialog({
  open,
  document,
  isSaving,
  onOpenChange,
  onSubmit,
}: CompanyDocumentFormDialogProps) {
  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="max-h-[min(90vh,40rem)] overflow-y-auto sm:max-w-lg">
        <DialogHeader>
          <DialogTitle>
            {document ? "Редактирование документа" : "Новый документ"}
          </DialogTitle>
          <DialogDescription>
            Лицензии, допуски СРО и другие документы организации.
          </DialogDescription>
        </DialogHeader>
        {open ? (
          <CompanyDocumentForm
            key={document?.id ?? "new"}
            layout="dialog"
            document={document ?? null}
            isSaving={isSaving}
            onCancel={() => onOpenChange(false)}
            onSubmit={onSubmit}
          />
        ) : null}
      </DialogContent>
    </Dialog>
  );
}
