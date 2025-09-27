// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'work_plan_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$WorkPlanModel {
  @JsonKey(includeIfNull: false)
  String? get id;
  DateTime get createdAt;
  DateTime get updatedAt;
  String get createdBy;
  DateTime get date;
  String get objectId;
  @JsonKey(includeIfNull: false)
  String? get objectName;
  @JsonKey(includeIfNull: false)
  String? get objectAddress;
  List<WorkBlockModel> get workBlocks;

  /// Create a copy of WorkPlanModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $WorkPlanModelCopyWith<WorkPlanModel> get copyWith =>
      _$WorkPlanModelCopyWithImpl<WorkPlanModel>(
          this as WorkPlanModel, _$identity);

  /// Serializes this WorkPlanModel to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is WorkPlanModel &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt) &&
            (identical(other.createdBy, createdBy) ||
                other.createdBy == createdBy) &&
            (identical(other.date, date) || other.date == date) &&
            (identical(other.objectId, objectId) ||
                other.objectId == objectId) &&
            (identical(other.objectName, objectName) ||
                other.objectName == objectName) &&
            (identical(other.objectAddress, objectAddress) ||
                other.objectAddress == objectAddress) &&
            const DeepCollectionEquality()
                .equals(other.workBlocks, workBlocks));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      createdAt,
      updatedAt,
      createdBy,
      date,
      objectId,
      objectName,
      objectAddress,
      const DeepCollectionEquality().hash(workBlocks));

  @override
  String toString() {
    return 'WorkPlanModel(id: $id, createdAt: $createdAt, updatedAt: $updatedAt, createdBy: $createdBy, date: $date, objectId: $objectId, objectName: $objectName, objectAddress: $objectAddress, workBlocks: $workBlocks)';
  }
}

/// @nodoc
abstract mixin class $WorkPlanModelCopyWith<$Res> {
  factory $WorkPlanModelCopyWith(
          WorkPlanModel value, $Res Function(WorkPlanModel) _then) =
      _$WorkPlanModelCopyWithImpl;
  @useResult
  $Res call(
      {@JsonKey(includeIfNull: false) String? id,
      DateTime createdAt,
      DateTime updatedAt,
      String createdBy,
      DateTime date,
      String objectId,
      @JsonKey(includeIfNull: false) String? objectName,
      @JsonKey(includeIfNull: false) String? objectAddress,
      List<WorkBlockModel> workBlocks});
}

/// @nodoc
class _$WorkPlanModelCopyWithImpl<$Res>
    implements $WorkPlanModelCopyWith<$Res> {
  _$WorkPlanModelCopyWithImpl(this._self, this._then);

  final WorkPlanModel _self;
  final $Res Function(WorkPlanModel) _then;

  /// Create a copy of WorkPlanModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = freezed,
    Object? createdAt = null,
    Object? updatedAt = null,
    Object? createdBy = null,
    Object? date = null,
    Object? objectId = null,
    Object? objectName = freezed,
    Object? objectAddress = freezed,
    Object? workBlocks = null,
  }) {
    return _then(_self.copyWith(
      id: freezed == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as String?,
      createdAt: null == createdAt
          ? _self.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      updatedAt: null == updatedAt
          ? _self.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      createdBy: null == createdBy
          ? _self.createdBy
          : createdBy // ignore: cast_nullable_to_non_nullable
              as String,
      date: null == date
          ? _self.date
          : date // ignore: cast_nullable_to_non_nullable
              as DateTime,
      objectId: null == objectId
          ? _self.objectId
          : objectId // ignore: cast_nullable_to_non_nullable
              as String,
      objectName: freezed == objectName
          ? _self.objectName
          : objectName // ignore: cast_nullable_to_non_nullable
              as String?,
      objectAddress: freezed == objectAddress
          ? _self.objectAddress
          : objectAddress // ignore: cast_nullable_to_non_nullable
              as String?,
      workBlocks: null == workBlocks
          ? _self.workBlocks
          : workBlocks // ignore: cast_nullable_to_non_nullable
              as List<WorkBlockModel>,
    ));
  }
}

/// @nodoc

