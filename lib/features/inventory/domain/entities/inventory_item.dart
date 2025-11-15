import 'package:freezed_annotation/freezed_annotation.dart';

part 'inventory_item.freezed.dart';

/// Статус ТМЦ.
enum InventoryItemStatus {
  /// Новый.
  new_,
  /// Хорошее состояние.
  good,
  /// Сломан.
  broken,
  /// Списан.
  writtenOff,
  /// В ремонте.
  repair,
  /// Критическое состояние.
  critical,
}

/// Состояние ТМЦ при приходе.
enum InventoryItemCondition {
  /// Новый.
  new_,
  /// Б/у.
  used,
}

/// Тип местоположения ТМЦ.
enum InventoryLocationType {
  /// На складе.
  warehouse,
  /// На объекте.
  object,
  /// У сотрудника.
  employee,
}

/// Сущность "ТМЦ" (доменная модель).
///
/// Описывает единицу товарно-материальных ценностей с полной информацией.
@freezed
abstract class InventoryItem with _$InventoryItem {
  /// Основной конструктор [InventoryItem].
  const factory InventoryItem({
    /// Уникальный идентификатор ТМЦ.
    required String id,

    /// Наименование ТМЦ.
    required String name,

    /// ID категории.
    required String categoryId,

    /// Название категории (для отображения).
    String? categoryName,

    /// Серийный номер.
    String? serialNumber,

    /// Единица измерения.
    required String unit,

    /// Количество единиц ТМЦ.
    @Default(1.0) double quantity,

    /// URL фотографии.
    String? photoUrl,

    /// Статус ТМЦ.
    @Default(InventoryItemStatus.new_) InventoryItemStatus status,

    /// Состояние при приходе.
    @Default(InventoryItemCondition.new_) InventoryItemCondition condition,

    /// Тип местоположения.
    @Default(InventoryLocationType.warehouse) InventoryLocationType locationType,

    /// ID местоположения (объект или сотрудник).
    String? locationId,

    /// Название местоположения (для отображения).
    String? locationName,

    /// ID ответственного лица.
    String? responsibleId,

    /// Имя ответственного (для отображения).
    String? responsibleName,

    /// ID накладной прихода.
    String? receiptId,

    /// ID позиции накладной.
    String? receiptItemId,

    /// Цена за единицу.
    double? price,

    /// Дата приобретения.
    DateTime? purchaseDate,

    /// Дата окончания гарантии.
    DateTime? warrantyExpiresAt,

    /// Срок службы в месяцах.
    int? serviceLifeMonths,

    /// Дата выдачи.
    DateTime? issuedAt,

    /// Примечания.
    String? notes,

    /// Дата создания.
    DateTime? createdAt,

    /// Дата обновления.
    DateTime? updatedAt,

    /// Кто создал.
    String? createdBy,

    /// Кто обновил.
    String? updatedBy,
  }) = _InventoryItem;
}

