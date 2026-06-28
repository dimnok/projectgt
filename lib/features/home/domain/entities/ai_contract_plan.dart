import 'package:freezed_annotation/freezed_annotation.dart';

part 'ai_contract_plan.freezed.dart';
part 'ai_contract_plan.g.dart';

/// Модель данных, возвращаемая AI-агентом для анализа плана по договору.
@freezed
abstract class AiContractPlan with _$AiContractPlan {
  /// Создаёт экземпляр [AiContractPlan].
  const factory AiContractPlan({
    /// Номер анализируемого договора
    @JsonKey(name: 'contract_number') String? contractNumber,
    
    /// Общая сумма договора
    @JsonKey(name: 'contract_amount') double? contractAmount,
    
    /// Сумма выполненных работ
    @JsonKey(name: 'executed_amount') double? executedAmount,
    
    /// Осталось дней
    @JsonKey(name: 'days_left') int? daysLeft,
    
    /// Рекомендуемое количество монтажников для выполнения в срок
    @JsonKey(name: 'required_installers') required int requiredInstallers,
    
    /// План по выработке на день в рублях
    @JsonKey(name: 'daily_plan_amount') required double dailyPlanAmount,
    
    /// План по монтажникам на сегодня
    @JsonKey(name: 'installers_plan_today') required int installersPlanToday,

    /// Средний факт монтажников (за последние 7 дней)
    @JsonKey(name: 'average_installers_fact') int? averageInstallersFact,

    /// Средний факт выработки (за последние 7 дней)
    @JsonKey(name: 'average_daily_production_fact') double? averageDailyProductionFact,
    
    /// Рекомендация от ИИ
    required String recommendation,
  }) = _AiContractPlan;

  /// Создаёт экземпляр из JSON ответа AI-агента.
  factory AiContractPlan.fromJson(Map<String, dynamic> json) =>
      _$AiContractPlanFromJson(json);
}
