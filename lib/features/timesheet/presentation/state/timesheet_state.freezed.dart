// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'timesheet_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$TimesheetState {

/// Записи табеля за выбранный период.
 List<TimesheetEntry> get entries;/// Справочник сотрудников компании (загружается вместе с табелем).
 List<Employee> get employees;/// Идёт загрузка данных с сервера.
 bool get isLoading;/// Текст ошибки загрузки.
 String? get error;/// Начало периода (включительно).
 DateTime get startDate;/// Конец периода (включительно).
 DateTime get endDate;/// Выбранные объекты для клиентского фильтра (`null` — без фильтра).
 List<String>? get selectedObjectIds;/// Назначения в открытых сменах на сегодня (контроль выхода).
 TimesheetTodayOpenShiftIndex get todayOpenShift;
/// Create a copy of TimesheetState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TimesheetStateCopyWith<TimesheetState> get copyWith => _$TimesheetStateCopyWithImpl<TimesheetState>(this as TimesheetState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TimesheetState&&const DeepCollectionEquality().equals(other.entries, entries)&&const DeepCollectionEquality().equals(other.employees, employees)&&(identical(other.isLoading, isLoading) || other.isLoading == isLoading)&&(identical(other.error, error) || other.error == error)&&(identical(other.startDate, startDate) || other.startDate == startDate)&&(identical(other.endDate, endDate) || other.endDate == endDate)&&const DeepCollectionEquality().equals(other.selectedObjectIds, selectedObjectIds)&&(identical(other.todayOpenShift, todayOpenShift) || other.todayOpenShift == todayOpenShift));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(entries),const DeepCollectionEquality().hash(employees),isLoading,error,startDate,endDate,const DeepCollectionEquality().hash(selectedObjectIds),todayOpenShift);

@override
String toString() {
  return 'TimesheetState(entries: $entries, employees: $employees, isLoading: $isLoading, error: $error, startDate: $startDate, endDate: $endDate, selectedObjectIds: $selectedObjectIds, todayOpenShift: $todayOpenShift)';
}


}

/// @nodoc
abstract mixin class $TimesheetStateCopyWith<$Res>  {
  factory $TimesheetStateCopyWith(TimesheetState value, $Res Function(TimesheetState) _then) = _$TimesheetStateCopyWithImpl;
@useResult
$Res call({
 List<TimesheetEntry> entries, List<Employee> employees, bool isLoading, String? error, DateTime startDate, DateTime endDate, List<String>? selectedObjectIds, TimesheetTodayOpenShiftIndex todayOpenShift
});




}
/// @nodoc
class _$TimesheetStateCopyWithImpl<$Res>
    implements $TimesheetStateCopyWith<$Res> {
  _$TimesheetStateCopyWithImpl(this._self, this._then);

  final TimesheetState _self;
  final $Res Function(TimesheetState) _then;

/// Create a copy of TimesheetState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? entries = null,Object? employees = null,Object? isLoading = null,Object? error = freezed,Object? startDate = null,Object? endDate = null,Object? selectedObjectIds = freezed,Object? todayOpenShift = null,}) {
  return _then(_self.copyWith(
entries: null == entries ? _self.entries : entries // ignore: cast_nullable_to_non_nullable
as List<TimesheetEntry>,employees: null == employees ? _self.employees : employees // ignore: cast_nullable_to_non_nullable
as List<Employee>,isLoading: null == isLoading ? _self.isLoading : isLoading // ignore: cast_nullable_to_non_nullable
as bool,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as String?,startDate: null == startDate ? _self.startDate : startDate // ignore: cast_nullable_to_non_nullable
as DateTime,endDate: null == endDate ? _self.endDate : endDate // ignore: cast_nullable_to_non_nullable
as DateTime,selectedObjectIds: freezed == selectedObjectIds ? _self.selectedObjectIds : selectedObjectIds // ignore: cast_nullable_to_non_nullable
as List<String>?,todayOpenShift: null == todayOpenShift ? _self.todayOpenShift : todayOpenShift // ignore: cast_nullable_to_non_nullable
as TimesheetTodayOpenShiftIndex,
  ));
}

}


/// @nodoc


class _TimesheetState implements TimesheetState {
  const _TimesheetState({final  List<TimesheetEntry> entries = const [], final  List<Employee> employees = const [], this.isLoading = false, this.error, required this.startDate, required this.endDate, final  List<String>? selectedObjectIds, this.todayOpenShift = TimesheetTodayOpenShiftIndex.empty}): _entries = entries,_employees = employees,_selectedObjectIds = selectedObjectIds;
  

/// Записи табеля за выбранный период.
 final  List<TimesheetEntry> _entries;
/// Записи табеля за выбранный период.
@override@JsonKey() List<TimesheetEntry> get entries {
  if (_entries is EqualUnmodifiableListView) return _entries;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_entries);
}