@JsonSerializable(explicitToJson: true, fieldRename: FieldRename.snake)
class _WorkPlanModel extends WorkPlanModel {
  const _WorkPlanModel(
      {@JsonKey(includeIfNull: false) this.id,
      required this.createdAt,
      required this.updatedAt,
      required this.createdBy,
      required this.date,
      required this.objectId,
      @JsonKey(includeIfNull: false) this.objectName,
      @JsonKey(includeIfNull: false) this.objectAddress,
      final List<WorkBlockModel> workBlocks = const []})
      : _workBlocks = workBlocks,
        super._();
  factory _WorkPlanModel.fromJson(Map<String, dynamic> json) =>
      _$WorkPlanModelFromJson(json);

  @override
  @JsonKey(includeIfNull: false)
  final String? id;
  @override
  final DateTime createdAt;
  @override
  final DateTime updatedAt;
  @override
  final String createdBy;
  @override
  final DateTime date;
  @override
  final String objectId;
  @override
  @JsonKey(includeIfNull: false)
  final String? objectName;
  @override
  @JsonKey(includeIfNull: false)
  final String? objectAddress;
  final List<WorkBlockModel> _workBlocks;
  @override
  @JsonKey()
  List<WorkBlockModel> get workBlocks {
    if (_workBlocks is EqualUnmodifiableListView) return _workBlocks;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_workBlocks);
  }

  /// Create a copy of WorkPlanModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$WorkPlanModelCopyWith<_WorkPlanModel> get copyWith =>
      __$WorkPlanModelCopyWithImpl<_WorkPlanModel>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$WorkPlanModelToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _WorkPlanModel &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt) &&
            (identical(other.createdBy, createdBy) ||
                other.createdBy == createdBy) &&
            (identical(other.date, date) || other.date == date) &&
            (identical(other.objectId, objectId) ||
                other.objectId == objectId) &&
            (identical(other.objectName, objectName) ||
                other.objectName == objectName) &&
            (identical(other.objectAddress, objectAddress) ||
                other.objectAddress == objectAddress) &&
            const DeepCollectionEquality()
                .equals(other._workBlocks, _workBlocks));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      createdAt,
      updatedAt,
      createdBy,
      date,
      objectId,
      objectName,
      objectAddress,
      const DeepCollectionEquality().hash(_workBlocks));

  @override
  String toString() {
    return 'WorkPlanModel(id: $id, createdAt: $createdAt, updatedAt: $updatedAt, createdBy: $createdBy, date: $date, objectId: $objectId, objectName: $objectName, objectAddress: $objectAddress, workBlocks: $workBlocks)';
  }
}

/// @nodoc
abstract mixin class _$WorkPlanModelCopyWith<$Res>
    implements $WorkPlanModelCopyWith<$Res> {
  factory _$WorkPlanModelCopyWith(
          _WorkPlanModel value, $Res Function(_WorkPlanModel) _then) =
      __$WorkPlanModelCopyWithImpl;
  @override
  @useResult
  $Res call(
      {@JsonKey(includeIfNull: false) String? id,
      DateTime createdAt,
      DateTime updatedAt,
      String createdBy,
      DateTime date,
      String objectId,
      @JsonKey(includeIfNull: false) String? objectName,
      @JsonKey(includeIfNull: false) String? objectAddress,
      List<WorkBlockModel> workBlocks});
}

/// @nodoc
class __$WorkPlanModelCopyWithImpl<$Res>
    implements _$WorkPlanModelCopyWith<$Res> {
  __$WorkPlanModelCopyWithImpl(this._self, this._then);

  final _WorkPlanModel _self;
  final $Res Function(_WorkPlanModel) _then;

  /// Create a copy of WorkPlanModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? id = freezed,
    Object? createdAt = null,
    Object? updatedAt = null,
    Object? createdBy = null,
    Object? date = null,
    Object? objectId = null,
    Object? objectName = freezed,
    Object? objectAddress = freezed,
    Object? workBlocks = null,
  }) {
    return _then(_WorkPlanModel(
      id: freezed == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as String?,
      createdAt: null == createdAt
          ? _self.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      updatedAt: null == updatedAt
          ? _self.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      createdBy: null == createdBy
          ? _self.createdBy
          : createdBy // ignore: cast_nullable_to_non_nullable
              as String,
      date: null == date
          ? _self.date
          : date // ignore: cast_nullable_to_non_nullable
              as DateTime,
      objectId: null == objectId
          ? _self.objectId
          : objectId // ignore: cast_nullable_to_non_nullable
              as String,
      objectName: freezed == objectName
          ? _self.objectName
          : objectName // ignore: cast_nullable_to_non_nullable
              as String?,
      objectAddress: freezed == objectAddress
          ? _self.objectAddress
          : objectAddress // ignore: cast_nullable_to_non_nullable
              as String?,
      workBlocks: null == workBlocks
          ? _self._workBlocks
          : workBlocks // ignore: cast_nullable_to_non_nullable
              as List<WorkBlockModel>,
    ));
  }
}

