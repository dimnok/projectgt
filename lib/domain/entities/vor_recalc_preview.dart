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

/// Строка списка в окне пересчёта (после объединения пар «удалено + добавлено»).
sealed class VorRecalcListEntry {
  const VorRecalcListEntry();
}

/// Изменение объёма, новая или удалённая позиция.
final class VorRecalcVolumeEntry extends VorRecalcListEntry {
  /// Создаёт [VorRecalcVolumeEntry].
  const VorRecalcVolumeEntry(this.change);

  /// Исходное отличие из RPC.
  final VorRecalcChange change;
}

/// Одинаковый объём, расходятся реквизиты строки (единица, написание в БД).
final class VorRecalcMetadataSyncEntry extends VorRecalcListEntry {
  /// Создаёт [VorRecalcMetadataSyncEntry].
  const VorRecalcMetadataSyncEntry({
    required this.section,
    required this.rowLabel,
    required this.quantity,
    required this.vorUnit,
    required this.journalUnit,
  });

  /// Раздел (система).
  final String section;

  /// Подпись позиции для списка.
  final String rowLabel;

  /// Объём (не меняется).
  final double quantity;

  /// Единица в сохранённой ведомости.
  final String vorUnit;

  /// Единица в журнале работ.
  final String journalUnit;

  /// Текст подсказки при наведении.
  String get tooltipMessage {
    final buffer = StringBuffer(
      'Объём без изменений: ${_formatQty(quantity)}.',
    );
    if (vorUnit.isNotEmpty &&
        journalUnit.isNotEmpty &&
        vorUnit != journalUnit) {
      buffer
        ..writeln()
        ..write('В ведомости: «$vorUnit».')
        ..writeln()
        ..write('В журнале: «$journalUnit».');
    } else if (vorUnit.isNotEmpty || journalUnit.isNotEmpty) {
      final vor = vorUnit.isNotEmpty ? vorUnit : '—';
      final journal = journalUnit.isNotEmpty ? journalUnit : '—';
      buffer
        ..writeln()
        ..write('В ведомости: «$vor».')
        ..writeln()
        ..write('В журнале: «$journal».');
    } else {
      buffer.writeln();
      buffer.write(
        'Отличается оформление строки; при пересчёте подтянутся данные журнала.',
      );
    }
    return buffer.toString();
  }

  static String _formatQty(double value) {
    if (value == value.roundToDouble()) {
      return value.toStringAsFixed(0);
    }
    return value.toString();
  }
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

  /// Элементы для UI: пары «удалено + добавлено» с тем же объёмом свёрнуты.
  List<VorRecalcListEntry> get displayEntries => buildDisplayEntries(changes);

  /// Группировка [displayEntries] по разделу.
  Map<String, List<VorRecalcListEntry>> get groupedDisplayEntries {
    final map = <String, List<VorRecalcListEntry>>{};
    for (final entry in displayEntries) {
      final section = switch (entry) {
        VorRecalcVolumeEntry(:final change) => change.section,
        VorRecalcMetadataSyncEntry(:final section) => section,
      };
      map.putIfAbsent(section, () => []).add(entry);
    }
    return map;
  }

  /// Есть ли хотя бы одно отличие.
  bool get hasChanges => changes.isNotEmpty;

  /// Объединяет пары removed+added с одинаковым объёмом в [VorRecalcMetadataSyncEntry].
  static List<VorRecalcListEntry> buildDisplayEntries(
    List<VorRecalcChange> rawChanges,
  ) {
    final remaining = List<VorRecalcChange>.from(rawChanges);
    final used = <int>{};
    final entries = <VorRecalcListEntry>[];

    for (var i = 0; i < remaining.length; i++) {
      if (used.contains(i)) continue;
      final removed = remaining[i];
      if (removed.changeType != VorRecalcChangeType.removed) continue;

      for (var j = 0; j < remaining.length; j++) {
        if (i == j || used.contains(j)) continue;
        final added = remaining[j];
        if (added.changeType != VorRecalcChangeType.added) continue;
        if (!_isMetadataSyncPair(removed, added)) continue;

        used
          ..add(i)
          ..add(j);
        entries.add(
          VorRecalcMetadataSyncEntry(
            section: removed.section,
            rowLabel: removed.rowLabel,
            quantity: removed.oldQuantity ?? added.newQuantity ?? 0,
            vorUnit: removed.unit,
            journalUnit: added.unit,
          ),
        );
        break;
      }
    }

    for (var i = 0; i < remaining.length; i++) {
      if (used.contains(i)) continue;
      entries.add(VorRecalcVolumeEntry(remaining[i]));
    }

    return entries;
  }

  static bool _isMetadataSyncPair(
    VorRecalcChange removed,
    VorRecalcChange added,
  ) {
    return removed.section == added.section &&
        removed.rowLabel == added.rowLabel &&
        _quantitiesMatch(removed.oldQuantity, added.newQuantity);
  }

  static bool _quantitiesMatch(double? a, double? b) {
    if (a == null || b == null) return false;
    return (a - b).abs() < 1e-6;
  }
}
