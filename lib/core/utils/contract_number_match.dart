/// Сравнение номеров договоров из Excel и справочника [contracts].
library;

/// Нормализует текст договора для сравнения (регистр, пробелы, типовые префиксы).
String normalizeContractNumber(String raw) {
  var s = raw.trim().toLowerCase().replaceAll('ё', 'е');
  s = s.replaceAll(RegExp(r'\s+'), ' ');
  const prefixes = [
    'договор подряда',
    'договор поставки',
    'договор',
    'дог.',
  ];
  for (final prefix in prefixes) {
    if (s.startsWith(prefix)) {
      s = s.substring(prefix.length).trim();
      break;
    }
  }
  return s;
}

/// Компактный ключ сравнения (фрагмент вида `173-суб-98`).
String contractNumberComparisonKey(String raw) {
  final normalized = normalizeContractNumber(raw);
  final match = RegExp(
    r'(\d+[-\s]?(?:суб|суб|sub)[-\s\w\d]*)',
    caseSensitive: false,
  ).firstMatch(normalized);
  if (match != null) {
    return match.group(1)!.replaceAll(RegExp(r'\s+'), '').toLowerCase();
  }
  return normalized.replaceAll(RegExp(r'\s+'), '');
}

/// Возвращает `true`, если обозначения относятся к одному договору.
bool contractNumbersMatch(String? a, String? b) {
  if (a == null || b == null) return false;
  final left = a.trim();
  final right = b.trim();
  if (left.isEmpty || right.isEmpty) return false;
  if (normalizeContractNumber(left) == normalizeContractNumber(right)) {
    return true;
  }
  return contractNumberComparisonKey(left) ==
      contractNumberComparisonKey(right);
}
