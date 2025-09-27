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
