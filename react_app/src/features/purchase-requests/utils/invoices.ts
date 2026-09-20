import type {
  PurchaseRequestFile,
  PurchaseRequestInvoice,
} from "@/features/purchase-requests/types/purchase-request.types";

export const INVOICE_FILE_EXTENSIONS = ["pdf", "jpg", "jpeg", "png"] as const;

export function purchaseRequestInvoicesReadyForSubmit(
  invoices: PurchaseRequestInvoice[]
) {
  if (invoices.length === 0) {
    return false;
  }
  return invoices.every((invoice) => Boolean(invoice.invoiceFile));
}

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

export function buildSafeStorageFileName(fileName: string) {
  return fileName.replaceAll(" ", "_").replace(/[^a-zA-Z0-9_.-]/g, "");
}
