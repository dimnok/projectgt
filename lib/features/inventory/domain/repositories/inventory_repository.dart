import '../entities/inventory_item.dart';

/// Репозиторий для работы с ТМЦ.
///
/// Определяет контракт для получения, создания, обновления и удаления ТМЦ.
abstract class InventoryRepository {
  /// Получает список всех ТМЦ.
  ///
  /// Возвращает список [InventoryItem].
  Future<List<InventoryItem>> getInventoryItems();

  /// Получает ТМЦ по идентификатору.
  ///
  /// [id] — идентификатор ТМЦ.
  /// Возвращает [InventoryItem], если найден, иначе null.
  Future<InventoryItem?> getInventoryItem(String id);

  /// Создаёт новую единицу ТМЦ.
  ///
  /// [item] — ТМЦ для создания.
  /// Возвращает созданный [InventoryItem].
  Future<InventoryItem> createInventoryItem(InventoryItem item);

  /// Обновляет существующую единицу ТМЦ.
  ///
  /// [item] — ТМЦ для обновления.
  /// Возвращает обновлённый [InventoryItem].
  Future<InventoryItem> updateInventoryItem(InventoryItem item);

  /// Удаляет ТМЦ по идентификатору.
  ///
  /// [id] — идентификатор ТМЦ.
  Future<void> deleteInventoryItem(String id);

  /// Получает список всех уникальных единиц измерения из БД.
  Future<List<String>> getUnits();
}

