import 'package:flutter/material.dart';
import 'package:projectgt/features/purchase_requests/domain/entities/purchase_request_status.dart';

/// Подписи и цвета UI модуля заявок на закупку.
abstract final class PurchaseRequestUiLabels {
  /// Фраза действия после ФИО: «Иванов И.И. создал заявку».
  static String historyActionPhrase(String action) => switch (action) {
    'created' => 'создал заявку',
    'submitted' => 'отправил на согласование',
    'resubmitted' => 'повторно отправил заявку',
    'approved' => 'согласовал',
    'returned' => 'вернул на доработку',
    'invoices_submitted' => 'отправил счета на согласование',
    'invoice_approved' => 'согласовал счет',
    'invoice_returned' => 'вернул счета на доработку',
    'queued_for_payment' => 'завёл на оплату',
    'paid' => 'оплатил',
    'received' => 'подтвердил получение',
    'cancelled' => 'вернул в черновик',
    _ => action,
  };

  /// Текст панели действий, когда у пользователя нет доступных операций.
  static String idleActionsMessage(PurchaseRequestStatus status) =>
      switch (status) {
        PurchaseRequestStatus.received => 'Заявка получена',
        PurchaseRequestStatus.cancelled => 'Заявка возвращена в черновик',
        _ => 'Ожидает действия ответственного',
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
      PurchaseRequestStatus.unknown =>
        dark ? const Color(0xFFBCAAA4) : const Color(0xFF6D4C41),
    };
  }
}
