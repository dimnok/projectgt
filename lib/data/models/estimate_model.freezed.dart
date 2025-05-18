// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'estimate_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$EstimateModel {
  String? get id;
  String get system;
  String get subsystem;
  @JsonKey(fromJson: _numberFromJson)
  String get number;
  String get name;
  String get article;
  String get manufacturer;
  String get unit;
  double get quantity;
  double get price;
  double get total;
  @JsonKey(name: 'object_id')
  String? get objectId;
  @JsonKey(name: 'contract_id')
  String? get contractId;
  @JsonKey(name: 'estimate_title')
  String? get estimateTitle;

  /// Create a copy of EstimateModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $EstimateModelCopyWith<EstimateModel> get copyWith =>
      _$EstimateModelCopyWithImpl<EstimateModel>(
          this as EstimateModel, _$identity);

  /// Serializes this EstimateModel to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is EstimateModel &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.system, system) || other.system == system) &&
            (identical(other.subsystem, subsystem) ||
                other.subsystem == subsystem) &&
            (identical(other.number, number) || other.number == number) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.article, article) || other.article == article) &&
            (identical(other.manufacturer, manufacturer) ||
                other.manufacturer == manufacturer) &&
            (identical(other.unit, unit) || other.unit == unit) &&
            (identical(other.quantity, quantity) ||
                other.quantity == quantity) &&
            (identical(other.price, price) || other.price == price) &&
            (identical(other.total, total) || other.total == total) &&
            (identical(other.objectId, objectId) ||
                other.objectId == objectId) &&
            (identical(other.contractId, contractId) ||
                other.contractId == contractId) &&
            (identical(other.estimateTitle, estimateTitle) ||
                other.estimateTitle == estimateTitle));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      system,
      subsystem,
      number,
      name,
      article,
      manufacturer,
      unit,
      quantity,
      price,
      total,
      objectId,
      contractId,
      estimateTitle);

  @override
  String toString() {
    return 'EstimateModel(id: $id, system: $system, subsystem: $subsystem, number: $number, name: $name, article: $article, manufacturer: $manufacturer, unit: $unit, quantity: $quantity, price: $price, total: $total, objectId: $objectId, contractId: $contractId, estimateTitle: $estimateTitle)';
  }
}

/// @nodoc
abstract mixin class $EstimateModelCopyWith<$Res> {
  factory $EstimateModelCopyWith(
          EstimateModel value, $Res Function(EstimateModel) _then) =
      _$EstimateModelCopyWithImpl;
  @useResult
  $Res call(
      {String? id,
      String system,
      String subsystem,
      @JsonKey(fromJson: _numberFromJson) String number,
      String name,
      String article,
      String manufacturer,
      String unit,
      double quantity,
      double price,
      double total,
      @JsonKey(name: 'object_id') String? objectId,
      @JsonKey(name: 'contract_id') String? contractId,
      @JsonKey(name: 'estimate_title') String? estimateTitle});
}

/// @nodoc
class _$EstimateModelCopyWithImpl<$Res>
    implements $EstimateModelCopyWith<$Res> {
  _$EstimateModelCopyWithImpl(this._self, this._then);

  final EstimateModel _self;
  final $Res Function(EstimateModel) _then;

  /// Create a copy of EstimateModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = freezed,
    Object? system = null,
    Object? subsystem = null,
    Object? number = null,
    Object? name = null,
    Object? article = null,
    Object? manufacturer = null,
    Object? unit = null,
    Object? quantity = null,
    Object? price = null,
    Object? total = null,
    Object? objectId = freezed,
    Object? contractId = freezed,
    Object? estimateTitle = freezed,
  }) {
    return _then(_self.copyWith(
      id: freezed == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as String?,
      system: null == system
          ? _self.system
          : system // ignore: cast_nullable_to_non_nullable
              as String,
      subsystem: null == subsystem
          ? _self.subsystem
          : subsystem // ignore: cast_nullable_to_non_nullable
              as String,
      number: null == number
          ? _self.number
          : number // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _self.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      article: null == article
          ? _self.article
          : article // ignore: cast_nullable_to_non_nullable
              as String,
      manufacturer: null == manufacturer
          ? _self.manufacturer
          : manufacturer // ignore: cast_nullable_to_non_nullable
              as String,
      unit: null == unit
          ? _self.unit
          : unit // ignore: cast_nullable_to_non_nullable
              as String,
      quantity: null == quantity
          ? _self.quantity
          : quantity // ignore: cast_nullable_to_non_nullable
              as double,
      price: null == price
          ? _self.price
          : price // ignore: cast_nullable_to_non_nullable
              as double,
      total: null == total
          ? _self.total
          : total // ignore: cast_nullable_to_non_nullable
              as double,
      objectId: freezed == objectId
          ? _self.objectId
          : objectId // ignore: cast_nullable_to_non_nullable
              as String?,
      contractId: freezed == contractId
          ? _self.contractId
          : contractId // ignore: cast_nullable_to_non_nullable
              as String?,
      estimateTitle: freezed == estimateTitle
          ? _self.estimateTitle
          : estimateTitle // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc

@JsonSerializable(explicitToJson: true, includeIfNull: false)
class _EstimateModel extends EstimateModel {
  const _EstimateModel(
      {this.id,
      required this.system,
      required this.subsystem,
      @JsonKey(fromJson: _numberFromJson) required this.number,
      required this.name,
      required this.article,
      required this.manufacturer,
      required this.unit,
      required this.quantity,
      required this.price,
      required this.total,
      @JsonKey(name: 'object_id') this.objectId,
      @JsonKey(name: 'contract_id') this.contractId,
      @JsonKey(name: 'estimate_title') this.estimateTitle})
      : super._();
  factory _EstimateModel.fromJson(Map<String, dynamic> json) =>
      _$EstimateModelFromJson(json);

  @override
  final String? id;
  @override
  final String system;
  @override
  final String subsystem;
  @override
  @JsonKey(fromJson: _numberFromJson)
  final String number;
  @override
  final String name;
  @override
  final String article;
  @override
  final String manufacturer;
  @override
  final String unit;
  @override
  final double quantity;
  @override
  final double price;
  @override
  final double total;
  @override
  @JsonKey(name: 'object_id')
  final String? objectId;
  @override
  @JsonKey(name: 'contract_id')
  final String? contractId;
  @override
  @JsonKey(name: 'estimate_title')
  final String? estimateTitle;

  /// Create a copy of EstimateModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$EstimateModelCopyWith<_EstimateModel> get copyWith =>
      __$EstimateModelCopyWithImpl<_EstimateModel>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$EstimateModelToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _EstimateModel &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.system, system) || other.system == system) &&
            (identical(other.subsystem, subsystem) ||
                other.subsystem == subsystem) &&
            (identical(other.number, number) || other.number == number) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.article, article) || other.article == article) &&
            (identical(other.manufacturer, manufacturer) ||
                other.manufacturer == manufacturer) &&
            (identical(other.unit, unit) || other.unit == unit) &&
            (identical(other.quantity, quantity) ||
                other.quantity == quantity) &&
            (identical(other.price, price) || other.price == price) &&
            (identical(other.total, total) || other.total == total) &&
            (identical(other.objectId, objectId) ||
                other.objectId == objectId) &&
            (identical(other.contractId, contractId) ||
                other.contractId == contractId) &&
            (identical(other.estimateTitle, estimateTitle) ||
                other.estimateTitle == estimateTitle));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      system,
      subsystem,
      number,
      name,
      article,
      manufacturer,
      unit,
      quantity,
      price,
      total,
      objectId,
      contractId,
      estimateTitle);

  @override
  String toString() {
    return 'EstimateModel(id: $id, system: $system, subsystem: $subsystem, number: $number, name: $name, article: $article, manufacturer: $manufacturer, unit: $unit, quantity: $quantity, price: $price, total: $total, objectId: $objectId, contractId: $contractId, estimateTitle: $estimateTitle)';
  }
}

