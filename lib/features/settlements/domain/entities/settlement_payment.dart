import 'package:freezed_annotation/freezed_annotation.dart';

part 'settlement_payment.freezed.dart';

/// Запись об оплате по счёту взаиморасчётов.
@freezed
abstract class SettlementPayment with _$SettlementPayment {
  /// Создаёт [SettlementPayment].
  const factory SettlementPayment({
    /// Идентификатор записи.
    required String id,

    /// Компания-владелец.
    required String companyId,

    /// Счёт, к которому относится оплата.
    required String settlementOperationId,

    /// Дата оплаты.
    required DateTime paymentDate,

    /// Сумма оплаты.
    required double amount,

    /// Примечание.
    String? note,

    /// Дата создания.
    DateTime? createdAt,

    /// Автор записи.
    String? createdBy,
  }) = _SettlementPayment;
}
