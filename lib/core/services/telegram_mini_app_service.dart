import 'dart:js' as js;
import 'package:flutter/foundation.dart';

/// Сервис для работы с Telegram Mini App.
class TelegramMiniAppService {
  /// Проверяет, запущено ли приложение в Telegram Mini App.
  static bool isTelegramMiniApp() {
    if (!kIsWeb) return false;
    try {
      final telegramWebApp = js.context['Telegram']?['WebApp'];
      return telegramWebApp != null;
    } catch (_) {
      return false;
    }
  }

  /// Получает initData от Telegram.
  /// Сначала пытается из localStorage (сохранено в index.html),
  /// потом из window.Telegram.WebApp.initData
  static String? getInitData() {
    if (!kIsWeb) return null;
    try {
      // Сначала пытаемся получить из localStorage (сохранено в index.html)
      final storage = js.context['localStorage'];
      final initDataFromStorage = storage?.callMethod('getItem', ['tg_init_data']) as String?;
      if (initDataFromStorage != null && initDataFromStorage.isNotEmpty) {
        return initDataFromStorage;
      }
      
      // Если нет в localStorage, пытаемся прямо из Telegram WebApp
      if (isTelegramMiniApp()) {
        return js.context['Telegram']['WebApp']['initData'] as String?;
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
