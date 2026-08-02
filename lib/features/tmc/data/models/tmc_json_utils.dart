/// Утилиты сериализации дат для моделей ТМЦ.
String? tmcDateOnlyToJson(DateTime? date) {
  if (date == null) return null;
  final y = date.year.toString().padLeft(4, '0');
  final m = date.month.toString().padLeft(2, '0');
  final d = date.day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}

/// Парсинг даты (date-only или ISO).
DateTime? tmcParseDate(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  return DateTime.parse(value as String);
}

/// Парсинг обязательной даты.
///
/// Бросает [FormatException], если значение отсутствует или некорректно.
DateTime tmcParseRequiredDate(dynamic value) {
  final parsed = tmcParseDate(value);
  if (parsed == null) {
    throw FormatException('Ожидалась дата, получено: $value');
  }
  return parsed;
}

/// Парсинг числа из JSON.
double tmcParseDouble(dynamic value, [double fallback = 0]) {
  if (value == null) return fallback;
  if (value is num) return value.toDouble();
  return double.tryParse(value as String) ?? fallback;
}

/// Парсинг целого из JSON.
int tmcParseInt(dynamic value, [int fallback = 0]) {
  if (value == null) return fallback;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value as String) ?? fallback;
}

/// Собирает ФИО сотрудника из join-объекта employees.
String? tmcEmployeeNameFromJson(dynamic employees) {
  if (employees == null) return null;
  if (employees is String) return employees;
  if (employees is! Map) return null;

  final map = Map<String, dynamic>.from(employees);
  final last = (map['last_name'] as String?)?.trim() ?? '';
  final first = (map['first_name'] as String?)?.trim() ?? '';
  final middle = (map['middle_name'] as String?)?.trim() ?? '';
  final parts = [last, first, middle].where((p) => p.isNotEmpty);
  final name = parts.join(' ');
  return name.isEmpty ? null : name;
}
