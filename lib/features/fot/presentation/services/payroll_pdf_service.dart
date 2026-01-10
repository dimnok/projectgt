import 'package:flutter/widgets.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import 'package:file_saver/file_saver.dart';
import 'package:logger/logger.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:projectgt/core/utils/formatters.dart';
import '../../domain/entities/payroll_calculation.dart';
import '../../data/models/payroll_payout_model.dart';
import '../../../../domain/entities/employee.dart';
import 'package:flutter/services.dart';

/// Детализация по конкретной ставке внутри месяца
class RateBreakdown {
  /// Ставка (стоимость часа)
  final double rate;

  /// Количество отработанных часов по данной ставке
  final double hours;

  /// Итоговая сумма (часы * ставка)
  final double amount;

  /// Создает детализацию по ставке
  RateBreakdown({
    required this.rate,
    required this.hours,
    required this.amount,
  });
}

/// Данные для одного месяца в отчете
class MonthlyReportData {
  /// Порядковый номер месяца (1-12)
  final int month;

  /// Год
  final int year;

  /// Данные расчета (могут отсутствовать, если расчет еще не произведен)
  final PayrollCalculation? calculation;

  /// Список выплат за этот месяц
  final List<PayrollPayoutModel> payouts;

  /// Детализация по ставкам (если за месяц были изменения ставок)
  final List<RateBreakdown> rateBreakdowns;

  /// Создает данные для ежемесячного отчета
  MonthlyReportData({
    required this.month,
    required this.year,
    this.calculation,
    required this.payouts,
    this.rateBreakdowns = const [],
  });
}

/// Сервис для генерации финансового отчета сотрудника в PDF.
class PayrollPdfService {
  static final Logger _logger = Logger();
  static final DateFormat _monthFormatter = DateFormat('MMMM yyyy', 'ru_RU');
  static final DateFormat _dateFormatter = DateFormat('dd.MM.yyyy', 'ru_RU');

  /// Вспомогательная функция для замены символа рубля на текст, 
  /// так как многие PDF-шрифты не поддерживают символ ₽.
  String _cleanCurrency(String value) {
    return value.replaceAll('₽', ' руб.');
  }

