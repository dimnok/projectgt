import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:projectgt/core/utils/formatters.dart';
import 'package:projectgt/core/utils/pdf_utils.dart';

/// Утилита для генерации PDF документов профиля.
class ProfilePdfGenerator {
  const ProfilePdfGenerator._();

  /// Генерирует заявление на ежегодный отпуск.
  static Future<Uint8List> generateVacationPdf({
    required PdfPageFormat format,
    required String fullName,
    required DateTime startDate,
    required DateTime endDate,
    required int durationDays,
    required DateTime date,
  }) async {
    final pdf = pw.Document();
    final font = await PdfUtils.loadSerifFont();
    final boldFont = await PdfUtils.loadSerifBoldFont();

    final startDateStr = formatRuDate(startDate);
    final endDateStr = formatRuDate(endDate);
    final dateStr = formatRuDate(date);

    pdf.addPage(
      pw.Page(
        pageFormat: format,
        theme: pw.ThemeData.withFont(base: font, bold: boldFont),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Шапка (половина ширины страницы справа)
              pw.Align(
                alignment: pw.Alignment.topRight,
                child: pw.SizedBox(
                  width: format.availableWidth / 2,
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Генеральному директору',
                        style: const pw.TextStyle(fontSize: 14),
                      ),
                      pw.Text(
                        'ООО "Грандтелеком"',
                        style: const pw.TextStyle(fontSize: 14),
                      ),
                      pw.Text(
                        'Тельнову Д.А.',
                        style: const pw.TextStyle(fontSize: 14),
                      ),
                      pw.SizedBox(height: 12),
                      pw.Text(
                        'от сотрудника',
                        style: const pw.TextStyle(fontSize: 14),
                      ),
                      pw.Text(
                        fullName,
                        style: const pw.TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),
              pw.SizedBox(height: 60),

              // Заголовок
              pw.Center(
                child: pw.Text(
                  'ЗАЯВЛЕНИЕ',
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.SizedBox(height: 20),

              // Текст заявления
              pw.Paragraph(
                margin: const pw.EdgeInsets.only(bottom: 10),
                padding: const pw.EdgeInsets.only(
                  left: 35,
                ), // Абзацный отступ ~1.25 см
                text:
                    'Прошу предоставить мне ежегодный оплачиваемый отпуск '
                    'продолжительностью $durationDays (прописью: ${PdfUtils.numberToWords(durationDays)}) ${_getDaysDeclension(durationDays)} '
                    'с $startDateStr г. по $endDateStr г.',
                style: const pw.TextStyle(
                  fontSize: 14,
                  lineSpacing: 1.5, // Межстрочный интервал 1.5
                ),
                textAlign: pw.TextAlign.justify, // Выравнивание по ширине
              ),
              pw.SizedBox(height: 40),

              // Подпись
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text(dateStr, style: const pw.TextStyle(fontSize: 14)),
                  pw.Column(
                    children: [
                      pw.Container(
                        width: 100,
                        decoration: const pw.BoxDecoration(
                          border: pw.Border(bottom: pw.BorderSide(width: 1)),
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        '(подпись)',
                        style: const pw.TextStyle(fontSize: 10),
                      ),
                    ],
                  ),
                  pw.Text(
                    _getInitials(fullName),
                    style: const pw.TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  /// Генерирует заявление на отпуск за свой счёт.
  static Future<Uint8List> generateUnpaidLeavePdf({
    required PdfPageFormat format,
    required String fullName,
    required DateTime startDate,
    required int durationDays,
    required DateTime date,
  }) async {
    final pdf = pw.Document();
    final font = await PdfUtils.loadSerifFont();
    final boldFont = await PdfUtils.loadSerifBoldFont();

    final startDateStr = formatRuDate(startDate);
    final dateStr = formatRuDate(date);

    pdf.addPage(
      pw.Page(
        pageFormat: format,
        theme: pw.ThemeData.withFont(base: font, bold: boldFont),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Шапка (половина ширины страницы справа)
              pw.Align(
                alignment: pw.Alignment.topRight,
                child: pw.SizedBox(
                  width: format.availableWidth / 2,
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Генеральному директору',
                        style: const pw.TextStyle(fontSize: 14),
                      ),
                      pw.Text(
                        'ООО "Грандтелеком"',
                        style: const pw.TextStyle(fontSize: 14),
                      ),
                      pw.Text(
                        'Тельнову Д.А.',
                        style: const pw.TextStyle(fontSize: 14),
                      ),
                      pw.SizedBox(height: 12),
                      pw.Text(
                        'от сотрудника',
                        style: const pw.TextStyle(fontSize: 14),
                      ),
                      pw.Text(
                        fullName,
                        style: const pw.TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),
              pw.SizedBox(height: 60),

              // Заголовок
              pw.Center(
                child: pw.Text(
                  'ЗАЯВЛЕНИЕ',
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.SizedBox(height: 20),

              // Текст заявления
              pw.Paragraph(
                margin: const pw.EdgeInsets.only(bottom: 10),
                padding: const pw.EdgeInsets.only(
                  left: 35,
                ), // Абзацный отступ ~1.25 см
                text:
                    'Прошу предоставить мне отпуск без сохранения заработной платы '
                    'продолжительностью $durationDays (прописью: ${PdfUtils.numberToWords(durationDays)}) ${_getDaysDeclension(durationDays)} '
                    'с $startDateStr г. по семейным обстоятельствам.',
                style: const pw.TextStyle(
                  fontSize: 14,
                  lineSpacing: 1.5, // Межстрочный интервал 1.5
                ),
                textAlign: pw.TextAlign.justify, // Выравнивание по ширине
              ),
              pw.SizedBox(height: 40),

              // Подпись
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text(dateStr, style: const pw.TextStyle(fontSize: 14)),
                  pw.Column(
                    children: [
                      pw.Container(
                        width: 100,
                        decoration: const pw.BoxDecoration(
                          border: pw.Border(bottom: pw.BorderSide(width: 1)),
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        '(подпись)',
                        style: const pw.TextStyle(fontSize: 10),
                      ),
                    ],
                  ),
                  pw.Text(
                    _getInitials(fullName),
                    style: const pw.TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  static String _getInitials(String fullName) {
    final parts = fullName.split(' ');
    if (parts.length >= 2) {
      return '${parts[0]} ${parts[1][0]}.';
    }
    return fullName;
  }

  static String _getDaysDeclension(int days) {
    if (days % 10 == 1 && days % 100 != 11) {
      return 'календарный день';
    } else if ([2, 3, 4].contains(days % 10) &&
        ![12, 13, 14].contains(days % 100)) {
      return 'календарных дня';
    } else {
      return 'календарных дней';
    }
  }
}
