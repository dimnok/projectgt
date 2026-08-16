/// Утилиты отображения имён пользователей (profiles, RPC).
///
/// Единый порядок: короткое имя → полное имя → email.
library;

/// Возвращает наиболее подходящее отображаемое имя пользователя.
String? pickUserDisplayName({
  String? shortName,
  String? fullName,
  String? email,
}) {
  for (final value in [shortName, fullName, email]) {
    if (value != null && value.trim().isNotEmpty) {
      return value.trim();
    }
  }
  return null;
}

/// Форматирует имя для UI с запасным значением.
String formatUserDisplayLabel(
  String? name, {
  String fallback = '—',
}) {
  final trimmed = name?.trim();
  if (trimmed != null && trimmed.isNotEmpty) {
    return trimmed;
  }
  return fallback;
}

/// Извлекает имя из строки таблицы [profiles] или вложенного embed.
String? pickProfileDisplayName(Map<String, dynamic> profile) {
  return pickUserDisplayName(
    shortName: profile['short_name'] as String?,
    fullName: profile['full_name'] as String?,
    email: profile['email'] as String?,
  );
}
