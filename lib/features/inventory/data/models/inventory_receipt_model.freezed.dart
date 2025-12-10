// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'inventory_receipt_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$InventoryReceiptModel {
  String get id;
  @JsonKey(name: 'receipt_number')
  String get receiptNumber;
  @JsonKey(name: 'receipt_date')
  DateTime get receiptDate;
  @JsonKey(name: 'supplier_id')
  String? get supplierId;
  @JsonKey(name: 'file_url')
  String? get fileUrl;
  String? get comment;
  @JsonKey(name: 'total_amount')
  double? get totalAmount;
  @JsonKey(name: 'items_count')
  int get itemsCount;
  @JsonKey(name: 'created_at')
  DateTime? get createdAt;
  @JsonKey(name: 'updated_at')
  DateTime? get updatedAt;
  @JsonKey(name: 'created_by')
  String? get createdBy;
  @JsonKey(includeFromJson: false, includeToJson: false)
  List<InventoryReceiptItemModel>? get items;

  /// Create a copy of InventoryReceiptModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $InventoryReceiptModelCopyWith<InventoryReceiptModel> get copyWith =>
      _$InventoryReceiptModelCopyWithImpl<InventoryReceiptModel>(
          this as InventoryReceiptModel, _$identity);

  /// Serializes this InventoryReceiptModel to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is InventoryReceiptModel &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.receiptNumber, receiptNumber) ||
                other.receiptNumber == receiptNumber) &&
            (identical(other.receiptDate, receiptDate) ||
                other.receiptDate == receiptDate) &&
            (identical(other.supplierId, supplierId) ||
                other.supplierId == supplierId) &&
            (identical(other.fileUrl, fileUrl) || other.fileUrl == fileUrl) &&
            (identical(other.comment, comment) || other.comment == comment) &&
            (identical(other.totalAmount, totalAmount) ||
                other.totalAmount == totalAmount) &&
            (identical(other.itemsCount, itemsCount) ||
                other.itemsCount == itemsCount) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt) &&
            (identical(other.createdBy, createdBy) ||
                other.createdBy == createdBy) &&
            const DeepCollectionEquality().equals(other.items, items));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      receiptNumber,
      receiptDate,
      supplierId,
      fileUrl,
      comment,
      totalAmount,
      itemsCount,
      createdAt,
      updatedAt,
      createdBy,
      const DeepCollectionEquality().hash(items));

  @override
  String toString() {
    return 'InventoryReceiptModel(id: $id, receiptNumber: $receiptNumber, receiptDate: $receiptDate, supplierId: $supplierId, fileUrl: $fileUrl, comment: $comment, totalAmount: $totalAmount, itemsCount: $itemsCount, createdAt: $createdAt, updatedAt: $updatedAt, createdBy: $createdBy, items: $items)';
  }
}

/// @nodoc
abstract mixin class $InventoryReceiptModelCopyWith<$Res> {
  factory $InventoryReceiptModelCopyWith(InventoryReceiptModel value,
          $Res Function(InventoryReceiptModel) _then) =
      _$InventoryReceiptModelCopyWithImpl;
  @useResult
  $Res call(
      {String id,
      @JsonKey(name: 'receipt_number') String receiptNumber,
      @JsonKey(name: 'receipt_date') DateTime receiptDate,
      @JsonKey(name: 'supplier_id') String? supplierId,
      @JsonKey(name: 'file_url') String? fileUrl,
      String? comment,
      @JsonKey(name: 'total_amount') double? totalAmount,
      @JsonKey(name: 'items_count') int itemsCount,
      @JsonKey(name: 'created_at') DateTime? createdAt,
      @JsonKey(name: 'updated_at') DateTime? updatedAt,
      @JsonKey(name: 'created_by') String? createdBy,
      @JsonKey(includeFromJson: false, includeToJson: false)
      List<InventoryReceiptItemModel>? items});
}

