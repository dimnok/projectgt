"use client";

import { Dialog, DialogContent } from "@/components/ui/dialog";
import { SettlementPaymentForm } from "@/features/settlements/ui/shared/settlement-payment-form";
import type {
  SettlementPayment,
  SettlementPaymentDraft,
} from "@/features/settlements/types/settlement.types";

type SettlementPaymentDialogProps = {
  open: boolean;
  payment?: SettlementPayment | null;
  isSaving: boolean;
  onOpenChange: (open: boolean) => void;
  onSubmit: (draft: SettlementPaymentDraft) => void;
};

/** Настольное окно оплаты: добавить или изменить. */
export function SettlementPaymentDialog({
  open,
  payment,
  isSaving,
  onOpenChange,
  onSubmit,
}: SettlementPaymentDialogProps) {
  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent>
        <SettlementPaymentForm
          layout="dialog"
          payment={payment}
          isSaving={isSaving}
          onCancel={() => onOpenChange(false)}
          onSubmit={onSubmit}
        />
      </DialogContent>
    </Dialog>
  );
}
