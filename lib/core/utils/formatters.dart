import 'dart:math';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

/// Единые форматтеры для проекта: валюта, даты и числа.
///
/// Используйте эти функции вместо локальных приватных хелперов
/// для обеспечения консистентного форматирования во всём приложении.
class GtFormatters {
  // Кешированные экземпляры для повышения производительности
  static final _currencyFormat = NumberFormat.currency(
    locale: 'ru_RU',
    symbol: '₽',
    decimalDigits: 2,
  );

  static final _dateFormat = DateFormat('dd.MM.yyyy', 'ru_RU');
  static final _dateTimeFormat = DateFormat('dd.MM.yyyy HH:mm', 'ru_RU');
  static final _apiDateFormat = DateFormat('yyyy-MM-dd');
  static final _monthYearFormat = DateFormat('LLLL yyyy', 'ru_RU');
  static final _compactMonthYearFormat = DateFormat('MMM yyyy', 'ru_RU');
  static final _quantityFormat = NumberFormat('###,##0.###', 'ru_RU');
  static final _amountFormat = NumberFormat('#,##0.00', 'ru_RU');

  /// Форматирует ФИО сотрудника сокращённо (Иванов И.И.).
  /// Пример: ("Иванов", "Иван", "Иванович") -> "Иванов И.И."
  static String formatAbbreviatedName(
    String lastName,
    String firstName, [
    String? middleName,
  ]) {
    final firstInitial = firstName.isNotEmpty ? '${firstName[0]}.' : '';
    final middleInitial = (middleName != null && middleName.isNotEmpty)
        ? '${middleName[0]}.'
        : '';
    return '$lastName $firstInitial$middleInitial'.trim();
  }

  /// Форматирует полное ФИО сотрудника (Иванов Иван Иванович).
  /// Пример: ("Иванов", "Иван", "Иванович") -> "Иванов Иван Иванович"
  static String formatFullName(
    String lastName,
    String firstName, [
    String? middleName,
  ]) {
    return [
      lastName,
      firstName,
      if (middleName != null && middleName.isNotEmpty) middleName,
    ].join(' ');
  }

  /// Форматирует валюту в локали ru_RU с двумя знаками копеек и символом ₽.
  /// Пример: 123456 -> "123 456,00 ₽"
  static String formatCurrency(num value) => _currencyFormat.format(value);

  /// Форматирует число с принудительными двумя знаками после запятой.
  /// Пример: 1000 -> "1 000,00"
  static String formatAmount(num value) => _amountFormat.format(value);

  /// Форматирует дату в виде dd.MM.yyyy в локали ru_RU.
  /// Пример: 2025-09-14 -> "14.09.2025".
  static String formatRuDate(DateTime date) => _dateFormat.format(date);

  /// Форматирует дату и время в виде dd.MM.yyyy HH:mm в локали ru_RU.
  /// Пример: 2025-09-14 14:30 -> "14.09.2025 14:30".
  static String formatRuDateTime(DateTime date) => _dateTimeFormat.format(date);

  /// Форматирует дату для API в формате yyyy-MM-dd.
  /// Пример: 2025-09-14 -> "2025-09-14".
  static String formatDateForApi(DateTime date) => _apiDateFormat.format(date);

  /// Форматирует месяц и год полностью.
  /// Пример: 2025-09-14 -> "сентябрь 2025".
  static String formatMonthYear(DateTime date) {
    final formatted = _monthYearFormat.format(date);
    if (formatted.isEmpty) return '';
    // Делаем первую букву заглавной
    return formatted[0].toUpperCase() + formatted.substring(1);
  }

  /// Форматирует месяц и год кратко.
  /// Пример: 2025-09-14 -> "сент. 2025".
  static String formatCompactMonthYear(DateTime date) =>
      _compactMonthYearFormat.format(date);

  /// Форматирует количество (до 3 знаков после запятой, группировка тысяч).
  /// Пример: 1234.5 -> "1 234,5".
  static String formatQuantity(num value) => _quantityFormat.format(value);

  /// Форматирует процент.
  /// [decimalDigits] — количество знаков после запятой.
  /// Пример: 95.5 -> "95,5%"
  static String formatPercentage(num value, {int decimalDigits = 0}) {
    return '${value.toStringAsFixed(decimalDigits).replaceAll('.', ',')}%';
  }

