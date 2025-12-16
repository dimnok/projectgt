// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'procurement_application.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ProcurementApplication {
  /// Уникальный идентификатор заявки.
  String get id;

  /// Читаемый ID заявки.
  @JsonKey(name: 'readable_id')
  String? get readableId;

  /// Дата создания.
  @JsonKey(name: 'created_at')
  DateTime get createdAt;

  /// Статус заявки.
  String get status; // Relations
  /// Объект, к которому относится заявка.
  @JsonKey(name: 'object', fromJson: _objectFromJson, toJson: _objectToJson)
  ObjectEntity? get object;

  /// Пользователь, создавший заявку.
  @JsonKey(name: 'requester')
  BotUserModel? get requester;

  /// Список позиций в заявке.
  @JsonKey(name: 'items')
  List<ProcurementRequest> get items;

  /// История изменений заявки.
  @JsonKey(name: 'history')
  List<ProcurementHistory> get history;

  /// Create a copy of ProcurementApplication
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $ProcurementApplicationCopyWith<ProcurementApplication> get copyWith =>
      _$ProcurementApplicationCopyWithImpl<ProcurementApplication>(
          this as ProcurementApplication, _$identity);

  /// Serializes this ProcurementApplication to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is ProcurementApplication &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.readableId, readableId) ||
                other.readableId == readableId) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.object, object) || other.object == object) &&
            (identical(other.requester, requester) ||
                other.requester == requester) &&
            const DeepCollectionEquality().equals(other.items, items) &&
            const DeepCollectionEquality().equals(other.history, history));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      readableId,
      createdAt,
      status,
      object,
      requester,
      const DeepCollectionEquality().hash(items),
      const DeepCollectionEquality().hash(history));

  @override
  String toString() {
    return 'ProcurementApplication(id: $id, readableId: $readableId, createdAt: $createdAt, status: $status, object: $object, requester: $requester, items: $items, history: $history)';
  }
}

/// @nodoc
abstract mixin class $ProcurementApplicationCopyWith<$Res> {
  factory $ProcurementApplicationCopyWith(ProcurementApplication value,
          $Res Function(ProcurementApplication) _then) =
      _$ProcurementApplicationCopyWithImpl;
  @useResult
  $Res call(
      {String id,
      @JsonKey(name: 'readable_id') String? readableId,
      @JsonKey(name: 'created_at') DateTime createdAt,
      String status,
      @JsonKey(name: 'object', fromJson: _objectFromJson, toJson: _objectToJson)
      ObjectEntity? object,
      @JsonKey(name: 'requester') BotUserModel? requester,
      @JsonKey(name: 'items') List<ProcurementRequest> items,
      @JsonKey(name: 'history') List<ProcurementHistory> history});

  $ObjectEntityCopyWith<$Res>? get object;
  $BotUserModelCopyWith<$Res>? get requester;
}

/// @nodoc
class _$ProcurementApplicationCopyWithImpl<$Res>
    implements $ProcurementApplicationCopyWith<$Res> {
  _$ProcurementApplicationCopyWithImpl(this._self, this._then);

  final ProcurementApplication _self;
  final $Res Function(ProcurementApplication) _then;

  /// Create a copy of ProcurementApplication
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? readableId = freezed,
    Object? createdAt = null,
    Object? status = null,
    Object? object = freezed,
    Object? requester = freezed,
    Object? items = null,
    Object? history = null,
  }) {
    return _then(_self.copyWith(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      readableId: freezed == readableId
          ? _self.readableId
          : readableId // ignore: cast_nullable_to_non_nullable
              as String?,
      createdAt: null == createdAt
          ? _self.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      status: null == status
          ? _self.status
          : status // ignore: cast_nullable_to_non_nullable
              as String,
      object: freezed == object
          ? _self.object
          : object // ignore: cast_nullable_to_non_nullable
              as ObjectEntity?,
      requester: freezed == requester
          ? _self.requester
          : requester // ignore: cast_nullable_to_non_nullable
              as BotUserModel?,
      items: null == items
          ? _self.items
          : items // ignore: cast_nullable_to_non_nullable
              as List<ProcurementRequest>,
      history: null == history
          ? _self.history
          : history // ignore: cast_nullable_to_non_nullable
              as List<ProcurementHistory>,
    ));
  }

  /// Create a copy of ProcurementApplication
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $ObjectEntityCopyWith<$Res>? get object {
    if (_self.object == null) {
      return null;
    }

    return $ObjectEntityCopyWith<$Res>(_self.object!, (value) {
      return _then(_self.copyWith(object: value));
    });
  }

  /// Create a copy of ProcurementApplication
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $BotUserModelCopyWith<$Res>? get requester {
    if (_self.requester == null) {
      return null;
    }

    return $BotUserModelCopyWith<$Res>(_self.requester!, (value) {
      return _then(_self.copyWith(requester: value));
    });
  }
}

