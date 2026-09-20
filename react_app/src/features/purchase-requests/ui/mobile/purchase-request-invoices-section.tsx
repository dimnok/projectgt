"use client";

import { DownloadIcon, EyeIcon, PlusIcon, Trash2Icon } from "lucide-react";

import { Button } from "@/components/ui/button";
import type {
  PurchaseRequestFile,
  PurchaseRequestInvoice,
} from "@/features/purchase-requests/types/purchase-request.types";
import { formatCurrency, formatRuDate } from "@/features/purchase-requests/utils/format";
import { PurchaseRequestInvoiceItemsList } from "@/features/purchase-requests/ui/shared/purchase-request-invoice-items-list";
import {
  EmptySection,
  SectionTitle,
} from "@/features/purchase-requests/ui/mobile/purchase-request-section";

type PurchaseRequestInvoicesSectionProps = {
  invoices: PurchaseRequestInvoice[];
  /** Можно добавлять и удалять счета. */
  canEdit: boolean;
  /** Файл, который сейчас открывается или скачивается. */
  busyFileId: string | null;
  /** Удаление счёта выполняется. */
  isDeleting: boolean;
  onAdd: () => void;
  onPreview: (file: PurchaseRequestFile) => void;
  onDownload: (file: PurchaseRequestFile) => void;
  onDelete: (invoiceId: string) => void;
};

/** Счета заявки: поставщик, сумма, файл и действия. */
export function PurchaseRequestInvoicesSection({
  invoices,
  canEdit,
  busyFileId,
  isDeleting,
  onAdd,
  onPreview,
  onDownload,
  onDelete,
}: PurchaseRequestInvoicesSectionProps) {
  return (
    <section className="flex flex-col gap-2">
      <SectionTitle
        title="Счета"
        count={invoices.length}
        action={
          canEdit ? (
            <Button type="button" size="sm" variant="ghost" onClick={onAdd}>
              <PlusIcon data-icon="inline-start" />
              Добавить
            </Button>
          ) : null
        }
      />

      {invoices.length === 0 ? (
        <EmptySection text="Счетов пока нет" />
      ) : (
        invoices.map((invoice) => (
          <div
            key={invoice.id}
            className="flex flex-col gap-2 rounded-xl border border-border/60 p-3"
          >
            <div className="flex items-start justify-between gap-2">
              <div className="min-w-0 flex-1">
                <p className="truncate text-sm font-medium">
                  {invoice.supplierName ?? "Поставщик"}
                </p>
                <p className="mt-0.5 truncate text-xs text-muted-foreground">
                  {[
                    invoice.invoiceNumber ?? "без номера",
                    formatRuDate(invoice.invoiceDate),
                  ]
                    .filter(Boolean)
                    .join(" · ")}
                </p>
              </div>
              <span className="shrink-0 text-sm font-semibold tabular-nums">
                {formatCurrency(invoice.amount)}
              </span>
            </div>

            <div className="flex items-center justify-between gap-2">
              <span className="min-w-0 truncate text-xs text-muted-foreground">
                {invoice.invoiceFile ? invoice.invoiceFile.fileName : "нет файла"}
              </span>
              <div className="flex shrink-0 items-center gap-1">
                {invoice.invoiceFile ? (
                  <>
                    <Button
                      type="button"
                      size="icon"
                      variant="ghost"
                      aria-label="Просмотреть счёт"
                      disabled={busyFileId === invoice.invoiceFile.id}
                      onClick={() => onPreview(invoice.invoiceFile!)}
                    >
                      <EyeIcon />
                    </Button>
                    <Button
                      type="button"
                      size="icon"
                      variant="ghost"
                      aria-label="Скачать счёт"
                      onClick={() => onDownload(invoice.invoiceFile!)}
                    >
                      <DownloadIcon />
                    </Button>
                  </>
                ) : null}
                {canEdit ? (
                  <Button
                    type="button"
                    size="icon"
                    variant="ghost"
                    className="text-destructive hover:text-destructive"
                    aria-label="Удалить счёт"
                    disabled={isDeleting}
                    onClick={() => onDelete(invoice.id)}
                  >
                    <Trash2Icon />
                  </Button>
                ) : null}
              </div>
            </div>

            <PurchaseRequestInvoiceItemsList items={invoice.items} />
          </div>
        ))
      )}
    </section>
  );
}
