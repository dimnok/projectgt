/// Разбор завершающей числовой группы в номере счёта.
class TrailingInvoiceNumber {
  /// Префикс до последней группы цифр.
  final String prefix;

  /// Числовое значение завершающей группы.
  final int value;

  /// Создаёт [TrailingInvoiceNumber].
  const TrailingInvoiceNumber(this.prefix, this.value);
}

/// Разбивает номер на префикс и завершающую группу цифр.
///
/// Примеры: `сч-13` → (`сч-`, 13), `217-3` → (`217-`, 3), `2` → (``, 2).
TrailingInvoiceNumber? parseTrailingInvoiceNumber(String value) {
  final match = RegExp(r'(\d+)\s*$').firstMatch(value);
  if (match == null) return null;
  final parsed = int.tryParse(match.group(1)!);
  if (parsed == null) return null;
  return TrailingInvoiceNumber(value.substring(0, match.start), parsed);
}

/// Возвращает следующий номер: max завершающей группы + 1 с префиксом победителя.
///
/// Должна совпадать с SQL `get_next_settlement_invoice_number`.
String computeNextInvoiceNumber(Iterable<String> existingNumbers) {
  var max = 0;
  String? prefix;

  for (final raw in existingNumbers) {
    final parsed = parseTrailingInvoiceNumber(raw);
    if (parsed == null) continue;
    if (parsed.value > max) {
      max = parsed.value;
      prefix = parsed.prefix;
    }
  }

  return '${prefix ?? ''}${max + 1}';
}
