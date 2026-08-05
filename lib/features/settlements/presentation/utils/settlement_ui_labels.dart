import 'package:flutter/material.dart';
import 'package:projectgt/features/settlements/domain/entities/settlement_operation.dart';

/// Подписи типов операций взаиморасчётов.
String settlementOperationTypeLabel(SettlementOperationType type) {
  return switch (type) {
    SettlementOperationType.act => 'Акт',
    SettlementOperationType.advance => 'Аванс',
    SettlementOperationType.other => 'Прочее',
  };
}

/// Подпись статуса оплаты счёта для UI.
String settlementPaymentStatusLabel(SettlementPaymentStatus status) {
  return switch (status) {
    SettlementPaymentStatus.unpaid => 'Не оплачен',
    SettlementPaymentStatus.partial => 'Частично',
    SettlementPaymentStatus.paid => 'Оплачен',
    SettlementPaymentStatus.overpaid => 'Переплата',
  };
}

/// Цвет бейджа статуса оплаты.
Color settlementPaymentStatusColor(
  ThemeData theme,
  SettlementPaymentStatus status,
) {
  final dark = theme.brightness == Brightness.dark;
  return switch (status) {
    SettlementPaymentStatus.paid =>
      dark ? const Color(0xFF69F0AE) : const Color(0xFF1B5E20),
    SettlementPaymentStatus.partial =>
      dark ? const Color(0xFFFFB74D) : const Color(0xFFE65100),
    SettlementPaymentStatus.overpaid =>
      dark ? const Color(0xFF82B1FF) : const Color(0xFF1565C0),
    SettlementPaymentStatus.unpaid =>
      theme.colorScheme.onSurface.withValues(alpha: 0.45),
  };
}
