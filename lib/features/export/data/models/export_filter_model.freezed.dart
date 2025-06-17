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

  /// Список идентификаторов объектов для фильтрации.
  @JsonKey(name: 'object_ids')
  List<String> get objectIds;

  /// Список идентификаторов договоров для фильтрации.
  @JsonKey(name: 'contract_ids')
  List<String> get contractIds;

  /// Список систем для фильтрации.
  List<String> get systems;

  /// Список подсистем для фильтрации.
  List<String> get subsystems;

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
    return 'ExportFilterModel(dateFrom: $dateFrom, dateTo: $dateTo, objectIds: $objectIds, contractIds: $contractIds, systems: $systems, subsystems: $subsystems)';
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
      @JsonKey(name: 'object_ids') List<String> objectIds,
      @JsonKey(name: 'contract_ids') List<String> contractIds,
      List<String> systems,
      List<String> subsystems});
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
class _ExportFilterModel implements ExportFilterModel {
  const _ExportFilterModel(
      {@JsonKey(name: 'date_from') required this.dateFrom,
      @JsonKey(name: 'date_to') required this.dateTo,
      @JsonKey(name: 'object_ids') final List<String> objectIds = const [],
      @JsonKey(name: 'contract_ids') final List<String> contractIds = const [],
      final List<String> systems = const [],
      final List<String> subsystems = const []})
      : _objectIds = objectIds,
        _contractIds = contractIds,
        _systems = systems,
        _subsystems = subsystems;
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

  /// Список идентификаторов объектов для фильтрации.
  final List<String> _objectIds;

  /// Список идентификаторов объектов для фильтрации.
  @override
  @JsonKey(name: 'object_ids')
  List<String> get objectIds {
    if (_objectIds is EqualUnmodifiableListView) return _objectIds;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_objectIds);
  }

  /// Список идентификаторов договоров для фильтрации.
  final List<String> _contractIds;

  /// Список идентификаторов договоров для фильтрации.
  @override
  @JsonKey(name: 'contract_ids')
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
    return 'ExportFilterModel(dateFrom: $dateFrom, dateTo: $dateTo, objectIds: $objectIds, contractIds: $contractIds, systems: $systems, subsystems: $subsystems)';
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
      @JsonKey(name: 'object_ids') List<String> objectIds,
      @JsonKey(name: 'contract_ids') List<String> contractIds,
      List<String> systems,
      List<String> subsystems});
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
    Object? objectIds = null,
    Object? contractIds = null,
    Object? systems = null,
    Object? subsystems = null,
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
