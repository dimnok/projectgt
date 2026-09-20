"use client";

import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";
import { SettlementForm } from "@/features/settlements/ui/shared/settlement-form";
import type { Contract } from "@/features/contracts/types/contract.types";
import type {
  Settlement,
  SettlementDraft,
  SettlementPickItem,
} from "@/features/settlements/types/settlement.types";

type SettlementFormDialogProps = {
  open: boolean;
  settlement?: Settlement | null;
  presetContract?: Contract | null;
  contractors: SettlementPickItem[];
  objects: SettlementPickItem[];
  contracts: Contract[];
  isSaving: boolean;
  onOpenChange: (open: boolean) => void;
  onSubmit: (draft: SettlementDraft) => void;
};

/** Настольное окно создания и правки счёта (форма общая с телефоном). */
export function SettlementFormDialog({
  open,
  settlement,
  presetContract,
  contractors,
  objects,
  contracts,
  isSaving,
  onOpenChange,
  onSubmit,
}: SettlementFormDialogProps) {
  const isNew = !settlement;

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="max-h-[min(92vh,56rem)] overflow-y-auto sm:max-w-3xl">
        <DialogHeader>
          <DialogTitle>{isNew ? "Новый счёт" : "Редактирование счёта"}</DialogTitle>
          <DialogDescription>
            Объект, контрагент, договор, номер и сумма обязательны. Оплаты
            добавляются в карточке счёта.
          </DialogDescription>
        </DialogHeader>
        <SettlementForm
          key={settlement?.id ?? presetContract?.id ?? "new"}
          layout="dialog"
          settlement={settlement}
          presetContract={presetContract}
          contractors={contractors}
          objects={objects}
          contracts={contracts}
          isSaving={isSaving}
          onCancel={() => onOpenChange(false)}
          onSubmit={onSubmit}
        />
      </DialogContent>
    </Dialog>
  );
}
