// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'bot_user_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$BotUserModel implements DiagnosticableTreeMixin {
  /// Уникальный идентификатор пользователя (UUID из profiles).
  String get id;

  /// Telegram ID пользователя.
  @JsonKey(name: 'telegram_chat_id')
  int get telegramChatId;

  /// Полное имя пользователя.
  @JsonKey(name: 'full_name')
  String get fullName;

  /// Идентификатор роли пользователя.
  @JsonKey(name: 'role_id')
  String? get roleId;

  /// Create a copy of BotUserModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $BotUserModelCopyWith<BotUserModel> get copyWith =>
      _$BotUserModelCopyWithImpl<BotUserModel>(
          this as BotUserModel, _$identity);

  /// Serializes this BotUserModel to a JSON map.
  Map<String, dynamic> toJson();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    properties
      ..add(DiagnosticsProperty('type', 'BotUserModel'))
      ..add(DiagnosticsProperty('id', id))
      ..add(DiagnosticsProperty('telegramChatId', telegramChatId))
      ..add(DiagnosticsProperty('fullName', fullName))
      ..add(DiagnosticsProperty('roleId', roleId));
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is BotUserModel &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.telegramChatId, telegramChatId) ||
                other.telegramChatId == telegramChatId) &&
            (identical(other.fullName, fullName) ||
                other.fullName == fullName) &&
            (identical(other.roleId, roleId) || other.roleId == roleId));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, id, telegramChatId, fullName, roleId);

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return 'BotUserModel(id: $id, telegramChatId: $telegramChatId, fullName: $fullName, roleId: $roleId)';
  }
}

/// @nodoc
abstract mixin class $BotUserModelCopyWith<$Res> {
  factory $BotUserModelCopyWith(
          BotUserModel value, $Res Function(BotUserModel) _then) =
      _$BotUserModelCopyWithImpl;
  @useResult
  $Res call(
      {String id,
      @JsonKey(name: 'telegram_chat_id') int telegramChatId,
      @JsonKey(name: 'full_name') String fullName,
      @JsonKey(name: 'role_id') String? roleId});
}

/// @nodoc
class _$BotUserModelCopyWithImpl<$Res> implements $BotUserModelCopyWith<$Res> {
  _$BotUserModelCopyWithImpl(this._self, this._then);

  final BotUserModel _self;
  final $Res Function(BotUserModel) _then;

  /// Create a copy of BotUserModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? telegramChatId = null,
    Object? fullName = null,
    Object? roleId = freezed,
  }) {
    return _then(_self.copyWith(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      telegramChatId: null == telegramChatId
          ? _self.telegramChatId
          : telegramChatId // ignore: cast_nullable_to_non_nullable
              as int,
      fullName: null == fullName
          ? _self.fullName
          : fullName // ignore: cast_nullable_to_non_nullable
              as String,
      roleId: freezed == roleId
          ? _self.roleId
          : roleId // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _BotUserModel with DiagnosticableTreeMixin implements BotUserModel {
  const _BotUserModel(
      {required this.id,
      @JsonKey(name: 'telegram_chat_id') required this.telegramChatId,
      @JsonKey(name: 'full_name') required this.fullName,
      @JsonKey(name: 'role_id') this.roleId});
  factory _BotUserModel.fromJson(Map<String, dynamic> json) =>
      _$BotUserModelFromJson(json);

  /// Уникальный идентификатор пользователя (UUID из profiles).
  @override
  final String id;

  /// Telegram ID пользователя.
  @override
  @JsonKey(name: 'telegram_chat_id')
  final int telegramChatId;

  /// Полное имя пользователя.
  @override
  @JsonKey(name: 'full_name')
  final String fullName;

  /// Идентификатор роли пользователя.
  @override
  @JsonKey(name: 'role_id')
  final String? roleId;

  /// Create a copy of BotUserModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$BotUserModelCopyWith<_BotUserModel> get copyWith =>
      __$BotUserModelCopyWithImpl<_BotUserModel>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$BotUserModelToJson(
      this,
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    properties
      ..add(DiagnosticsProperty('type', 'BotUserModel'))
      ..add(DiagnosticsProperty('id', id))
      ..add(DiagnosticsProperty('telegramChatId', telegramChatId))
      ..add(DiagnosticsProperty('fullName', fullName))
      ..add(DiagnosticsProperty('roleId', roleId));
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _BotUserModel &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.telegramChatId, telegramChatId) ||
                other.telegramChatId == telegramChatId) &&
            (identical(other.fullName, fullName) ||
                other.fullName == fullName) &&
            (identical(other.roleId, roleId) || other.roleId == roleId));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, id, telegramChatId, fullName, roleId);

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return 'BotUserModel(id: $id, telegramChatId: $telegramChatId, fullName: $fullName, roleId: $roleId)';
  }
}

/// @nodoc
abstract mixin class _$BotUserModelCopyWith<$Res>
    implements $BotUserModelCopyWith<$Res> {
  factory _$BotUserModelCopyWith(
          _BotUserModel value, $Res Function(_BotUserModel) _then) =
      __$BotUserModelCopyWithImpl;
  @override
  @useResult
  $Res call(
      {String id,
      @JsonKey(name: 'telegram_chat_id') int telegramChatId,
      @JsonKey(name: 'full_name') String fullName,
      @JsonKey(name: 'role_id') String? roleId});
}

/// @nodoc
class __$BotUserModelCopyWithImpl<$Res>
    implements _$BotUserModelCopyWith<$Res> {
  __$BotUserModelCopyWithImpl(this._self, this._then);

  final _BotUserModel _self;
  final $Res Function(_BotUserModel) _then;

  /// Create a copy of BotUserModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? id = null,
    Object? telegramChatId = null,
    Object? fullName = null,
    Object? roleId = freezed,
  }) {
    return _then(_BotUserModel(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      telegramChatId: null == telegramChatId
          ? _self.telegramChatId
          : telegramChatId // ignore: cast_nullable_to_non_nullable
              as int,
      fullName: null == fullName
          ? _self.fullName
          : fullName // ignore: cast_nullable_to_non_nullable
              as String,
      roleId: freezed == roleId
          ? _self.roleId
          : roleId // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

// dart format on
