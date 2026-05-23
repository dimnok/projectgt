/// Источник / режим акта по договору (`contract_acts.act_kind`).
enum ContractActKind {
  /// Ручной ввод сумм и реквизитов.
  manual,

  /// Акт КС-2 по утверждённой ВОР.
  ks2,
}

/// Откуда взята сумма акта (`contract_acts.amount_source`).
enum ContractActAmountSource {
  /// Введена вручную.
  manual,

  /// Рассчитана по превью ВОР (`ks2_operations`).
  vorPreview,
}

/// Строковые значения [ContractActKind] в PostgREST.
extension ContractActKindApi on ContractActKind {
  /// Значение колонки `act_kind`.
  String get apiValue => switch (this) {
        ContractActKind.manual => 'manual',
        ContractActKind.ks2 => 'ks2',
      };

  /// Парсинг из API.
  static ContractActKind parse(String raw) {
    return ContractActKind.values.firstWhere(
      (e) => e.apiValue == raw,
      orElse: () => ContractActKind.manual,
    );
  }
}

/// Строковые значения [ContractActAmountSource] в PostgREST.
extension ContractActAmountSourceApi on ContractActAmountSource {
  /// Значение колонки `amount_source`.
  String get apiValue => switch (this) {
        ContractActAmountSource.manual => 'manual',
        ContractActAmountSource.vorPreview => 'vor_preview',
      };

  /// Парсинг из API.
  static ContractActAmountSource parse(String raw) {
    return ContractActAmountSource.values.firstWhere(
      (e) => e.apiValue == raw,
      orElse: () => ContractActAmountSource.manual,
    );
  }
}
