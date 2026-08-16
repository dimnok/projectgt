import 'package:projectgt/features/purchase_requests/domain/entities/purchase_request_file.dart';
import 'package:projectgt/features/purchase_requests/domain/entities/purchase_request_invoice.dart';

/// Проверяет готовность счетов к RPC `purchase_request_submit_invoices`.
bool purchaseRequestInvoicesReadyForSubmit(
  List<PurchaseRequestInvoice> invoices,
) {
  if (invoices.isEmpty) return false;
  return invoices.every((invoice) => invoice.hasInvoiceFile);
}

/// Можно ли открыть файл счёта внутри приложения (PDF или изображение).
bool isPurchaseRequestInvoiceFilePreviewable(PurchaseRequestFile file) {
  final name = file.fileName.toLowerCase();
  final mime = (file.mimeType ?? '').toLowerCase();
  return mime.contains('pdf') ||
      mime.startsWith('image/') ||
      name.endsWith('.pdf') ||
      name.endsWith('.jpg') ||
      name.endsWith('.jpeg') ||
      name.endsWith('.png');
}

