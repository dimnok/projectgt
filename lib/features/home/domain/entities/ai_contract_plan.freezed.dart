// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'ai_contract_plan.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$AiContractPlan {

/// Номер анализируемого договора
@JsonKey(name: 'contract_number') String? get contractNumber;/// Общая сумма договора
@JsonKey(name: 'contract_amount') double? get contractAmount;/// Сумма выполненных работ
@JsonKey(name: 'executed_amount') double? get executedAmount;/// Осталось дней
@JsonKey(name: 'days_left') int? get daysLeft;/// Рекомендуемое количество монтажников для выполнения в срок
@JsonKey(name: 'required_installers') int get requiredInstallers;/// План по выработке на день в рублях
@JsonKey(name: 'daily_plan_amount') double get dailyPlanAmount;/// План по монтажникам на сегодня
@JsonKey(name: 'installers_plan_today') int get installersPlanToday;/// Средний факт монтажников (за последние 7 дней)
@JsonKey(name: 'average_installers_fact') int? get averageInstallersFact;/// Средний факт выработки (за последние 7 дней)
@JsonKey(name: 'average_daily_production_fact') double? get averageDailyProductionFact;/// Рекомендация от ИИ
 String get recommendation;
/// Create a copy of AiContractPlan
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AiContractPlanCopyWith<AiContractPlan> get copyWith => _$AiContractPlanCopyWithImpl<AiContractPlan>(this as AiContractPlan, _$identity);

  /// Serializes this AiContractPlan to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AiContractPlan&&(identical(other.contractNumber, contractNumber) || other.contractNumber == contractNumber)&&(identical(other.contractAmount, contractAmount) || other.contractAmount == contractAmount)&&(identical(other.executedAmount, executedAmount) || other.executedAmount == executedAmount)&&(identical(other.daysLeft, daysLeft) || other.daysLeft == daysLeft)&&(identical(other.requiredInstallers, requiredInstallers) || other.requiredInstallers == requiredInstallers)&&(identical(other.dailyPlanAmount, dailyPlanAmount) || other.dailyPlanAmount == dailyPlanAmount)&&(identical(other.installersPlanToday, installersPlanToday) || other.installersPlanToday == installersPlanToday)&&(identical(other.averageInstallersFact, averageInstallersFact) || other.averageInstallersFact == averageInstallersFact)&&(identical(other.averageDailyProductionFact, averageDailyProductionFact) || other.averageDailyProductionFact == averageDailyProductionFact)&&(identical(other.recommendation, recommendation) || other.recommendation == recommendation));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,contractNumber,contractAmount,executedAmount,daysLeft,requiredInstallers,dailyPlanAmount,installersPlanToday,averageInstallersFact,averageDailyProductionFact,recommendation);

@override
String toString() {
  return 'AiContractPlan(contractNumber: $contractNumber, contractAmount: $contractAmount, executedAmount: $executedAmount, daysLeft: $daysLeft, requiredInstallers: $requiredInstallers, dailyPlanAmount: $dailyPlanAmount, installersPlanToday: $installersPlanToday, averageInstallersFact: $averageInstallersFact, averageDailyProductionFact: $averageDailyProductionFact, recommendation: $recommendation)';
}


}

