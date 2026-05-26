import 'dart:typed_data';

import 'package:excel/excel.dart';
import 'package:projectgt/core/utils/formatters.dart';
import 'package:projectgt/core/utils/xlsx_excel_compatibility.dart';
import 'package:projectgt/domain/entities/employee.dart';
import 'package:projectgt/features/fot/domain/entities/payroll_payout_import.dart';

/// Парсинг Excel-ведомости выплат и сопоставление ФИО со справочником сотрудников.
///
/// Ожидаемый формат: колонки «ФИО работника» и «Сумма перевода» (порядок полей:
/// Фамилия Имя Отчество). Файл обрабатывается только в памяти.
class PayrollPayoutExcelImportService {
  PayrollPayoutExcelImportService._();

  static final RegExp _fioHeaderPattern = RegExp(r'фио', caseSensitive: false);
  static final RegExp _amountHeaderPattern = RegExp(
    r'сумм|перевод',
    caseSensitive: false,
  );

  /// Сопоставляет ФИО из файла со справочником [employees].
  static PayrollPayoutImportRow matchFioToEmployees({
    required int excelRowNumber,
    required String fioFromFile,
    required double amount,
    required List<Employee> employees,
  }) =>
      _matchRow(
        excelRowNumber: excelRowNumber,
        fioFromFile: fioFromFile,
        amount: amount,
        employees: employees,
      );

  /// Читает `.xlsx` и сопоставляет строки с [employees] (включая уволенных).
  static PayrollPayoutImportParseResult parseAndMatch(
    Uint8List bytes,
    List<Employee> employees,
  ) {
    final excel = Excel.decodeBytes(sanitizeXlsxForExcelNumberFormats(bytes));
    if (excel.tables.isEmpty) {
      throw Exception('Файл Excel пуст или не содержит листов');
    }

    final sheet = excel.tables[excel.tables.keys.first]!;
    if (sheet.rows.isEmpty) {
      throw Exception('Лист Excel не содержит данных');
    }

    final columnMap = _detectColumns(sheet.rows);
    final dataStartRow = columnMap.dataStartRowIndex;

    final parsedRows = <({int rowNumber, String fio, double amount})>[];

    for (var ri = dataStartRow; ri < sheet.rows.length; ri++) {
      final row = sheet.rows[ri];
      if (row.isEmpty) continue;

      final fio = _cellString(
        columnMap.fioColumnIndex < row.length
            ? row[columnMap.fioColumnIndex]
            : null,
      );
      if (fio.isEmpty) continue;

      final amount = _parseAmountCell(
        columnMap.amountColumnIndex < row.length
            ? row[columnMap.amountColumnIndex]
            : null,
        ri + 1,
      );
      if (amount == null || amount <= 0) continue;

      parsedRows.add((rowNumber: ri + 1, fio: fio, amount: amount));
    }

    if (parsedRows.isEmpty) {
      throw Exception(
        'В файле нет строк с ФИО и суммой. Проверьте формат ведомости.',
      );
    }

    final rows = parsedRows
        .map(
          (r) => _matchRow(
            excelRowNumber: r.rowNumber,
            fioFromFile: r.fio,
            amount: r.amount,
            employees: employees,
          ),
        )
        .toList();

    return PayrollPayoutImportParseResult(rows: rows);
  }

  static PayrollPayoutImportRow _matchRow({
    required int excelRowNumber,
    required String fioFromFile,
    required double amount,
    required List<Employee> employees,
  }) {
    final normalizedFile = normalizePayrollImportFio(fioFromFile);

    final exactMatches = employees
        .where((e) => normalizePayrollImportFio(e.fullName) == normalizedFile)
        .toList();

    if (exactMatches.length == 1) {
      return PayrollPayoutImportRow(
        excelRowNumber: excelRowNumber,
        fioFromFile: fioFromFile,
        amount: amount,
        status: PayrollPayoutImportMatchStatus.matched,
        matchedEmployee: exactMatches.first,
      );
    }
    if (exactMatches.length > 1) {
      return PayrollPayoutImportRow(
        excelRowNumber: excelRowNumber,
        fioFromFile: fioFromFile,
        amount: amount,
        status: PayrollPayoutImportMatchStatus.ambiguous,
        ambiguousCandidates: exactMatches,
      );
    }

    final tokenMatches = _matchByTokens(normalizedFile, employees);
    if (tokenMatches.length == 1) {
      return PayrollPayoutImportRow(
        excelRowNumber: excelRowNumber,
        fioFromFile: fioFromFile,
        amount: amount,
        status: PayrollPayoutImportMatchStatus.matched,
        matchedEmployee: tokenMatches.first,
      );
    }
    if (tokenMatches.length > 1) {
      return PayrollPayoutImportRow(
        excelRowNumber: excelRowNumber,
        fioFromFile: fioFromFile,
        amount: amount,
        status: PayrollPayoutImportMatchStatus.ambiguous,
        ambiguousCandidates: tokenMatches,
      );
    }

    return PayrollPayoutImportRow(
      excelRowNumber: excelRowNumber,
      fioFromFile: fioFromFile,
      amount: amount,
      status: PayrollPayoutImportMatchStatus.notFound,
    );
  }

