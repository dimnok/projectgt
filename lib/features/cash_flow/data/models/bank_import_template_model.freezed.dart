// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'bank_import_template_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$BankImportTemplateModel {

 String get id; String get companyId; String get bankName; Map<String, String> get columnMapping; int get startRow; String get dateFormat;
/// Create a copy of BankImportTemplateModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BankImportTemplateModelCopyWith<BankImportTemplateModel> get copyWith => _$BankImportTemplateModelCopyWithImpl<BankImportTemplateModel>(this as BankImportTemplateModel, _$identity);

  /// Serializes this BankImportTemplateModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BankImportTemplateModel&&(identical(other.id, id) || other.id == id)&&(identical(other.companyId, companyId) || other.companyId == companyId)&&(identical(other.bankName, bankName) || other.bankName == bankName)&&const DeepCollectionEquality().equals(other.columnMapping, columnMapping)&&(identical(other.startRow, startRow) || other.startRow == startRow)&&(identical(other.dateFormat, dateFormat) || other.dateFormat == dateFormat));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,companyId,bankName,const DeepCollectionEquality().hash(columnMapping),startRow,dateFormat);

@override
String toString() {
  return 'BankImportTemplateModel(id: $id, companyId: $companyId, bankName: $bankName, columnMapping: $columnMapping, startRow: $startRow, dateFormat: $dateFormat)';
}


}

/// @nodoc
abstract mixin class $BankImportTemplateModelCopyWith<$Res>  {
  factory $BankImportTemplateModelCopyWith(BankImportTemplateModel value, $Res Function(BankImportTemplateModel) _then) = _$BankImportTemplateModelCopyWithImpl;
@useResult
$Res call({
 String id, String companyId, String bankName, Map<String, String> columnMapping, int startRow, String dateFormat
});




}
/// @nodoc
class _$BankImportTemplateModelCopyWithImpl<$Res>
    implements $BankImportTemplateModelCopyWith<$Res> {
  _$BankImportTemplateModelCopyWithImpl(this._self, this._then);

  final BankImportTemplateModel _self;
  final $Res Function(BankImportTemplateModel) _then;

/// Create a copy of BankImportTemplateModel
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

@JsonSerializable(fieldRename: FieldRename.snake)
class _BankImportTemplateModel extends BankImportTemplateModel {
  const _BankImportTemplateModel({required this.id, required this.companyId, required this.bankName, required final  Map<String, String> columnMapping, this.startRow = 1, this.dateFormat = 'dd.MM.yyyy'}): _columnMapping = columnMapping,super._();
  factory _BankImportTemplateModel.fromJson(Map<String, dynamic> json) => _$BankImportTemplateModelFromJson(json);

@override final  String id;
@override final  String companyId;
@override final  String bankName;
 final  Map<String, String> _columnMapping;
@override Map<String, String> get columnMapping {
  if (_columnMapping is EqualUnmodifiableMapView) return _columnMapping;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_columnMapping);
}

@override@JsonKey() final  int startRow;
@override@JsonKey() final  String dateFormat;

/// Create a copy of BankImportTemplateModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BankImportTemplateModelCopyWith<_BankImportTemplateModel> get copyWith => __$BankImportTemplateModelCopyWithImpl<_BankImportTemplateModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BankImportTemplateModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _BankImportTemplateModel&&(identical(other.id, id) || other.id == id)&&(identical(other.companyId, companyId) || other.companyId == companyId)&&(identical(other.bankName, bankName) || other.bankName == bankName)&&const DeepCollectionEquality().equals(other._columnMapping, _columnMapping)&&(identical(other.startRow, startRow) || other.startRow == startRow)&&(identical(other.dateFormat, dateFormat) || other.dateFormat == dateFormat));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,companyId,bankName,const DeepCollectionEquality().hash(_columnMapping),startRow,dateFormat);

@override
String toString() {
  return 'BankImportTemplateModel(id: $id, companyId: $companyId, bankName: $bankName, columnMapping: $columnMapping, startRow: $startRow, dateFormat: $dateFormat)';
}


}

/// @nodoc
abstract mixin class _$BankImportTemplateModelCopyWith<$Res> implements $BankImportTemplateModelCopyWith<$Res> {
  factory _$BankImportTemplateModelCopyWith(_BankImportTemplateModel value, $Res Function(_BankImportTemplateModel) _then) = __$BankImportTemplateModelCopyWithImpl;
@override @useResult
$Res call({
 String id, String companyId, String bankName, Map<String, String> columnMapping, int startRow, String dateFormat
});




}
/// @nodoc
class __$BankImportTemplateModelCopyWithImpl<$Res>
    implements _$BankImportTemplateModelCopyWith<$Res> {
  __$BankImportTemplateModelCopyWithImpl(this._self, this._then);

  final _BankImportTemplateModel _self;
  final $Res Function(_BankImportTemplateModel) _then;

/// Create a copy of BankImportTemplateModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? companyId = null,Object? bankName = null,Object? columnMapping = null,Object? startRow = null,Object? dateFormat = null,}) {
  return _then(_BankImportTemplateModel(
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
