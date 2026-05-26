/// Тип изменения состава ВОР при пересчёте.
enum VorRecalcChangeType {
  /// Позиция появилась в новом расчёте.
  added,

  /// Позиция исчезла из нового расчёта.
  removed,

  /// Изменился объём (или единица/признак превышения).
  modified,
}

/// Одна строка отличия между сохранённым составом ВОР и актуальным расчётом.
class VorRecalcChange {
  /// Тип изменения.
  final VorRecalcChangeType changeType;

  /// Раздел (инженерная система из сметы).
  final String section;

  /// Наименование позиции для отображения.
  final String rowLabel;

  /// Единица измерения.
  final String unit;

  /// Объём до пересчёта.
  final double? oldQuantity;

  /// Суммарный объём после пересчёта (норма + превышение).
  final double? newQuantity;

  /// Объём по смете до пересчёта.
  final double? oldNorm;

  /// Объём по смете после пересчёта.
  final double? newNorm;

  /// Превышение до пересчёта.
  final double? oldExtra;

  /// Превышение после пересчёта.
  final double? newExtra;

  /// Создаёт [VorRecalcChange].
  const VorRecalcChange({
    required this.changeType,
    required this.section,
    required this.rowLabel,
    required this.unit,
    this.oldQuantity,
    this.newQuantity,
    this.oldNorm,
    this.newNorm,
    this.oldExtra,
    this.newExtra,
  });

  /// Разбирает объект из ответа RPC `get_vor_recalc_changes`.
  factory VorRecalcChange.fromJson(Map<String, dynamic> json) {
    return VorRecalcChange(
      changeType: _parseChangeType(json['change_type'] as String?),
      section: json['section'] as String? ?? 'Без системы',
      rowLabel: json['row_label'] as String? ?? '',
      unit: json['unit'] as String? ?? '',
      oldQuantity: _parseQuantity(json['old_quantity']),
      newQuantity: _parseQuantity(json['new_quantity']),
      oldNorm: _parseQuantity(json['old_norm']),
      newNorm: _parseQuantity(json['new_norm']),
      oldExtra: _parseQuantity(json['old_extra']),
      newExtra: _parseQuantity(json['new_extra']),
    );
  }

  /// Есть ли отдельная составляющая превышения.
  bool get hasExtraComponent =>
      (oldExtra ?? 0) > 0 || (newExtra ?? 0) > 0;
}

VorRecalcChangeType _parseChangeType(String? raw) {
  switch (raw) {
    case 'added':
      return VorRecalcChangeType.added;
    case 'removed':
      return VorRecalcChangeType.removed;
    case 'modified':
    default:
      return VorRecalcChangeType.modified;
  }
}

double? _parseQuantity(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString());
}

/// Сводка изменений, сгруппированная по разделам.
class VorRecalcPreview {
  /// Список всех отличий.
  final List<VorRecalcChange> changes;

  /// Создаёт [VorRecalcPreview].
  const VorRecalcPreview({required this.changes});

  /// Пустая сводка (расхождений нет).
  static const empty = VorRecalcPreview(changes: []);

  /// Группировка по разделу (системе).
  Map<String, List<VorRecalcChange>> get groupedBySection {
    final map = <String, List<VorRecalcChange>>{};
    for (final change in changes) {
      map.putIfAbsent(change.section, () => []).add(change);
    }
    return map;
  }

  /// Есть ли хотя бы одно отличие.
  bool get hasChanges => changes.isNotEmpty;
}
