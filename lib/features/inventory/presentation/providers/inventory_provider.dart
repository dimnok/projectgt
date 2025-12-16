import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:projectgt/features/inventory/data/datasources/inventory_data_source.dart';
import 'package:projectgt/features/inventory/data/datasources/inventory_data_source_impl.dart';
import 'package:projectgt/features/inventory/data/repositories/inventory_repository_impl.dart';
import 'package:projectgt/features/inventory/domain/entities/inventory_item.dart';
import 'package:projectgt/features/inventory/domain/repositories/inventory_repository.dart';

/// Провайдер для [InventoryDataSource].
final inventoryDataSourceProvider = Provider<InventoryDataSource>((ref) {
  final client = Supabase.instance.client;
  return SupabaseInventoryDataSource(client);
});

/// Провайдер для [InventoryRepository].
final inventoryRepositoryProvider = Provider<InventoryRepository>((ref) {
  final dataSource = ref.watch(inventoryDataSourceProvider);
  return InventoryRepositoryImpl(dataSource);
});

/// Провайдер для списка всех ТМЦ с обогащением данными категорий.
final inventoryItemsProvider = FutureProvider<List<InventoryItem>>((ref) async {
  final repository = ref.watch(inventoryRepositoryProvider);
  final items = await repository.getInventoryItems();

  // Загружаем категории для обогащения данных
  final client = Supabase.instance.client;
  final categoriesResponse =
      await client.from('inventory_categories').select('id, name');

  final categoriesMap = <String, String>{};
  for (final cat in categoriesResponse) {
    categoriesMap[cat['id'] as String] = cat['name'] as String;
  }

  // Обогащаем ТМЦ названиями категорий
  return items.map((item) {
    return item.copyWith(
      categoryName: categoriesMap[item.categoryId],
    );
  }).toList();
});