/// @nodoc
mixin _$WorkPlanItemModel {
  String get estimateId;
  String get name;
  String get unit;
  double get price;
  double get plannedQuantity;
  double get actualQuantity;

  /// Create a copy of WorkPlanItemModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $WorkPlanItemModelCopyWith<WorkPlanItemModel> get copyWith =>
      _$WorkPlanItemModelCopyWithImpl<WorkPlanItemModel>(
          this as WorkPlanItemModel, _$identity);

  /// Serializes this WorkPlanItemModel to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is WorkPlanItemModel &&
            (identical(other.estimateId, estimateId) ||
                other.estimateId == estimateId) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.unit, unit) || other.unit == unit) &&
            (identical(other.price, price) || other.price == price) &&
            (identical(other.plannedQuantity, plannedQuantity) ||
                other.plannedQuantity == plannedQuantity) &&
            (identical(other.actualQuantity, actualQuantity) ||
                other.actualQuantity == actualQuantity));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, estimateId, name, unit, price,
      plannedQuantity, actualQuantity);

  @override
  String toString() {
    return 'WorkPlanItemModel(estimateId: $estimateId, name: $name, unit: $unit, price: $price, plannedQuantity: $plannedQuantity, actualQuantity: $actualQuantity)';
  }
}

/// @nodoc
abstract mixin class $WorkPlanItemModelCopyWith<$Res> {
  factory $WorkPlanItemModelCopyWith(
          WorkPlanItemModel value, $Res Function(WorkPlanItemModel) _then) =
      _$WorkPlanItemModelCopyWithImpl;
  @useResult
  $Res call(
      {String estimateId,
      String name,
      String unit,
      double price,
      double plannedQuantity,
      double actualQuantity});
}

/// @nodoc
class _$WorkPlanItemModelCopyWithImpl<$Res>
    implements $WorkPlanItemModelCopyWith<$Res> {
  _$WorkPlanItemModelCopyWithImpl(this._self, this._then);

  final WorkPlanItemModel _self;
  final $Res Function(WorkPlanItemModel) _then;

  /// Create a copy of WorkPlanItemModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? estimateId = null,
    Object? name = null,
    Object? unit = null,
    Object? price = null,
    Object? plannedQuantity = null,
    Object? actualQuantity = null,
  }) {
    return _then(_self.copyWith(
      estimateId: null == estimateId
          ? _self.estimateId
          : estimateId // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _self.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      unit: null == unit
          ? _self.unit
          : unit // ignore: cast_nullable_to_non_nullable
              as String,
      price: null == price
          ? _self.price
          : price // ignore: cast_nullable_to_non_nullable
              as double,
      plannedQuantity: null == plannedQuantity
          ? _self.plannedQuantity
          : plannedQuantity // ignore: cast_nullable_to_non_nullable
              as double,
      actualQuantity: null == actualQuantity
          ? _self.actualQuantity
          : actualQuantity // ignore: cast_nullable_to_non_nullable
              as double,
    ));
  }
}

/// @nodoc

@JsonSerializable(explicitToJson: true, fieldRename: FieldRename.snake)
class _WorkPlanItemModel extends WorkPlanItemModel {
  const _WorkPlanItemModel(
      {required this.estimateId,
      required this.name,
      required this.unit,
      required this.price,
      this.plannedQuantity = 0,
      this.actualQuantity = 0})
      : super._();
  factory _WorkPlanItemModel.fromJson(Map<String, dynamic> json) =>
      _$WorkPlanItemModelFromJson(json);

