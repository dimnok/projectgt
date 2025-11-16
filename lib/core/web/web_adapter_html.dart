import 'dart:convert';
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
/// final userId = await evaluateJavaScript('window.Telegram?.WebApp?.initData?.user?.id');
/// ```
Future<dynamic> evaluateJavaScript(String jsCode) async {
  try {
    // Выполняем JavaScript код
    // Для Telegram initData используем специальную функцию
    if (jsCode.contains('initData')) {
      return _getTelegramInitData();
    }
    
    // Для остальных случаев - выполняем через Function конструктор
    return _executeJS(jsCode);
  } catch (e) {
    throw Exception('Failed to evaluate JavaScript: $e');
  }
}

/// Специальная функция для получения Telegram initData
dynamic _getTelegramInitData() {
  try {
    // Прямой доступ к объекту Telegram через window
    final window = web.window;
    
    // Используем динамический доступ для получения Telegram
    final telegrams = (window as dynamic)['Telegram'];
    if (telegrams == null) return null;
    
    final webApp = telegrams['WebApp'];
    if (webApp == null) return null;
    
    final initData = webApp['initData'];
    if (initData == null || initData.toString().isEmpty) return null;
    
    return initData.toString();
  } catch (e) {
    return null;
  }
}

/// Вспомогательная функция для выполнения JavaScript через Function конструктор
dynamic _executeJS(String code) {
  try {
    // Используем Function конструктор для выполнения кода в глобальном контексте
    // Более безопасно чем eval
    return (web.window as dynamic).Function(code).call();
  } catch (e) {
    return null;
  }
}
