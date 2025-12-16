import 'package:projectgt/features/inventory/data/models/inventory_receipt_model.dart';
import 'package:projectgt/features/inventory/data/models/inventory_receipt_item_model.dart';
import 'package:projectgt/features/inventory/data/models/inventory_item_model.dart';
import 'package:projectgt/features/inventory/domain/entities/inventory_item.dart';

/// Абстракция для источника данных по накладным прихода ТМЦ.
abstract class InventoryReceiptDataSource {
  /// Создаёт накладную прихода с позициями и ТМЦ.
  ///
  /// [receipt] - данные накладной
  /// [items] - список позиций накладной
  /// [itemStatuses] - Map со статусами для каждой позиции (ключ - id позиции, значение - InventoryItemStatus)
  /// [itemServiceLives] - Map со сроками службы для каждой позиции (ключ - id позиции, значение - срок в месяцах или null)
  ///
  /// Возвращает созданную накладную с заполненными полями.
  Future<InventoryReceiptModel> createReceipt(
    InventoryReceiptModel receipt,
    List<InventoryReceiptItemModel> items,
    Map<String, InventoryItemStatus> itemStatuses,
    Map<String, int?> itemServiceLives,
  );

  /// Создаёт единицы ТМЦ из позиции накладной.
  ///
  /// [receiptItem] - позиция накладной
  /// [receiptId] - ID накладной
  /// [receiptDate] - дата накладной
  /// [status] - статус ТМЦ (InventoryItemStatus)
  /// [serviceLifeMonths] - срок службы в месяцах (null если не указан)
  ///
  /// Создаёт [quantity] единиц ТМЦ для позиции.
  Future<List<InventoryItemModel>> createInventoryItemsFromReceiptItem(
    InventoryReceiptItemModel receiptItem,
    String receiptId,
    DateTime receiptDate,
    InventoryItemStatus status,
    int? serviceLifeMonths,
  );
}