  @override
  final String estimateId;
  @override
  final String name;
  @override
  final String unit;
  @override
  final double price;
  @override
  @JsonKey()
  final double plannedQuantity;
  @override
  @JsonKey()
  final double actualQuantity;

  /// Create a copy of WorkPlanItemModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$WorkPlanItemModelCopyWith<_WorkPlanItemModel> get copyWith =>
      __$WorkPlanItemModelCopyWithImpl<_WorkPlanItemModel>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$WorkPlanItemModelToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _WorkPlanItemModel &&
            (identical(other.estimateId, estimateId) ||
                other.estimateId == estimateId) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.unit, unit) || other.unit == unit) &&
            (identical(other.price, price) || other.price == price) &&
            (identical(other.plannedQuantity, plannedQuantity) ||
                other.plannedQuantity == plannedQuantity) &&
            (identical(other.actualQuantity, actualQuantity) ||
                other.actualQuantity == actualQuantity));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, estimateId, name, unit, price,
      plannedQuantity, actualQuantity);

  @override
  String toString() {
    return 'WorkPlanItemModel(estimateId: $estimateId, name: $name, unit: $unit, price: $price, plannedQuantity: $plannedQuantity, actualQuantity: $actualQuantity)';
  }
}

/// @nodoc
abstract mixin class _$WorkPlanItemModelCopyWith<$Res>
    implements $WorkPlanItemModelCopyWith<$Res> {
  factory _$WorkPlanItemModelCopyWith(
          _WorkPlanItemModel value, $Res Function(_WorkPlanItemModel) _then) =
      __$WorkPlanItemModelCopyWithImpl;
  @override
  @useResult
  $Res call(
      {String estimateId,
      String name,
      String unit,
      double price,
      double plannedQuantity,
      double actualQuantity});
}

/// @nodoc
class __$WorkPlanItemModelCopyWithImpl<$Res>
    implements _$WorkPlanItemModelCopyWith<$Res> {
  __$WorkPlanItemModelCopyWithImpl(this._self, this._then);

  final _WorkPlanItemModel _self;
  final $Res Function(_WorkPlanItemModel) _then;

  /// Create a copy of WorkPlanItemModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? estimateId = null,
    Object? name = null,
    Object? unit = null,
    Object? price = null,
    Object? plannedQuantity = null,
    Object? actualQuantity = null,
  }) {
    return _then(_WorkPlanItemModel(
      estimateId: null == estimateId
          ? _self.estimateId
          : estimateId // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _self.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      unit: null == unit
          ? _self.unit
          : unit // ignore: cast_nullable_to_non_nullable
              as String,
      price: null == price
          ? _self.price
          : price // ignore: cast_nullable_to_non_nullable
              as double,
      plannedQuantity: null == plannedQuantity
          ? _self.plannedQuantity
          : plannedQuantity // ignore: cast_nullable_to_non_nullable
              as double,
      actualQuantity: null == actualQuantity
          ? _self.actualQuantity
          : actualQuantity // ignore: cast_nullable_to_non_nullable
              as double,
    ));
  }
}