/// Справочник сотрудников компании (загружается вместе с табелем).
 final  List<Employee> _employees;
/// Справочник сотрудников компании (загружается вместе с табелем).
@override@JsonKey() List<Employee> get employees {
  if (_employees is EqualUnmodifiableListView) return _employees;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_employees);
}

/// Идёт загрузка данных с сервера.
@override@JsonKey() final  bool isLoading;
/// Текст ошибки загрузки.
@override final  String? error;
/// Начало периода (включительно).
@override final  DateTime startDate;
/// Конец периода (включительно).
@override final  DateTime endDate;
/// Выбранные объекты для клиентского фильтра (`null` — без фильтра).
 final  List<String>? _selectedObjectIds;
/// Выбранные объекты для клиентского фильтра (`null` — без фильтра).
@override List<String>? get selectedObjectIds {
  final value = _selectedObjectIds;
  if (value == null) return null;
  if (_selectedObjectIds is EqualUnmodifiableListView) return _selectedObjectIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}

/// Назначения в открытых сменах на сегодня (контроль выхода).
@override@JsonKey() final  TimesheetTodayOpenShiftIndex todayOpenShift;

/// Create a copy of TimesheetState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TimesheetStateCopyWith<_TimesheetState> get copyWith => __$TimesheetStateCopyWithImpl<_TimesheetState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TimesheetState&&const DeepCollectionEquality().equals(other._entries, _entries)&&const DeepCollectionEquality().equals(other._employees, _employees)&&(identical(other.isLoading, isLoading) || other.isLoading == isLoading)&&(identical(other.error, error) || other.error == error)&&(identical(other.startDate, startDate) || other.startDate == startDate)&&(identical(other.endDate, endDate) || other.endDate == endDate)&&const DeepCollectionEquality().equals(other._selectedObjectIds, _selectedObjectIds)&&(identical(other.todayOpenShift, todayOpenShift) || other.todayOpenShift == todayOpenShift));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_entries),const DeepCollectionEquality().hash(_employees),isLoading,error,startDate,endDate,const DeepCollectionEquality().hash(_selectedObjectIds),todayOpenShift);

@override
String toString() {
  return 'TimesheetState(entries: $entries, employees: $employees, isLoading: $isLoading, error: $error, startDate: $startDate, endDate: $endDate, selectedObjectIds: $selectedObjectIds, todayOpenShift: $todayOpenShift)';
}


}

/// @nodoc
abstract mixin class _$TimesheetStateCopyWith<$Res> implements $TimesheetStateCopyWith<$Res> {
  factory _$TimesheetStateCopyWith(_TimesheetState value, $Res Function(_TimesheetState) _then) = __$TimesheetStateCopyWithImpl;
@override @useResult
$Res call({
 List<TimesheetEntry> entries, List<Employee> employees, bool isLoading, String? error, DateTime startDate, DateTime endDate, List<String>? selectedObjectIds, TimesheetTodayOpenShiftIndex todayOpenShift
});




}
/// @nodoc
class __$TimesheetStateCopyWithImpl<$Res>
    implements _$TimesheetStateCopyWith<$Res> {
  __$TimesheetStateCopyWithImpl(this._self, this._then);

  final _TimesheetState _self;
  final $Res Function(_TimesheetState) _then;

/// Create a copy of TimesheetState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? entries = null,Object? employees = null,Object? isLoading = null,Object? error = freezed,Object? startDate = null,Object? endDate = null,Object? selectedObjectIds = freezed,Object? todayOpenShift = null,}) {
  return _then(_TimesheetState(
entries: null == entries ? _self._entries : entries // ignore: cast_nullable_to_non_nullable
as List<TimesheetEntry>,employees: null == employees ? _self._employees : employees // ignore: cast_nullable_to_non_nullable
as List<Employee>,isLoading: null == isLoading ? _self.isLoading : isLoading // ignore: cast_nullable_to_non_nullable
as bool,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as String?,startDate: null == startDate ? _self.startDate : startDate // ignore: cast_nullable_to_non_nullable
as DateTime,endDate: null == endDate ? _self.endDate : endDate // ignore: cast_nullable_to_non_nullable
as DateTime,selectedObjectIds: freezed == selectedObjectIds ? _self._selectedObjectIds : selectedObjectIds // ignore: cast_nullable_to_non_nullable
as List<String>?,todayOpenShift: null == todayOpenShift ? _self.todayOpenShift : todayOpenShift // ignore: cast_nullable_to_non_nullable
as TimesheetTodayOpenShiftIndex,
  ));
}


}

// dart format on
