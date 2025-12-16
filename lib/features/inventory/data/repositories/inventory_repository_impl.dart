import 'package:projectgt/features/inventory/data/datasources/inventory_data_source.dart';
import 'package:projectgt/features/inventory/data/models/inventory_item_model.dart';
import 'package:projectgt/features/inventory/domain/entities/inventory_item.dart';
import 'package:projectgt/features/inventory/domain/repositories/inventory_repository.dart';

/// Имплементация [InventoryRepository] для работы с ТМЦ через data source.
///
/// Инкапсулирует преобразование моделей и делегирует вызовы data-слою.
class InventoryRepositoryImpl implements InventoryRepository {
  /// Источник данных для работы с ТМЦ.
  final InventoryDataSource dataSource;

  /// Создаёт [InventoryRepositoryImpl] с указанным [dataSource].
  InventoryRepositoryImpl(this.dataSource);

  @override
  Future<List<InventoryItem>> getInventoryItems() async {
    final models = await dataSource.getInventoryItems();
    return models.map((model) => model.toDomain()).toList();
  }

  @override
  Future<InventoryItem?> getInventoryItem(String id) async {
    final model = await dataSource.getInventoryItem(id);
    return model?.toDomain();
  }

  @override
  Future<InventoryItem> createInventoryItem(InventoryItem item) async {
    final model = await dataSource
        .createInventoryItem(InventoryItemModel.fromDomain(item));
    return model.toDomain();
  }

  @override
  Future<InventoryItem> updateInventoryItem(InventoryItem item) async {
    final model = await dataSource
        .updateInventoryItem(InventoryItemModel.fromDomain(item));
    return model.toDomain();
  }

  @override
  Future<void> deleteInventoryItem(String id) async {
    await dataSource.deleteInventoryItem(id);
  }

  @override
  Future<List<String>> getUnits() async {
    return await dataSource.getUnits();
  }

  @override
  Future<List<Map<String, dynamic>>> getSuppliersForDropdown() async {
    return await dataSource.getSuppliersForDropdown();
  }
}
