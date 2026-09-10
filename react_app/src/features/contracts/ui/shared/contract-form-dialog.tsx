"use client";

import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";
import { ContractForm } from "@/features/contracts/ui/shared/contract-form";
import type {
  Contract,
  ContractDraft,
  ContractPickItem,
} from "@/features/contracts/types/contract.types";

type ContractFormDialogProps = {
  open: boolean;
  contract?: Contract | null;
  contractors: ContractPickItem[];
  objects: ContractPickItem[];
  isSaving: boolean;
  onOpenChange: (open: boolean) => void;
  onSubmit: (draft: ContractDraft) => void;
};

export function ContractFormDialog({
  open,
  contract,
  contractors,
  objects,
  isSaving,
  onOpenChange,
  onSubmit,
}: ContractFormDialogProps) {
  const isNew = !contract;

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="max-h-[min(90vh,52rem)] overflow-y-auto sm:max-w-2xl">
        <DialogHeader>
          <DialogTitle>
            {isNew ? "Новый договор" : "Редактирование договора"}
          </DialogTitle>
          <DialogDescription>
            Номер, даты, контрагент, объект и сумма обязательны. Файлы и акты
            пока только в приложении.
          </DialogDescription>
        </DialogHeader>
        <ContractForm
          key={contract?.id ?? "new"}
          contract={contract}
          contractors={contractors}
          objects={objects}
          isSaving={isSaving}
          onCancel={() => onOpenChange(false)}
          onSubmit={onSubmit}
        />
      </DialogContent>
    </Dialog>
  );
}