  /// Парсит строку с числом, очищая её от пробелов и заменяя запятую на точку.
  /// Поддерживает форматы "1 000,50", "1,000.50", "1000.50".
  static double? parseAmount(String? text) {
    if (text == null || text.isEmpty) return null;
    final normalized = text
        .replaceAll('\u00A0', '') // Неразрывный пробел
        .replaceAll('\u202F', '') // Узкий неразрывный пробел
        .replaceAll(' ', '')
        .replaceAll(',', '.');
    return double.tryParse(normalized);
  }

  /// Парсит дату из строки по заданному формату.
  static DateTime? parseDate(String? text, String format) {
    if (text == null || text.isEmpty) return null;
    try {
      return DateFormat(format).parse(text);
    } catch (_) {
      return null;
    }
  }

  /// Форматирует номер телефона в реальном времени.
  /// Маска: +7 XXX XXX XX XX
  static TextInputFormatter phoneFormatter() => _PhoneInputFormatter();

  /// Форматирует номер телефона для отображения.
  /// Пример: "79610092141" -> "+7 961 009 21 41"
  static String formatPhone(String? phone) {
    if (phone == null || phone.isEmpty) return 'Не указан';

    // Очищаем от всего, кроме цифр
    String digits = phone.replaceAll(RegExp(r'\D'), '');

    // Если это российский номер (11 цифр, начинается с 7 или 8), берем последние 10 цифр
    if (digits.length == 11 &&
        (digits.startsWith('7') || digits.startsWith('8'))) {
      digits = digits.substring(1);
    }

    // Если у нас ровно 10 цифр (код + номер), форматируем по стандарту +7 XXX XXX XX XX
    if (digits.length == 10) {
      return '+7 ${digits.substring(0, 3)} ${digits.substring(3, 6)} ${digits.substring(6, 8)} ${digits.substring(8, 10)}';
    }

    // Если цифр меньше 10 или это не российский номер, возвращаем с префиксом + если это похоже на номер
    if (digits.isNotEmpty) {
      return phone.startsWith('+') ? phone : '+$digits';
    }

    return phone;
  }

  /// Форматирует сумму с разделением тысяч пробелом в реальном времени.
  /// Пример: 1234567.89 -> "1 234 567.89"
  static TextInputFormatter amountFormatter() => _AmountInputFormatter();

  /// Форматирует количество в реальном времени (до 3 знаков после запятой).
  static TextInputFormatter quantityFormatter() => _QuantityInputFormatter();
}

class _AmountInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue;
    }

    // Заменяем точку на запятую для единообразия (стандарт РФ)
    final String cleanText = newValue.text.replaceAll('.', ',');

    // Очищаем от всего, кроме цифр и одной запятой
    String digitsOnly = cleanText.replaceAll(RegExp(r'[^0-9,]'), '');

    // Обработка случая с несколькими запятыми
    final commas = RegExp(r',').allMatches(digitsOnly).toList();
    if (commas.length > 1) {
      // Оставляем только первую запятую
      final firstCommaIndex = digitsOnly.indexOf(',');
      digitsOnly =
          digitsOnly.substring(0, firstCommaIndex + 1) +
          digitsOnly.substring(firstCommaIndex + 1).replaceAll(',', '');
    }

    final parts = digitsOnly.split(',');
    String integerPart = parts[0];
    String? decimalPart = parts.length > 1 ? parts[1] : null;

    // Форматируем целую часть с пробелами
    final StringBuffer formattedInteger = StringBuffer();
    for (int i = 0; i < integerPart.length; i++) {
      if (i > 0 && (integerPart.length - i) % 3 == 0) {
        formattedInteger.write(' ');
      }
      formattedInteger.write(integerPart[i]);
    }

    String result = formattedInteger.toString();
    if (decimalPart != null) {
      // Ограничиваем копейки двумя знаками
      result += ',${decimalPart.substring(0, min(decimalPart.length, 2))}';
    } else if (digitsOnly.endsWith(',')) {
      // Сохраняем запятую в конце, если пользователь её только что ввёл
      result += ',';
    }

    return TextEditingValue(
      text: result,
      selection: TextSelection.collapsed(offset: result.length),
    );
  }
}

