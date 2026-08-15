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
    final scheme = theme.colorScheme;
    return switch (status) {
      PurchaseRequestStatus.draft =>
        scheme.onSurface.withValues(alpha: 0.55),
      PurchaseRequestStatus.approval ||
      PurchaseRequestStatus.invoiceApproval ||
      PurchaseRequestStatus.accounting ||
      PurchaseRequestStatus.paymentQueue =>
        scheme.primary,
      PurchaseRequestStatus.revision => scheme.tertiary,
      PurchaseRequestStatus.invoicePreparation => scheme.secondary,
      PurchaseRequestStatus.paid || PurchaseRequestStatus.received =>
        Colors.green.shade700,
      PurchaseRequestStatus.cancelled =>
        scheme.onSurface.withValues(alpha: 0.35),
    };
  }
}
