// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bot_user_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_BotUserModel _$BotUserModelFromJson(Map<String, dynamic> json) =>
    _BotUserModel(
      id: json['id'] as String,
      telegramChatId: (json['telegram_chat_id'] as num).toInt(),
      fullName: json['full_name'] as String,
      roleId: json['role_id'] as String?,
    );

Map<String, dynamic> _$BotUserModelToJson(_BotUserModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'telegram_chat_id': instance.telegramChatId,
      'full_name': instance.fullName,
      'role_id': instance.roleId,
    };
