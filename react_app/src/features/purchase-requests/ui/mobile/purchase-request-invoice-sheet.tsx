"use client";

import { MobileSheet } from "@/components/shared/mobile-sheet-chrome";
import {
  PurchaseRequestInvoiceForm,
  type PurchaseRequestInvoiceFormInput,
} from "@/features/purchase-requests/ui/shared/purchase-request-invoice-form";

type PurchaseRequestInvoiceSheetProps = {
  open: boolean;
  /** Заявка: нужна для распознавания счёта. */
  requestId: string;
  isSaving: boolean;
  onOpenChange: (open: boolean) => void;
  onSubmit: (input: PurchaseRequestInvoiceFormInput) => void;
};

/**
 * Добавление счёта на телефоне.
 *
 * Форма общая с настольным окном; здесь — только мобильное окно снизу.
 */
export function PurchaseRequestInvoiceSheet({
  open,
  requestId,
  isSaving,
  onOpenChange,
  onSubmit,
}: PurchaseRequestInvoiceSheetProps) {
  return (
    <MobileSheet open={open} onOpenChange={onOpenChange}>
      {open ? (
        <PurchaseRequestInvoiceForm
          layout="sheet"
          requestId={requestId}
          isSaving={isSaving}
          onCancel={() => onOpenChange(false)}
          onSubmit={onSubmit}
        />
      ) : null}
    </MobileSheet>
  );
}
