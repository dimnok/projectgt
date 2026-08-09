import 'package:projectgt/domain/entities/contract.dart';
import 'package:projectgt/features/cash_flow/domain/entities/bank_statement_entry.dart';
import 'package:projectgt/features/cash_flow/domain/entities/bank_statement_match_result.dart';
import 'package:projectgt/features/cash_flow/domain/entities/cash_flow_category.dart';
import 'package:projectgt/features/cash_flow/domain/entities/cash_flow_category_rule.dart';
import 'package:projectgt/features/cash_flow/domain/repositories/cash_flow_repository_interface.dart';
import 'package:projectgt/features/cash_flow/domain/services/bank_statement_matching_service.dart';
import 'package:projectgt/features/contractors/domain/entities/contractor.dart';

/// Координатор автосопоставления и пакетной обработки банковских выписок.
class BankStatementAutoProcessService {
  final ICashFlowRepository _repository;
  final BankStatementMatchingService _matchingService;

  /// Создаёт [BankStatementAutoProcessService].
  BankStatementAutoProcessService(
    this._repository,
    this._matchingService,
  );

  /// Вычисляет автосопоставление для списка строк выписки.
  Future<Map<String, BankStatementMatchResult>> computeMatches({
    required List<BankStatementEntry> entries,
    required List<Contractor> contractors,
    required List<Contract> contracts,
    required List<CashFlowCategory> categories,
    required List<CashFlowCategoryRule> rules,
    required Set<String> duplicateHashes,
  }) async {
    if (entries.isEmpty) return {};

    final context = await _repository.getMatchingContext();

    return _matchingService.matchAll(
      entries: entries,
      contractors: contractors,
      contracts: contracts,
      categories: categories,
      rules: rules,
      context: context,
      duplicateHashes: duplicateHashes,
    );
  }

  /// Пакетно обрабатывает строки с высокой уверенностью автосопоставления.
  Future<BankStatementBatchProcessResult> processAutoMatched({
    required List<BankStatementEntry> entries,
    required Map<String, BankStatementMatchResult> matches,
    required String companyId,
    bool linkSettlements = true,
  }) async {
    final items = <Map<String, dynamic>>[];

    for (final entry in entries) {
      final match = matches[entry.id];
      if (match == null || !match.isAutoProcessable) continue;

      items.add({
        'entry_id': entry.id,
        'date': _formatDate(entry.date),
        'type': entry.type.name,
        'amount': entry.amount,
        'category_id': match.categoryId,
        'object_id': match.objectId,
        'contract_id': match.contractId,
        'contractor_id': match.contractorId,
        'contractor_name': entry.contractorName,
        'contractor_inn': entry.contractorInn,
        'comment': entry.comment,
        'operation_hash': entry.operationHash,
        if (linkSettlements && match.settlementOperationId != null)
          'settlement_operation_id': match.settlementOperationId,
      });
    }

    if (items.isEmpty) {
      return const BankStatementBatchProcessResult(processed: 0, failures: []);
    }

    return _repository.batchProcessBankStatementEntries(
      companyId: companyId,
      items: items,
    );
  }

  String _formatDate(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }
}
