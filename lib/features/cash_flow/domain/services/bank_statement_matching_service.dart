import 'package:collection/collection.dart';
import 'package:projectgt/domain/entities/contract.dart';
import 'package:projectgt/features/cash_flow/domain/entities/bank_statement_entry.dart';
import 'package:projectgt/features/cash_flow/domain/entities/bank_statement_match_result.dart';
import 'package:projectgt/features/cash_flow/domain/entities/bank_statement_matching_context.dart';
import 'package:projectgt/features/cash_flow/domain/entities/cash_flow_category.dart';
import 'package:projectgt/features/cash_flow/domain/entities/cash_flow_category_rule.dart';
import 'package:projectgt/features/cash_flow/domain/entities/cash_flow_transaction.dart';
import 'package:projectgt/features/contractors/domain/entities/contractor.dart';
import 'package:projectgt/features/settlements/domain/entities/settlement_operation.dart';

/// Результат сопоставления статьи ДДС.
class _CategoryMatch {
  final String? categoryId;
  final bool categoryOnly;

  const _CategoryMatch({this.categoryId, this.categoryOnly = false});
}

/// Доменный сервис автосопоставления строк банковской выписки.
class BankStatementMatchingService {
  static const _amountEpsilon = SettlementOperation.amountEpsilon;

  /// Сопоставляет одну строку выписки с реквизитами ДДС.
  BankStatementMatchResult match({
    required BankStatementEntry entry,
    required List<Contractor> contractors,
    required List<Contract> contracts,
    required List<CashFlowCategory> categories,
    required List<CashFlowCategoryRule> rules,
    required BankStatementMatchingContext context,
    required Set<String> duplicateHashes,
  }) {
    final reasons = <String>[];

    if (entry.isImported) {
      return _low(entry.id, reasons, 'Строка уже обработана');
    }

    final hash = entry.operationHash;
    if (hash != null && duplicateHashes.contains(hash)) {
      return _low(entry.id, reasons, 'Дубликат операции в реестре');
    }

    final operationType = _toCategoryOperationType(entry.type);

    final categoryMatch = _matchCategory(
      comment: entry.comment,
      operationType: operationType,
      rules: rules,
      contractorId: _matchContractorInn(entry, contractors),
      context: context,
      categories: categories,
      reasons: reasons,
    );

    final categoryOnly = categoryMatch.categoryOnly &&
        categoryMatch.categoryId != null;

    String? contractorId;
    _ContractMatch contractMatch;

    if (categoryOnly) {
      reasons.add('Операция без договора — только статья ДДС');
      contractorId = null;
      contractMatch = const _ContractMatch();
    } else {
      contractorId = _matchContractor(entry, contractors, reasons);
      contractMatch = _matchContract(
        contractorId: contractorId,
        contracts: contracts,
        context: context,
        reasons: reasons,
      );
    }

    final settlementId = contractMatch.contractId != null
        ? _matchSettlement(
            amount: entry.amount,
            contractId: contractMatch.contractId!,
            context: context,
            reasons: reasons,
          )
        : null;

    final confidence = _resolveConfidence(
      categoryId: categoryMatch.categoryId,
      categoryOnly: categoryOnly,
      contractorId: contractorId,
      contractId: contractMatch.contractId,
      objectId: contractMatch.objectId,
      ambiguousContract: contractMatch.ambiguous,
    );

    return BankStatementMatchResult(
      entryId: entry.id,
      confidence: confidence,
      categoryId: categoryMatch.categoryId,
      contractorId: contractorId,
      contractId: contractMatch.contractId,
      objectId: contractMatch.objectId,
      settlementOperationId: settlementId,
      matchReasons: List.unmodifiable(reasons),
    );
  }

  /// Сопоставляет все строки выписки.
  Map<String, BankStatementMatchResult> matchAll({
    required List<BankStatementEntry> entries,
    required List<Contractor> contractors,
    required List<Contract> contracts,
    required List<CashFlowCategory> categories,
    required List<CashFlowCategoryRule> rules,
    required BankStatementMatchingContext context,
    required Set<String> duplicateHashes,
  }) {
    return {
      for (final entry in entries)
        entry.id: match(
          entry: entry,
          contractors: contractors,
          contracts: contracts,
          categories: categories,
          rules: rules,
          context: context,
          duplicateHashes: duplicateHashes,
        ),
    };
  }

  CashFlowOperationType _toCategoryOperationType(CashFlowType type) {
    return type == CashFlowType.income
        ? CashFlowOperationType.income
        : CashFlowOperationType.expense;
  }

  /// Ищет контрагента по ИНН без записи в [reasons].
  String? _matchContractorInn(
    BankStatementEntry entry,
    List<Contractor> contractors,
  ) {
    final inn = entry.contractorInn?.trim();
    if (inn == null || inn.isEmpty) return null;
    return contractors
        .where((c) => c.inn == inn)
        .map((c) => c.id)
        .firstOrNull;
  }

  String? _matchContractor(
    BankStatementEntry entry,
    List<Contractor> contractors,
    List<String> reasons,
  ) {
    final inn = entry.contractorInn?.trim();
    if (inn == null || inn.isEmpty) {
      reasons.add('ИНН контрагента не указан в выписке');
      return null;
    }

    final matched = contractors.where((c) => c.inn == inn).toList();
    if (matched.isEmpty) {
      reasons.add('Контрагент с ИНН $inn не найден в системе');
      return null;
    }

    if (matched.length > 1) {
      reasons.add('Несколько контрагентов с ИНН $inn');
      return matched.first.id;
    }

    reasons.add('Контрагент найден по ИНН');
    return matched.first.id;
  }