/// @nodoc
abstract mixin class _$EstimateModelCopyWith<$Res>
    implements $EstimateModelCopyWith<$Res> {
  factory _$EstimateModelCopyWith(
          _EstimateModel value, $Res Function(_EstimateModel) _then) =
      __$EstimateModelCopyWithImpl;
  @override
  @useResult
  $Res call(
      {String? id,
      String system,
      String subsystem,
      @JsonKey(fromJson: _numberFromJson) String number,
      String name,
      String article,
      String manufacturer,
      String unit,
      double quantity,
      double price,
      double total,
      @JsonKey(name: 'object_id') String? objectId,
      @JsonKey(name: 'contract_id') String? contractId,
      @JsonKey(name: 'estimate_title') String? estimateTitle});
}

/// @nodoc
class __$EstimateModelCopyWithImpl<$Res>
    implements _$EstimateModelCopyWith<$Res> {
  __$EstimateModelCopyWithImpl(this._self, this._then);

  final _EstimateModel _self;
  final $Res Function(_EstimateModel) _then;

  /// Create a copy of EstimateModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? id = freezed,
    Object? system = null,
    Object? subsystem = null,
    Object? number = null,
    Object? name = null,
    Object? article = null,
    Object? manufacturer = null,
    Object? unit = null,
    Object? quantity = null,
    Object? price = null,
    Object? total = null,
    Object? objectId = freezed,
    Object? contractId = freezed,
    Object? estimateTitle = freezed,
  }) {
    return _then(_EstimateModel(
      id: freezed == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as String?,
      system: null == system
          ? _self.system
          : system // ignore: cast_nullable_to_non_nullable
              as String,
      subsystem: null == subsystem
          ? _self.subsystem
          : subsystem // ignore: cast_nullable_to_non_nullable
              as String,
      number: null == number
          ? _self.number
          : number // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _self.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      article: null == article
          ? _self.article
          : article // ignore: cast_nullable_to_non_nullable
              as String,
      manufacturer: null == manufacturer
          ? _self.manufacturer
          : manufacturer // ignore: cast_nullable_to_non_nullable
              as String,
      unit: null == unit
          ? _self.unit
          : unit // ignore: cast_nullable_to_non_nullable
              as String,
      quantity: null == quantity
          ? _self.quantity
          : quantity // ignore: cast_nullable_to_non_nullable
              as double,
      price: null == price
          ? _self.price
          : price // ignore: cast_nullable_to_non_nullable
              as double,
      total: null == total
          ? _self.total
          : total // ignore: cast_nullable_to_non_nullable
              as double,
      objectId: freezed == objectId
          ? _self.objectId
          : objectId // ignore: cast_nullable_to_non_nullable
              as String?,
      contractId: freezed == contractId
          ? _self.contractId
          : contractId // ignore: cast_nullable_to_non_nullable
              as String?,
      estimateTitle: freezed == estimateTitle
          ? _self.estimateTitle
          : estimateTitle // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

// dart format on
