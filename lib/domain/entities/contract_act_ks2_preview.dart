/// Данные предпросмотра состава акта КС-2 по ВОР (`ks2_operations` preview).
class ContractActKs2Preview {
  /// Создаёт данные предпросмотра.
  const ContractActKs2Preview({
    required this.totalAmount,
    required this.itemsCount,
    required this.skippedCount,
    required this.candidates,
  });

  /// Сумма позиций, попадающих в акт.
  final double totalAmount;

  /// Число позиций в акте.
  final int itemsCount;

  /// Число пропущенных строк (превышение сметы и т.п.).
  final int skippedCount;

  /// Сырые строки кандидатов из Edge Function.
  final List<dynamic> candidates;

  /// Создаёт экземпляр из JSON ответа `ks2_operations`.
  factory ContractActKs2Preview.fromJson(Map<String, dynamic> json) {
    return ContractActKs2Preview(
      totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0,
      itemsCount: json['stats']?['candidatesCount'] as int? ?? 0,
      skippedCount: json['stats']?['skippedCount'] as int? ?? 0,
      candidates: json['candidates'] as List<dynamic>? ?? const [],
    );
  }
}
