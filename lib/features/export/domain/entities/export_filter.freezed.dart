// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'export_filter.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ExportFilter {
  /// Дата начала периода.
  DateTime get dateFrom;

  /// Дата окончания периода.
  DateTime get dateTo;

  /// Идентификатор объекта для фильтрации.
  String? get objectId;

  /// Идентификатор договора для фильтрации.
  String? get contractId;

  /// Система для фильтрации.
  String? get system;

  /// Подсистема для фильтрации.
  String? get subsystem;

  /// Create a copy of ExportFilter
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $ExportFilterCopyWith<ExportFilter> get copyWith =>
      _$ExportFilterCopyWithImpl<ExportFilter>(
          this as ExportFilter, _$identity);

  /// Serializes this ExportFilter to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is ExportFilter &&
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
    return 'ExportFilter(dateFrom: $dateFrom, dateTo: $dateTo, objectId: $objectId, contractId: $contractId, system: $system, subsystem: $subsystem)';
  }
}

/// @nodoc
abstract mixin class $ExportFilterCopyWith<$Res> {
  factory $ExportFilterCopyWith(
          ExportFilter value, $Res Function(ExportFilter) _then) =
      _$ExportFilterCopyWithImpl;
  @useResult
  $Res call(
      {DateTime dateFrom,
      DateTime dateTo,
      String? objectId,
      String? contractId,
      String? system,
      String? subsystem});
}

/// @nodoc
class _$ExportFilterCopyWithImpl<$Res> implements $ExportFilterCopyWith<$Res> {
  _$ExportFilterCopyWithImpl(this._self, this._then);

  final ExportFilter _self;
  final $Res Function(ExportFilter) _then;

  /// Create a copy of ExportFilter
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
class _ExportFilter implements ExportFilter {
  const _ExportFilter(
      {required this.dateFrom,
      required this.dateTo,
      this.objectId,
      this.contractId,
      this.system,
      this.subsystem});
  factory _ExportFilter.fromJson(Map<String, dynamic> json) =>
      _$ExportFilterFromJson(json);

  /// Дата начала периода.
  @override
  final DateTime dateFrom;

  /// Дата окончания периода.
  @override
  final DateTime dateTo;

  /// Идентификатор объекта для фильтрации.
  @override
  final String? objectId;

  /// Идентификатор договора для фильтрации.
  @override
  final String? contractId;

  /// Система для фильтрации.
  @override
  final String? system;

  /// Подсистема для фильтрации.
  @override
  final String? subsystem;

  /// Create a copy of ExportFilter
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$ExportFilterCopyWith<_ExportFilter> get copyWith =>
      __$ExportFilterCopyWithImpl<_ExportFilter>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$ExportFilterToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _ExportFilter &&
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
    return 'ExportFilter(dateFrom: $dateFrom, dateTo: $dateTo, objectId: $objectId, contractId: $contractId, system: $system, subsystem: $subsystem)';
  }
}

/// @nodoc
abstract mixin class _$ExportFilterCopyWith<$Res>
    implements $ExportFilterCopyWith<$Res> {
  factory _$ExportFilterCopyWith(
          _ExportFilter value, $Res Function(_ExportFilter) _then) =
      __$ExportFilterCopyWithImpl;
  @override
  @useResult
  $Res call(
      {DateTime dateFrom,
      DateTime dateTo,
      String? objectId,
      String? contractId,
      String? system,
      String? subsystem});
}

/// @nodoc
class __$ExportFilterCopyWithImpl<$Res>
    implements _$ExportFilterCopyWith<$Res> {
  __$ExportFilterCopyWithImpl(this._self, this._then);

  final _ExportFilter _self;
  final $Res Function(_ExportFilter) _then;

  /// Create a copy of ExportFilter
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
    return _then(_ExportFilter(
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