  static List<Employee> _matchByTokens(
    String normalizedFileFio,
    List<Employee> employees,
  ) {
    final tokens = normalizedFileFio
        .split(' ')
        .where((t) => t.isNotEmpty)
        .toList();
    if (tokens.length < 2) return [];

    final fileLast = tokens[0];
    final fileFirst = tokens[1];
    final fileMiddle = tokens.length > 2 ? tokens.sublist(2).join(' ') : '';

    return employees.where((e) {
      final last = normalizePayrollImportFio(e.lastName);
      final first = normalizePayrollImportFio(e.firstName);
      final middle = e.middleName != null && e.middleName!.trim().isNotEmpty
          ? normalizePayrollImportFio(e.middleName!)
          : '';

      if (last != fileLast || first != fileFirst) return false;

      if (tokens.length >= 3) {
        return middle == fileMiddle;
      }
      // В файле только фамилия и имя — подходит любой с такой парой.
      return true;
    }).toList();
  }

  static _ColumnMap _detectColumns(List<List<Data?>> rows) {
    for (var ri = 0; ri < rows.length && ri < 15; ri++) {
      final row = rows[ri];
      int? fioCol;
      int? amountCol;

      for (var ci = 0; ci < row.length; ci++) {
        final text = _cellString(row[ci]).toLowerCase();
        if (fioCol == null && _fioHeaderPattern.hasMatch(text)) {
          fioCol = ci;
        }
        if (amountCol == null && _amountHeaderPattern.hasMatch(text)) {
          amountCol = ci;
        }
      }

      if (fioCol != null && amountCol != null) {
        return _ColumnMap(
          fioColumnIndex: fioCol,
          amountColumnIndex: amountCol,
          dataStartRowIndex: ri + 1,
        );
      }
    }

    // Формат без заголовка или нестандартный: B=ФИО, C=сумма (индексы 1 и 2).
    return const _ColumnMap(
      fioColumnIndex: 1,
      amountColumnIndex: 2,
      dataStartRowIndex: 1,
    );
  }

  static String _cellString(Data? cell) {
    if (cell?.value == null) return '';
    final v = cell!.value!;
    if (v is IntCellValue) return v.value.toString();
    if (v is DoubleCellValue) {
      final d = v.value;
      if (d == d.roundToDouble()) return d.round().toString();
      return d.toString();
    }
    return v.toString().trim();
  }

  static double? _parseAmountCell(Data? cell, int excelRow1Based) {
    if (cell?.value == null) return null;
    final v = cell!.value!;
    if (v is DoubleCellValue) {
      final n = v.value;
      if (n <= 0) return null;
      return n;
    }
    if (v is IntCellValue) {
      final n = v.value.toDouble();
      if (n <= 0) return null;
      return n;
    }
    final text = v.toString().trim().replaceAll('₽', '').trim();
    if (text.isEmpty) return null;
    final parsed = parseAmount(text);
    if (parsed == null) {
      throw Exception('Неверная сумма в строке $excelRow1Based');
    }
    return parsed;
  }
}

/// Нормализует ФИО для сравнения (регистр, пробелы, «ё»).
String normalizePayrollImportFio(String value) {
  return value
      .trim()
      .toLowerCase()
      .replaceAll('ё', 'е')
      .replaceAll(RegExp(r'\s+'), ' ');
}

class _ColumnMap {
  const _ColumnMap({
    required this.fioColumnIndex,
    required this.amountColumnIndex,
    required this.dataStartRowIndex,
  });

  final int fioColumnIndex;
  final int amountColumnIndex;
  final int dataStartRowIndex;
}
