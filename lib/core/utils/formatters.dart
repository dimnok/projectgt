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

  /// Форматирует дату и время в виде dd.MM.yyyy HH:mm в локали ru_RU.
  /// Пример: 2025-09-14 14:30 -> "14.09.2025 14:30".
  static String formatRuDateTime(DateTime date) {
    return DateFormat('dd.MM.yyyy HH:mm', 'ru_RU').format(date);
  }

  /// Форматирует количество (до 3 знаков после запятой, группировка тысяч).
  /// Пример: 1234.5 -> "1 234,5".
  static String formatQuantity(num value) {
    return NumberFormat('###,##0.###', 'ru_RU').format(value);
  }
}

/// Короткие топ-левел алиасы для форматирования валюты (ru_RU, ₽, 2 знака).
String formatCurrency(num value) => GtFormatters.formatCurrency(value);

/// Короткие топ-левел алиасы для форматирования дат (dd.MM.yyyy, ru_RU).
String formatRuDate(DateTime date) => GtFormatters.formatRuDate(date);

/// Короткие топ-левел алиасы для форматирования даты и времени (dd.MM.yyyy HH:mm, ru_RU).
String formatRuDateTime(DateTime date) => GtFormatters.formatRuDateTime(date);

/// Короткие топ-левел алиасы для форматирования количества.
String formatQuantity(num value) => GtFormatters.formatQuantity(value);
