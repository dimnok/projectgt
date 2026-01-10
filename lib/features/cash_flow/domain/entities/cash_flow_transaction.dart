import 'package:freezed_annotation/freezed_annotation.dart';

part 'cash_flow_transaction.freezed.dart';

/// Тип финансовой операции.
enum CashFlowType {
  /// Приход (поступление денежных средств).
  income,
  /// Расход (списание денежных средств).
  expense,
}

/// Сущность "Финансовая операция" (Cash Flow Transaction).
///
/// Описывает единичный факт движения денежных средств.
@freezed
abstract class CashFlowTransaction with _$CashFlowTransaction {
  /// Создаёт экземпляр [CashFlowTransaction].
  const factory CashFlowTransaction({
    /// Уникальный идентификатор операции.
    required String id,
    /// Идентификатор компании, которой принадлежит операция.
    required String companyId,
    /// Дата платежа.
    required DateTime date,
    /// Тип операции (приход/расход).
    required CashFlowType type,
    /// Сумма операции.
    required double amount,
    /// Идентификатор объекта (необязательно).
    String? objectId,
    /// Наименование объекта (подгружается для отображения).
    String? objectName,
    /// Идентификатор договора (необязательно).
    String? contractId,
    /// Номер договора (подгружается для отображения).
    String? contractNumber,
    /// Идентификатор контрагента (необязательно).
    String? contractorId,
    /// Наименование контрагента (подгружается для отображения или хранится текстом).
    String? contractorName,
    /// ИНН контрагента (для импортированных транзакций).
    String? contractorInn,
    /// Идентификатор статьи ДДС (необязательно).
    String? categoryId,
    /// Наименование статьи ДДС (подгружается для отображения).
    String? categoryName,
    /// Дата создания записи.
    DateTime? createdAt,
    /// Идентификатор создателя (профиль).
    String? createdBy,
    /// Имя создателя (подгружается для отображения).
    String? createdByName,
    /// Комментарий к операции.
    String? comment,
    /// Уникальный хеш операции для дедупликации (при импорте из банка).
    String? operationHash,
  }) = _CashFlowTransaction;

  const CashFlowTransaction._();
}

