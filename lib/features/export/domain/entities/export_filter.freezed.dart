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

  /// Список идентификаторов объектов для фильтрации.
  List<String> get objectIds;

  /// Список идентификаторов договоров для фильтрации.
  List<String> get contractIds;

  /// Список систем для фильтрации.
  List<String> get systems;

  /// Список подсистем для фильтрации.
  List<String> get subsystems;

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
            const DeepCollectionEquality().equals(other.objectIds, objectIds) &&
            const DeepCollectionEquality()
                .equals(other.contractIds, contractIds) &&
            const DeepCollectionEquality().equals(other.systems, systems) &&
            const DeepCollectionEquality()
                .equals(other.subsystems, subsystems));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      dateFrom,
      dateTo,
      const DeepCollectionEquality().hash(objectIds),
      const DeepCollectionEquality().hash(contractIds),
      const DeepCollectionEquality().hash(systems),
      const DeepCollectionEquality().hash(subsystems));

  @override
  String toString() {
    return 'ExportFilter(dateFrom: $dateFrom, dateTo: $dateTo, objectIds: $objectIds, contractIds: $contractIds, systems: $systems, subsystems: $subsystems)';
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
      List<String> objectIds,
      List<String> contractIds,
      List<String> systems,
      List<String> subsystems});
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
    Object? objectIds = null,
    Object? contractIds = null,
    Object? systems = null,
    Object? subsystems = null,
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
      objectIds: null == objectIds
          ? _self.objectIds
          : objectIds // ignore: cast_nullable_to_non_nullable
              as List<String>,
      contractIds: null == contractIds
          ? _self.contractIds
          : contractIds // ignore: cast_nullable_to_non_nullable
              as List<String>,
      systems: null == systems
          ? _self.systems
          : systems // ignore: cast_nullable_to_non_nullable
              as List<String>,
      subsystems: null == subsystems
          ? _self.subsystems
          : subsystems // ignore: cast_nullable_to_non_nullable
              as List<String>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _ExportFilter implements ExportFilter {
  const _ExportFilter(
      {required this.dateFrom,
      required this.dateTo,
      final List<String> objectIds = const [],
      final List<String> contractIds = const [],
      final List<String> systems = const [],
      final List<String> subsystems = const []})
      : _objectIds = objectIds,
        _contractIds = contractIds,
        _systems = systems,
        _subsystems = subsystems;
  factory _ExportFilter.fromJson(Map<String, dynamic> json) =>
      _$ExportFilterFromJson(json);

  /// Дата начала периода.
  @override
  final DateTime dateFrom;

  /// Дата окончания периода.
  @override
  final DateTime dateTo;

  /// Список идентификаторов объектов для фильтрации.
  final List<String> _objectIds;

  /// Список идентификаторов объектов для фильтрации.
  @override
  @JsonKey()
  List<String> get objectIds {
    if (_objectIds is EqualUnmodifiableListView) return _objectIds;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_objectIds);
  }

  /// Список идентификаторов договоров для фильтрации.
  final List<String> _contractIds;

  /// Список идентификаторов договоров для фильтрации.
  @override
  @JsonKey()
  List<String> get contractIds {
    if (_contractIds is EqualUnmodifiableListView) return _contractIds;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_contractIds);
  }

  /// Список систем для фильтрации.
  final List<String> _systems;

  /// Список систем для фильтрации.
  @override
  @JsonKey()
  List<String> get systems {
    if (_systems is EqualUnmodifiableListView) return _systems;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_systems);
  }

  /// Список подсистем для фильтрации.
  final List<String> _subsystems;

  /// Список подсистем для фильтрации.
  @override
  @JsonKey()
  List<String> get subsystems {
    if (_subsystems is EqualUnmodifiableListView) return _subsystems;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_subsystems);
  }

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
            const DeepCollectionEquality()
                .equals(other._objectIds, _objectIds) &&
            const DeepCollectionEquality()
                .equals(other._contractIds, _contractIds) &&
            const DeepCollectionEquality().equals(other._systems, _systems) &&
            const DeepCollectionEquality()
                .equals(other._subsystems, _subsystems));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      dateFrom,
      dateTo,
      const DeepCollectionEquality().hash(_objectIds),
      const DeepCollectionEquality().hash(_contractIds),
      const DeepCollectionEquality().hash(_systems),
      const DeepCollectionEquality().hash(_subsystems));

  @override
  String toString() {
    return 'ExportFilter(dateFrom: $dateFrom, dateTo: $dateTo, objectIds: $objectIds, contractIds: $contractIds, systems: $systems, subsystems: $subsystems)';
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
      List<String> objectIds,
      List<String> contractIds,
      List<String> systems,
      List<String> subsystems});
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
    Object? objectIds = null,
    Object? contractIds = null,
    Object? systems = null,
    Object? subsystems = null,
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
      objectIds: null == objectIds
          ? _self._objectIds
          : objectIds // ignore: cast_nullable_to_non_nullable
              as List<String>,
      contractIds: null == contractIds
          ? _self._contractIds
          : contractIds // ignore: cast_nullable_to_non_nullable
              as List<String>,
      systems: null == systems
          ? _self._systems
          : systems // ignore: cast_nullable_to_non_nullable
              as List<String>,
      subsystems: null == subsystems
          ? _self._subsystems
          : subsystems // ignore: cast_nullable_to_non_nullable
              as List<String>,
    ));
  }
}

// dart format on
