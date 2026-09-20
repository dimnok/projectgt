"use client";

import { useEffect, useRef, useState } from "react";
import { toast } from "sonner";

import { downloadPurchaseRequestInvoiceFile } from "@/features/purchase-requests/api/mutate-invoices";
import type { PurchaseRequestFile } from "@/features/purchase-requests/types/purchase-request.types";
import {
  contentTypeForFileName,
  isPurchaseRequestInvoiceFilePreviewable,
} from "@/features/purchase-requests/utils/invoices";

type InvoiceFilePreview = {
  file: PurchaseRequestFile;
  url: string;
};

/**
 * Просмотр и скачивание файла счёта внутри приложения.
 *
 * Отдаёт состояние занятости, открытый файл и адрес blob. Адрес освобождается
 * при замене файла, закрытии просмотра и уходе с экрана — без утечек памяти.
 */
export function usePurchaseRequestInvoiceFile() {
  const [busyFileId, setBusyFileId] = useState<string | null>(null);
  const [preview, setPreview] = useState<InvoiceFilePreview | null>(null);
  const previewUrlRef = useRef<string | null>(null);

  useEffect(() => {
    return () => {
      if (previewUrlRef.current) {
        URL.revokeObjectURL(previewUrlRef.current);
        previewUrlRef.current = null;
      }
    };
  }, []);

  /** Заменяет адрес просмотра, освобождая предыдущий. */
  function rememberPreviewUrl(url: string | null) {
    if (previewUrlRef.current && previewUrlRef.current !== url) {
      URL.revokeObjectURL(previewUrlRef.current);
    }
    previewUrlRef.current = url;
  }

  async function openFile(
    file: PurchaseRequestFile,
    mode: "preview" | "download"
  ) {
    try {
      setBusyFileId(file.id);
      const blob = await downloadPurchaseRequestInvoiceFile(file.storagePath);
      // Тип задаём явно: иначе браузер может скачать PDF вместо того, чтобы показать.
      const url = URL.createObjectURL(
        new Blob([blob], { type: contentTypeForFileName(file.fileName) })
      );

      if (mode === "download") {
        const anchor = document.createElement("a");
        anchor.href = url;
        anchor.download = file.fileName;
        document.body.appendChild(anchor);
        anchor.click();
        document.body.removeChild(anchor);
        window.setTimeout(() => URL.revokeObjectURL(url), 1000);
        return;
      }

      if (!isPurchaseRequestInvoiceFilePreviewable(file)) {
        toast.message("Этот формат нужно скачать");
        URL.revokeObjectURL(url);
        return;
      }

      rememberPreviewUrl(url);
      setPreview({ file, url });
    } catch (error) {
      toast.error(
        error instanceof Error ? error.message : "Не удалось открыть файл"
      );
    } finally {
      setBusyFileId(null);
    }
  }

  function closePreview() {
    rememberPreviewUrl(null);
    setPreview(null);
  }

  return { busyFileId, preview, openFile, closePreview };
}
