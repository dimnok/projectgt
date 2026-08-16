import 'package:projectgt/features/purchase_requests/domain/entities/purchase_request_file.dart';

/// Счёт поставщика по заявке (`purchase_request_invoices`).
class PurchaseRequestInvoice {
  /// Создаёт счёт.
  const PurchaseRequestInvoice({
    required this.id,
    required this.requestId,
    required this.companyId,
    required this.supplierId,
    this.supplierName,
    required this.amount,
    this.invoiceNumber,
    this.invoiceDate,
    this.comment,
    this.createdAt,
    this.invoiceFile,
  });

  /// Идентификатор счёта.
  final String id;

  /// Заявка.
  final String requestId;

  /// Компания.
  final String companyId;

  /// Поставщик (`contractors.id`).
  final String supplierId;

  /// Название поставщика для UI.
  final String? supplierName;

  /// Сумма счёта.
  final double amount;

  /// Номер счёта.
  final String? invoiceNumber;

  /// Дата счёта.
  final DateTime? invoiceDate;

  /// Комментарий.
  final String? comment;

  /// Дата создания записи.
  final DateTime? createdAt;

  /// Прикреплённый файл счёта (type = invoice).
  final PurchaseRequestFile? invoiceFile;

  /// Есть ли файл, необходимый для отправки на согласование.
  bool get hasInvoiceFile => invoiceFile != null;
}
