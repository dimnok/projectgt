import 'package:freezed_annotation/freezed_annotation.dart';

part 'cash_flow_category.freezed.dart';

/// Тип операции в категории Cash Flow.
enum CashFlowOperationType {
  /// Только приход.
  income,
  /// Только расход.
  expense,
}

/// Сущность "Статья ДДС" (категория движения денежных средств).
///
/// Позволяет классифицировать финансовые операции.
@freezed
abstract class CashFlowCategory with _$CashFlowCategory {
  /// Создаёт экземпляр [CashFlowCategory].
  const factory CashFlowCategory({
    /// Уникальный идентификатор категории.
    required String id,
    /// Идентификатор компании, которой принадлежит категория.
    required String companyId,
    /// Наименование категории.
    required String name,
    /// Тип допустимых операций для этой категории.
    @Default(CashFlowOperationType.expense) CashFlowOperationType type,
    /// Дата создания.
    DateTime? createdAt,
  }) = _CashFlowCategory;

  const CashFlowCategory._();
}

