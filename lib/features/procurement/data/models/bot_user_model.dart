import 'package:flutter/foundation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'bot_user_model.freezed.dart';
part 'bot_user_model.g.dart';

/// Модель пользователя бота.
@freezed
abstract class BotUserModel with _$BotUserModel {
  /// Создаёт экземпляр пользователя бота.
  const factory BotUserModel({
    /// Уникальный идентификатор пользователя (UUID из profiles).
    required String id,

    /// Telegram ID пользователя.
    @JsonKey(name: 'telegram_chat_id') required int telegramChatId,

    /// Полное имя пользователя.
    @JsonKey(name: 'full_name') required String fullName,

    /// Идентификатор роли пользователя.
    @JsonKey(name: 'role_id') String? roleId,
  }) = _BotUserModel;

  /// Создаёт модель пользователя из JSON.
  factory BotUserModel.fromJson(Map<String, dynamic> json) =>
      _$BotUserModelFromJson(json);
}