  _CategoryMatch _matchCategory({
    required String? comment,
    required CashFlowOperationType operationType,
    required List<CashFlowCategoryRule> rules,
    required String? contractorId,
    required BankStatementMatchingContext context,
    required List<CashFlowCategory> categories,
    required List<String> reasons,
  }) {
    final normalizedComment = (comment ?? '').toLowerCase();

    final applicableRules = rules
        .where((r) => r.operationType == operationType)
        .toList()
      ..sort((a, b) {
        final priorityCompare = b.priority.compareTo(a.priority);
        if (priorityCompare != 0) return priorityCompare;
        return b.keyword.length.compareTo(a.keyword.length);
      });

    for (final rule in applicableRules) {
      final keyword = rule.keyword.trim().toLowerCase();
      if (keyword.isEmpty) continue;
      if (normalizedComment.contains(keyword)) {
        if (_categoryExists(rule.categoryId, categories)) {
          reasons.add('Статья по правилу «${rule.keyword}»');
          if (!rule.requiresContractBinding) {
            reasons.add('Правило без привязки к договору');
          }
          return _CategoryMatch(
            categoryId: rule.categoryId,
            categoryOnly: !rule.requiresContractBinding,
          );
        }
      }
    }

    if (contractorId != null) {
      final hint = context.contractorHints[contractorId];
      final hintCategory = hint?.categoryId;
      if (hintCategory != null && _categoryExists(hintCategory, categories)) {
        final historyCategoryOnly =
            hint!.contractId == null && hint.objectId == null;
        if (historyCategoryOnly) {
          reasons.add('Статья из истории операций без договора');
        } else {
          reasons.add('Статья из истории операций контрагента');
        }
        return _CategoryMatch(
          categoryId: hintCategory,
          categoryOnly: historyCategoryOnly,
        );
      }
    }

    reasons.add('Статья ДДС не определена');
    return const _CategoryMatch();
  }

  bool _categoryExists(String categoryId, List<CashFlowCategory> categories) {
    return categories.any((c) => c.id == categoryId);
  }

  _ContractMatch _matchContract({
    required String? contractorId,
    required List<Contract> contracts,
    required BankStatementMatchingContext context,
    required List<String> reasons,
  }) {
    if (contractorId == null) {
      reasons.add('Договор не определён: контрагент не найден');
      return const _ContractMatch();
    }

    final hint = context.contractorHints[contractorId];
    if (hint?.contractId != null) {
      reasons.add('Договор из истории операций контрагента');
      return _ContractMatch(
        contractId: hint!.contractId,
        objectId: hint.objectId,
      );
    }

    final activeContracts = contracts
        .where(
          (c) =>
              c.contractorId == contractorId &&
              c.status == ContractStatus.active,
        )
        .toList();

    if (activeContracts.length == 1) {
      reasons.add('Единственный активный договор контрагента');
      return _ContractMatch(
        contractId: activeContracts.first.id,
        objectId: activeContracts.first.objectId,
      );
    }

    if (activeContracts.isEmpty) {
      reasons.add('Нет активных договоров контрагента');
      return const _ContractMatch();
    }

    reasons.add('Несколько активных договоров — нужна ручная проверка');
    return const _ContractMatch(ambiguous: true);
  }

  String? _matchSettlement({
    required double amount,
    required String contractId,
    required BankStatementMatchingContext context,
    required List<String> reasons,
  }) {
    final candidates = context.openSettlements
        .where((s) => s.contractId == contractId)
        .where((s) => s.remainingAmount >= amount - _amountEpsilon)
        .toList();

    if (candidates.isEmpty) return null;

    final exactMatches = candidates
        .where((s) => (s.remainingAmount - amount).abs() <= _amountEpsilon)
        .toList();

    final match =
        exactMatches.isNotEmpty ? exactMatches.first : candidates.first;

    if ((match.remainingAmount - amount).abs() <= _amountEpsilon) {
      reasons.add('Счёт взаиморасчётов ${match.invoiceNumber} (точная сумма)');
    } else {
      reasons.add(
        'Счёт взаиморасчётов ${match.invoiceNumber} (частичное покрытие)',
      );
    }

    return match.id;
  }

  BankStatementMatchConfidence _resolveConfidence({
    required String? categoryId,
    required bool categoryOnly,
    required String? contractorId,
    required String? contractId,
    required String? objectId,
    required bool ambiguousContract,
  }) {
    if (categoryOnly && categoryId != null) {
      return BankStatementMatchConfidence.high;
    }

    if (ambiguousContract) {
      return BankStatementMatchConfidence.medium;
    }

    if (categoryId != null &&
        contractorId != null &&
        contractId != null &&
        objectId != null) {
      return BankStatementMatchConfidence.high;
    }

    if (categoryId != null || contractorId != null) {
      return BankStatementMatchConfidence.medium;
    }

    return BankStatementMatchConfidence.low;
  }

  BankStatementMatchResult _low(
    String entryId,
    List<String> reasons,
    String message,
  ) {
    reasons.add(message);
    return BankStatementMatchResult(
      entryId: entryId,
      confidence: BankStatementMatchConfidence.low,
      matchReasons: List.unmodifiable(reasons),
    );
  }
}

class _ContractMatch {
  final String? contractId;
  final String? objectId;
  final bool ambiguous;

  const _ContractMatch({
    this.contractId,
    this.objectId,
    this.ambiguous = false,
  });
}
