"use client";

import { Dialog, DialogContent } from "@/components/ui/dialog";
import {
  PurchaseRequestInvoiceForm,
  type PurchaseRequestInvoiceFormInput,
} from "@/features/purchase-requests/ui/shared/purchase-request-invoice-form";

type PurchaseRequestInvoiceDialogProps = {
  open: boolean;
  /** Заявка: нужна для распознавания счёта. */
  requestId: string;
  isSaving: boolean;
  onOpenChange: (open: boolean) => void;
  onSubmit: (input: PurchaseRequestInvoiceFormInput) => void;
};

/**
 * Добавление счёта на компьютере.
 *
 * Форма общая с мобильным окном; здесь — только настольная рамка.
 * Содержимое монтируется при открытии, поэтому форма всегда открывается
 * с чистыми полями.
 */
export function PurchaseRequestInvoiceDialog({
  open,
  requestId,
  isSaving,
  onOpenChange,
  onSubmit,
}: PurchaseRequestInvoiceDialogProps) {
  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="sm:max-w-[1240px]">
        {open ? (
          <PurchaseRequestInvoiceForm
            layout="dialog"
            requestId={requestId}
            isSaving={isSaving}
            onCancel={() => onOpenChange(false)}
            onSubmit={onSubmit}
          />
        ) : null}
      </DialogContent>
    </Dialog>
  );
}
