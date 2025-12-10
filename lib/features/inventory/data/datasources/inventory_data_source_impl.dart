import 'package:logger/logger.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:projectgt/features/inventory/data/datasources/inventory_data_source.dart';
import 'package:projectgt/features/inventory/data/models/inventory_item_model.dart';

/// Реализация [InventoryDataSource] через Supabase.
///
/// Использует Supabase для CRUD-операций с таблицей inventory_items.
class SupabaseInventoryDataSource implements InventoryDataSource {
  /// Клиент Supabase для выполнения запросов к базе данных.
  final SupabaseClient client;

  /// Создаёт [SupabaseInventoryDataSource] с указанным [client].
  SupabaseInventoryDataSource(this.client);

  @override
  Future<List<InventoryItemModel>> getInventoryItems() async {
    try {
      // Загружаем ТМЦ
      final response = await client
          .from('inventory_items')
          .select('*')
          .order('created_at', ascending: false);

      return response.map<InventoryItemModel>((json) {
        return InventoryItemModel.fromJson(json);
      }).toList();
    } catch (e) {
      Logger().e('Error fetching inventory items: $e');
      return [];
    }
  }

  @override
  Future<InventoryItemModel?> getInventoryItem(String id) async {
    try {
      final response = await client
          .from('inventory_items')
          .select('*')
          .eq('id', id)
          .maybeSingle();

      if (response == null) return null;
      return InventoryItemModel.fromJson(response);
    } catch (e) {
      Logger().e('Error fetching inventory item: $e');
      return null;
    }
  }

  @override
  Future<InventoryItemModel> createInventoryItem(
      InventoryItemModel item) async {
    try {
      final itemJson = item.toJson();
      // Удаляем id для новых записей - Supabase сгенерирует его автоматически
      itemJson.remove('id');

      final response = await client
          .from('inventory_items')
          .insert(itemJson)
          .select('*')
          .single();

      return InventoryItemModel.fromJson(response);
    } catch (e) {
      Logger().e('Error creating inventory item: $e');
      rethrow;
    }
  }

  @override
  Future<InventoryItemModel> updateInventoryItem(
      InventoryItemModel item) async {
    try {
      if (item.id.isEmpty) {
        throw Exception('Cannot update item without ID');
      }
      
      final itemJson = item.toJson();
      // Удаляем поля, которые не должны обновляться
      itemJson.remove('id'); // ID не может быть изменён
      itemJson.remove('created_at');
      itemJson.remove('created_by');

      final response = await client
          .from('inventory_items')
          .update(itemJson)
          .eq('id', item.id)
          .select('*')
          .single();

      return InventoryItemModel.fromJson(response);
    } catch (e) {
      Logger().e('Error updating inventory item: $e');
      rethrow;
    }
  }

  @override
  Future<void> deleteInventoryItem(String id) async {
    try {
      await client.from('inventory_items').delete().eq('id', id);
    } catch (e) {
      Logger().e('Error deleting inventory item: $e');
      rethrow;
    }
  }


  @override
  Future<List<String>> getUnits() async {
    try {
      final data = await client
          .from('inventory_items')
          .select('unit')
          .not('unit', 'is', null);

      final units = <String>{};
      for (final row in data as List) {
        final unit = row['unit']?.toString().trim();
        if (unit != null && unit.isNotEmpty) {
          units.add(unit);
        }
      }
      return units.toList()..sort();
    } catch (e) {
      Logger().e('Error fetching units: $e');
      return [];
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getSuppliersForDropdown() async {
    try {
      final response = await client.rpc('get_suppliers_for_dropdown');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      Logger().e('Error fetching suppliers for dropdown: $e');
      return [];
    }
  }
}
