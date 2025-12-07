import 'dart:io' show Platform;

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_app_installations/firebase_app_installations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Провайдер сервиса управления FCM токенами.
///
/// Предоставляет глобальный доступ к экземпляру [FcmTokenService]
/// для управления Firebase Cloud Messaging токенами пользователей.
final fcmTokenServiceProvider = Provider<FcmTokenService>((ref) {
  return FcmTokenService(ref: ref);
});

/// Сервис для управления Firebase Cloud Messaging токенами.
///
/// Отвечает за получение, хранение и синхронизацию FCM токенов пользователей
/// с сервером Supabase. Автоматически отслеживает изменения токенов и
/// состояния аутентификации пользователей.
class FcmTokenService {
  /// Создает экземпляр сервиса FCM токенов.
  ///
  /// [ref] - ссылка на Riverpod Ref для доступа к другим провайдерам.
  FcmTokenService({required this.ref});

  /// Ссылка на Riverpod Ref для доступа к провайдерам.
  final Ref ref;
  bool _initialized = false;
  String? _lastToken;

  /// Инициализирует сервис FCM токенов.
  ///
  /// Настраивает прослушивание изменений FCM токенов и состояния аутентификации.
  /// Запрашивает разрешения на push-уведомления и синхронизирует токен
  /// для текущего пользователя.
  Future<void> initialize() async {
    if (_initialized) return;
    // На Windows/macOS/Linux сервис токенов не работает (нет поддержки FCM)
    if (!kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux)) {
      return;
    }

    _initialized = true;

    await _requestPushPermissionsIfNeeded();

    // Синхронизируем токен, если пользователь уже авторизован
    await _syncTokenIfPossible();

    // Следим за обновлением самого FCM-токена — добавляем debounce, чтобы не писать дубликаты
    String? pendingToken;
    void commit() {
      final t = pendingToken;
      if (t != null && t.isNotEmpty) {
        pendingToken = null;
        _saveToken(t);
      }
    }

    FirebaseMessaging.instance.onTokenRefresh.listen((token) async {
      pendingToken = token;
      // задержка 1 секунда на случай каскадных событий
      await Future<void>.delayed(const Duration(seconds: 1));
      commit();
    });

    // Следим за изменением состояния аутентификации Supabase
    Supabase.instance.client.auth.onAuthStateChange.listen((data) async {
      final session = data.session;
      if (session?.user != null) {
        // Пользователь вошёл/сменился → принудительно перепривяжем токен
        await _forceRebindForCurrentUser();
      } else {
        // Пользователь выходит → пометим текущий токен как неактивный (best-effort)
        final currentToken = _lastToken;
        if (currentToken != null && currentToken.isNotEmpty) {
          try {
            await Supabase.instance.client
                .from('user_tokens')
                .update({'is_active': false}).eq('token', currentToken);
          } catch (_) {}
        }
      }
    });
  }

  Future<void> _forceRebindForCurrentUser() async {
    try {
      await FirebaseMessaging.instance.deleteToken();
    } catch (_) {}
    await _syncTokenIfPossible();
  }

  Future<void> _requestPushPermissionsIfNeeded() async {
    if (kIsWeb) return; // Web не требует явного запроса

    final settings = await FirebaseMessaging.instance.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      // Пользователь отклонил — просто выходим, повторные попытки не делаем здесь
      return;
    }
  }

  Future<void> _syncTokenIfPossible() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    // Для Web требуется передать VAPID ключ
    final String? token = await FirebaseMessaging.instance.getToken(
      vapidKey: kIsWeb
          ? 'BGPPZr58sdNUlGT4RFTLiteNdyOxQWI9mJdxnP4ycqEA0qUrGh6sDRKdkvXN6O1jpdmeH1ETcwn8ePeTPocORW4'
          : null,
    );
    if (token == null || token.isEmpty) return;

    // Получаем installation_id для уникальной привязки установки
    String? installationId;
    try {
      installationId = await FirebaseInstallations.instance.getId();
    } catch (_) {}

    await _saveToken(token, installationId: installationId);
  }

  Future<void> _saveToken(String token, {String? installationId}) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    final String platform = kIsWeb
        ? 'web'
        : Platform.isIOS
            ? 'ios'
            : 'android';

    try {
      // Деактивируем старые записи этой установки/платформы с другим токеном
      if (installationId != null && installationId.isNotEmpty) {
        try {
          await Supabase.instance.client
              .from('user_tokens')
              .update({'is_active': false})
              .eq('installation_id', installationId)
              .eq('platform', platform)
              .neq('token', token);
        } catch (_) {}
      }

      await Supabase.instance.client.from('user_tokens').upsert(
        {
          'user_id': user.id,
          'token': token,
          'platform': platform,
          'installation_id': installationId,
          'is_active': true,
          'updated_at': DateTime.now().toIso8601String(),
        },
        onConflict: 'installation_id,platform',
      );
      _lastToken = token;
    } catch (_) {
      // Проглатываем ошибку сохранения, чтобы не блокировать запуск приложения
    }
  }
}
