/// Строка остатка ТМЦ на складе.
class TmcStockBalance {
  /// Id позиции каталога.
  final String itemId;

  /// Наименование позиции.
  final String itemName;

  /// Тип учёта (individual / quantitative).
  final String accountingType;

  /// Единица измерения.
  final String unitOfMeasure;

  /// Id склада.
  final String? warehouseId;

  /// Название склада.
  final String? warehouseName;

  /// Тип места (warehouse / office).
  final String locationType;

  /// Количество.
  final double quantity;

  /// Id единицы (для индивидуального учёта).
  final String? unitId;

  /// Инвентарный номер.
  final String? inventoryNumber;

  /// Статус единицы.
  final String? unitStatus;

  /// Создаёт [TmcStockBalance].
  const TmcStockBalance({
    required this.itemId,
    required this.itemName,
    required this.accountingType,
    required this.unitOfMeasure,
    this.warehouseId,
    this.warehouseName,
    required this.locationType,
    required this.quantity,
    this.unitId,
    this.inventoryNumber,
    this.unitStatus,
  });
}
