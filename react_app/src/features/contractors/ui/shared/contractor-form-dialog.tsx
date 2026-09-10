"use client";

import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";
import { ContractorForm } from "@/features/contractors/ui/shared/contractor-form";
import type {
  Contractor,
  ContractorDraft,
} from "@/features/contractors/types/contractor.types";

type ContractorFormDialogProps = {
  open: boolean;
  contractor?: Contractor | null;
  existingContractors: Contractor[];
  isSaving: boolean;
  onOpenChange: (open: boolean) => void;
  onSubmit: (draft: ContractorDraft) => void;
};

export function ContractorFormDialog({
  open,
  contractor,
  existingContractors,
  isSaving,
  onOpenChange,
  onSubmit,
}: ContractorFormDialogProps) {
  const isNew = !contractor;

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="max-h-[min(90vh,52rem)] overflow-y-auto sm:max-w-2xl">
        <DialogHeader>
          <DialogTitle>
            {isNew ? "Новый контрагент" : "Редактирование контрагента"}
          </DialogTitle>
          <DialogDescription>
            Полное и краткое наименование, ИНН и директор обязательны.
          </DialogDescription>
        </DialogHeader>
        <ContractorForm
          key={contractor?.id ?? "new"}
          contractor={contractor}
          existingContractors={existingContractors}
          isSaving={isSaving}
          onCancel={() => onOpenChange(false)}
          onSubmit={onSubmit}
        />
      </DialogContent>
    </Dialog>
  );
}
