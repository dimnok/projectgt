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