/// @nodoc
mixin _$WorkBlockModel {
  /// Уникальный идентификатор блока работ.
  @JsonKey(includeIfNull: false)
  String? get id;

  /// ID ответственного сотрудника за блок.
  @JsonKey(includeIfNull: false)
  String? get responsibleId;

  /// Список ID работников, назначенных на блок.
  List<String> get workerIds;

  /// Участок объекта для данного блока.
  @JsonKey(includeIfNull: false)
  String? get section;

  /// Этаж объекта для данного блока.
  @JsonKey(includeIfNull: false)
  String? get floor;

  /// Система работ (обязательное поле).
  String get system;

  /// Список работ в блоке с объемами.
  List<WorkPlanItemModel> get selectedWorks;

  /// Create a copy of WorkBlockModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $WorkBlockModelCopyWith<WorkBlockModel> get copyWith =>
      _$WorkBlockModelCopyWithImpl<WorkBlockModel>(
          this as WorkBlockModel, _$identity);

  /// Serializes this WorkBlockModel to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is WorkBlockModel &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.responsibleId, responsibleId) ||
                other.responsibleId == responsibleId) &&
            const DeepCollectionEquality().equals(other.workerIds, workerIds) &&
            (identical(other.section, section) || other.section == section) &&
            (identical(other.floor, floor) || other.floor == floor) &&
            (identical(other.system, system) || other.system == system) &&
            const DeepCollectionEquality()
                .equals(other.selectedWorks, selectedWorks));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      responsibleId,
      const DeepCollectionEquality().hash(workerIds),
      section,
      floor,
      system,
      const DeepCollectionEquality().hash(selectedWorks));

  @override
  String toString() {
    return 'WorkBlockModel(id: $id, responsibleId: $responsibleId, workerIds: $workerIds, section: $section, floor: $floor, system: $system, selectedWorks: $selectedWorks)';
  }
}

/// @nodoc
abstract mixin class $WorkBlockModelCopyWith<$Res> {
  factory $WorkBlockModelCopyWith(
          WorkBlockModel value, $Res Function(WorkBlockModel) _then) =
      _$WorkBlockModelCopyWithImpl;
  @useResult
  $Res call(
      {@JsonKey(includeIfNull: false) String? id,
      @JsonKey(includeIfNull: false) String? responsibleId,
      List<String> workerIds,
      @JsonKey(includeIfNull: false) String? section,
      @JsonKey(includeIfNull: false) String? floor,
      String system,
      List<WorkPlanItemModel> selectedWorks});
}

/// @nodoc
class _$WorkBlockModelCopyWithImpl<$Res>
    implements $WorkBlockModelCopyWith<$Res> {
  _$WorkBlockModelCopyWithImpl(this._self, this._then);

  final WorkBlockModel _self;
  final $Res Function(WorkBlockModel) _then;

  /// Create a copy of WorkBlockModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = freezed,
    Object? responsibleId = freezed,
    Object? workerIds = null,
    Object? section = freezed,
    Object? floor = freezed,
    Object? system = null,
    Object? selectedWorks = null,
  }) {
    return _then(_self.copyWith(
      id: freezed == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as String?,
      responsibleId: freezed == responsibleId
          ? _self.responsibleId
          : responsibleId // ignore: cast_nullable_to_non_nullable
              as String?,
      workerIds: null == workerIds
          ? _self.workerIds
          : workerIds // ignore: cast_nullable_to_non_nullable
              as List<String>,
      section: freezed == section
          ? _self.section
          : section // ignore: cast_nullable_to_non_nullable
              as String?,
      floor: freezed == floor
          ? _self.floor
          : floor // ignore: cast_nullable_to_non_nullable
              as String?,
      system: null == system
          ? _self.system
          : system // ignore: cast_nullable_to_non_nullable
              as String,
      selectedWorks: null == selectedWorks
          ? _self.selectedWorks
          : selectedWorks // ignore: cast_nullable_to_non_nullable
              as List<WorkPlanItemModel>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _WorkBlockModel implements WorkBlockModel {
  const _WorkBlockModel(
      {@JsonKey(includeIfNull: false) this.id,
      @JsonKey(includeIfNull: false) this.responsibleId,
      final List<String> workerIds = const [],
      @JsonKey(includeIfNull: false) this.section,
      @JsonKey(includeIfNull: false) this.floor,
      required this.system,
      final List<WorkPlanItemModel> selectedWorks = const []})
      : _workerIds = workerIds,
        _selectedWorks = selectedWorks;
  factory _WorkBlockModel.fromJson(Map<String, dynamic> json) =>
      _$WorkBlockModelFromJson(json);

  /// Уникальный идентификатор блока работ.
  @override
  @JsonKey(includeIfNull: false)
  final String? id;

  /// ID ответственного сотрудника за блок.
  @override
  @JsonKey(includeIfNull: false)
  final String? responsibleId;

  /// Список ID работников, назначенных на блок.
  final List<String> _workerIds;

  /// Список ID работников, назначенных на блок.
  @override
  @JsonKey()
  List<String> get workerIds {
    if (_workerIds is EqualUnmodifiableListView) return _workerIds;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_workerIds);
  }

  /// Участок объекта для данного блока.
  @override
  @JsonKey(includeIfNull: false)
  final String? section;

  /// Этаж объекта для данного блока.
  @override
  @JsonKey(includeIfNull: false)
  final String? floor;

  /// Система работ (обязательное поле).
  @override
  final String system;

  /// Список работ в блоке с объемами.
  final List<WorkPlanItemModel> _selectedWorks;

  /// Список работ в блоке с объемами.
  @override
  @JsonKey()
  List<WorkPlanItemModel> get selectedWorks {
    if (_selectedWorks is EqualUnmodifiableListView) return _selectedWorks;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_selectedWorks);
  }

  /// Create a copy of WorkBlockModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$WorkBlockModelCopyWith<_WorkBlockModel> get copyWith =>
      __$WorkBlockModelCopyWithImpl<_WorkBlockModel>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$WorkBlockModelToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _WorkBlockModel &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.responsibleId, responsibleId) ||
                other.responsibleId == responsibleId) &&
            const DeepCollectionEquality()
                .equals(other._workerIds, _workerIds) &&
            (identical(other.section, section) || other.section == section) &&
            (identical(other.floor, floor) || other.floor == floor) &&
            (identical(other.system, system) || other.system == system) &&
            const DeepCollectionEquality()
                .equals(other._selectedWorks, _selectedWorks));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      responsibleId,
      const DeepCollectionEquality().hash(_workerIds),
      section,
      floor,
      system,
      const DeepCollectionEquality().hash(_selectedWorks));

  @override
  String toString() {
    return 'WorkBlockModel(id: $id, responsibleId: $responsibleId, workerIds: $workerIds, section: $section, floor: $floor, system: $system, selectedWorks: $selectedWorks)';
  }
}

