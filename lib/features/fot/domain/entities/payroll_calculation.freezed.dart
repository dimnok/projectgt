// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'payroll_calculation.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$PayrollCalculation {

/// Идентификатор сотрудника.
/// Может быть null в исключительных случаях (например, при ошибках данных).
 String? get employeeId;/// Месяц расчета (первый день месяца).
 DateTime get periodMonth;/// Отработанные часы за период.
 double get hoursWorked;/// Часовая ставка сотрудника.
 double get hourlyRate;/// Базовая сумма (hoursWorked * hourlyRate).
 double get baseSalary;/// Сумма премий.
 double get bonusesTotal;/// Сумма штрафов.
 double get penaltiesTotal;/// Сумма суточных выплат.
 double get businessTripTotal;/// К выплате (baseSalary + bonusesTotal + businessTripTotal - penaltiesTotal).
 double get netSalary;
/// Create a copy of PayrollCalculation
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PayrollCalculationCopyWith<PayrollCalculation> get copyWith => _$PayrollCalculationCopyWithImpl<PayrollCalculation>(this as PayrollCalculation, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PayrollCalculation&&(identical(other.employeeId, employeeId) || other.employeeId == employeeId)&&(identical(other.periodMonth, periodMonth) || other.periodMonth == periodMonth)&&(identical(other.hoursWorked, hoursWorked) || other.hoursWorked == hoursWorked)&&(identical(other.hourlyRate, hourlyRate) || other.hourlyRate == hourlyRate)&&(identical(other.baseSalary, baseSalary) || other.baseSalary == baseSalary)&&(identical(other.bonusesTotal, bonusesTotal) || other.bonusesTotal == bonusesTotal)&&(identical(other.penaltiesTotal, penaltiesTotal) || other.penaltiesTotal == penaltiesTotal)&&(identical(other.businessTripTotal, businessTripTotal) || other.businessTripTotal == businessTripTotal)&&(identical(other.netSalary, netSalary) || other.netSalary == netSalary));
}


@override
int get hashCode => Object.hash(runtimeType,employeeId,periodMonth,hoursWorked,hourlyRate,baseSalary,bonusesTotal,penaltiesTotal,businessTripTotal,netSalary);

@override
String toString() {
  return 'PayrollCalculation(employeeId: $employeeId, periodMonth: $periodMonth, hoursWorked: $hoursWorked, hourlyRate: $hourlyRate, baseSalary: $baseSalary, bonusesTotal: $bonusesTotal, penaltiesTotal: $penaltiesTotal, businessTripTotal: $businessTripTotal, netSalary: $netSalary)';
}


}

/// @nodoc
abstract mixin class $PayrollCalculationCopyWith<$Res>  {
  factory $PayrollCalculationCopyWith(PayrollCalculation value, $Res Function(PayrollCalculation) _then) = _$PayrollCalculationCopyWithImpl;
@useResult
$Res call({
 String? employeeId, DateTime periodMonth, double hoursWorked, double hourlyRate, double baseSalary, double bonusesTotal, double penaltiesTotal, double businessTripTotal, double netSalary
});




}
/// @nodoc
class _$PayrollCalculationCopyWithImpl<$Res>
    implements $PayrollCalculationCopyWith<$Res> {
  _$PayrollCalculationCopyWithImpl(this._self, this._then);

  final PayrollCalculation _self;
  final $Res Function(PayrollCalculation) _then;

/// Create a copy of PayrollCalculation
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? employeeId = freezed,Object? periodMonth = null,Object? hoursWorked = null,Object? hourlyRate = null,Object? baseSalary = null,Object? bonusesTotal = null,Object? penaltiesTotal = null,Object? businessTripTotal = null,Object? netSalary = null,}) {
  return _then(_self.copyWith(
employeeId: freezed == employeeId ? _self.employeeId : employeeId // ignore: cast_nullable_to_non_nullable
as String?,periodMonth: null == periodMonth ? _self.periodMonth : periodMonth // ignore: cast_nullable_to_non_nullable
as DateTime,hoursWorked: null == hoursWorked ? _self.hoursWorked : hoursWorked // ignore: cast_nullable_to_non_nullable
as double,hourlyRate: null == hourlyRate ? _self.hourlyRate : hourlyRate // ignore: cast_nullable_to_non_nullable
as double,baseSalary: null == baseSalary ? _self.baseSalary : baseSalary // ignore: cast_nullable_to_non_nullable
as double,bonusesTotal: null == bonusesTotal ? _self.bonusesTotal : bonusesTotal // ignore: cast_nullable_to_non_nullable
as double,penaltiesTotal: null == penaltiesTotal ? _self.penaltiesTotal : penaltiesTotal // ignore: cast_nullable_to_non_nullable
as double,businessTripTotal: null == businessTripTotal ? _self.businessTripTotal : businessTripTotal // ignore: cast_nullable_to_non_nullable
as double,netSalary: null == netSalary ? _self.netSalary : netSalary // ignore: cast_nullable_to_non_nullable
as double,
  ));
}

}


/// @nodoc


