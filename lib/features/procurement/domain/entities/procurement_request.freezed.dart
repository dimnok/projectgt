// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'procurement_request.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ProcurementRequest {
  /// Уникальный идентификатор позиции.
  String get id;

  /// Наименование товара или услуги.
  @JsonKey(name: 'item_name')
  String get itemName;

  /// Количество (с единицами измерения в строке).
  String get quantity;

  /// Статус позиции.
  String get status;

  /// Дата создания позиции.
  @JsonKey(name: 'created_at')
  DateTime get createdAt;

  /// Описание или примечание.
  @JsonKey(name: 'description')
  String? get description;

  /// Telegram ID заявителя (для обратной совместимости или быстрого доступа).
  @JsonKey(name: 'requester_telegram_id')
  int? get requesterTelegramId;

  /// Create a copy of ProcurementRequest
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $ProcurementRequestCopyWith<ProcurementRequest> get copyWith =>
      _$ProcurementRequestCopyWithImpl<ProcurementRequest>(
          this as ProcurementRequest, _$identity);

  /// Serializes this ProcurementRequest to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is ProcurementRequest &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.itemName, itemName) ||
                other.itemName == itemName) &&
            (identical(other.quantity, quantity) ||
                other.quantity == quantity) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.requesterTelegramId, requesterTelegramId) ||
                other.requesterTelegramId == requesterTelegramId));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, itemName, quantity, status,
      createdAt, description, requesterTelegramId);

  @override
  String toString() {
    return 'ProcurementRequest(id: $id, itemName: $itemName, quantity: $quantity, status: $status, createdAt: $createdAt, description: $description, requesterTelegramId: $requesterTelegramId)';
  }
}

/// @nodoc
abstract mixin class $ProcurementRequestCopyWith<$Res> {
  factory $ProcurementRequestCopyWith(
          ProcurementRequest value, $Res Function(ProcurementRequest) _then) =
      _$ProcurementRequestCopyWithImpl;
  @useResult
  $Res call(
      {String id,
      @JsonKey(name: 'item_name') String itemName,
      String quantity,
      String status,
      @JsonKey(name: 'created_at') DateTime createdAt,
      @JsonKey(name: 'description') String? description,
      @JsonKey(name: 'requester_telegram_id') int? requesterTelegramId});
}

/// @nodoc
class _$ProcurementRequestCopyWithImpl<$Res>
    implements $ProcurementRequestCopyWith<$Res> {
  _$ProcurementRequestCopyWithImpl(this._self, this._then);

  final ProcurementRequest _self;
  final $Res Function(ProcurementRequest) _then;

  /// Create a copy of ProcurementRequest
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? itemName = null,
    Object? quantity = null,
    Object? status = null,
    Object? createdAt = null,
    Object? description = freezed,
    Object? requesterTelegramId = freezed,
  }) {
    return _then(_self.copyWith(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      itemName: null == itemName
          ? _self.itemName
          : itemName // ignore: cast_nullable_to_non_nullable
              as String,
      quantity: null == quantity
          ? _self.quantity
          : quantity // ignore: cast_nullable_to_non_nullable
              as String,
      status: null == status
          ? _self.status
          : status // ignore: cast_nullable_to_non_nullable
              as String,
      createdAt: null == createdAt
          ? _self.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      description: freezed == description
          ? _self.description
          : description // ignore: cast_nullable_to_non_nullable
              as String?,
      requesterTelegramId: freezed == requesterTelegramId
          ? _self.requesterTelegramId
          : requesterTelegramId // ignore: cast_nullable_to_non_nullable
              as int?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _ProcurementRequest implements ProcurementRequest {
  const _ProcurementRequest(
      {required this.id,
      @JsonKey(name: 'item_name') required this.itemName,
      required this.quantity,
      this.status = 'pending_approval',
      @JsonKey(name: 'created_at') required this.createdAt,
      @JsonKey(name: 'description') this.description,
      @JsonKey(name: 'requester_telegram_id') this.requesterTelegramId});
  factory _ProcurementRequest.fromJson(Map<String, dynamic> json) =>
      _$ProcurementRequestFromJson(json);

  /// Уникальный идентификатор позиции.
  @override
  final String id;

  /// Наименование товара или услуги.
  @override
  @JsonKey(name: 'item_name')
  final String itemName;

  /// Количество (с единицами измерения в строке).
  @override
  final String quantity;

  /// Статус позиции.
  @override
  @JsonKey()
  final String status;

  /// Дата создания позиции.
  @override
  @JsonKey(name: 'created_at')
  final DateTime createdAt;

  /// Описание или примечание.
  @override
  @JsonKey(name: 'description')
  final String? description;

  /// Telegram ID заявителя (для обратной совместимости или быстрого доступа).
  @override
  @JsonKey(name: 'requester_telegram_id')
  final int? requesterTelegramId;

  /// Create a copy of ProcurementRequest
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$ProcurementRequestCopyWith<_ProcurementRequest> get copyWith =>
      __$ProcurementRequestCopyWithImpl<_ProcurementRequest>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$ProcurementRequestToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _ProcurementRequest &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.itemName, itemName) ||
                other.itemName == itemName) &&
            (identical(other.quantity, quantity) ||
                other.quantity == quantity) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.requesterTelegramId, requesterTelegramId) ||
                other.requesterTelegramId == requesterTelegramId));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, itemName, quantity, status,
      createdAt, description, requesterTelegramId);

  @override
  String toString() {
    return 'ProcurementRequest(id: $id, itemName: $itemName, quantity: $quantity, status: $status, createdAt: $createdAt, description: $description, requesterTelegramId: $requesterTelegramId)';
  }
}

/// @nodoc
abstract mixin class _$ProcurementRequestCopyWith<$Res>
    implements $ProcurementRequestCopyWith<$Res> {
  factory _$ProcurementRequestCopyWith(
          _ProcurementRequest value, $Res Function(_ProcurementRequest) _then) =
      __$ProcurementRequestCopyWithImpl;
  @override
  @useResult
  $Res call(
      {String id,
      @JsonKey(name: 'item_name') String itemName,
      String quantity,
      String status,
      @JsonKey(name: 'created_at') DateTime createdAt,
      @JsonKey(name: 'description') String? description,
      @JsonKey(name: 'requester_telegram_id') int? requesterTelegramId});
}

/// @nodoc
class __$ProcurementRequestCopyWithImpl<$Res>
    implements _$ProcurementRequestCopyWith<$Res> {
  __$ProcurementRequestCopyWithImpl(this._self, this._then);

  final _ProcurementRequest _self;
  final $Res Function(_ProcurementRequest) _then;

  /// Create a copy of ProcurementRequest
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? id = null,
    Object? itemName = null,
    Object? quantity = null,
    Object? status = null,
    Object? createdAt = null,
    Object? description = freezed,
    Object? requesterTelegramId = freezed,
  }) {
    return _then(_ProcurementRequest(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      itemName: null == itemName
          ? _self.itemName
          : itemName // ignore: cast_nullable_to_non_nullable
              as String,
      quantity: null == quantity
          ? _self.quantity
          : quantity // ignore: cast_nullable_to_non_nullable
              as String,
      status: null == status
          ? _self.status
          : status // ignore: cast_nullable_to_non_nullable
              as String,
      createdAt: null == createdAt
          ? _self.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      description: freezed == description
          ? _self.description
          : description // ignore: cast_nullable_to_non_nullable
              as String?,
      requesterTelegramId: freezed == requesterTelegramId
          ? _self.requesterTelegramId
          : requesterTelegramId // ignore: cast_nullable_to_non_nullable
              as int?,
    ));
  }
}

// dart format on