/// @nodoc
@JsonSerializable()
class _ProcurementApplication implements ProcurementApplication {
  const _ProcurementApplication(
      {required this.id,
      @JsonKey(name: 'readable_id') this.readableId,
      @JsonKey(name: 'created_at') required this.createdAt,
      this.status = 'pending_approval',
      @JsonKey(name: 'object', fromJson: _objectFromJson, toJson: _objectToJson)
      this.object,
      @JsonKey(name: 'requester') this.requester,
      @JsonKey(name: 'items') final List<ProcurementRequest> items = const [],
      @JsonKey(name: 'history')
      final List<ProcurementHistory> history = const []})
      : _items = items,
        _history = history;
  factory _ProcurementApplication.fromJson(Map<String, dynamic> json) =>
      _$ProcurementApplicationFromJson(json);

  /// Уникальный идентификатор заявки.
  @override
  final String id;

  /// Читаемый ID заявки.
  @override
  @JsonKey(name: 'readable_id')
  final String? readableId;

  /// Дата создания.
  @override
  @JsonKey(name: 'created_at')
  final DateTime createdAt;

  /// Статус заявки.
  @override
  @JsonKey()
  final String status;
// Relations
  /// Объект, к которому относится заявка.
  @override
  @JsonKey(name: 'object', fromJson: _objectFromJson, toJson: _objectToJson)
  final ObjectEntity? object;

  /// Пользователь, создавший заявку.
  @override
  @JsonKey(name: 'requester')
  final BotUserModel? requester;

  /// Список позиций в заявке.
  final List<ProcurementRequest> _items;

  /// Список позиций в заявке.
  @override
  @JsonKey(name: 'items')
  List<ProcurementRequest> get items {
    if (_items is EqualUnmodifiableListView) return _items;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_items);
  }

  /// История изменений заявки.
  final List<ProcurementHistory> _history;

  /// История изменений заявки.
  @override
  @JsonKey(name: 'history')
  List<ProcurementHistory> get history {
    if (_history is EqualUnmodifiableListView) return _history;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_history);
  }

  /// Create a copy of ProcurementApplication
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$ProcurementApplicationCopyWith<_ProcurementApplication> get copyWith =>
      __$ProcurementApplicationCopyWithImpl<_ProcurementApplication>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$ProcurementApplicationToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _ProcurementApplication &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.readableId, readableId) ||
                other.readableId == readableId) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.object, object) || other.object == object) &&
            (identical(other.requester, requester) ||
                other.requester == requester) &&
            const DeepCollectionEquality().equals(other._items, _items) &&
            const DeepCollectionEquality().equals(other._history, _history));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      readableId,
      createdAt,
      status,
      object,
      requester,
      const DeepCollectionEquality().hash(_items),
      const DeepCollectionEquality().hash(_history));

  @override
  String toString() {
    return 'ProcurementApplication(id: $id, readableId: $readableId, createdAt: $createdAt, status: $status, object: $object, requester: $requester, items: $items, history: $history)';
  }
}

/// @nodoc
abstract mixin class _$ProcurementApplicationCopyWith<$Res>
    implements $ProcurementApplicationCopyWith<$Res> {
  factory _$ProcurementApplicationCopyWith(_ProcurementApplication value,
          $Res Function(_ProcurementApplication) _then) =
      __$ProcurementApplicationCopyWithImpl;
  @override
  @useResult
  $Res call(
      {String id,
      @JsonKey(name: 'readable_id') String? readableId,
      @JsonKey(name: 'created_at') DateTime createdAt,
      String status,
      @JsonKey(name: 'object', fromJson: _objectFromJson, toJson: _objectToJson)
      ObjectEntity? object,
      @JsonKey(name: 'requester') BotUserModel? requester,
      @JsonKey(name: 'items') List<ProcurementRequest> items,
      @JsonKey(name: 'history') List<ProcurementHistory> history});

  @override
  $ObjectEntityCopyWith<$Res>? get object;
  @override
  $BotUserModelCopyWith<$Res>? get requester;
}

