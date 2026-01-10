import 'package:freezed_annotation/freezed_annotation.dart';

part 'work_item.freezed.dart';
part 'work_item.g.dart';

/// Сущность "Работа в смене".
///
/// Описывает отдельную работу, выполненную в рамках смены, с деталями по смете, секции, этажу и т.д.
@freezed
abstract class WorkItem with _$WorkItem {
  /// Создаёт сущность работы в смене.
  ///
  /// [id] — идентификатор работы
  /// [workId] — идентификатор смены
  /// [section] — секция
  /// [floor] — этаж
  /// [estimateId] — идентификатор сметы
  /// [name] — наименование работы
  /// [system] — система
  /// [subsystem] — подсистема
  /// [unit] — единица измерения
  /// [quantity] — объём/количество
  /// [price] — цена за единицу (опционально)
  /// [total] — итоговая сумма (опционально)
  /// [createdAt] — дата создания записи (опционально)
  /// [updatedAt] — дата последнего обновления (опционально)
  const factory WorkItem({
    /// Идентификатор работы.
    required String id,

    /// Идентификатор компании.
    required String companyId,

    /// Идентификатор смены.
    required String workId,

    /// Секция.
    required String section,

    /// Этаж.
    required String floor,

    /// Идентификатор сметы.
    required String estimateId,

    /// Наименование работы.
    required String name,

    /// Система.
    required String system,

    /// Подсистема.
    required String subsystem,

    /// Единица измерения.
    required String unit,

    /// Объём/количество.
    required num quantity,

    /// Цена за единицу.
    double? price,

    /// Итоговая сумма.
    double? total,

    /// Дата создания записи.
    DateTime? createdAt,

    /// Дата последнего обновления.
    DateTime? updatedAt,

    /// Идентификатор акта КС-2 (если работа закрыта актом).
    String? ks2Id,
  }) = _WorkItem;

  /// Создаёт сущность из JSON.
  factory WorkItem.fromJson(Map<String, dynamic> json) =>
      _$WorkItemFromJson(json);
}