/// @nodoc
class _$InventoryReceiptModelCopyWithImpl<$Res>
    implements $InventoryReceiptModelCopyWith<$Res> {
  _$InventoryReceiptModelCopyWithImpl(this._self, this._then);

  final InventoryReceiptModel _self;
  final $Res Function(InventoryReceiptModel) _then;

  /// Create a copy of InventoryReceiptModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? receiptNumber = null,
    Object? receiptDate = null,
    Object? supplierId = freezed,
    Object? fileUrl = freezed,
    Object? comment = freezed,
    Object? totalAmount = freezed,
    Object? itemsCount = null,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
    Object? createdBy = freezed,
    Object? items = freezed,
  }) {
    return _then(_self.copyWith(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      receiptNumber: null == receiptNumber
          ? _self.receiptNumber
          : receiptNumber // ignore: cast_nullable_to_non_nullable
              as String,
      receiptDate: null == receiptDate
          ? _self.receiptDate
          : receiptDate // ignore: cast_nullable_to_non_nullable
              as DateTime,
      supplierId: freezed == supplierId
          ? _self.supplierId
          : supplierId // ignore: cast_nullable_to_non_nullable
              as String?,
      fileUrl: freezed == fileUrl
          ? _self.fileUrl
          : fileUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      comment: freezed == comment
          ? _self.comment
          : comment // ignore: cast_nullable_to_non_nullable
              as String?,
      totalAmount: freezed == totalAmount
          ? _self.totalAmount
          : totalAmount // ignore: cast_nullable_to_non_nullable
              as double?,
      itemsCount: null == itemsCount
          ? _self.itemsCount
          : itemsCount // ignore: cast_nullable_to_non_nullable
              as int,
      createdAt: freezed == createdAt
          ? _self.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      updatedAt: freezed == updatedAt
          ? _self.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      createdBy: freezed == createdBy
          ? _self.createdBy
          : createdBy // ignore: cast_nullable_to_non_nullable
              as String?,
      items: freezed == items
          ? _self.items
          : items // ignore: cast_nullable_to_non_nullable
              as List<InventoryReceiptItemModel>?,
    ));
  }
}

/// @nodoc

@JsonSerializable(explicitToJson: true, fieldRename: FieldRename.snake)
class _InventoryReceiptModel extends InventoryReceiptModel {
  const _InventoryReceiptModel(
      {required this.id,
      @JsonKey(name: 'receipt_number') required this.receiptNumber,
      @JsonKey(name: 'receipt_date') required this.receiptDate,
      @JsonKey(name: 'supplier_id') this.supplierId,
      @JsonKey(name: 'file_url') this.fileUrl,
      this.comment,
      @JsonKey(name: 'total_amount') this.totalAmount,
      @JsonKey(name: 'items_count') this.itemsCount = 0,
      @JsonKey(name: 'created_at') this.createdAt,
      @JsonKey(name: 'updated_at') this.updatedAt,
      @JsonKey(name: 'created_by') this.createdBy,
      @JsonKey(includeFromJson: false, includeToJson: false)
      final List<InventoryReceiptItemModel>? items})
      : _items = items,
        super._();
  factory _InventoryReceiptModel.fromJson(Map<String, dynamic> json) =>
      _$InventoryReceiptModelFromJson(json);

  @override
  final String id;
  @override
  @JsonKey(name: 'receipt_number')
  final String receiptNumber;
  @override
  @JsonKey(name: 'receipt_date')
  final DateTime receiptDate;
  @override
  @JsonKey(name: 'supplier_id')
  final String? supplierId;
  @override
  @JsonKey(name: 'file_url')
  final String? fileUrl;
  @override
  final String? comment;
  @override
  @JsonKey(name: 'total_amount')
  final double? totalAmount;
  @override
  @JsonKey(name: 'items_count')
  final int itemsCount;
  @override
  @JsonKey(name: 'created_at')
  final DateTime? createdAt;
  @override
  @JsonKey(name: 'updated_at')
  final DateTime? updatedAt;
  @override
  @JsonKey(name: 'created_by')
  final String? createdBy;
  final List<InventoryReceiptItemModel>? _items;
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  List<InventoryReceiptItemModel>? get items {
    final value = _items;
    if (value == null) return null;
    if (_items is EqualUnmodifiableListView) return _items;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  /// Create a copy of InventoryReceiptModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$InventoryReceiptModelCopyWith<_InventoryReceiptModel> get copyWith =>
      __$InventoryReceiptModelCopyWithImpl<_InventoryReceiptModel>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$InventoryReceiptModelToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _InventoryReceiptModel &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.receiptNumber, receiptNumber) ||
                other.receiptNumber == receiptNumber) &&
            (identical(other.receiptDate, receiptDate) ||
                other.receiptDate == receiptDate) &&
            (identical(other.supplierId, supplierId) ||
                other.supplierId == supplierId) &&
            (identical(other.fileUrl, fileUrl) || other.fileUrl == fileUrl) &&
            (identical(other.comment, comment) || other.comment == comment) &&
            (identical(other.totalAmount, totalAmount) ||
                other.totalAmount == totalAmount) &&
            (identical(other.itemsCount, itemsCount) ||
                other.itemsCount == itemsCount) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt) &&
            (identical(other.createdBy, createdBy) ||
                other.createdBy == createdBy) &&
            const DeepCollectionEquality().equals(other._items, _items));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      receiptNumber,
      receiptDate,
      supplierId,
      fileUrl,
      comment,
      totalAmount,
      itemsCount,
      createdAt,
      updatedAt,
      createdBy,
      const DeepCollectionEquality().hash(_items));

  @override
  String toString() {
    return 'InventoryReceiptModel(id: $id, receiptNumber: $receiptNumber, receiptDate: $receiptDate, supplierId: $supplierId, fileUrl: $fileUrl, comment: $comment, totalAmount: $totalAmount, itemsCount: $itemsCount, createdAt: $createdAt, updatedAt: $updatedAt, createdBy: $createdBy, items: $items)';
  }
}

