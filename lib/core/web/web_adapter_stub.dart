import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;

/// Возвращает признак, что текущая платформа не Web.
bool isWeb() => false;

/// Возвращает текущий URL для не-Web платформ (пустая строка).
String currentHref() => '';

/// Возвращает текущий hash-фрагмент URL для не-Web платформ (пустая строка).
String currentHash() => '';

/// На не-Web платформах не изменяет адресную строку (no-op).
void replaceUrlPreservingHash(String base, String? hash) {
  // no-op on non-web
}

/// На не-Web платформах пытается открыть URL во внешнем приложении.
void setLocationHref(String url) {
  // On non-web, try to open externally
  openExternalUrl(url);
}

/// Выполняет HTTP GET запрос и парсит JSON-ответ.
Future<Map<String, dynamic>> httpGetJson(String url,
    {Map<String, String>? headers}) async {
  final resp = await http.get(Uri.parse(url), headers: headers);
  final body = resp.body.isNotEmpty ? resp.body : '{}';
  return jsonDecode(body) as Map<String, dynamic>;
}

/// Открывает внешний URL при помощи `url_launcher`.
Future<bool> openExternalUrl(String url) async {
  final uri = Uri.parse(url);
  if (await canLaunchUrl(uri)) {
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }
  return false;
}

/// Возвращает значение из LocalStorage (на не-Web всегда `null`).
String? localStorageGet(String key) => null;

/// Сохраняет значение в LocalStorage (на не-Web — no-op).
void localStorageSet(String key, String value) {}

/// Удаляет значение из LocalStorage (на не-Web — no-op).
void localStorageRemove(String key) {}

/// На не-Web платформах не может выполнять JavaScript (всегда возвращает null).
Future<dynamic> evaluateJavaScript(String jsCode) async {
  // JavaScript недоступен на нативных платформах
  return null;
}