class _PayrollCalculation extends PayrollCalculation {
  const _PayrollCalculation({this.employeeId, required this.periodMonth, required this.hoursWorked, required this.hourlyRate, required this.baseSalary, this.bonusesTotal = 0, this.penaltiesTotal = 0, this.businessTripTotal = 0, required this.netSalary}): super._();
  

/// Идентификатор сотрудника.
/// Может быть null в исключительных случаях (например, при ошибках данных).
@override final  String? employeeId;
/// Месяц расчета (первый день месяца).
@override final  DateTime periodMonth;
/// Отработанные часы за период.
@override final  double hoursWorked;
/// Часовая ставка сотрудника.
@override final  double hourlyRate;
/// Базовая сумма (hoursWorked * hourlyRate).
@override final  double baseSalary;
/// Сумма премий.
@override@JsonKey() final  double bonusesTotal;
/// Сумма штрафов.
@override@JsonKey() final  double penaltiesTotal;
/// Сумма суточных выплат.
@override@JsonKey() final  double businessTripTotal;
/// К выплате (baseSalary + bonusesTotal + businessTripTotal - penaltiesTotal).
@override final  double netSalary;

/// Create a copy of PayrollCalculation
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PayrollCalculationCopyWith<_PayrollCalculation> get copyWith => __$PayrollCalculationCopyWithImpl<_PayrollCalculation>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PayrollCalculation&&(identical(other.employeeId, employeeId) || other.employeeId == employeeId)&&(identical(other.periodMonth, periodMonth) || other.periodMonth == periodMonth)&&(identical(other.hoursWorked, hoursWorked) || other.hoursWorked == hoursWorked)&&(identical(other.hourlyRate, hourlyRate) || other.hourlyRate == hourlyRate)&&(identical(other.baseSalary, baseSalary) || other.baseSalary == baseSalary)&&(identical(other.bonusesTotal, bonusesTotal) || other.bonusesTotal == bonusesTotal)&&(identical(other.penaltiesTotal, penaltiesTotal) || other.penaltiesTotal == penaltiesTotal)&&(identical(other.businessTripTotal, businessTripTotal) || other.businessTripTotal == businessTripTotal)&&(identical(other.netSalary, netSalary) || other.netSalary == netSalary));
}


@override
int get hashCode => Object.hash(runtimeType,employeeId,periodMonth,hoursWorked,hourlyRate,baseSalary,bonusesTotal,penaltiesTotal,businessTripTotal,netSalary);

@override
String toString() {
  return 'PayrollCalculation(employeeId: $employeeId, periodMonth: $periodMonth, hoursWorked: $hoursWorked, hourlyRate: $hourlyRate, baseSalary: $baseSalary, bonusesTotal: $bonusesTotal, penaltiesTotal: $penaltiesTotal, businessTripTotal: $businessTripTotal, netSalary: $netSalary)';
}


}

/// @nodoc
abstract mixin class _$PayrollCalculationCopyWith<$Res> implements $PayrollCalculationCopyWith<$Res> {
  factory _$PayrollCalculationCopyWith(_PayrollCalculation value, $Res Function(_PayrollCalculation) _then) = __$PayrollCalculationCopyWithImpl;
@override @useResult
$Res call({
 String? employeeId, DateTime periodMonth, double hoursWorked, double hourlyRate, double baseSalary, double bonusesTotal, double penaltiesTotal, double businessTripTotal, double netSalary
});




}
/// @nodoc
class __$PayrollCalculationCopyWithImpl<$Res>
    implements _$PayrollCalculationCopyWith<$Res> {
  __$PayrollCalculationCopyWithImpl(this._self, this._then);

  final _PayrollCalculation _self;
  final $Res Function(_PayrollCalculation) _then;

/// Create a copy of PayrollCalculation
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? employeeId = freezed,Object? periodMonth = null,Object? hoursWorked = null,Object? hourlyRate = null,Object? baseSalary = null,Object? bonusesTotal = null,Object? penaltiesTotal = null,Object? businessTripTotal = null,Object? netSalary = null,}) {
  return _then(_PayrollCalculation(
employeeId: freezed == employeeId ? _self.employeeId : employeeId // ignore: cast_nullable_to_non_nullable
as String?,periodMonth: null == periodMonth ? _self.periodMonth : periodMonth // ignore: cast_nullable_to_non_nullable
as DateTime,hoursWorked: null == hoursWorked ? _self.hoursWorked : hoursWorked // ignore: cast_nullable_to_non_nullable
as double,hourlyRate: null == hourlyRate ? _self.hourlyRate : hourlyRate // ignore: cast_nullable_to_non_nullable
as double,baseSalary: null == baseSalary ? _self.baseSalary : baseSalary // ignore: cast_nullable_to_non_nullable
as double,bonusesTotal: null == bonusesTotal ? _self.bonusesTotal : bonusesTotal // ignore: cast_nullable_to_non_nullable
as double,penaltiesTotal: null == penaltiesTotal ? _self.penaltiesTotal : penaltiesTotal // ignore: cast_nullable_to_non_nullable
as double,businessTripTotal: null == businessTripTotal ? _self.businessTripTotal : businessTripTotal // ignore: cast_nullable_to_non_nullable
as double,netSalary: null == netSalary ? _self.netSalary : netSalary // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}

// dart format on
