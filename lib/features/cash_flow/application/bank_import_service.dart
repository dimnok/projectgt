import 'dart:typed_data';
import 'package:projectgt/features/cash_flow/domain/entities/bank_import_template.dart';
import 'package:projectgt/features/cash_flow/domain/entities/bank_statement_entry.dart';
import 'package:projectgt/features/cash_flow/domain/repositories/cash_flow_repository_interface.dart';
import 'package:projectgt/features/cash_flow/domain/services/bank_statement_parser.dart';
import 'package:projectgt/features/company/domain/entities/company_bank_account.dart';

/// Результат импорта банковской выписки.
class BankImportResult {
  /// Всего записей в файле.
  final int total;

  /// Добавлено новых записей.
  final int added;

  /// Пропущено дубликатов.
  final int skipped;

  /// Список новых записей для сохранения.
  final List<BankStatementEntry> newEntries;

  /// Создаёт [BankImportResult].
  const BankImportResult({
    required this.total,
    required this.added,
    required this.skipped,
    required this.newEntries,
  });
}

/// Сервис для координации процесса импорта банковских выписок.
class BankImportService {
  final ICashFlowRepository _repository;

  /// Создаёт [BankImportService].
  BankImportService(this._repository);

  /// Обрабатывает байты файла выписки, проверяет на дубликаты и возвращает результат.
  Future<BankImportResult> processStatement({
    required Uint8List bytes,
    required BankImportTemplate template,
    required CompanyBankAccount account,
    String? targetInn,
  }) async {
    // 1. Получаем существующие хеши для проверки дублей
    final existingHashes = await _repository.getExistingOperationHashes();

    // 2. Парсим файл через Edge Function
    final parsedEntries = await BankStatementParser.parse(
      bytes: bytes,
      template: template,
      companyId: template.companyId,
      bankAccountId: account.id,
      targetInn: targetInn,
      targetAccountNumber: account.accountNumber,
    );

    if (parsedEntries.isEmpty) {
      return const BankImportResult(
        total: 0,
        added: 0,
        skipped: 0,
        newEntries: [],
      );
    }

    // 3. Фильтруем дубликаты
    final newEntries = <BankStatementEntry>[];
    int skipped = 0;

    for (final entry in parsedEntries) {
      if (entry.operationHash != null &&
          existingHashes.contains(entry.operationHash)) {
        skipped++;
      } else {
        newEntries.add(entry);
      }
    }

    return BankImportResult(
      total: parsedEntries.length,
      added: newEntries.length,
      skipped: skipped,
      newEntries: newEntries,
    );
  }
}