  /// Формирует PDF документ и возвращает его байты.
  Future<Uint8List> buildEmployeeYearlyReport({
    required Employee employee,
    required int year,
    required List<MonthlyReportData> monthlyData,
  }) async {
    WidgetsFlutterBinding.ensureInitialized();
    
    // Загружаем локальные шрифты Inter (они гарантированно есть в проекте)
    final fontData = await rootBundle.load('assets/fonts/Inter-Regular.ttf');
    final fontBoldData = await rootBundle.load('assets/fonts/Inter-Bold.ttf');
    
    final font = pw.Font.ttf(fontData);
    final fontBold = pw.Font.ttf(fontBoldData);

    final pdf = pw.Document();

    final fullName = [
      employee.lastName,
      employee.firstName,
      employee.middleName,
    ].where((e) => e != null && e.isNotEmpty).join(' ');

    // Считаем общие итоги
    double totalEarned = 0;
    double totalReceived = 0;

    for (final data in monthlyData) {
      totalEarned += data.calculation?.netSalary ?? 0;
      totalReceived += data.payouts.fold<double>(0, (sum, p) => sum + p.amount);
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(30),
        theme: pw.ThemeData.withFont(
          base: font,
          bold: fontBold,
        ),
        build: (context) => [
          // Заголовок
          pw.Text(
            'Финансовый отчет сотрудника',
            style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            fullName,
            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
          ),
          pw.Text('Год: $year'),
          pw.Divider(thickness: 2, height: 20),

          // Данные по месяцам
          ...monthlyData.map((data) {
            final calc = data.calculation;
            final monthTitle =
                _monthFormatter.format(DateTime(data.year, data.month));

            if (calc == null && data.payouts.isEmpty) {
              return pw.SizedBox.shrink();
            }

            final monthEarned = calc?.netSalary ?? 0;
            final monthPaid =
                data.payouts.fold<double>(0, (sum, p) => sum + p.amount);

            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.SizedBox(height: 15),
                pw.Text(
                  monthTitle.toUpperCase(),
                  style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold, fontSize: 12),
                ),
                pw.SizedBox(height: 5),

                if (calc != null && calc.hoursWorked > 0) ...[
                  if (data.rateBreakdowns.isNotEmpty)
                    ...data.rateBreakdowns.map((rb) => _buildRow(
                          'сумма по ставке (ставка ${formatCurrency(rb.rate)})',
                          '${formatQuantity(rb.hours)} x ${_cleanCurrency(formatCurrency(rb.rate))} = ${_cleanCurrency(formatCurrency(rb.amount))}',
                        ))
                  else ...[
                    _buildRow('ставка',
                        _cleanCurrency(formatCurrency(calc.hourlyRate))),
                    _buildRow(
                        'отработано часов', formatQuantity(calc.hoursWorked)),
                    _buildRow(
                      'сумма по ставке',
                      '${formatQuantity(calc.hoursWorked)} x ${_cleanCurrency(formatCurrency(calc.hourlyRate))} = ${_cleanCurrency(formatCurrency(calc.baseSalary))}',
                    ),
                  ],

                  if (calc.businessTripTotal > 0)
                    _buildRow('суточные',
                        _cleanCurrency(formatCurrency(calc.businessTripTotal))),
                  if (calc.bonusesTotal > 0)
                    _buildRow('премии',
                        _cleanCurrency(formatCurrency(calc.bonusesTotal))),
                  if (calc.penaltiesTotal > 0)
                    _buildRow('штрафы',
                        _cleanCurrency(formatCurrency(calc.penaltiesTotal))),

                  pw.SizedBox(height: 2),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('ИТОГО заработано:',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      pw.Text(_cleanCurrency(formatCurrency(monthEarned)),
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    ],
                  ),
                ],

                if (data.payouts.isNotEmpty) ...[
                  pw.SizedBox(height: 5),
                  pw.Text('Выплаты:',
                      style: const pw.TextStyle(
                          fontSize: 10,
                          decoration: pw.TextDecoration.underline)),
                  ...data.payouts.map((p) => pw.Padding(
                        padding: const pw.EdgeInsets.only(left: 10),
                        child: pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text(_dateFormatter.format(p.payoutDate),
                                style: const pw.TextStyle(fontSize: 9)),
                            pw.Text(_cleanCurrency(formatCurrency(p.amount)),
                                style: const pw.TextStyle(fontSize: 9)),
                          ],
                        ),
                      )),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('Всего выплачено:',
                          style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold, fontSize: 9)),
                      pw.Text(_cleanCurrency(formatCurrency(monthPaid)),
                          style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold, fontSize: 9)),
                    ],
                  ),
                ],
                pw.SizedBox(height: 5),
                pw.Divider(color: PdfColors.grey300, thickness: 0.5),
              ],
            );
          }),

          // Итого за год
          pw.SizedBox(height: 20),
          pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.black, width: 1),
              color: PdfColors.grey100,
            ),
            child: pw.Column(
              children: [
                _buildTotalRow(
                    'ОБЩАЯ СУММА ЗАРАБОТАНО ЗА ГОД:',
                    _cleanCurrency(formatCurrency(totalEarned)),
                    fontBold),
                _buildTotalRow(
                    'ОБЩАЯ СУММА ПОЛУЧЕНО ЗА ГОД:',
                    _cleanCurrency(formatCurrency(totalReceived)),
                    fontBold),
                pw.Divider(),
                _buildTotalRow(
                  'ОСТАТОК К ВЫПЛАТЕ:',
                  _cleanCurrency(formatCurrency(totalEarned - totalReceived)),
                  fontBold,
                  color: (totalEarned - totalReceived) > 0
                      ? PdfColors.green700
                      : ((totalEarned - totalReceived) < 0
                          ? PdfColors.red700
                          : PdfColors.black),
                ),
              ],
            ),
          ),

          pw.Spacer(),
          pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.Text(
              'Дата формирования: ${DateFormat('dd.MM.yyyy HH:mm').format(DateTime.now())}',
              style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
            ),
          ),
        ],
      ),
    );

    return pdf.save();
  }

  /// Генерирует и сохраняет PDF отчет (старый метод для совместимости или прямого экспорта).
  Future<void> generateEmployeeYearlyReport({
    required Employee employee,
    required int year,
    required List<MonthlyReportData> monthlyData,
  }) async {
    try {
      final bytes = await buildEmployeeYearlyReport(
        employee: employee,
        year: year,
        monthlyData: monthlyData,
      );

      final fileName = 'Financial_Report_${employee.lastName}_$year.pdf';

      if (kIsWeb) {
        await FileSaver.instance.saveFile(
          name: fileName,
          bytes: Uint8List.fromList(bytes),
          mimeType: MimeType.pdf,
        );
      } else if (Platform.isMacOS) {
        // На Mac самый стабильный и "стандартный" способ - открыть в приложении "Просмотр" (Preview.app)
        // Это обходит проблемы Sandbox с диалогом печати и дает полноценный интерфейс macOS.
        try {
          final tempDir = await getTemporaryDirectory();
          final file = File('${tempDir.path}/$fileName');
          await file.writeAsBytes(bytes);
          
          final url = Uri.file(file.path);
          if (await canLaunchUrl(url)) {
            await launchUrl(url);
          } else {
            // Если url_launcher не сработал, пробуем через Printing как последний шанс
            await Printing.layoutPdf(
              onLayout: (format) async => bytes,
              name: fileName,
            );
          }
        } catch (e) {
          _logger.e('Ошибка при открытии PDF на macOS', error: e);
          // Фоллбек на системный диалог, если что-то пошло не так
          await Printing.layoutPdf(
            onLayout: (format) async => bytes,
            name: fileName,
          );
        }
      } else {
        // На iOS и Android стандартное поведение через системный лист
        await Printing.layoutPdf(
          onLayout: (format) async => bytes,
          name: fileName,
        );
      }
    } catch (e, stackTrace) {
      _logger.e('Ошибка при генерации PDF отчета',
          error: e, stackTrace: stackTrace);
    }
  }

  pw.Widget _buildRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 1),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: const pw.TextStyle(fontSize: 10)),
          pw.Text(value, style: const pw.TextStyle(fontSize: 10)),
        ],
      ),
    );
  }

  pw.Widget _buildTotalRow(String label, String value, pw.Font fontBold, {PdfColor color = PdfColors.black}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11)),
          pw.Text(value, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11, color: color)),
        ],
      ),
    );
  }
}
