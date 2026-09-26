import type {
  PurchaseRequestFile,
  PurchaseRequestInvoice,
} from "@/features/purchase-requests/types/purchase-request.types";

/** Форматы файла счёта, которые принимает форма. */
export const INVOICE_FILE_EXTENSIONS = ["pdf", "jpg", "jpeg", "png"] as const;

/**
 * Можно ли отправлять счета на согласование: счета есть и у каждого файл.
 * Те же правила проверяет серверная функция.
 */
export function purchaseRequestInvoicesReadyForSubmit(
  invoices: PurchaseRequestInvoice[]
) {
  if (invoices.length === 0) {
    return false;
  }
  return invoices.every((invoice) => Boolean(invoice.invoiceFile));
}

/** Файл можно показать внутри приложения: PDF или картинка. */
export function isPurchaseRequestInvoiceFilePreviewable(file: PurchaseRequestFile) {
  const name = file.fileName.toLowerCase();
  const mime = (file.mimeType ?? "").toLowerCase();
  return (
    mime.includes("pdf") ||
    mime.startsWith("image/") ||
    name.endsWith(".pdf") ||
    name.endsWith(".jpg") ||
    name.endsWith(".jpeg") ||
    name.endsWith(".png")
  );
}

/** PDF показываем встроенным просмотрщиком, остальное — как картинку. */
export function isPurchaseRequestInvoiceFilePdf(file: PurchaseRequestFile) {
  const name = file.fileName.toLowerCase();
  const mime = (file.mimeType ?? "").toLowerCase();
  return mime.includes("pdf") || name.endsWith(".pdf");
}

/** Тип файла по расширению: нужен, чтобы браузер показал PDF, а не скачал его. */
export function contentTypeForFileName(fileName: string) {
  const extension = fileName.split(".").pop()?.toLowerCase();
  if (extension === "pdf") {
    return "application/pdf";
  }
  if (extension === "jpg" || extension === "jpeg") {
    return "image/jpeg";
  }
  if (extension === "png") {
    return "image/png";
  }
  return "application/octet-stream";
}

/** Имя файла для хранилища: без пробелов и символов, ломающих путь. */
export function buildSafeStorageFileName(fileName: string) {
  return fileName.replaceAll(" ", "_").replace(/[^a-zA-Z0-9_.-]/g, "");
}