class _QuantityInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue;
    }

    final String cleanText = newValue.text.replaceAll('.', ',');
    String digitsOnly = cleanText.replaceAll(RegExp(r'[^0-9,]'), '');

    final commas = RegExp(r',').allMatches(digitsOnly).toList();
    if (commas.length > 1) {
      final firstCommaIndex = digitsOnly.indexOf(',');
      digitsOnly =
          digitsOnly.substring(0, firstCommaIndex + 1) +
          digitsOnly.substring(firstCommaIndex + 1).replaceAll(',', '');
    }

    final parts = digitsOnly.split(',');
    String integerPart = parts[0];
    String? decimalPart = parts.length > 1 ? parts[1] : null;

    final StringBuffer formattedInteger = StringBuffer();
    for (int i = 0; i < integerPart.length; i++) {
      if (i > 0 && (integerPart.length - i) % 3 == 0) {
        formattedInteger.write(' ');
      }
      formattedInteger.write(integerPart[i]);
    }

    String result = formattedInteger.toString();
    if (decimalPart != null) {
      // Для количества допускаем до 3-х знаков
      result += ',${decimalPart.substring(0, min(decimalPart.length, 3))}';
    } else if (digitsOnly.endsWith(',')) {
      result += ',';
    }

    return TextEditingValue(
      text: result,
      selection: TextSelection.collapsed(offset: result.length),
    );
  }
}

class _PhoneInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final String text = newValue.text;

    // Всегда поддерживаем префикс "+7 "
    if (text.length < 3 || !text.startsWith('+7 ')) {
      return const TextEditingValue(
        text: '+7 ',
        selection: TextSelection.collapsed(offset: 3),
      );
    }

    final String digits = text.substring(3).replaceAll(RegExp(r'\D'), '');
    String formatted = '+7 ';

    if (digits.isNotEmpty) {
      if (digits.length <= 3) {
        formatted += digits;
      } else if (digits.length <= 6) {
        formatted += '${digits.substring(0, 3)} ${digits.substring(3)}';
      } else if (digits.length <= 8) {
        formatted +=
            '${digits.substring(0, 3)} ${digits.substring(3, 6)} ${digits.substring(6)}';
      } else {
        formatted +=
            '${digits.substring(0, 3)} ${digits.substring(3, 6)} ${digits.substring(6, 8)} ${digits.substring(8, min(digits.length, 10))}';
      }
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

// --- Глобальные алиасы для удобства использования в UI ---

/// Алиас для форматирования ФИО сотрудника сокращённо (Иванов И.И.).
String formatAbbreviatedName(
  String lastName,
  String firstName, [
  String? middleName,
]) => GtFormatters.formatAbbreviatedName(lastName, firstName, middleName);

/// Алиас для форматирования полного ФИО сотрудника (Иванов Иван Иванович).
String formatFullName(
  String lastName,
  String firstName, [
  String? middleName,
]) => GtFormatters.formatFullName(lastName, firstName, middleName);

/// Алиас для форматирования валюты (ru_RU, ₽, 2 знака).
String formatCurrency(num value) => GtFormatters.formatCurrency(value);

/// Алиас для форматирования дат (dd.MM.yyyy, ru_RU).
String formatRuDate(DateTime date) => GtFormatters.formatRuDate(date);

/// Алиас для форматирования даты и времени (dd.MM.yyyy HH:mm, ru_RU).
String formatRuDateTime(DateTime date) => GtFormatters.formatRuDateTime(date);

/// Алиас для форматирования месяца и года полностью (Сентябрь 2025).
String formatMonthYear(DateTime date) => GtFormatters.formatMonthYear(date);

/// Алиас для форматирования количества.
String formatQuantity(num value) => GtFormatters.formatQuantity(value);

/// Алиас для форматирования процента.
String formatPercentage(num value, {int decimalDigits = 0}) =>
    GtFormatters.formatPercentage(value, decimalDigits: decimalDigits);

/// Алиас для получения форматтера сумм (разделение тысяч пробелом).
TextInputFormatter amountFormatter() => GtFormatters.amountFormatter();

/// Алиас для получения форматтера количества (до 3 знаков после запятой).
TextInputFormatter quantityFormatter() => GtFormatters.quantityFormatter();

/// Алиас для парсинга сумм из строк.
double? parseAmount(String? text) => GtFormatters.parseAmount(text);

/// Алиас для парсинга даты из строки.
DateTime? parseDate(String? text, String format) =>
    GtFormatters.parseDate(text, format);

/// Алиас для форматирования номера телефона для отображения (+7 XXX XXX XX XX).
String formatPhone(String? phone) => GtFormatters.formatPhone(phone);
