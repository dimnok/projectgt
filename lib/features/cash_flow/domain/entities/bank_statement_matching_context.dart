/// Подсказка из последней операции ДДС по контрагенту.
class ContractorCashFlowHint {
  /// ID контрагента.
  final String contractorId;

  /// Последний использованный договор.
  final String? contractId;

  /// Объект из последней операции.
  final String? objectId;

  /// Последняя использованная статья ДДС.
  final String? categoryId;

  /// Создаёт [ContractorCashFlowHint].
  const ContractorCashFlowHint({
    required this.contractorId,
    this.contractId,
    this.objectId,
    this.categoryId,
  });
}

/// Открытый счёт взаиморасчётов для автоподбора оплаты.
class OpenSettlementCandidate {
  /// ID операции взаиморасчётов.
  final String id;

  /// Договор.
  final String contractId;

  /// Контрагент.
  final String contractorId;

  /// Остаток к оплате.
  final double remainingAmount;

  /// Номер счёта.
  final String invoiceNumber;

  /// Создаёт [OpenSettlementCandidate].
  const OpenSettlementCandidate({
    required this.id,
    required this.contractId,
    required this.contractorId,
    required this.remainingAmount,
    required this.invoiceNumber,
  });
}

/// Контекст для автосопоставления (загружается одним RPC-запросом).
class BankStatementMatchingContext {
  /// Подсказки по контрагентам из истории ДДС.
  final Map<String, ContractorCashFlowHint> contractorHints;

  /// Открытые счета взаиморасчётов.
  final List<OpenSettlementCandidate> openSettlements;

  /// Создаёт [BankStatementMatchingContext].
  const BankStatementMatchingContext({
    required this.contractorHints,
    required this.openSettlements,
  });

  /// Пустой контекст.
  static const empty = BankStatementMatchingContext(
    contractorHints: {},
    openSettlements: [],
  );
}
