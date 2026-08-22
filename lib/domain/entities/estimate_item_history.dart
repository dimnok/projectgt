/// Запись журнала ручного изменения сметной позиции.
class EstimateItemHistoryEntry {
  /// Создаёт запись журнала.
  const EstimateItemHistoryEntry({
    required this.createdAt,
    required this.action,
    this.userName,
    this.changes = const {},
  });

  /// Время правки.
  final DateTime createdAt;

  /// Код действия (`updated`).
  final String action;

  /// Короткое ФИО автора правки.
  final String? userName;

  /// Изменённые поля: ключ колонки → старое и новое значение.
  final Map<String, EstimateItemFieldChange> changes;
}

/// Одно изменённое поле позиции сметы.
class EstimateItemFieldChange {
  /// Создаёт описание изменения поля.
  const EstimateItemFieldChange({
    required this.from,
    required this.to,
  });

  /// Значение до правки.
  final Object? from;

  /// Значение после правки.
  final Object? to;
}