/// @nodoc
abstract mixin class _$InventoryReceiptModelCopyWith<$Res>
    implements $InventoryReceiptModelCopyWith<$Res> {
  factory _$InventoryReceiptModelCopyWith(_InventoryReceiptModel value,
          $Res Function(_InventoryReceiptModel) _then) =
      __$InventoryReceiptModelCopyWithImpl;
  @override
  @useResult
  $Res call(
      {String id,
      @JsonKey(name: 'receipt_number') String receiptNumber,
      @JsonKey(name: 'receipt_date') DateTime receiptDate,
      @JsonKey(name: 'supplier_id') String? supplierId,
      @JsonKey(name: 'file_url') String? fileUrl,
      String? comment,
      @JsonKey(name: 'total_amount') double? totalAmount,
      @JsonKey(name: 'items_count') int itemsCount,
      @JsonKey(name: 'created_at') DateTime? createdAt,
      @JsonKey(name: 'updated_at') DateTime? updatedAt,
      @JsonKey(name: 'created_by') String? createdBy,
      @JsonKey(includeFromJson: false, includeToJson: false)
      List<InventoryReceiptItemModel>? items});
}

/// @nodoc
class __$InventoryReceiptModelCopyWithImpl<$Res>
    implements _$InventoryReceiptModelCopyWith<$Res> {
  __$InventoryReceiptModelCopyWithImpl(this._self, this._then);

  final _InventoryReceiptModel _self;
  final $Res Function(_InventoryReceiptModel) _then;

  /// Create a copy of InventoryReceiptModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? id = null,
    Object? receiptNumber = null,
    Object? receiptDate = null,
    Object? supplierId = freezed,
    Object? fileUrl = freezed,
    Object? comment = freezed,
    Object? totalAmount = freezed,
    Object? itemsCount = null,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
    Object? createdBy = freezed,
    Object? items = freezed,
  }) {
    return _then(_InventoryReceiptModel(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      receiptNumber: null == receiptNumber
          ? _self.receiptNumber
          : receiptNumber // ignore: cast_nullable_to_non_nullable
              as String,
      receiptDate: null == receiptDate
          ? _self.receiptDate
          : receiptDate // ignore: cast_nullable_to_non_nullable
              as DateTime,
      supplierId: freezed == supplierId
          ? _self.supplierId
          : supplierId // ignore: cast_nullable_to_non_nullable
              as String?,
      fileUrl: freezed == fileUrl
          ? _self.fileUrl
          : fileUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      comment: freezed == comment
          ? _self.comment
          : comment // ignore: cast_nullable_to_non_nullable
              as String?,
      totalAmount: freezed == totalAmount
          ? _self.totalAmount
          : totalAmount // ignore: cast_nullable_to_non_nullable
              as double?,
      itemsCount: null == itemsCount
          ? _self.itemsCount
          : itemsCount // ignore: cast_nullable_to_non_nullable
              as int,
      createdAt: freezed == createdAt
          ? _self.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      updatedAt: freezed == updatedAt
          ? _self.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      createdBy: freezed == createdBy
          ? _self.createdBy
          : createdBy // ignore: cast_nullable_to_non_nullable
              as String?,
      items: freezed == items
          ? _self._items
          : items // ignore: cast_nullable_to_non_nullable
              as List<InventoryReceiptItemModel>?,
    ));
  }
}

// dart format on
