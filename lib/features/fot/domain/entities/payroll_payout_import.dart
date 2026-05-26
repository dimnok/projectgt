import 'package:projectgt/domain/entities/employee.dart';

/// Статус сопоставления строки Excel со справочником сотрудников.
enum PayrollPayoutImportMatchStatus {
  /// ФИО однозначно найдено в справочнике.
  matched,

  /// Сотрудник с таким ФИО не найден.
  notFound,

  /// Найдено несколько подходящих сотрудников.
  ambiguous,
}

/// Строка выплаты, прочитанная из Excel (до сохранения в БД).
class PayrollPayoutImportRow {
  /// Создаёт строку импорта.
  const PayrollPayoutImportRow({
    required this.excelRowNumber,
    required this.fioFromFile,
    required this.amount,
    required this.status,
    this.matchedEmployee,
    this.ambiguousCandidates = const [],
  });

  /// Номер строки в Excel (1-based, для сообщений пользователю).
  final int excelRowNumber;

  /// ФИО из файла как есть.
  final String fioFromFile;

  /// Сумма выплаты.
  final double amount;

  /// Результат сопоставления с справочником.
  final PayrollPayoutImportMatchStatus status;

  /// Сотрудник при [PayrollPayoutImportMatchStatus.matched].
  final Employee? matchedEmployee;

  /// Кандидаты при [PayrollPayoutImportMatchStatus.ambiguous].
  final List<Employee> ambiguousCandidates;

  /// Успешно сопоставлена ли строка.
  bool get isMatched => status == PayrollPayoutImportMatchStatus.matched;
}

/// Результат разбора Excel-файла с выплатами.
class PayrollPayoutImportParseResult {
  /// Создаёт результат парсинга.
  const PayrollPayoutImportParseResult({
    required this.rows,
  });

  /// Все строки с данными из файла.
  final List<PayrollPayoutImportRow> rows;

  /// Строки, готовые к импорту.
  List<PayrollPayoutImportRow> get matchedRows =>
      rows.where((r) => r.isMatched).toList();

  /// Строки без сопоставления.
  List<PayrollPayoutImportRow> get notFoundRows => rows
      .where((r) => r.status == PayrollPayoutImportMatchStatus.notFound)
      .toList();

  /// Строки с неоднозначным сопоставлением.
  List<PayrollPayoutImportRow> get ambiguousRows => rows
      .where((r) => r.status == PayrollPayoutImportMatchStatus.ambiguous)
      .toList();

  /// Есть ли проблемные строки (не найден или неоднозначен).
  bool get hasIssues =>
      notFoundRows.isNotEmpty || ambiguousRows.isNotEmpty;
}
