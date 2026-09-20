"use client";

import type { PurchaseRequestFile } from "@/features/purchase-requests/types/purchase-request.types";
import { isPurchaseRequestInvoiceFilePdf } from "@/features/purchase-requests/utils/invoices";
import { cn } from "@/lib/utils";

type PurchaseRequestFilePreviewContentProps = {
  file: PurchaseRequestFile;
  /** Адрес уже загруженного файла (blob). */
  url: string;
  className?: string;
};

/**
 * Содержимое просмотра счёта.
 *
 * PDF листается встроенным просмотрщиком браузера, картинка показывается
 * целиком. Рамку и размеры задаёт вызывающий компонент: на компьютере это
 * окно, на телефоне — панель снизу.
 */
export function PurchaseRequestFilePreviewContent({
  file,
  url,
  className,
}: PurchaseRequestFilePreviewContentProps) {
  return (
    <div
      className={cn(
        "flex min-h-0 flex-1 items-center justify-center overflow-auto bg-muted/40",
        className
      )}
    >
      {isPurchaseRequestInvoiceFilePdf(file) ? (
        <iframe
          src={url}
          title={file.fileName}
          className="h-full w-full border-0 bg-white"
        />
      ) : (
        // Blob-адрес загруженного файла: next/image здесь не нужен.
        // eslint-disable-next-line @next/next/no-img-element
        <img
          src={url}
          alt={file.fileName}
          className="max-h-full max-w-full object-contain"
        />
      )}
    </div>
  );
}
