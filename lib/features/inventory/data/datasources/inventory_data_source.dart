import 'package:projectgt/features/inventory/data/models/inventory_item_model.dart';

/// Абстракция для источника данных по ТМЦ.
///
/// Определяет контракт для получения, создания, обновления и удаления ТМЦ.
abstract class InventoryDataSource {
  /// Получает список всех ТМЦ.
  Future<List<InventoryItemModel>> getInventoryItems();

  /// Получает ТМЦ по идентификатору.
  Future<InventoryItemModel?> getInventoryItem(String id);

  /// Создаёт новую единицу ТМЦ.
  Future<InventoryItemModel> createInventoryItem(InventoryItemModel item);

  /// Обновляет существующую единицу ТМЦ.
  Future<InventoryItemModel> updateInventoryItem(InventoryItemModel item);

  /// Удаляет ТМЦ по идентификатору.
  Future<void> deleteInventoryItem(String id);

  /// Получает список всех уникальных единиц измерения из БД.
  Future<List<String>> getUnits();

  /// Получает список поставщиков для выпадающего списка.
  Future<List<Map<String, dynamic>>> getSuppliersForDropdown();
}

