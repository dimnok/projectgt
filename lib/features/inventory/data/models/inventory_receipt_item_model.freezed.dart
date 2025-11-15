// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'inventory_receipt_item_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$InventoryReceiptItemModel {
  String get id;
  @JsonKey(name: 'receipt_id')
  String get receiptId;
  String get name;
  @JsonKey(name: 'category_id')
  String get categoryId;
  String get unit;
  double get quantity;
  double? get price;
  double? get total;
  @JsonKey(name: 'serial_number')
  String? get serialNumber;
  @JsonKey(name: 'photo_url')
  String? get photoUrl;
  String? get notes;
  @JsonKey(name: 'created_at')
  DateTime? get createdAt;

  /// Create a copy of InventoryReceiptItemModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $InventoryReceiptItemModelCopyWith<InventoryReceiptItemModel> get copyWith =>
      _$InventoryReceiptItemModelCopyWithImpl<InventoryReceiptItemModel>(
          this as InventoryReceiptItemModel, _$identity);

  /// Serializes this InventoryReceiptItemModel to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is InventoryReceiptItemModel &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.receiptId, receiptId) ||
                other.receiptId == receiptId) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.categoryId, categoryId) ||
                other.categoryId == categoryId) &&
            (identical(other.unit, unit) || other.unit == unit) &&
            (identical(other.quantity, quantity) ||
                other.quantity == quantity) &&
            (identical(other.price, price) || other.price == price) &&
            (identical(other.total, total) || other.total == total) &&
            (identical(other.serialNumber, serialNumber) ||
                other.serialNumber == serialNumber) &&
            (identical(other.photoUrl, photoUrl) ||
                other.photoUrl == photoUrl) &&
            (identical(other.notes, notes) || other.notes == notes) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, receiptId, name, categoryId,
      unit, quantity, price, total, serialNumber, photoUrl, notes, createdAt);

  @override
  String toString() {
    return 'InventoryReceiptItemModel(id: $id, receiptId: $receiptId, name: $name, categoryId: $categoryId, unit: $unit, quantity: $quantity, price: $price, total: $total, serialNumber: $serialNumber, photoUrl: $photoUrl, notes: $notes, createdAt: $createdAt)';
  }
}

/// @nodoc
abstract mixin class $InventoryReceiptItemModelCopyWith<$Res> {
  factory $InventoryReceiptItemModelCopyWith(InventoryReceiptItemModel value,
          $Res Function(InventoryReceiptItemModel) _then) =
      _$InventoryReceiptItemModelCopyWithImpl;
  @useResult
  $Res call(
      {String id,
      @JsonKey(name: 'receipt_id') String receiptId,
      String name,
      @JsonKey(name: 'category_id') String categoryId,
      String unit,
      double quantity,
      double? price,
      double? total,
      @JsonKey(name: 'serial_number') String? serialNumber,
      @JsonKey(name: 'photo_url') String? photoUrl,
      String? notes,
      @JsonKey(name: 'created_at') DateTime? createdAt});
}

