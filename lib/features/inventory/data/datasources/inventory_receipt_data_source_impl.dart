import 'package:logger/logger.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:projectgt/features/inventory/data/datasources/inventory_receipt_data_source.dart';
import 'package:projectgt/features/inventory/data/models/inventory_receipt_model.dart';
import 'package:projectgt/features/inventory/data/models/inventory_receipt_item_model.dart';
import 'package:projectgt/features/inventory/data/models/inventory_item_model.dart';
import 'package:projectgt/features/inventory/domain/entities/inventory_item.dart';

/// Реализация [InventoryReceiptDataSource] через Supabase.
class SupabaseInventoryReceiptDataSource implements InventoryReceiptDataSource {
  /// Клиент Supabase для выполнения запросов к базе данных.
  final SupabaseClient client;

  /// Создаёт [SupabaseInventoryReceiptDataSource] с указанным [client].
  SupabaseInventoryReceiptDataSource(this.client);

  @override
  Future<InventoryReceiptModel> createReceipt(
    InventoryReceiptModel receipt,
    List<InventoryReceiptItemModel> items,
    Map<String, InventoryItemStatus> itemStatuses,
    Map<String, int?> itemServiceLives,
  ) async {
    try {
      // Вычисляем общую сумму и количество позиций
      final totalAmount = items
          .map((item) => item.total ?? 0.0)
          .fold(0.0, (sum, total) => sum + total);
      final itemsCount = items.length;

      // Создаём накладную
      final receiptJson = receipt
          .copyWith(
            totalAmount: totalAmount,
            itemsCount: itemsCount,
          )
          .toJson();
      receiptJson.remove('items'); // Убираем items из JSON
      // Убираем поля с датами, чтобы использовались значения по умолчанию из БД
      receiptJson.remove('created_at');
      receiptJson.remove('updated_at');

      final receiptResponse = await client
          .from('inventory_receipts')
          .insert(receiptJson)
          .select('*')
          .single();

      final createdReceipt = InventoryReceiptModel.fromJson(receiptResponse);
      final receiptId = createdReceipt.id;

      // Создаём позиции накладной
      final itemsToInsert = items.map((item) {
        final itemJson = item.copyWith(receiptId: receiptId).toJson();
        // Убираем created_at, чтобы использовалось значение по умолчанию из БД
        itemJson.remove('created_at');
        return itemJson;
      }).toList();

      final itemsResponse = await client
          .from('inventory_receipt_items')
          .insert(itemsToInsert)
          .select('*');

      final createdItems = (itemsResponse as List)
          .map((json) => InventoryReceiptItemModel.fromJson(json))
          .toList();

      // Создаём ТМЦ из позиций накладной
      final allInventoryItems = <InventoryItemModel>[];
      for (final item in createdItems) {
        final status = itemStatuses[item.id] ??
            InventoryItemStatus.new_; // Получаем статус по id позиции
        final serviceLifeMonths =
            itemServiceLives[item.id]; // Получаем срок службы по id позиции
        final inventoryItems = await createInventoryItemsFromReceiptItem(
          item,
          receiptId,
          receipt.receiptDate,
          status,
          serviceLifeMonths,
        );
        allInventoryItems.addAll(inventoryItems);
      }

      return createdReceipt.copyWith(items: createdItems);
    } catch (e) {
      Logger().e('Error creating receipt: $e');
      rethrow;
    }
  }

  @override
  Future<List<InventoryItemModel>> createInventoryItemsFromReceiptItem(
    InventoryReceiptItemModel receiptItem,
    String receiptId,
    DateTime receiptDate,
    InventoryItemStatus status,
    int? serviceLifeMonths,
  ) async {
    try {
      // Получаем информацию о категории (нужен ли серийный номер)
      final categoryInfoResponse = await client
          .from('inventory_categories')
          .select('serial_number_required')
          .eq('id', receiptItem.categoryId)
          .maybeSingle();

      if (categoryInfoResponse == null) {
        throw Exception(
            'Категория товара не найдена (id: ${receiptItem.categoryId})');
      }

      final serialNumberRequired =
          categoryInfoResponse['serial_number_required'] as bool? ?? false;

      final quantity = receiptItem.quantity;

      // Проверяем обязательность серийного номера
      if (serialNumberRequired && receiptItem.serialNumber == null) {
        throw Exception(
          'Серийный номер обязателен для категории "${receiptItem.name}"',
        );
      }

      // Создаём ОДНУ запись с указанным количеством
      final item = InventoryItemModel(
        id: const Uuid().v4(),
        name: receiptItem.name,
        categoryId: receiptItem.categoryId,
        serialNumber: receiptItem.serialNumber,
        unit: receiptItem.unit,
        quantity: quantity,
        photoUrl: receiptItem.photoUrl,
        status: InventoryItemModel.statusToString(status),
        condition: 'new',
        locationType: 'warehouse',
        locationId: null,
        responsibleId: null,
        receiptId: receiptId,
        receiptItemId: receiptItem.id,
        price: receiptItem.price,
        purchaseDate: receiptDate,
        serviceLifeMonths: serviceLifeMonths,
        notes: receiptItem.notes,
      );

      // Вставляем ТМЦ в БД
      final itemJson = item.toJson();
      // Убираем created_at и updated_at, чтобы использовались значения по умолчанию из БД
      itemJson.remove('created_at');
      itemJson.remove('updated_at');
      await client.from('inventory_items').insert(itemJson);

      return [item];
    } catch (e) {
      Logger().e('Error creating inventory items from receipt item: $e');
      rethrow;
    }
  }
}
