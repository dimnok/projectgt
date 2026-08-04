import 'package:collection/collection.dart';
import 'package:projectgt/features/settlements/domain/entities/settlement_operation.dart';

/// Подписи типов операций взаиморасчётов.
String settlementOperationTypeLabel(SettlementOperationType type) {
  return switch (type) {
    SettlementOperationType.act => 'Акт',
    SettlementOperationType.advance => 'Аванс',
    SettlementOperationType.other => 'Прочее',
  };
}

/// Подписи статусов оплаты.
String settlementPaymentStatusLabel(SettlementPaymentStatus status) {
  return switch (status) {
    SettlementPaymentStatus.unpaid => 'Не оплачен',
    SettlementPaymentStatus.partial => 'Частично оплачен',
    SettlementPaymentStatus.paid => 'Оплачен',
    SettlementPaymentStatus.overpaid => 'Переплата',
  };
}

/// Опция ставки НДС.
class SettlementVatRateOption {
  /// Подпись для UI.
  final String label;

  /// Ставка в процентах. null = без НДС.
  final double? rate;

  /// Создаёт опцию.
  const SettlementVatRateOption(this.label, this.rate);
}

/// Доступные ставки НДС (актуальны с 2026 года).
const settlementVatRateOptions = [
  SettlementVatRateOption('22 %', 22),
  SettlementVatRateOption('10 %', 10),
  SettlementVatRateOption('7 %', 7),
  SettlementVatRateOption('5 %', 5),
  SettlementVatRateOption('0 %', 0),
  SettlementVatRateOption('Без НДС', null),
];

/// Находит опцию ставки НДС по значению ставки.
SettlementVatRateOption? settlementVatRateOptionFor(double? rate) {
  return settlementVatRateOptions
      .firstWhereOrNull((o) => o.rate == rate);
}