/// @nodoc
abstract mixin class $AiContractPlanCopyWith<$Res>  {
  factory $AiContractPlanCopyWith(AiContractPlan value, $Res Function(AiContractPlan) _then) = _$AiContractPlanCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'contract_number') String? contractNumber,@JsonKey(name: 'contract_amount') double? contractAmount,@JsonKey(name: 'executed_amount') double? executedAmount,@JsonKey(name: 'days_left') int? daysLeft,@JsonKey(name: 'required_installers') int requiredInstallers,@JsonKey(name: 'daily_plan_amount') double dailyPlanAmount,@JsonKey(name: 'installers_plan_today') int installersPlanToday,@JsonKey(name: 'average_installers_fact') int? averageInstallersFact,@JsonKey(name: 'average_daily_production_fact') double? averageDailyProductionFact, String recommendation
});




}
/// @nodoc
class _$AiContractPlanCopyWithImpl<$Res>
    implements $AiContractPlanCopyWith<$Res> {
  _$AiContractPlanCopyWithImpl(this._self, this._then);

  final AiContractPlan _self;
  final $Res Function(AiContractPlan) _then;

/// Create a copy of AiContractPlan
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? contractNumber = freezed,Object? contractAmount = freezed,Object? executedAmount = freezed,Object? daysLeft = freezed,Object? requiredInstallers = null,Object? dailyPlanAmount = null,Object? installersPlanToday = null,Object? averageInstallersFact = freezed,Object? averageDailyProductionFact = freezed,Object? recommendation = null,}) {
  return _then(_self.copyWith(
contractNumber: freezed == contractNumber ? _self.contractNumber : contractNumber // ignore: cast_nullable_to_non_nullable
as String?,contractAmount: freezed == contractAmount ? _self.contractAmount : contractAmount // ignore: cast_nullable_to_non_nullable
as double?,executedAmount: freezed == executedAmount ? _self.executedAmount : executedAmount // ignore: cast_nullable_to_non_nullable
as double?,daysLeft: freezed == daysLeft ? _self.daysLeft : daysLeft // ignore: cast_nullable_to_non_nullable
as int?,requiredInstallers: null == requiredInstallers ? _self.requiredInstallers : requiredInstallers // ignore: cast_nullable_to_non_nullable
as int,dailyPlanAmount: null == dailyPlanAmount ? _self.dailyPlanAmount : dailyPlanAmount // ignore: cast_nullable_to_non_nullable
as double,installersPlanToday: null == installersPlanToday ? _self.installersPlanToday : installersPlanToday // ignore: cast_nullable_to_non_nullable
as int,averageInstallersFact: freezed == averageInstallersFact ? _self.averageInstallersFact : averageInstallersFact // ignore: cast_nullable_to_non_nullable
as int?,averageDailyProductionFact: freezed == averageDailyProductionFact ? _self.averageDailyProductionFact : averageDailyProductionFact // ignore: cast_nullable_to_non_nullable
as double?,recommendation: null == recommendation ? _self.recommendation : recommendation // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// @nodoc
@JsonSerializable()

class _AiContractPlan implements AiContractPlan {
  const _AiContractPlan({@JsonKey(name: 'contract_number') this.contractNumber, @JsonKey(name: 'contract_amount') this.contractAmount, @JsonKey(name: 'executed_amount') this.executedAmount, @JsonKey(name: 'days_left') this.daysLeft, @JsonKey(name: 'required_installers') required this.requiredInstallers, @JsonKey(name: 'daily_plan_amount') required this.dailyPlanAmount, @JsonKey(name: 'installers_plan_today') required this.installersPlanToday, @JsonKey(name: 'average_installers_fact') this.averageInstallersFact, @JsonKey(name: 'average_daily_production_fact') this.averageDailyProductionFact, required this.recommendation});
  factory _AiContractPlan.fromJson(Map<String, dynamic> json) => _$AiContractPlanFromJson(json);

/// Номер анализируемого договора
@override@JsonKey(name: 'contract_number') final  String? contractNumber;
/// Общая сумма договора
@override@JsonKey(name: 'contract_amount') final  double? contractAmount;
/// Сумма выполненных работ
@override@JsonKey(name: 'executed_amount') final  double? executedAmount;
/// Осталось дней
@override@JsonKey(name: 'days_left') final  int? daysLeft;
/// Рекомендуемое количество монтажников для выполнения в срок
@override@JsonKey(name: 'required_installers') final  int requiredInstallers;
/// План по выработке на день в рублях
@override@JsonKey(name: 'daily_plan_amount') final  double dailyPlanAmount;
/// План по монтажникам на сегодня
@override@JsonKey(name: 'installers_plan_today') final  int installersPlanToday;
/// Средний факт монтажников (за последние 7 дней)
@override@JsonKey(name: 'average_installers_fact') final  int? averageInstallersFact;
/// Средний факт выработки (за последние 7 дней)
@override@JsonKey(name: 'average_daily_production_fact') final  double? averageDailyProductionFact;
/// Рекомендация от ИИ
@override final  String recommendation;

/// Create a copy of AiContractPlan
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AiContractPlanCopyWith<_AiContractPlan> get copyWith => __$AiContractPlanCopyWithImpl<_AiContractPlan>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AiContractPlanToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AiContractPlan&&(identical(other.contractNumber, contractNumber) || other.contractNumber == contractNumber)&&(identical(other.contractAmount, contractAmount) || other.contractAmount == contractAmount)&&(identical(other.executedAmount, executedAmount) || other.executedAmount == executedAmount)&&(identical(other.daysLeft, daysLeft) || other.daysLeft == daysLeft)&&(identical(other.requiredInstallers, requiredInstallers) || other.requiredInstallers == requiredInstallers)&&(identical(other.dailyPlanAmount, dailyPlanAmount) || other.dailyPlanAmount == dailyPlanAmount)&&(identical(other.installersPlanToday, installersPlanToday) || other.installersPlanToday == installersPlanToday)&&(identical(other.averageInstallersFact, averageInstallersFact) || other.averageInstallersFact == averageInstallersFact)&&(identical(other.averageDailyProductionFact, averageDailyProductionFact) || other.averageDailyProductionFact == averageDailyProductionFact)&&(identical(other.recommendation, recommendation) || other.recommendation == recommendation));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,contractNumber,contractAmount,executedAmount,daysLeft,requiredInstallers,dailyPlanAmount,installersPlanToday,averageInstallersFact,averageDailyProductionFact,recommendation);

@override
String toString() {
  return 'AiContractPlan(contractNumber: $contractNumber, contractAmount: $contractAmount, executedAmount: $executedAmount, daysLeft: $daysLeft, requiredInstallers: $requiredInstallers, dailyPlanAmount: $dailyPlanAmount, installersPlanToday: $installersPlanToday, averageInstallersFact: $averageInstallersFact, averageDailyProductionFact: $averageDailyProductionFact, recommendation: $recommendation)';
}


}

/// @nodoc
abstract mixin class _$AiContractPlanCopyWith<$Res> implements $AiContractPlanCopyWith<$Res> {
  factory _$AiContractPlanCopyWith(_AiContractPlan value, $Res Function(_AiContractPlan) _then) = __$AiContractPlanCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'contract_number') String? contractNumber,@JsonKey(name: 'contract_amount') double? contractAmount,@JsonKey(name: 'executed_amount') double? executedAmount,@JsonKey(name: 'days_left') int? daysLeft,@JsonKey(name: 'required_installers') int requiredInstallers,@JsonKey(name: 'daily_plan_amount') double dailyPlanAmount,@JsonKey(name: 'installers_plan_today') int installersPlanToday,@JsonKey(name: 'average_installers_fact') int? averageInstallersFact,@JsonKey(name: 'average_daily_production_fact') double? averageDailyProductionFact, String recommendation
});




}
/// @nodoc
class __$AiContractPlanCopyWithImpl<$Res>
    implements _$AiContractPlanCopyWith<$Res> {
  __$AiContractPlanCopyWithImpl(this._self, this._then);

  final _AiContractPlan _self;
  final $Res Function(_AiContractPlan) _then;

/// Create a copy of AiContractPlan
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? contractNumber = freezed,Object? contractAmount = freezed,Object? executedAmount = freezed,Object? daysLeft = freezed,Object? requiredInstallers = null,Object? dailyPlanAmount = null,Object? installersPlanToday = null,Object? averageInstallersFact = freezed,Object? averageDailyProductionFact = freezed,Object? recommendation = null,}) {
  return _then(_AiContractPlan(
contractNumber: freezed == contractNumber ? _self.contractNumber : contractNumber // ignore: cast_nullable_to_non_nullable
as String?,contractAmount: freezed == contractAmount ? _self.contractAmount : contractAmount // ignore: cast_nullable_to_non_nullable
as double?,executedAmount: freezed == executedAmount ? _self.executedAmount : executedAmount // ignore: cast_nullable_to_non_nullable
as double?,daysLeft: freezed == daysLeft ? _self.daysLeft : daysLeft // ignore: cast_nullable_to_non_nullable
as int?,requiredInstallers: null == requiredInstallers ? _self.requiredInstallers : requiredInstallers // ignore: cast_nullable_to_non_nullable
as int,dailyPlanAmount: null == dailyPlanAmount ? _self.dailyPlanAmount : dailyPlanAmount // ignore: cast_nullable_to_non_nullable
as double,installersPlanToday: null == installersPlanToday ? _self.installersPlanToday : installersPlanToday // ignore: cast_nullable_to_non_nullable
as int,averageInstallersFact: freezed == averageInstallersFact ? _self.averageInstallersFact : averageInstallersFact // ignore: cast_nullable_to_non_nullable
as int?,averageDailyProductionFact: freezed == averageDailyProductionFact ? _self.averageDailyProductionFact : averageDailyProductionFact // ignore: cast_nullable_to_non_nullable
as double?,recommendation: null == recommendation ? _self.recommendation : recommendation // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
