import 'package:projectgt/features/inventory/domain/entities/inventory_item.dart';

/// Модель строки позиции накладной для редактирования.
class ReceiptItemRow {
  /// Наименование позиции.
  String name;

  /// Идентификатор категории ТМЦ.
  String categoryId;

  /// Отображаемое имя категории.
  String categoryName;

  /// Единица измерения (шт., м, кг).
  String unit;

  /// Количество ТМЦ.
  double quantity;

  /// Цена за единицу.
  double? price;

  /// Серийный номер (если требуется).
  String? serialNumber;

  /// Дополнительные примечания.
  String? notes;

  /// Статус ТМЦ на момент прихода.
  InventoryItemStatus status;

  /// Срок службы в месяцах (для категорий со сроком эксплуатации).
  int? serviceLifeMonths;

  /// Создаёт модель строки позиции накладной.
  ReceiptItemRow({
    this.name = '',
    this.categoryId = '',
    this.categoryName = '',
    this.unit = '',
    this.quantity = 1,
    this.price,
    this.serialNumber,
    this.notes,
    this.status = InventoryItemStatus.new_,
    this.serviceLifeMonths,
  });
}
