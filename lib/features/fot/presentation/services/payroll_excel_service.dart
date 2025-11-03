import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:excel/excel.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:file_saver/file_saver.dart';
import '../../domain/entities/payroll_calculation.dart';

/// Сервис для экспорта данных ФОТ в Excel.
class PayrollExcelService {
  static final NumberFormat _numberFormat = NumberFormat.currency(
    locale: 'ru_RU',
    symbol: '₽',
    decimalDigits: 2,
  );

  /// Экспортирует данные ФОТ в Excel файл.
  /// Простой экспорт без стилей - только данные.
  Future<void> exportPayrollToExcel({
    required List<PayrollCalculation> payrolls,
    required Map<String, double> payoutsByEmployee,
    required Map<String, double> aggregatedBalance,
    required Map<String, String> employeeNames,
    required int year,
    required int month,
  }) async {
    try {
      // Создаём новый Excel файл
      final excel = Excel.createExcel();

      // Формируем имя листа: месяц год
      final monthName = DateFormat('MMMM', 'ru').format(DateTime(year, month));
      final sheetName = '$monthName $year';

      // Используем существующий лист или создаём новый
      excel.rename('Sheet1', sheetName);
      final currentSheet = excel[sheetName] as dynamic;

      // Заголовки колонок (как в таблице на desktop версии)
      final headers = [
        'Сотрудник',
        'Часы',
        'Ставка',
        'Базовая сумма',
        'Премии',
        'Штрафы',
        'Суточные',
        'К выплате',
        'Выплаты',
        'Остаток',
        'Баланс',
      ];

      // Добавляем заголовки
      for (int col = 0; col < headers.length; col++) {
        final cell = currentSheet.cell(CellIndex.indexByColumnRow(
          columnIndex: col,
          rowIndex: 0,
        ));
        cell.value = TextCellValue(headers[col]);
      }

      // Добавляем данные (сортируем как в таблице - по алфавиту)
      int rowIndex = 1;
      for (final payroll in payrolls) {
        final employeeName = employeeNames[payroll.employeeId] ?? 'Неизвестный';
        final payout = payoutsByEmployee[payroll.employeeId] ?? 0;
        final balance = aggregatedBalance[payroll.employeeId ?? ''] ?? 0;
        final remainder = payroll.netSalary - payout;

        final rowData = [
          employeeName,
          payroll.hoursWorked.toString(),
          _numberFormat.format(payroll.hourlyRate),
          _numberFormat.format(payroll.baseSalary),
          _numberFormat.format(payroll.bonusesTotal),
          _numberFormat.format(payroll.penaltiesTotal),
          _numberFormat.format(payroll.businessTripTotal),
          _numberFormat.format(payroll.netSalary),
          _numberFormat.format(payout),
          _numberFormat.format(remainder),
          _numberFormat.format(balance),
        ];

        for (int col = 0; col < rowData.length; col++) {
          final cell = currentSheet.cell(CellIndex.indexByColumnRow(
            columnIndex: col,
            rowIndex: rowIndex,
          ));
          cell.value = TextCellValue(rowData[col]);
        }

        rowIndex++;
      }

      // Добавляем итоговую строку
      final totalHours =
          payrolls.fold<double>(0, (sum, p) => sum + p.hoursWorked);
      final totalBase =
          payrolls.fold<double>(0, (sum, p) => sum + p.baseSalary);
      final totalBonus =
          payrolls.fold<double>(0, (sum, p) => sum + p.bonusesTotal);
      final totalPenalty =
          payrolls.fold<double>(0, (sum, p) => sum + p.penaltiesTotal);
      final totalTrip =
          payrolls.fold<double>(0, (sum, p) => sum + p.businessTripTotal);
      final totalNet = payrolls.fold<double>(0, (sum, p) => sum + p.netSalary);
      final totalPayouts =
          payoutsByEmployee.values.fold<double>(0, (sum, p) => sum + p);
      final totalRemainder = totalNet - totalPayouts;
      final totalBalance =
          aggregatedBalance.values.fold<double>(0, (sum, b) => sum + b);

      final totalsRow = [
        'ИТОГО',
        totalHours.toString(),
        '',
        _numberFormat.format(totalBase),
        _numberFormat.format(totalBonus),
        _numberFormat.format(totalPenalty),
        _numberFormat.format(totalTrip),
        _numberFormat.format(totalNet),
        _numberFormat.format(totalPayouts),
        _numberFormat.format(totalRemainder),
        _numberFormat.format(totalBalance),
      ];

      for (int col = 0; col < totalsRow.length; col++) {
        final cell = currentSheet.cell(CellIndex.indexByColumnRow(
          columnIndex: col,
          rowIndex: rowIndex,
        ));
        cell.value = TextCellValue(totalsRow[col]);
      }

      // Автоподбор ширины колонок
      for (int i = 0; i < headers.length; i++) {
        currentSheet.setColumnAutoFit(i);
      }

      // Сохраняем файл
      final fileName =
          'ФОТ_${DateFormat('dd.MM.yyyy').format(DateTime.now())}.xlsx';
      final bytes = excel.encode();

      if (bytes == null) {
        throw Exception('Не удалось создать Excel файл');
      }

      if (kIsWeb) {
        await FileSaver.instance.saveFile(
          name: fileName,
          bytes: Uint8List.fromList(bytes),
          mimeType: MimeType.microsoftExcel,
        );
      } else {
        final directory = await getApplicationDocumentsDirectory();
        final file = File('${directory.path}/$fileName');
        await file.writeAsBytes(bytes);
      }
    } catch (e) {
      rethrow;
    }
  }
}