/// @nodoc
class __$ProcurementApplicationCopyWithImpl<$Res>
    implements _$ProcurementApplicationCopyWith<$Res> {
  __$ProcurementApplicationCopyWithImpl(this._self, this._then);

  final _ProcurementApplication _self;
  final $Res Function(_ProcurementApplication) _then;

  /// Create a copy of ProcurementApplication
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? id = null,
    Object? readableId = freezed,
    Object? createdAt = null,
    Object? status = null,
    Object? object = freezed,
    Object? requester = freezed,
    Object? items = null,
    Object? history = null,
  }) {
    return _then(_ProcurementApplication(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      readableId: freezed == readableId
          ? _self.readableId
          : readableId // ignore: cast_nullable_to_non_nullable
              as String?,
      createdAt: null == createdAt
          ? _self.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      status: null == status
          ? _self.status
          : status // ignore: cast_nullable_to_non_nullable
              as String,
      object: freezed == object
          ? _self.object
          : object // ignore: cast_nullable_to_non_nullable
              as ObjectEntity?,
      requester: freezed == requester
          ? _self.requester
          : requester // ignore: cast_nullable_to_non_nullable
              as BotUserModel?,
      items: null == items
          ? _self._items
          : items // ignore: cast_nullable_to_non_nullable
              as List<ProcurementRequest>,
      history: null == history
          ? _self._history
          : history // ignore: cast_nullable_to_non_nullable
              as List<ProcurementHistory>,
    ));
  }

  /// Create a copy of ProcurementApplication
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $ObjectEntityCopyWith<$Res>? get object {
    if (_self.object == null) {
      return null;
    }

    return $ObjectEntityCopyWith<$Res>(_self.object!, (value) {
      return _then(_self.copyWith(object: value));
    });
  }

  /// Create a copy of ProcurementApplication
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $BotUserModelCopyWith<$Res>? get requester {
    if (_self.requester == null) {
      return null;
    }

    return $BotUserModelCopyWith<$Res>(_self.requester!, (value) {
      return _then(_self.copyWith(requester: value));
    });
  }
}

/// @nodoc
mixin _$ProcurementHistory {
  /// Уникальный идентификатор записи истории.
  String get id;

  /// Новый статус заявки.
  @JsonKey(name: 'new_status')
  String get newStatus;

  /// Дата изменения.
  @JsonKey(name: 'changed_at')
  DateTime get changedAt;

  /// Комментарий к изменению.
  String? get comment;

  /// Пользователь, внесший изменение.
  @JsonKey(name: 'actor')
  BotUserModel? get actor;

  /// Create a copy of ProcurementHistory
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $ProcurementHistoryCopyWith<ProcurementHistory> get copyWith =>
      _$ProcurementHistoryCopyWithImpl<ProcurementHistory>(
          this as ProcurementHistory, _$identity);

  /// Serializes this ProcurementHistory to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is ProcurementHistory &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.newStatus, newStatus) ||
                other.newStatus == newStatus) &&
            (identical(other.changedAt, changedAt) ||
                other.changedAt == changedAt) &&
            (identical(other.comment, comment) || other.comment == comment) &&
            (identical(other.actor, actor) || other.actor == actor));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, id, newStatus, changedAt, comment, actor);

  @override
  String toString() {
    return 'ProcurementHistory(id: $id, newStatus: $newStatus, changedAt: $changedAt, comment: $comment, actor: $actor)';
  }
}

/// @nodoc
abstract mixin class $ProcurementHistoryCopyWith<$Res> {
  factory $ProcurementHistoryCopyWith(
          ProcurementHistory value, $Res Function(ProcurementHistory) _then) =
      _$ProcurementHistoryCopyWithImpl;
  @useResult
  $Res call(
      {String id,
      @JsonKey(name: 'new_status') String newStatus,
      @JsonKey(name: 'changed_at') DateTime changedAt,
      String? comment,
      @JsonKey(name: 'actor') BotUserModel? actor});

  $BotUserModelCopyWith<$Res>? get actor;
}

