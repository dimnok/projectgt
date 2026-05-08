/// Строка шаблона массового обновления сметы.
///
/// Содержит служебные идентификаторы из `estimates`, чтобы Excel можно было
/// загрузить обратно без потери связей с фактами, ВОР и подрядчиками.
class EstimateBulkUpdateTemplateRow {
  /// Первичный ключ строки в `estimates`.
  final String id;

  /// Сквозной идентификатор позиции.
  final String positionId;

  /// Время последнего обновления строки для optimistic locking.
  final DateTime updatedAt;

  /// Система.
  final String system;

  /// Подсистема.
  final String subsystem;

  /// Номер позиции.
  final String number;

  /// Наименование.
  final String name;

  /// Артикул.
  final String article;

  /// Производитель.
  final String manufacturer;

  /// Единица измерения.
  final String unit;

  /// Количество.
  final double quantity;

  /// Цена.
  final double price;

  /// Сумма.
  final double total;

  /// Создаёт строку шаблона массового обновления.
  const EstimateBulkUpdateTemplateRow({
    required this.id,
    required this.positionId,
    required this.updatedAt,
    required this.system,
    required this.subsystem,
    required this.number,
    required this.name,
    required this.article,
    required this.manufacturer,
    required this.unit,
    required this.quantity,
    required this.price,
    required this.total,
  });
}

/// Строка, прочитанная из Excel-файла массового обновления.
class EstimateBulkUpdateImportRow {
  /// Номер строки в Excel.
  final int rowNo;

  /// Первичный ключ строки в `estimates`; пустой означает новую строку.
  final String? id;

  /// Сквозной идентификатор позиции.
  final String? positionId;

  /// Значение `updated_at` на момент выгрузки шаблона.
  final DateTime? updatedAt;

  /// Система.
  final String system;

  /// Подсистема.
  final String subsystem;

  /// Номер позиции.
  final String number;

  /// Наименование.
  final String name;

  /// Артикул.
  final String article;

  /// Производитель.
  final String manufacturer;

  /// Единица измерения.
  final String unit;

  /// Количество.
  final double quantity;

  /// Цена.
  final double price;

  /// Создаёт строку импорта массового обновления.
  const EstimateBulkUpdateImportRow({
    required this.rowNo,
    required this.id,
    required this.positionId,
    required this.updatedAt,
    required this.system,
    required this.subsystem,
    required this.number,
    required this.name,
    required this.article,
    required this.manufacturer,
    required this.unit,
    required this.quantity,
    required this.price,
  });

  /// Преобразует строку в JSON для RPC `apply_estimate_bulk_update`.
  Map<String, dynamic> toRpcJson() {
    return {
      'id': id,
      'position_id': positionId,
      'updated_at': updatedAt?.toIso8601String(),
      'system': system,
      'subsystem': subsystem,
      'number': number,
      'name': name,
      'article': article,
      'manufacturer': manufacturer,
      'unit': unit,
      'quantity': quantity,
      'price': price,
    };
  }
}

/// Краткая сводка preview/apply массового обновления.
class EstimateBulkUpdateSummary {
  /// Всего строк в файле.
  final int total;

  /// Строк будет/было обновлено.
  final int updated;

  /// Строк будет/было добавлено.
  final int inserted;

  /// Строк пропущено.
  final int skipped;

  /// Количество конфликтов.
  final int conflicts;

  /// Создаёт сводку массового обновления.
  const EstimateBulkUpdateSummary({
    required this.total,
    required this.updated,
    required this.inserted,
    required this.skipped,
    required this.conflicts,
  });

  /// Создаёт сводку из JSON ответа RPC.
  factory EstimateBulkUpdateSummary.fromJson(Map<String, dynamic> json) {
    int toInt(Object? value) => value is num ? value.toInt() : 0;
    return EstimateBulkUpdateSummary(
      total: toInt(json['total']),
      updated: toInt(json['updated']),
      inserted: toInt(json['inserted']),
      skipped: toInt(json['skipped']),
      conflicts: toInt(json['conflicts']),
    );
  }
}

/// Одна строка результата preview/apply.
class EstimateBulkUpdateResultItem {
  /// Номер строки в Excel.
  final int rowNo;

  /// Действие: update/insert/noop/invalid/conflict.
  final String action;

  /// Статус: applied/skipped/conflict.
  final String status;

  /// Сообщение для пользователя.
  final String message;

  /// Создаёт строку результата массового обновления.
  const EstimateBulkUpdateResultItem({
    required this.rowNo,
    required this.action,
    required this.status,
    required this.message,
  });

  /// Создаёт строку результата из JSON ответа RPC.
  factory EstimateBulkUpdateResultItem.fromJson(Map<String, dynamic> json) {
    return EstimateBulkUpdateResultItem(
      rowNo: (json['row_no'] as num?)?.toInt() ?? 0,
      action: json['action']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
    );
  }
}

/// Результат preview/apply массового обновления сметы.
class EstimateBulkUpdateResult {
  /// Был ли это dry-run.
  final bool dryRun;

  /// Применил ли сервер изменения.
  final bool applied;

  /// ID audit batch после применения.
  final String? batchId;

  /// Сообщение верхнего уровня.
  final String? message;

  /// Сводка.
  final EstimateBulkUpdateSummary summary;

  /// Детали по строкам.
  final List<EstimateBulkUpdateResultItem> items;

  /// Создаёт результат массового обновления.
  const EstimateBulkUpdateResult({
    required this.dryRun,
    required this.applied,
    required this.summary,
    required this.items,
    this.batchId,
    this.message,
  });

  /// Создаёт результат из JSON ответа RPC.
  factory EstimateBulkUpdateResult.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'];
    return EstimateBulkUpdateResult(
      dryRun: json['dry_run'] == true,
      applied: json['applied'] == true,
      batchId: json['batch_id']?.toString(),
      message: json['message']?.toString(),
      summary: EstimateBulkUpdateSummary.fromJson(
        (json['summary'] as Map?)?.cast<String, dynamic>() ??
            const <String, dynamic>{},
      ),
      items: rawItems is List
          ? rawItems
                .whereType<Map>()
                .map(
                  (e) => EstimateBulkUpdateResultItem.fromJson(
                    e.cast<String, dynamic>(),
                  ),
                )
                .toList()
          : const [],
    );
  }
}
