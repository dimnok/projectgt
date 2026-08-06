import 'package:projectgt/features/settlements/domain/entities/settlement_operation.dart';

/// Опция выпадающего фильтра взаиморасчётов (ид + подпись).
class SettlementsFilterOption {
  /// Создаёт опцию фильтра.
  const SettlementsFilterOption({
    required this.id,
    required this.label,
  });

  /// Идентификатор сущности.
  final String id;

  /// Подпись в списке.
  final String label;
}

/// Сборка списков фильтров из загруженных операций.
abstract final class SettlementsFilterOptionsBuilder {
  /// Уникальные контрагенты из операций.
  static List<SettlementsFilterOption> contractors(
    List<SettlementOperation> operations,
  ) {
    return _uniqueOptions(
      operations,
      id: (op) => op.contractorId,
      label: (op) => op.contractorName?.trim(),
      fallbackPrefix: 'Контрагент',
    );
  }

  /// Уникальные объекты из операций.
  static List<SettlementsFilterOption> objects(
    List<SettlementOperation> operations,
  ) {
    return _uniqueOptions(
      operations,
      id: (op) => op.objectId,
      label: (op) => op.objectName?.trim(),
      fallbackPrefix: 'Объект',
    );
  }

  /// Уникальные договоры из операций.
  static List<SettlementsFilterOption> contracts(
    List<SettlementOperation> operations,
  ) {
    return _uniqueOptions(
      operations,
      id: (op) => op.contractId,
      label: (op) => op.contractNumber?.trim(),
      fallbackPrefix: 'Договор',
    );
  }

  static List<SettlementsFilterOption> _uniqueOptions(
    List<SettlementOperation> operations, {
    required String Function(SettlementOperation op) id,
    required String? Function(SettlementOperation op) label,
    required String fallbackPrefix,
  }) {
    final map = <String, String>{};
    for (final op in operations) {
      final entityId = id(op);
      if (entityId.isEmpty) continue;
      final name = label(op);
      final display = name != null && name.isNotEmpty
          ? name
          : '$fallbackPrefix $entityId';
      map.putIfAbsent(entityId, () => display);
    }
    final items = map.entries
        .map(
          (e) => SettlementsFilterOption(id: e.key, label: e.value),
        )
        .toList(growable: false);
    items.sort(
      (a, b) => a.label.toLowerCase().compareTo(b.label.toLowerCase()),
    );
    return items;
  }

  /// Находит подпись опции по идентификатору.
  static String? labelForId(
    List<SettlementsFilterOption> options,
    String? id,
  ) {
    if (id == null) return null;
    for (final option in options) {
      if (option.id == id) return option.label;
    }
    return null;
  }
}
