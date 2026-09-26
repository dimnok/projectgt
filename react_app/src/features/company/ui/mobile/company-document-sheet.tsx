"use client";

import { MobileSheet } from "@/components/shared/mobile-sheet-chrome";
import { CompanyDocumentForm } from "@/features/company/ui/shared/company-document-form";
import type {
  CompanyDocument,
  CompanyDocumentDraft,
} from "@/features/company/types/company.types";

type CompanyDocumentSheetProps = {
  open: boolean;
  document?: CompanyDocument | null;
  isSaving: boolean;
  onOpenChange: (open: boolean) => void;
  onSubmit: (draft: CompanyDocumentDraft) => void;
};

/**
 * Создание и правка документа на телефоне: окно снизу.
 *
 * Форма общая с настольным окном; здесь — только мобильное окно.
 */
export function CompanyDocumentSheet({
  open,
  document,
  isSaving,
  onOpenChange,
  onSubmit,
}: CompanyDocumentSheetProps) {
  return (
    <MobileSheet open={open} onOpenChange={onOpenChange}>
      {open ? (
        <CompanyDocumentForm
          key={document?.id ?? "new"}
          layout="sheet"
          document={document ?? null}
          isSaving={isSaving}
          onCancel={() => onOpenChange(false)}
          onSubmit={onSubmit}
        />
      ) : null}
    </MobileSheet>
  );
}
