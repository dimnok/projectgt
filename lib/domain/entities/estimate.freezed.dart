// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'estimate.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Estimate {
  String get id;
  String get system;
  String get subsystem;
  String get number;
  String get name;
  String get article;
  String get manufacturer;
  String get unit;
  double get quantity;
  double get price;
  double get total;
  String? get objectId;
  String? get contractId;
  String? get contractNumber;
  String? get estimateTitle;

  /// Create a copy of Estimate
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $EstimateCopyWith<Estimate> get copyWith =>
      _$EstimateCopyWithImpl<Estimate>(this as Estimate, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is Estimate &&
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
            (identical(other.contractNumber, contractNumber) ||
                other.contractNumber == contractNumber) &&
            (identical(other.estimateTitle, estimateTitle) ||
                other.estimateTitle == estimateTitle));
  }

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
      contractNumber,
      estimateTitle);

  @override
  String toString() {
    return 'Estimate(id: $id, system: $system, subsystem: $subsystem, number: $number, name: $name, article: $article, manufacturer: $manufacturer, unit: $unit, quantity: $quantity, price: $price, total: $total, objectId: $objectId, contractId: $contractId, contractNumber: $contractNumber, estimateTitle: $estimateTitle)';
  }
}

/// @nodoc
abstract mixin class $EstimateCopyWith<$Res> {
  factory $EstimateCopyWith(Estimate value, $Res Function(Estimate) _then) =
      _$EstimateCopyWithImpl;
  @useResult
  $Res call(
      {String id,
      String system,
      String subsystem,
      String number,
      String name,
      String article,
      String manufacturer,
      String unit,
      double quantity,
      double price,
      double total,
      String? objectId,
      String? contractId,
      String? contractNumber,
      String? estimateTitle});
}

/// @nodoc
class _$EstimateCopyWithImpl<$Res> implements $EstimateCopyWith<$Res> {
  _$EstimateCopyWithImpl(this._self, this._then);

  final Estimate _self;
  final $Res Function(Estimate) _then;

  /// Create a copy of Estimate
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
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
    Object? contractNumber = freezed,
    Object? estimateTitle = freezed,
  }) {
    return _then(_self.copyWith(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
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
      contractNumber: freezed == contractNumber
          ? _self.contractNumber
          : contractNumber // ignore: cast_nullable_to_non_nullable
              as String?,
      estimateTitle: freezed == estimateTitle
          ? _self.estimateTitle
          : estimateTitle // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc

class _Estimate extends Estimate {
  const _Estimate(
      {required this.id,
      required this.system,
      required this.subsystem,
      required this.number,
      required this.name,
      required this.article,
      required this.manufacturer,
      required this.unit,
      required this.quantity,
      required this.price,
      required this.total,
      this.objectId,
      this.contractId,
      this.contractNumber,
      this.estimateTitle})
      : super._();

  @override
  final String id;
  @override
  final String system;
  @override
  final String subsystem;
  @override
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
  final String? objectId;
  @override
  final String? contractId;
  @override
  final String? contractNumber;
  @override
  final String? estimateTitle;

  /// Create a copy of Estimate
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$EstimateCopyWith<_Estimate> get copyWith =>
      __$EstimateCopyWithImpl<_Estimate>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _Estimate &&
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
            (identical(other.contractNumber, contractNumber) ||
                other.contractNumber == contractNumber) &&
            (identical(other.estimateTitle, estimateTitle) ||
                other.estimateTitle == estimateTitle));
  }

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
      contractNumber,
      estimateTitle);

  @override
  String toString() {
    return 'Estimate(id: $id, system: $system, subsystem: $subsystem, number: $number, name: $name, article: $article, manufacturer: $manufacturer, unit: $unit, quantity: $quantity, price: $price, total: $total, objectId: $objectId, contractId: $contractId, contractNumber: $contractNumber, estimateTitle: $estimateTitle)';
  }
}

/// @nodoc
abstract mixin class _$EstimateCopyWith<$Res>
    implements $EstimateCopyWith<$Res> {
  factory _$EstimateCopyWith(_Estimate value, $Res Function(_Estimate) _then) =
      __$EstimateCopyWithImpl;
  @override
  @useResult
  $Res call(
      {String id,
      String system,
      String subsystem,
      String number,
      String name,
      String article,
      String manufacturer,
      String unit,
      double quantity,
      double price,
      double total,
      String? objectId,
      String? contractId,
      String? contractNumber,
      String? estimateTitle});
}

/// @nodoc
class __$EstimateCopyWithImpl<$Res> implements _$EstimateCopyWith<$Res> {
  __$EstimateCopyWithImpl(this._self, this._then);

  final _Estimate _self;
  final $Res Function(_Estimate) _then;

  /// Create a copy of Estimate
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? id = null,
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
    Object? contractNumber = freezed,
    Object? estimateTitle = freezed,
  }) {
    return _then(_Estimate(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
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
      contractNumber: freezed == contractNumber
          ? _self.contractNumber
          : contractNumber // ignore: cast_nullable_to_non_nullable
              as String?,
      estimateTitle: freezed == estimateTitle
          ? _self.estimateTitle
          : estimateTitle // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

// dart format on
