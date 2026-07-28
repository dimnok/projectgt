import 'package:freezed_annotation/freezed_annotation.dart';

part 'settlement_operation.freezed.dart';

/// Тип операции взаиморасчётов.
enum SettlementOperationType {
  /// Закрытие работ / поставки со счётом.
  act,

  /// Предоплата до акта.
  advance,

  /// Доплата, корректировка и иное.
  other,
}

/// Статус оплаты операции взаиморасчётов.
enum SettlementPaymentStatus {
  /// Ничего не оплачено.
  unpaid,

  /// Частичная оплата.
  partial,

  /// Полностью оплачено.
  paid,

  /// Оплачено больше, чем к оплате.
  overpaid,
}

/// Операция взаиморасчётов (акт / аванс / прочее).
@freezed
abstract class SettlementOperation with _$SettlementOperation {
  /// Создаёт [SettlementOperation].
  const factory SettlementOperation({
    /// Идентификатор записи.
    required String id,

    /// Компания-владелец.
    required String companyId,

    /// Тип операции.
    required SettlementOperationType operationType,

    /// Объект.
    required String objectId,

    /// Название объекта (join).
    String? objectName,

    /// Контрагент.
    required String contractorId,

    /// Название контрагента (join).
    String? contractorName,

    /// Договор.
    required String contractId,

    /// Номер договора (join).
    String? contractNumber,

    /// Начало периода работ (для типа акт).
    DateTime? periodFrom,

    /// Конец периода работ (для типа акт).
    DateTime? periodTo,

    /// Номер акта (для типа акт).
    String? actNumber,

    /// Дата акта (для типа акт).
    DateTime? actDate,

    /// Номер счёта.
    required String invoiceNumber,

    /// Дата счёта.
    required DateTime invoiceDate,

    /// Базовая сумма.
    required double amount,

    /// Сумма НДС.
    @Default(0) double vatAmount,

    /// Авансовые удержания (только акт).
    @Default(0) double advanceRetention,

    /// Гарантийные удержания (только акт).
    @Default(0) double warrantyRetention,

    /// К оплате (из БД / формулы).
    @Default(0) double totalToPay,

    /// Уже оплачено.
    @Default(0) double paidAmount,

    /// Статус оплаты.
    @Default(SettlementPaymentStatus.unpaid)
    SettlementPaymentStatus paymentStatus,

    /// Назначение (обязательно для «прочее»).
    String? purpose,

    /// Комментарий.
    String? note,

    /// Дата создания.
    DateTime? createdAt,

    /// Автор.
    String? createdBy,
  }) = _SettlementOperation;

  const SettlementOperation._();

  /// Остаток к оплате (может быть отрицательным при переплате).
  double get remainingAmount => totalToPay - paidAmount;
}

/// Считает «к оплате» по формуле v1.
double computeSettlementTotalToPay({
  required double amount,
  required double vatAmount,
  double advanceRetention = 0,
  double warrantyRetention = 0,
}) {
  final value = amount + vatAmount - advanceRetention - warrantyRetention;
  return value < 0 ? 0 : value;
}

/// Считает статус оплаты по суммам.
SettlementPaymentStatus computeSettlementPaymentStatus({
  required double totalToPay,
  required double paidAmount,
}) {
  const eps = 0.005;
  if (paidAmount <= eps) {
    return SettlementPaymentStatus.unpaid;
  }
  if (paidAmount + eps < totalToPay) {
    return SettlementPaymentStatus.partial;
  }
  if ((paidAmount - totalToPay).abs() <= eps) {
    return SettlementPaymentStatus.paid;
  }
  return SettlementPaymentStatus.overpaid;
}
