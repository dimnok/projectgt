import 'package:flutter/material.dart';
import 'package:projectgt/features/purchase_requests/domain/entities/purchase_request_status.dart';

/// Подписи и цвета UI модуля заявок на закупку.
abstract final class PurchaseRequestUiLabels {
  /// Подпись действия в истории.
  static String historyActionLabel(String action) => switch (action) {
        'created' => 'Создал заявку',
        'submitted' => 'Отправил на согласование',
        'resubmitted' => 'Повторно отправил заявку',
        'approved' => 'Согласовал',
        'returned' => 'Вернул на доработку',
        'invoices_submitted' => 'Отправил счета на согласование',
        'invoice_approved' => 'Согласовал счет',
        'invoice_returned' => 'Вернул счета на доработку',
        'queued_for_payment' => 'Заведено на оплату',
        'paid' => 'Оплачено',
        'received' => 'Материал получен',
        'cancelled' => 'Отменил заявку',
        _ => action,
      };

  /// Цвет статуса для бейджа.
  static Color statusColor(ThemeData theme, PurchaseRequestStatus status) {
    final dark = theme.brightness == Brightness.dark;
    return switch (status) {
      PurchaseRequestStatus.draft =>
        dark ? const Color(0xFFB0BEC5) : const Color(0xFF546E7A),
      PurchaseRequestStatus.approval =>
        dark ? const Color(0xFF64B5F6) : const Color(0xFF1565C0),
      PurchaseRequestStatus.revision =>
        dark ? const Color(0xFFFFB74D) : const Color(0xFFE65100),
      PurchaseRequestStatus.invoicePreparation =>
        dark ? const Color(0xFFBA68C8) : const Color(0xFF7B1FA2),
      PurchaseRequestStatus.invoiceApproval =>
        dark ? const Color(0xFF4FC3F7) : const Color(0xFF0277BD),
      PurchaseRequestStatus.accounting =>
        dark ? const Color(0xFF4DD0E1) : const Color(0xFF00838F),
      PurchaseRequestStatus.paymentQueue =>
        dark ? const Color(0xFFFFD54F) : const Color(0xFFF9A825),
      PurchaseRequestStatus.paid =>
        dark ? const Color(0xFF69F0AE) : const Color(0xFF2E7D32),
      PurchaseRequestStatus.received =>
        dark ? const Color(0xFFA5D6A7) : const Color(0xFF1B5E20),
      PurchaseRequestStatus.cancelled =>
        dark ? const Color(0xFFEF9A9A) : const Color(0xFFC62828),
    };
  }
}
