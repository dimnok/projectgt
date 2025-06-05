// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'export_filter_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ExportFilterModel {
  /// Дата начала периода.
  @JsonKey(name: 'date_from')
  DateTime get dateFrom;

  /// Дата окончания периода.
  @JsonKey(name: 'date_to')
  DateTime get dateTo;

  /// Идентификатор объекта для фильтрации.
  @JsonKey(name: 'object_id')
  String? get objectId;

  /// Идентификатор договора для фильтрации.
  @JsonKey(name: 'contract_id')
  String? get contractId;

  /// Система для фильтрации.
  String? get system;

  /// Подсистема для фильтрации.
  String? get subsystem;

  /// Create a copy of ExportFilterModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $ExportFilterModelCopyWith<ExportFilterModel> get copyWith =>
      _$ExportFilterModelCopyWithImpl<ExportFilterModel>(
          this as ExportFilterModel, _$identity);

  /// Serializes this ExportFilterModel to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is ExportFilterModel &&
            (identical(other.dateFrom, dateFrom) ||
                other.dateFrom == dateFrom) &&
            (identical(other.dateTo, dateTo) || other.dateTo == dateTo) &&
            (identical(other.objectId, objectId) ||
                other.objectId == objectId) &&
            (identical(other.contractId, contractId) ||
                other.contractId == contractId) &&
            (identical(other.system, system) || other.system == system) &&
            (identical(other.subsystem, subsystem) ||
                other.subsystem == subsystem));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType, dateFrom, dateTo, objectId, contractId, system, subsystem);

  @override
  String toString() {
    return 'ExportFilterModel(dateFrom: $dateFrom, dateTo: $dateTo, objectId: $objectId, contractId: $contractId, system: $system, subsystem: $subsystem)';
  }
}

/// @nodoc
abstract mixin class $ExportFilterModelCopyWith<$Res> {
  factory $ExportFilterModelCopyWith(
          ExportFilterModel value, $Res Function(ExportFilterModel) _then) =
      _$ExportFilterModelCopyWithImpl;
  @useResult
  $Res call(
      {@JsonKey(name: 'date_from') DateTime dateFrom,
      @JsonKey(name: 'date_to') DateTime dateTo,
      @JsonKey(name: 'object_id') String? objectId,
      @JsonKey(name: 'contract_id') String? contractId,
      String? system,
      String? subsystem});
}