/// @nodoc
class _$ProcurementHistoryCopyWithImpl<$Res>
    implements $ProcurementHistoryCopyWith<$Res> {
  _$ProcurementHistoryCopyWithImpl(this._self, this._then);

  final ProcurementHistory _self;
  final $Res Function(ProcurementHistory) _then;

  /// Create a copy of ProcurementHistory
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? newStatus = null,
    Object? changedAt = null,
    Object? comment = freezed,
    Object? actor = freezed,
  }) {
    return _then(_self.copyWith(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      newStatus: null == newStatus
          ? _self.newStatus
          : newStatus // ignore: cast_nullable_to_non_nullable
              as String,
      changedAt: null == changedAt
          ? _self.changedAt
          : changedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      comment: freezed == comment
          ? _self.comment
          : comment // ignore: cast_nullable_to_non_nullable
              as String?,
      actor: freezed == actor
          ? _self.actor
          : actor // ignore: cast_nullable_to_non_nullable
              as BotUserModel?,
    ));
  }

  /// Create a copy of ProcurementHistory
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $BotUserModelCopyWith<$Res>? get actor {
    if (_self.actor == null) {
      return null;
    }

    return $BotUserModelCopyWith<$Res>(_self.actor!, (value) {
      return _then(_self.copyWith(actor: value));
    });
  }
}

/// @nodoc
@JsonSerializable()
class _ProcurementHistory implements ProcurementHistory {
  const _ProcurementHistory(
      {required this.id,
      @JsonKey(name: 'new_status') required this.newStatus,
      @JsonKey(name: 'changed_at') required this.changedAt,
      this.comment,
      @JsonKey(name: 'actor') this.actor});
  factory _ProcurementHistory.fromJson(Map<String, dynamic> json) =>
      _$ProcurementHistoryFromJson(json);

  /// Уникальный идентификатор записи истории.
  @override
  final String id;

  /// Новый статус заявки.
  @override
  @JsonKey(name: 'new_status')
  final String newStatus;

  /// Дата изменения.
  @override
  @JsonKey(name: 'changed_at')
  final DateTime changedAt;

  /// Комментарий к изменению.
  @override
  final String? comment;

  /// Пользователь, внесший изменение.
  @override
  @JsonKey(name: 'actor')
  final BotUserModel? actor;

  /// Create a copy of ProcurementHistory
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$ProcurementHistoryCopyWith<_ProcurementHistory> get copyWith =>
      __$ProcurementHistoryCopyWithImpl<_ProcurementHistory>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$ProcurementHistoryToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _ProcurementHistory &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.newStatus, newStatus) ||
                other.newStatus == newStatus) &&
            (identical(other.changedAt, changedAt) ||
                other.changedAt == changedAt) &&
            (identical(other.comment, comment) || other.comment == comment) &&
            (identical(other.actor, actor) || other.actor == actor));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, id, newStatus, changedAt, comment, actor);

  @override
  String toString() {
    return 'ProcurementHistory(id: $id, newStatus: $newStatus, changedAt: $changedAt, comment: $comment, actor: $actor)';
  }
}

/// @nodoc
abstract mixin class _$ProcurementHistoryCopyWith<$Res>
    implements $ProcurementHistoryCopyWith<$Res> {
  factory _$ProcurementHistoryCopyWith(
          _ProcurementHistory value, $Res Function(_ProcurementHistory) _then) =
      __$ProcurementHistoryCopyWithImpl;
  @override
  @useResult
  $Res call(
      {String id,
      @JsonKey(name: 'new_status') String newStatus,
      @JsonKey(name: 'changed_at') DateTime changedAt,
      String? comment,
      @JsonKey(name: 'actor') BotUserModel? actor});

  @override
  $BotUserModelCopyWith<$Res>? get actor;
}

/// @nodoc
class __$ProcurementHistoryCopyWithImpl<$Res>
    implements _$ProcurementHistoryCopyWith<$Res> {
  __$ProcurementHistoryCopyWithImpl(this._self, this._then);

  final _ProcurementHistory _self;
  final $Res Function(_ProcurementHistory) _then;

  /// Create a copy of ProcurementHistory
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? id = null,
    Object? newStatus = null,
    Object? changedAt = null,
    Object? comment = freezed,
    Object? actor = freezed,
  }) {
    return _then(_ProcurementHistory(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      newStatus: null == newStatus
          ? _self.newStatus
          : newStatus // ignore: cast_nullable_to_non_nullable
              as String,
      changedAt: null == changedAt
          ? _self.changedAt
          : changedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      comment: freezed == comment
          ? _self.comment
          : comment // ignore: cast_nullable_to_non_nullable
              as String?,
      actor: freezed == actor
          ? _self.actor
          : actor // ignore: cast_nullable_to_non_nullable
              as BotUserModel?,
    ));
  }

  /// Create a copy of ProcurementHistory
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $BotUserModelCopyWith<$Res>? get actor {
    if (_self.actor == null) {
      return null;
    }

    return $BotUserModelCopyWith<$Res>(_self.actor!, (value) {
      return _then(_self.copyWith(actor: value));
    });
  }
}

// dart format on