/// @nodoc
abstract mixin class _$WorkBlockModelCopyWith<$Res>
    implements $WorkBlockModelCopyWith<$Res> {
  factory _$WorkBlockModelCopyWith(
          _WorkBlockModel value, $Res Function(_WorkBlockModel) _then) =
      __$WorkBlockModelCopyWithImpl;
  @override
  @useResult
  $Res call(
      {@JsonKey(includeIfNull: false) String? id,
      @JsonKey(includeIfNull: false) String? responsibleId,
      List<String> workerIds,
      @JsonKey(includeIfNull: false) String? section,
      @JsonKey(includeIfNull: false) String? floor,
      String system,
      List<WorkPlanItemModel> selectedWorks});
}

/// @nodoc
class __$WorkBlockModelCopyWithImpl<$Res>
    implements _$WorkBlockModelCopyWith<$Res> {
  __$WorkBlockModelCopyWithImpl(this._self, this._then);

  final _WorkBlockModel _self;
  final $Res Function(_WorkBlockModel) _then;

  /// Create a copy of WorkBlockModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? id = freezed,
    Object? responsibleId = freezed,
    Object? workerIds = null,
    Object? section = freezed,
    Object? floor = freezed,
    Object? system = null,
    Object? selectedWorks = null,
  }) {
    return _then(_WorkBlockModel(
      id: freezed == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as String?,
      responsibleId: freezed == responsibleId
          ? _self.responsibleId
          : responsibleId // ignore: cast_nullable_to_non_nullable
              as String?,
      workerIds: null == workerIds
          ? _self._workerIds
          : workerIds // ignore: cast_nullable_to_non_nullable
              as List<String>,
      section: freezed == section
          ? _self.section
          : section // ignore: cast_nullable_to_non_nullable
              as String?,
      floor: freezed == floor
          ? _self.floor
          : floor // ignore: cast_nullable_to_non_nullable
              as String?,
      system: null == system
          ? _self.system
          : system // ignore: cast_nullable_to_non_nullable
              as String,
      selectedWorks: null == selectedWorks
          ? _self._selectedWorks
          : selectedWorks // ignore: cast_nullable_to_non_nullable
              as List<WorkPlanItemModel>,
    ));
  }
}

// dart format on