/// @nodoc
class _$InventoryReceiptItemModelCopyWithImpl<$Res>
    implements $InventoryReceiptItemModelCopyWith<$Res> {
  _$InventoryReceiptItemModelCopyWithImpl(this._self, this._then);

  final InventoryReceiptItemModel _self;
  final $Res Function(InventoryReceiptItemModel) _then;

  /// Create a copy of InventoryReceiptItemModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? receiptId = null,
    Object? name = null,
    Object? categoryId = null,
    Object? unit = null,
    Object? quantity = null,
    Object? price = freezed,
    Object? total = freezed,
    Object? serialNumber = freezed,
    Object? photoUrl = freezed,
    Object? notes = freezed,
    Object? createdAt = freezed,
  }) {
    return _then(_self.copyWith(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      receiptId: null == receiptId
          ? _self.receiptId
          : receiptId // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _self.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      categoryId: null == categoryId
          ? _self.categoryId
          : categoryId // ignore: cast_nullable_to_non_nullable
              as String,
      unit: null == unit
          ? _self.unit
          : unit // ignore: cast_nullable_to_non_nullable
              as String,
      quantity: null == quantity
          ? _self.quantity
          : quantity // ignore: cast_nullable_to_non_nullable
              as double,
      price: freezed == price
          ? _self.price
          : price // ignore: cast_nullable_to_non_nullable
              as double?,
      total: freezed == total
          ? _self.total
          : total // ignore: cast_nullable_to_non_nullable
              as double?,
      serialNumber: freezed == serialNumber
          ? _self.serialNumber
          : serialNumber // ignore: cast_nullable_to_non_nullable
              as String?,
      photoUrl: freezed == photoUrl
          ? _self.photoUrl
          : photoUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      notes: freezed == notes
          ? _self.notes
          : notes // ignore: cast_nullable_to_non_nullable
              as String?,
      createdAt: freezed == createdAt
          ? _self.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

/// @nodoc

@JsonSerializable(explicitToJson: true, fieldRename: FieldRename.snake)
class _InventoryReceiptItemModel extends InventoryReceiptItemModel {
  const _InventoryReceiptItemModel(
      {required this.id,
      @JsonKey(name: 'receipt_id') required this.receiptId,
      required this.name,
      @JsonKey(name: 'category_id') required this.categoryId,
      required this.unit,
      required this.quantity,
      this.price,
      this.total,
      @JsonKey(name: 'serial_number') this.serialNumber,
      @JsonKey(name: 'photo_url') this.photoUrl,
      this.notes,
      @JsonKey(name: 'created_at') this.createdAt})
      : super._();
  factory _InventoryReceiptItemModel.fromJson(Map<String, dynamic> json) =>
      _$InventoryReceiptItemModelFromJson(json);

  @override
  final String id;
  @override
  @JsonKey(name: 'receipt_id')
  final String receiptId;
  @override
  final String name;
  @override
  @JsonKey(name: 'category_id')
  final String categoryId;
  @override
  final String unit;
  @override
  final double quantity;
  @override
  final double? price;
  @override
  final double? total;
  @override
  @JsonKey(name: 'serial_number')
  final String? serialNumber;
  @override
  @JsonKey(name: 'photo_url')
  final String? photoUrl;
  @override
  final String? notes;
  @override
  @JsonKey(name: 'created_at')
  final DateTime? createdAt;

  /// Create a copy of InventoryReceiptItemModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$InventoryReceiptItemModelCopyWith<_InventoryReceiptItemModel>
      get copyWith =>
          __$InventoryReceiptItemModelCopyWithImpl<_InventoryReceiptItemModel>(
              this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$InventoryReceiptItemModelToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _InventoryReceiptItemModel &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.receiptId, receiptId) ||
                other.receiptId == receiptId) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.categoryId, categoryId) ||
                other.categoryId == categoryId) &&
            (identical(other.unit, unit) || other.unit == unit) &&
            (identical(other.quantity, quantity) ||
                other.quantity == quantity) &&
            (identical(other.price, price) || other.price == price) &&
            (identical(other.total, total) || other.total == total) &&
            (identical(other.serialNumber, serialNumber) ||
                other.serialNumber == serialNumber) &&
            (identical(other.photoUrl, photoUrl) ||
                other.photoUrl == photoUrl) &&
            (identical(other.notes, notes) || other.notes == notes) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, receiptId, name, categoryId,
      unit, quantity, price, total, serialNumber, photoUrl, notes, createdAt);

  @override
  String toString() {
    return 'InventoryReceiptItemModel(id: $id, receiptId: $receiptId, name: $name, categoryId: $categoryId, unit: $unit, quantity: $quantity, price: $price, total: $total, serialNumber: $serialNumber, photoUrl: $photoUrl, notes: $notes, createdAt: $createdAt)';
  }
}

/// @nodoc
abstract mixin class _$InventoryReceiptItemModelCopyWith<$Res>
    implements $InventoryReceiptItemModelCopyWith<$Res> {
  factory _$InventoryReceiptItemModelCopyWith(_InventoryReceiptItemModel value,
          $Res Function(_InventoryReceiptItemModel) _then) =
      __$InventoryReceiptItemModelCopyWithImpl;
  @override
  @useResult
  $Res call(
      {String id,
      @JsonKey(name: 'receipt_id') String receiptId,
      String name,
      @JsonKey(name: 'category_id') String categoryId,
      String unit,
      double quantity,
      double? price,
      double? total,
      @JsonKey(name: 'serial_number') String? serialNumber,
      @JsonKey(name: 'photo_url') String? photoUrl,
      String? notes,
      @JsonKey(name: 'created_at') DateTime? createdAt});
}

/// @nodoc
class __$InventoryReceiptItemModelCopyWithImpl<$Res>
    implements _$InventoryReceiptItemModelCopyWith<$Res> {
  __$InventoryReceiptItemModelCopyWithImpl(this._self, this._then);

  final _InventoryReceiptItemModel _self;
  final $Res Function(_InventoryReceiptItemModel) _then;

  /// Create a copy of InventoryReceiptItemModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? id = null,
    Object? receiptId = null,
    Object? name = null,
    Object? categoryId = null,
    Object? unit = null,
    Object? quantity = null,
    Object? price = freezed,
    Object? total = freezed,
    Object? serialNumber = freezed,
    Object? photoUrl = freezed,
    Object? notes = freezed,
    Object? createdAt = freezed,
  }) {
    return _then(_InventoryReceiptItemModel(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      receiptId: null == receiptId
          ? _self.receiptId
          : receiptId // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _self.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      categoryId: null == categoryId
          ? _self.categoryId
          : categoryId // ignore: cast_nullable_to_non_nullable
              as String,
      unit: null == unit
          ? _self.unit
          : unit // ignore: cast_nullable_to_non_nullable
              as String,
      quantity: null == quantity
          ? _self.quantity
          : quantity // ignore: cast_nullable_to_non_nullable
              as double,
      price: freezed == price
          ? _self.price
          : price // ignore: cast_nullable_to_non_nullable
              as double?,
      total: freezed == total
          ? _self.total
          : total // ignore: cast_nullable_to_non_nullable
              as double?,
      serialNumber: freezed == serialNumber
          ? _self.serialNumber
          : serialNumber // ignore: cast_nullable_to_non_nullable
              as String?,
      photoUrl: freezed == photoUrl
          ? _self.photoUrl
          : photoUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      notes: freezed == notes
          ? _self.notes
          : notes // ignore: cast_nullable_to_non_nullable
              as String?,
      createdAt: freezed == createdAt
          ? _self.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

// dart format on
