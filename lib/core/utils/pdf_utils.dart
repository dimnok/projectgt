import 'package:flutter/services.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

/// Утилиты для работы с PDF.
class PdfUtils {
  /// Загружает обычный шрифт для PDF (Inter-Regular).
  static Future<pw.Font> loadFont() async {
    final fontData = await rootBundle.load('assets/fonts/Inter-Regular.ttf');
    return pw.Font.ttf(fontData);
  }

  /// Загружает жирный шрифт для PDF (Inter-Bold).
  static Future<pw.Font> loadBoldFont() async {
    final fontData = await rootBundle.load('assets/fonts/Inter-Bold.ttf');
    return pw.Font.ttf(fontData);
  }

  /// Загружает шрифт с засечками (Times New Roman аналог - Tinos) для PDF.
  static Future<pw.Font> loadSerifFont() async {
    return await PdfGoogleFonts.tinosRegular();
  }

  /// Загружает жирный шрифт с засечками (Times New Roman аналог - Tinos) для PDF.
  static Future<pw.Font> loadSerifBoldFont() async {
    return await PdfGoogleFonts.tinosBold();
  }

  /// Преобразует число в строку прописью (для дней отпуска).
  /// Поддерживает числа от 0 до 100.
  static String numberToWords(int number) {
    if (number == 0) return 'ноль';
    if (number >= 100) return number.toString();

    final units = [
      '',
      'один',
      'два',
      'три',
      'четыре',
      'пять',
      'шесть',
      'семь',
      'восемь',
      'девять'
    ];
    final teens = [
      'десять',
      'одиннадцать',
      'двенадцать',
      'тринадцать',
      'четырнадцать',
      'пятнадцать',
      'шестнадцать',
      'семнадцать',
      'восемнадцать',
      'девятнадцать'
    ];
    final tens = [
      '',
      '',
      'двадцать',
      'тридцать',
      'сорок',
      'пятьдесят',
      'шестьдесят',
      'семьдесят',
      'восемьдесят',
      'девяносто'
    ];

    if (number < 10) return units[number];
    if (number < 20) return teens[number - 10];

    final ten = number ~/ 10;
    final unit = number % 10;
    return '${tens[ten]} ${units[unit]}'.trim();
  }
}

