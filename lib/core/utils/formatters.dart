import 'package:intl/intl.dart';

/// Единые форматтеры для проекта: валюта и даты.
///
/// Используйте эти функции вместо локальных приватных хелперов
/// для обеспечения консистентного форматирования во всём приложении.
class GtFormatters {
  /// Форматирует валюту в локали ru_RU с двумя знаками копеек и символом ₽.
  /// Пример: 123456 -> "123 456,00 ₽" (неразрывные пробелы в группировке).
  static String formatCurrency(num value) {
    final formatter = NumberFormat.currency(
      locale: 'ru_RU',
      symbol: '₽',
      decimalDigits: 2,
    );
    return formatter.format(value);
  }

  /// Форматирует дату в виде dd.MM.yyyy в локали ru_RU.
  /// Пример: 2025-09-14 -> "14.09.2025".
  static String formatRuDate(DateTime date) {
    return DateFormat('dd.MM.yyyy', 'ru_RU').format(date);
  }
}

/// Короткие топ-левел алиасы для форматирования валюты (ru_RU, ₽, 2 знака).
String formatCurrency(num value) => GtFormatters.formatCurrency(value);

/// Короткие топ-левел алиасы для форматирования дат (dd.MM.yyyy, ru_RU).
String formatRuDate(DateTime date) => GtFormatters.formatRuDate(date);
