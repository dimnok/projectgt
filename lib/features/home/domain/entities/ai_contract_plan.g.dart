// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ai_contract_plan.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_AiContractPlan _$AiContractPlanFromJson(Map<String, dynamic> json) =>
    _AiContractPlan(
      contractNumber: json['contract_number'] as String?,
      contractAmount: (json['contract_amount'] as num?)?.toDouble(),
      executedAmount: (json['executed_amount'] as num?)?.toDouble(),
      daysLeft: (json['days_left'] as num?)?.toInt(),
      requiredInstallers: (json['required_installers'] as num).toInt(),
      dailyPlanAmount: (json['daily_plan_amount'] as num).toDouble(),
      installersPlanToday: (json['installers_plan_today'] as num).toInt(),
      averageInstallersFact: (json['average_installers_fact'] as num?)?.toInt(),
      averageDailyProductionFact:
          (json['average_daily_production_fact'] as num?)?.toDouble(),
      recommendation: json['recommendation'] as String,
    );

Map<String, dynamic> _$AiContractPlanToJson(_AiContractPlan instance) =>
    <String, dynamic>{
      'contract_number': instance.contractNumber,
      'contract_amount': instance.contractAmount,
      'executed_amount': instance.executedAmount,
      'days_left': instance.daysLeft,
      'required_installers': instance.requiredInstallers,
      'daily_plan_amount': instance.dailyPlanAmount,
      'installers_plan_today': instance.installersPlanToday,
      'average_installers_fact': instance.averageInstallersFact,
      'average_daily_production_fact': instance.averageDailyProductionFact,
      'recommendation': instance.recommendation,
    };
