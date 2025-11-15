import 'dart:js' as js;
import 'package:flutter/foundation.dart';

/// Сервис для работы с Telegram Mini App.
class TelegramMiniAppService {
  /// Проверяет, запущено ли приложение в Telegram Mini App.
  static bool isTelegramMiniApp() {
    if (!kIsWeb) {
      print('❌ Not web');
      return false;
    }
    try {
      final telegram = js.context['Telegram'];
      print('🔍 Telegram object: $telegram');
      
      final telegramWebApp = telegram?['WebApp'];
      print('🔍 Telegram.WebApp: $telegramWebApp');
      
      final result = telegramWebApp != null;
      print('✅ isTelegramMiniApp result: $result');
      
      return result;
    } catch (e) {
      print('❌ Error checking Telegram: $e');
      return false;
    }
  }

  /// Получает initData от Telegram.
  /// initData сохраняется в sessionStorage в index.html перед загрузкой Flutter
  static String? getInitData() {
    if (!kIsWeb) return null;
    try {
      // Сначала пробуем прямой доступ через Telegram WebApp
      final telegramInitData = js.context['Telegram']?['WebApp']?['initData'] as String?;
      if (telegramInitData != null && telegramInitData.isNotEmpty) {
        return telegramInitData;
      }
      
      // Если нет, получаем из sessionStorage (сохранено в index.html)
      final sessionStorage = js.context['sessionStorage'];
      final hash = sessionStorage?.callMethod('getItem', ['tg_hash']) as String?;
      if (hash != null && hash.contains('tgWebAppData')) {
        // Парсим hash: #tgWebAppData=...&tgWebAppVersion=...&...
        final params = Uri.splitQueryString(hash.replaceFirst('#', ''));
        return params['tgWebAppData'];
      }
      
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Получает ID пользователя Telegram.
  static int? getTelegramUserId() {
    if (!isTelegramMiniApp()) return null;
    try {
      final initData = getInitData();
      if (initData == null) return null;

      final params = Uri.splitQueryString(initData);
      final userJson = params['user'];
      if (userJson == null) return null;

      // Парсим JSON вручную (простой способ)
      // {"id":123456789,"is_bot":false,...}
      final idMatch = RegExp(r'"id":(\d+)').firstMatch(userJson);
      return idMatch != null ? int.parse(idMatch.group(1)!) : null;
    } catch (_) {
      return null;
    }
  }
}
