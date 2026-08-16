import 'package:projectgt/features/purchase_requests/domain/entities/purchase_request_invoice.dart';

/// Проверяет готовность счетов к RPC `purchase_request_submit_invoices`.
bool purchaseRequestInvoicesReadyForSubmit(
  List<PurchaseRequestInvoice> invoices,
) {
  if (invoices.isEmpty) return false;
  return invoices.every((invoice) => invoice.hasInvoiceFile);
}
