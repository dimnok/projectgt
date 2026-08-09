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

    /// Базовая сумма (без НДС).
    required double amount,

    /// Включён ли НДС в введённую сумму (true — «в том числе», false — «сверху»).
    @Default(true) bool isVatIncluded,

    /// Ставка НДС (в процентах). null = без НДС.
    double? vatRate,

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

  /// Допуск сравнения денежных сумм (копейки).
  static const amountEpsilon = 0.005;

  /// Остаток к оплате (может быть отрицательным при переплате).
  double get remainingAmount => totalToPay - paidAmount;

  /// Статус оплаты — всегда из сумм (единая логика в приложении).
  SettlementPaymentStatus get resolvedPaymentStatus =>
      computeSettlementPaymentStatus(
        totalToPay: totalToPay,
        paidAmount: paidAmount,
      );

  /// Положительный долг по счёту (0 при переплате или полной оплате).
  double get positiveDebt {
    final remaining = remainingAmount;
    return remaining > amountEpsilon ? remaining : 0;
  }

  /// Есть непогашенный остаток.
  bool get hasOutstandingDebt => remainingAmount > amountEpsilon;

  /// Есть переплата.
  bool get hasOverpayment => remainingAmount < -amountEpsilon;
}

/// Считает статус оплаты по суммам.
///
/// [totalToPay] — сумма к оплате; [paidAmount] — уже оплачено.
/// При нулевой сумме к оплате счёт считается оплаченным.
///
/// Должна совпадать с SQL-триггером `sync_settlement_payment_status`.
SettlementPaymentStatus computeSettlementPaymentStatus({
  required double totalToPay,
  required double paidAmount,
}) {
  const eps = SettlementOperation.amountEpsilon;
  if (totalToPay <= eps) {
    return paidAmount <= eps
        ? SettlementPaymentStatus.paid
        : SettlementPaymentStatus.overpaid;
  }
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

/// Агрегированные суммы по списку счетов.
extension SettlementOperationsTotals on List<SettlementOperation> {
  /// Сумма «к оплате» по всем счетам.
  double get totalAmount => fold<double>(0, (s, o) => s + o.totalToPay);

  /// Сумма оплат.
  double get totalPaid => fold<double>(0, (s, o) => s + o.paidAmount);

  /// Остаток долга (только положительные остатки).
  double get totalDebt => fold<double>(0, (s, o) => s + o.positiveDebt);
}