/// @nodoc
class _$ExportFilterModelCopyWithImpl<$Res>
    implements $ExportFilterModelCopyWith<$Res> {
  _$ExportFilterModelCopyWithImpl(this._self, this._then);

  final ExportFilterModel _self;
  final $Res Function(ExportFilterModel) _then;

  /// Create a copy of ExportFilterModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? dateFrom = null,
    Object? dateTo = null,
    Object? objectId = freezed,
    Object? contractId = freezed,
    Object? system = freezed,
    Object? subsystem = freezed,
  }) {
    return _then(_self.copyWith(
      dateFrom: null == dateFrom
          ? _self.dateFrom
          : dateFrom // ignore: cast_nullable_to_non_nullable
              as DateTime,
      dateTo: null == dateTo
          ? _self.dateTo
          : dateTo // ignore: cast_nullable_to_non_nullable
              as DateTime,
      objectId: freezed == objectId
          ? _self.objectId
          : objectId // ignore: cast_nullable_to_non_nullable
              as String?,
      contractId: freezed == contractId
          ? _self.contractId
          : contractId // ignore: cast_nullable_to_non_nullable
              as String?,
      system: freezed == system
          ? _self.system
          : system // ignore: cast_nullable_to_non_nullable
              as String?,
      subsystem: freezed == subsystem
          ? _self.subsystem
          : subsystem // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _ExportFilterModel implements ExportFilterModel {
  const _ExportFilterModel(
      {@JsonKey(name: 'date_from') required this.dateFrom,
      @JsonKey(name: 'date_to') required this.dateTo,
      @JsonKey(name: 'object_id') this.objectId,
      @JsonKey(name: 'contract_id') this.contractId,
      this.system,
      this.subsystem});
  factory _ExportFilterModel.fromJson(Map<String, dynamic> json) =>
      _$ExportFilterModelFromJson(json);

  /// Дата начала периода.
  @override
  @JsonKey(name: 'date_from')
  final DateTime dateFrom;

  /// Дата окончания периода.
  @override
  @JsonKey(name: 'date_to')
  final DateTime dateTo;

  /// Идентификатор объекта для фильтрации.
  @override
  @JsonKey(name: 'object_id')
  final String? objectId;

  /// Идентификатор договора для фильтрации.
  @override
  @JsonKey(name: 'contract_id')
  final String? contractId;

  /// Система для фильтрации.
  @override
  final String? system;

  /// Подсистема для фильтрации.
  @override
  final String? subsystem;

  /// Create a copy of ExportFilterModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$ExportFilterModelCopyWith<_ExportFilterModel> get copyWith =>
      __$ExportFilterModelCopyWithImpl<_ExportFilterModel>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$ExportFilterModelToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _ExportFilterModel &&
            (identical(other.dateFrom, dateFrom) ||
                other.dateFrom == dateFrom) &&
            (identical(other.dateTo, dateTo) || other.dateTo == dateTo) &&
            (identical(other.objectId, objectId) ||
                other.objectId == objectId) &&
            (identical(other.contractId, contractId) ||
                other.contractId == contractId) &&
            (identical(other.system, system) || other.system == system) &&
            (identical(other.subsystem, subsystem) ||
                other.subsystem == subsystem));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType, dateFrom, dateTo, objectId, contractId, system, subsystem);

  @override
  String toString() {
    return 'ExportFilterModel(dateFrom: $dateFrom, dateTo: $dateTo, objectId: $objectId, contractId: $contractId, system: $system, subsystem: $subsystem)';
  }
}

/// @nodoc
abstract mixin class _$ExportFilterModelCopyWith<$Res>
    implements $ExportFilterModelCopyWith<$Res> {
  factory _$ExportFilterModelCopyWith(
          _ExportFilterModel value, $Res Function(_ExportFilterModel) _then) =
      __$ExportFilterModelCopyWithImpl;
  @override
  @useResult
  $Res call(
      {@JsonKey(name: 'date_from') DateTime dateFrom,
      @JsonKey(name: 'date_to') DateTime dateTo,
      @JsonKey(name: 'object_id') String? objectId,
      @JsonKey(name: 'contract_id') String? contractId,
      String? system,
      String? subsystem});
}

/// @nodoc
class __$ExportFilterModelCopyWithImpl<$Res>
    implements _$ExportFilterModelCopyWith<$Res> {
  __$ExportFilterModelCopyWithImpl(this._self, this._then);

  final _ExportFilterModel _self;
  final $Res Function(_ExportFilterModel) _then;

  /// Create a copy of ExportFilterModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? dateFrom = null,
    Object? dateTo = null,
    Object? objectId = freezed,
    Object? contractId = freezed,
    Object? system = freezed,
    Object? subsystem = freezed,
  }) {
    return _then(_ExportFilterModel(
      dateFrom: null == dateFrom
          ? _self.dateFrom
          : dateFrom // ignore: cast_nullable_to_non_nullable
              as DateTime,
      dateTo: null == dateTo
          ? _self.dateTo
          : dateTo // ignore: cast_nullable_to_non_nullable
              as DateTime,
      objectId: freezed == objectId
          ? _self.objectId
          : objectId // ignore: cast_nullable_to_non_nullable
              as String?,
      contractId: freezed == contractId
          ? _self.contractId
          : contractId // ignore: cast_nullable_to_non_nullable
              as String?,
      system: freezed == system
          ? _self.system
          : system // ignore: cast_nullable_to_non_nullable
              as String?,
      subsystem: freezed == subsystem
          ? _self.subsystem
          : subsystem // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

// dart format on
