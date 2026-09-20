"use client";

import { MobileSheet } from "@/components/shared/mobile-sheet-chrome";
import { SettlementPaymentForm } from "@/features/settlements/ui/shared/settlement-payment-form";
import type {
  SettlementPayment,
  SettlementPaymentDraft,
} from "@/features/settlements/types/settlement.types";

type SettlementPaymentSheetProps = {
  open: boolean;
  payment?: SettlementPayment | null;
  isSaving: boolean;
  onOpenChange: (open: boolean) => void;
  onSubmit: (draft: SettlementPaymentDraft) => void;
};

/**
 * Оплата на телефоне: форма общая с настольным окном, здесь — только
 * мобильное окно снизу.
 */
export function SettlementPaymentSheet({
  open,
  payment,
  isSaving,
  onOpenChange,
  onSubmit,
}: SettlementPaymentSheetProps) {
  return (
    <MobileSheet open={open} onOpenChange={onOpenChange}>
      {open ? (
        <SettlementPaymentForm
          key={payment?.id ?? "new"}
          layout="sheet"
          payment={payment}
          isSaving={isSaving}
          onCancel={() => onOpenChange(false)}
          onSubmit={onSubmit}
        />
      ) : null}
    </MobileSheet>
  );
}
