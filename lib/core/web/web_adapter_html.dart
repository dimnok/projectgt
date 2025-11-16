import 'dart:convert';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:web/web.dart' as web;
import 'package:http/http.dart' as http;

/// Возвращает признак, что код выполняется в браузере (web-сборка).
bool isWeb() => true;

/// Текущий полный URL страницы (включая hash и query).
String currentHref() => web.window.location.href;

/// Текущий hash-фрагмент URL (начинается с '#').
String currentHash() => web.window.location.hash;

/// Заменяет адрес в адресной строке без перезагрузки, сохраняя/устанавливая hash.
void replaceUrlPreservingHash(String base, String? hash) {
  web.window.history.replaceState(null, '', base + (hash ?? ''));
}

/// Перенаправляет текущую вкладку на указанный URL.
void setLocationHref(String url) {
  web.window.location.href = url;
}

/// Выполняет HTTP GET и парсит JSON-ответ.
Future<Map<String, dynamic>> httpGetJson(String url,
    {Map<String, String>? headers}) async {
  final resp = await http.get(Uri.parse(url), headers: headers);
  final body = resp.body.isNotEmpty ? resp.body : '{}';
  return jsonDecode(body) as Map<String, dynamic>;
}

/// Открывает URL во внешней/новой вкладке браузера.
Future<bool> openExternalUrl(String url) async {
  web.window.open(url, '_blank');
  return true;
}

/// Возвращает значение из LocalStorage по ключу.
String? localStorageGet(String key) => web.window.localStorage.getItem(key);

/// Сохраняет значение в LocalStorage по ключу.
void localStorageSet(String key, String value) {
  web.window.localStorage.setItem(key, value);
}

/// Удаляет значение из LocalStorage по ключу.
void localStorageRemove(String key) {
  web.window.localStorage.removeItem(key);
}

/// Выполняет JavaScript код и возвращает результат.
///
/// [jsCode] — JavaScript код для выполнения (например, 'window.Telegram?.WebApp?.initData')
///
/// Примеры:
/// ```dart
/// final initData = await evaluateJavaScript('window.Telegram?.WebApp?.initData');
/// final search = await evaluateJavaScript('window.location.search');
/// ```
Future<dynamic> evaluateJavaScript(String jsCode) async {
  try {
    // Специальная функция для Telegram initData - только для 'initData' ключевого слова в контексте Telegram
    if (jsCode.contains('Telegram') && jsCode.contains('initData')) {
      return _getTelegramInitData();
    }

    // Для остальных случаев (например, window.location.search) - получаем напрямую
    return _getJavaScriptValue(jsCode);
  } catch (e) {
    throw Exception('Failed to evaluate JavaScript: $e');
  }
}

/// Специальная функция для получения Telegram initData
///
/// Сначала пытается получить из сохраненной глобальной переменной (надежнее),
/// затем - напрямую из объекта Telegram.WebApp (fallback)
dynamic _getTelegramInitData() {
  try {
    final window = web.window;

    // 1️⃣ Сначала проверяем сохраненную глобальную переменную
    // (установлена при инициализации в web/index.html)
    final flutterInitData = (window as dynamic)['__flutterTelegramInitData'];
    if (flutterInitData != null && flutterInitData.toString().isNotEmpty) {
      debugPrint('[TelegramInitData] Got from __flutterTelegramInitData');
      return flutterInitData.toString();
    }

    // 2️⃣ Fallback: Прямой доступ к объекту Telegram через window
    final telegrams = (window as dynamic)['Telegram'];
    if (telegrams == null) {
      debugPrint('[TelegramInitData] No Telegram object found');
      return null;
    }

    final webApp = telegrams['WebApp'];
    if (webApp == null) {
      debugPrint('[TelegramInitData] No Telegram.WebApp found');
      return null;
    }

    final initData = webApp['initData'];
    if (initData == null || initData.toString().isEmpty) {
      debugPrint('[TelegramInitData] No initData in Telegram.WebApp');
      return null;
    }

    debugPrint('[TelegramInitData] Got from Telegram.WebApp.initData');
    return initData.toString();
  } catch (e) {
    debugPrint('[TelegramInitData] Error: $e');
    return null;
  }
}

/// Получает значение JavaScript выражения (например, window.location.search)
///
/// Это прямой доступ через dart:web к объектам браузера.
/// Работает для простых выражений типа:
/// - window.location.search
/// - window.location.href
/// - Прямые обращения к объектам
///
/// Важно: не использует eval(), только прямые обращения к window
dynamic _getJavaScriptValue(String accessor) {
  try {
    final window = web.window;

    // Специальные случаи
    if (accessor == 'window.location.search') {
      return window.location.search;
    }
    if (accessor == 'window.location.href') {
      return window.location.href;
    }
    if (accessor == 'window.location.hash') {
      return window.location.hash;
    }

    // Для других обращений - пытаемся получить через динамический доступ
    // Примеры: window.__flutterTelegramInitData, window.customValue и т.д.
    if (accessor.startsWith('window.')) {
      final key = accessor.substring(7); // удаляем 'window.'
      return (window as dynamic)[key];
    }

    return null;
  } catch (e) {
    debugPrint('[getJavaScriptValue] Error accessing "$accessor": $e');
    return null;
  }
}
