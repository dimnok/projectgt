import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:projectgt/features/cash_flow/domain/entities/cash_flow_category.dart';

part 'cash_flow_category_rule.freezed.dart';

/// Правило автосопоставления статьи ДДС по ключевому слову в назначении платежа.
@freezed
abstract class CashFlowCategoryRule with _$CashFlowCategoryRule {
  /// Создаёт [CashFlowCategoryRule].
  const factory CashFlowCategoryRule({
    /// Уникальный идентификатор.
    required String id,

    /// Компания-владелец.
    required String companyId,

    /// Статья ДДС, которую назначить при совпадении.
    required String categoryId,

    /// Ключевое слово (поиск без учёта регистра в назначении платежа).
    required String keyword,

    /// Тип операции, для которого применяется правило.
    required CashFlowOperationType operationType,

    /// Приоритет: больше — проверяется раньше.
    @Default(0) int priority,

    /// Нужна ли привязка к договору и объекту.
    ///
    /// `false` — операция обрабатывается только по статье (например, налоги).
    @Default(true) bool requiresContractBinding,

    /// Дата создания.
    DateTime? createdAt,

    /// Наименование категории (join для UI).
    String? categoryName,
  }) = _CashFlowCategoryRule;
}
