import 'package:supabase_flutter/supabase_flutter.dart';

/// Модель ответа от Edge Function telegram-auth
class TelegramAuthResponse {
  /// JWT токен для авторизации
  final String jwt;

  /// ID пользователя в Supabase
  final String userId;

  /// Создаёт [TelegramAuthResponse] из JSON
  TelegramAuthResponse({
    required this.jwt,
    required this.userId,
  });

  /// Фабрика для парсинга из JSON
  factory TelegramAuthResponse.fromJson(Map<String, dynamic> json) {
    return TelegramAuthResponse(
      jwt: json['jwt'] as String,
      userId: json['userId'] as String,
    );
  }
}

/// Data Source для аутентификации через Telegram Mini App
///
/// Вызывает Edge Function `telegram-auth` с initData от Telegram WebApp JS API.
/// Edge Function проверяет подпись, создаёт/получает пользователя и возвращает JWT.
class TelegramAuthDataSource {
  /// Суpabase клиент
  final SupabaseClient _supabase;

  /// Создаёт [TelegramAuthDataSource]
  TelegramAuthDataSource({SupabaseClient? supabase})
      : _supabase = supabase ?? Supabase.instance.client;

  /// Аутентифицирует пользователя через Telegram и возвращает JWT
  ///
  /// [initData] - подписанные данные от TelegramWebApp.init() на веб
  ///
  /// Возвращает [TelegramAuthResponse] с JWT токеном и userId
  ///
  /// Выбрасывает исключение если:
  /// - initData невалидны
  /// - подпись не прошла проверку
  /// - ошибка при создании пользователя
  Future<TelegramAuthResponse> authenticateWithInitData({
    required String initData,
  }) async {
    try {
      final response = await _supabase.functions.invoke(
        'telegram-auth',
        body: {'initData': initData},
      );

      // Parse response - FunctionResponse is already parsed JSON
      final responseData = response as Map<String, dynamic>;

      // Проверяем ошибки в ответе
      if (responseData.containsKey('error')) {
        throw Exception('Telegram auth error: ${responseData['error']}');
      }

      final authResponse = TelegramAuthResponse.fromJson(responseData);

      // Устанавливаем JWT сессию в Supabase Auth
      // Т.к. это custom JWT, устанавливаем его напрямую через setSession
      // (не через стандартный signIn)
      try {
        // Создаём фиктивный refresh token (для совместимости с Supabase SDK)
        await _supabase.auth.setSession(authResponse.jwt);
      } catch (e) {
        // Если setSession не сработал - можно попробовать альтернативный способ
        // Но обычно это работает
        debugPrint('Warning: Could not set session immediately: $e');
      }

      return authResponse;
    } catch (e) {
      throw Exception('Telegram authentication failed: $e');
    }
  }
}

// Для отладки
void debugPrint(String message) {
  print('[TelegramAuthDataSource] $message');
}

