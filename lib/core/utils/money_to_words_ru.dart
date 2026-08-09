import 'package:projectgt/core/utils/formatters.dart';

/// Преобразует денежную сумму в строку прописью на русском языке.
///
/// Пример: `1234.56` → «Одна тысяча двести тридцать четыре рубля 56 копеек».
String moneyToWordsRu(double amount, {bool capitalize = true}) {
  final negative = amount < 0;
  final abs = amount.abs();
  final rubles = abs.truncate();
  final kopecks = ((abs * 100).round() % 100).clamp(0, 99);

  final rublesWords = _numberToWords(rubles);
  final rublesText = capitalize ? _capitalize(rublesWords) : rublesWords;
  final rublesUnit = _pluralize(rubles, ['рубль', 'рубля', 'рублей']);
  final kopecksUnit = _pluralize(kopecks, ['копейка', 'копейки', 'копеек']);
  final kopecksStr = kopecks.toString().padLeft(2, '0');

  final result = '$rublesText $rublesUnit $kopecksStr $kopecksUnit';
  return negative ? 'Минус $result' : result;
}

/// Числовая сумма с единицами: «4 979 304 рубля 23 копейки».
String moneyNumericWithUnitsRu(double amount) {
  final abs = amount.abs();
  final rubles = abs.truncate();
  final kopecks = ((abs * 100).round() % 100).clamp(0, 99);
  final parts = formatAmount(abs).split(',');
  final rublesPart = parts.first;
  final kopecksPart = parts.length > 1 ? parts[1].padLeft(2, '0') : '00';
  final rublesUnit = _pluralize(rubles, ['рубль', 'рубля', 'рублей']);
  final kopecksUnit = _pluralize(kopecks, ['копейка', 'копейки', 'копеек']);

  final result = '$rublesPart $rublesUnit $kopecksPart $kopecksUnit';
  return amount < 0 ? 'Минус $result' : result;
}

String _capitalize(String value) {
  if (value.isEmpty) return value;
  return '${value[0].toUpperCase()}${value.substring(1)}';
}

String _pluralize(int n, List<String> forms) {
  final mod100 = n % 100;
  if (mod100 >= 11 && mod100 <= 14) return forms[2];
  return switch (n % 10) {
    1 => forms[0],
    2 || 3 || 4 => forms[1],
    _ => forms[2],
  };
}

String _numberToWords(int n) {
  if (n == 0) return 'ноль';

  const unitsMale = [
    '',
    'один',
    'два',
    'три',
    'четыре',
    'пять',
    'шесть',
    'семь',
    'восемь',
    'девять',
  ];
  const unitsFemale = [
    '',
    'одна',
    'две',
    'три',
    'четыре',
    'пять',
    'шесть',
    'семь',
    'восемь',
    'девять',
  ];
  const teens = [
    'десять',
    'одиннадцать',
    'двенадцать',
    'тринадцать',
    'четырнадцать',
    'пятнадцать',
    'шестнадцать',
    'семнадцать',
    'восемнадцать',
    'девятнадцать',
  ];
  const tens = [
    '',
    '',
    'двадцать',
    'тридцать',
    'сорок',
    'пятьдесят',
    'шестьдесят',
    'семьдесят',
    'восемьдесят',
    'девяносто',
  ];
  const hundreds = [
    '',
    'сто',
    'двести',
    'триста',
    'четыреста',
    'пятьсот',
    'шестьсот',
    'семьсот',
    'восемьсот',
    'девятьсот',
  ];

  String triplet(int value, {required bool female}) {
    if (value == 0) return '';
    final h = value ~/ 100;
    final t = (value % 100) ~/ 10;
    final u = value % 10;
    final parts = <String>[];
    if (h > 0) parts.add(hundreds[h]);
    if (t == 1) {
      parts.add(teens[u]);
    } else {
      if (t > 1) parts.add(tens[t]);
      if (u > 0) {
        parts.add((female ? unitsFemale : unitsMale)[u]);
      }
    }
    return parts.join(' ');
  }

  final groups = <String>[];
  var rest = n;

  final billions = rest ~/ 1000000000;
  rest %= 1000000000;
  if (billions > 0) {
    groups.add(
      '${triplet(billions, female: false)} ${_pluralize(billions, ['миллиард', 'миллиарда', 'миллиардов'])}',
    );
  }

  final millions = rest ~/ 1000000;
  rest %= 1000000;
  if (millions > 0) {
    groups.add(
      '${triplet(millions, female: false)} ${_pluralize(millions, ['миллион', 'миллиона', 'миллионов'])}',
    );
  }

  final thousands = rest ~/ 1000;
  rest %= 1000;
  if (thousands > 0) {
    groups.add(
      '${triplet(thousands, female: true)} ${_pluralize(thousands, ['тысяча', 'тысячи', 'тысяч'])}',
    );
  }

  if (rest > 0) {
    groups.add(triplet(rest, female: false));
  }

  return groups.join(' ').trim();
}
