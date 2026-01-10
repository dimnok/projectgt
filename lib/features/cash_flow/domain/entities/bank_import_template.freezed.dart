// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'bank_import_template.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$BankImportTemplate {

/// Уникальный идентификатор шаблона.
 String get id;/// Идентификатор компании, которой принадлежит шаблон.
 String get companyId;/// Название банка или шаблона (например, "Тинькофф", "Сбер").
 String get bankName;/// Маппинг колонок: ключ - поле системы, значение - название колонки в Excel.
/// 
/// Ключи: date, amount, type, contractor_inn, contractor_name, comment, transaction_number.
 Map<String, String> get columnMapping;/// Номер строки, с которой начинаются данные (по умолчанию 1).
 int get startRow;/// Формат даты в файле (по умолчанию dd.MM.yyyy).
 String get dateFormat;
/// Create a copy of BankImportTemplate
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BankImportTemplateCopyWith<BankImportTemplate> get copyWith => _$BankImportTemplateCopyWithImpl<BankImportTemplate>(this as BankImportTemplate, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BankImportTemplate&&(identical(other.id, id) || other.id == id)&&(identical(other.companyId, companyId) || other.companyId == companyId)&&(identical(other.bankName, bankName) || other.bankName == bankName)&&const DeepCollectionEquality().equals(other.columnMapping, columnMapping)&&(identical(other.startRow, startRow) || other.startRow == startRow)&&(identical(other.dateFormat, dateFormat) || other.dateFormat == dateFormat));
}


@override
int get hashCode => Object.hash(runtimeType,id,companyId,bankName,const DeepCollectionEquality().hash(columnMapping),startRow,dateFormat);

@override
String toString() {
  return 'BankImportTemplate(id: $id, companyId: $companyId, bankName: $bankName, columnMapping: $columnMapping, startRow: $startRow, dateFormat: $dateFormat)';
}


}

/// @nodoc
abstract mixin class $BankImportTemplateCopyWith<$Res>  {
  factory $BankImportTemplateCopyWith(BankImportTemplate value, $Res Function(BankImportTemplate) _then) = _$BankImportTemplateCopyWithImpl;
@useResult
$Res call({
 String id, String companyId, String bankName, Map<String, String> columnMapping, int startRow, String dateFormat
});




}
/// @nodoc
class _$BankImportTemplateCopyWithImpl<$Res>
    implements $BankImportTemplateCopyWith<$Res> {
  _$BankImportTemplateCopyWithImpl(this._self, this._then);

  final BankImportTemplate _self;
  final $Res Function(BankImportTemplate) _then;

/// Create a copy of BankImportTemplate
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? companyId = null,Object? bankName = null,Object? columnMapping = null,Object? startRow = null,Object? dateFormat = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,companyId: null == companyId ? _self.companyId : companyId // ignore: cast_nullable_to_non_nullable
as String,bankName: null == bankName ? _self.bankName : bankName // ignore: cast_nullable_to_non_nullable
as String,columnMapping: null == columnMapping ? _self.columnMapping : columnMapping // ignore: cast_nullable_to_non_nullable
as Map<String, String>,startRow: null == startRow ? _self.startRow : startRow // ignore: cast_nullable_to_non_nullable
as int,dateFormat: null == dateFormat ? _self.dateFormat : dateFormat // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// @nodoc


class _BankImportTemplate implements BankImportTemplate {
  const _BankImportTemplate({required this.id, required this.companyId, required this.bankName, required final  Map<String, String> columnMapping, this.startRow = 1, this.dateFormat = 'dd.MM.yyyy'}): _columnMapping = columnMapping;
  

/// Уникальный идентификатор шаблона.
@override final  String id;
/// Идентификатор компании, которой принадлежит шаблон.
@override final  String companyId;
/// Название банка или шаблона (например, "Тинькофф", "Сбер").
@override final  String bankName;
/// Маппинг колонок: ключ - поле системы, значение - название колонки в Excel.
/// 
/// Ключи: date, amount, type, contractor_inn, contractor_name, comment, transaction_number.
 final  Map<String, String> _columnMapping;
/// Маппинг колонок: ключ - поле системы, значение - название колонки в Excel.
/// 
/// Ключи: date, amount, type, contractor_inn, contractor_name, comment, transaction_number.
@override Map<String, String> get columnMapping {
  if (_columnMapping is EqualUnmodifiableMapView) return _columnMapping;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_columnMapping);
}

/// Номер строки, с которой начинаются данные (по умолчанию 1).
@override@JsonKey() final  int startRow;
/// Формат даты в файле (по умолчанию dd.MM.yyyy).
@override@JsonKey() final  String dateFormat;

/// Create a copy of BankImportTemplate
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BankImportTemplateCopyWith<_BankImportTemplate> get copyWith => __$BankImportTemplateCopyWithImpl<_BankImportTemplate>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _BankImportTemplate&&(identical(other.id, id) || other.id == id)&&(identical(other.companyId, companyId) || other.companyId == companyId)&&(identical(other.bankName, bankName) || other.bankName == bankName)&&const DeepCollectionEquality().equals(other._columnMapping, _columnMapping)&&(identical(other.startRow, startRow) || other.startRow == startRow)&&(identical(other.dateFormat, dateFormat) || other.dateFormat == dateFormat));
}


@override
int get hashCode => Object.hash(runtimeType,id,companyId,bankName,const DeepCollectionEquality().hash(_columnMapping),startRow,dateFormat);

@override
String toString() {
  return 'BankImportTemplate(id: $id, companyId: $companyId, bankName: $bankName, columnMapping: $columnMapping, startRow: $startRow, dateFormat: $dateFormat)';
}


}

/// @nodoc
abstract mixin class _$BankImportTemplateCopyWith<$Res> implements $BankImportTemplateCopyWith<$Res> {
  factory _$BankImportTemplateCopyWith(_BankImportTemplate value, $Res Function(_BankImportTemplate) _then) = __$BankImportTemplateCopyWithImpl;
@override @useResult
$Res call({
 String id, String companyId, String bankName, Map<String, String> columnMapping, int startRow, String dateFormat
});




}
/// @nodoc
class __$BankImportTemplateCopyWithImpl<$Res>
    implements _$BankImportTemplateCopyWith<$Res> {
  __$BankImportTemplateCopyWithImpl(this._self, this._then);

  final _BankImportTemplate _self;
  final $Res Function(_BankImportTemplate) _then;

/// Create a copy of BankImportTemplate
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? companyId = null,Object? bankName = null,Object? columnMapping = null,Object? startRow = null,Object? dateFormat = null,}) {
  return _then(_BankImportTemplate(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,companyId: null == companyId ? _self.companyId : companyId // ignore: cast_nullable_to_non_nullable
as String,bankName: null == bankName ? _self.bankName : bankName // ignore: cast_nullable_to_non_nullable
as String,columnMapping: null == columnMapping ? _self._columnMapping : columnMapping // ignore: cast_nullable_to_non_nullable
as Map<String, String>,startRow: null == startRow ? _self.startRow : startRow // ignore: cast_nullable_to_non_nullable
as int,dateFormat: null == dateFormat ? _self.dateFormat : dateFormat // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
