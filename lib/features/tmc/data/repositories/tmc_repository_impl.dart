import 'package:projectgt/features/tmc/data/models/tmc_assignment_model.dart';
import 'package:projectgt/features/tmc/data/models/tmc_category_model.dart';
import 'package:projectgt/features/tmc/data/models/tmc_condition_model.dart';
import 'package:projectgt/features/tmc/data/models/tmc_dashboard_stats_model.dart';
import 'package:projectgt/features/tmc/data/models/tmc_item_model.dart';
import 'package:projectgt/features/tmc/data/models/tmc_json_utils.dart';
import 'package:projectgt/features/tmc/data/models/tmc_notification_model.dart';
import 'package:projectgt/features/tmc/data/models/tmc_operation_model.dart';
import 'package:projectgt/features/tmc/data/models/tmc_unit_model.dart';
import 'package:projectgt/features/tmc/data/models/tmc_warehouse_model.dart';
import 'package:projectgt/features/tmc/data/models/tmc_write_off_model.dart';
import 'package:projectgt/features/tmc/domain/entities/tmc_assignment.dart';
import 'package:projectgt/features/tmc/domain/entities/tmc_category.dart';
import 'package:projectgt/features/tmc/domain/entities/tmc_condition.dart';
import 'package:projectgt/features/tmc/domain/entities/tmc_dashboard_stats.dart';
import 'package:projectgt/features/tmc/domain/entities/tmc_enums.dart';
import 'package:projectgt/features/tmc/domain/entities/tmc_item.dart';
import 'package:projectgt/features/tmc/domain/entities/tmc_notification.dart';
import 'package:projectgt/features/tmc/domain/entities/tmc_operation.dart';
import 'package:projectgt/features/tmc/domain/entities/tmc_stock_balance.dart';
import 'package:projectgt/features/tmc/domain/entities/tmc_unit.dart';
import 'package:projectgt/features/tmc/domain/entities/tmc_warehouse.dart';
import 'package:projectgt/features/tmc/domain/entities/tmc_write_off.dart';
import 'package:projectgt/features/tmc/domain/repositories/tmc_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Реализация [TmcRepository] через Supabase.
class TmcRepositoryImpl implements TmcRepository {
  /// Клиент Supabase.
  final SupabaseClient client;

  /// Активная компания (пустая строка — запросы не выполняются).
  final String activeCompanyId;

  /// Создаёт репозиторий.
  TmcRepositoryImpl(this.client, this.activeCompanyId);

  bool get _hasCompany => activeCompanyId.isNotEmpty;

  static const _itemSelect = '''
    *,
    tmc_categories:category_id(name),
    subcategory:subcategory_id(name),
    contractors:supplier_id(short_name)
  ''';

  static const _unitSelect = '''
    *,
    tmc_items:item_id(name),
    tmc_conditions:condition_id(name),
    tmc_warehouses:warehouse_id(name),
    objects:object_id(name),
    employees:employee_id(last_name, first_name, middle_name)
  ''';

  static const _operationSelect = '''
    *,
    tmc_operation_items(
      *,
      tmc_items:item_id(name),
      tmc_units:unit_id(inventory_number)
    )
  ''';

  static const _assignmentSelect = '''
    *,
    tmc_items:item_id(name, unit_price),
    tmc_units:unit_id(inventory_number),
    employees:employee_id(last_name, first_name, middle_name),
    objects:object_id(name)
  ''';

  static const _writeOffSelect = '''
    *,
    tmc_items:item_id(name),
    tmc_units:unit_id(inventory_number)
  ''';

  @override
  Future<TmcDashboardStats> getDashboardStats() async {
    if (!_hasCompany) {
      return const TmcDashboardStats();
    }

    final response = await client.rpc(
      'tmc_dashboard_stats',
      params: {'p_company_id': activeCompanyId},
    );

    return TmcDashboardStatsModel.fromJson(
      Map<String, dynamic>.from(response as Map),
    ).toDomain();
  }

  @override
  Future<TmcItemsListResult> listItems({
    String? search,
    String? categoryId,
    TmcAccountingType? accountingType,
    int limit = 50,
    int offset = 0,
  }) async {
    if (!_hasCompany) {
      return (items: <TmcItem>[], totalCount: 0);
    }

    final response = await client.rpc(
      'tmc_list_items',
      params: {
        'p_company_id': activeCompanyId,
        'p_search': search,
        'p_category_id': categoryId,
        'p_accounting_type': accountingType?.dbValue,
        'p_limit': limit,
        'p_offset': offset,
      },
    );

    final rows = response as List;
    if (rows.isEmpty) {
      return (items: <TmcItem>[], totalCount: 0);
    }

    final models = rows.map((row) {
      final map = Map<String, dynamic>.from(row as Map);
      return TmcItem(
        id: map['id'] as String,
        companyId: activeCompanyId,
        name: map['name'] as String,
        accountingType: TmcAccountingType.values.firstWhere(
          (e) => e.dbValue == map['accounting_type'],
        ),
        sku: map['sku'] as String?,
        unitOfMeasure: map['unit_of_measure'] as String? ?? 'шт',
        quantity: tmcParseDouble(map['quantity']),
        qtyInStock: tmcParseDouble(map['qty_in_stock']),
        qtyIssued: tmcParseDouble(map['qty_issued']),
        qtyOnObject: tmcParseDouble(map['qty_on_object']),
        locationSummary: map['location_summary'] as String?,
        unitPrice: tmcParseDouble(map['unit_price']),
        totalCost: tmcParseDouble(map['total_cost']),
        status: TmcItemStatus.values.firstWhere(
          (e) => e.dbValue == map['status'],
        ),
        photoUrl: map['photo_url'] as String?,
        deliveryDate: tmcParseDate(map['delivery_date']),
        createdAt: map['created_at'] == null
            ? null
            : DateTime.parse(map['created_at'] as String),
        categoryName: map['category_name'] as String?,
        subcategoryName: map['subcategory_name'] as String?,
        supplierName: map['supplier_name'] as String?,
      );
    }).toList();

    final totalCount = rows.isEmpty
        ? 0
        : tmcParseInt(
            Map<String, dynamic>.from(rows.first as Map)['total_count'],
          );

    return (items: models, totalCount: totalCount);
  }

  @override
  Future<TmcItem?> getItem(String id) async {
    if (!_hasCompany) return null;

    final row = await client
        .from('tmc_items')
        .select(_itemSelect)
        .eq('id', id)
        .eq('company_id', activeCompanyId)
        .maybeSingle();

    if (row == null) return null;

    final item = TmcItemModel.fromJson(
      Map<String, dynamic>.from(row),
    ).toDomain();

    // Обогащаем остатками из list RPC (одна позиция через stock breakdown).
    final page = await listItems(search: item.name, limit: 100, offset: 0);
    for (final candidate in page.items) {
      if (candidate.id == id) {
        return item.copyWith(
          quantity: candidate.quantity,
          qtyInStock: candidate.qtyInStock,
          qtyIssued: candidate.qtyIssued,
          qtyOnObject: candidate.qtyOnObject,
          locationSummary: candidate.locationSummary,
          totalCost: candidate.totalCost,
        );
      }
    }
    return item;
  }

  @override
  Future<TmcItem> createItem(TmcItem item) async {
    if (!_hasCompany) {
      throw StateError('Не выбрана активная компания');
    }
    final model = TmcItemModel.fromDomain(item);
    final payload = model.toWriteJson(includeId: false);
    payload['company_id'] = activeCompanyId;

    final row = await client
        .from('tmc_items')
        .insert(payload)
        .select(_itemSelect)
        .single();

    return TmcItemModel.fromJson(Map<String, dynamic>.from(row)).toDomain();
  }

  @override
  Future<TmcItem> createItemWithReceipt({
    required TmcItem item,
    double receiveQuantity = 0,
    String? warehouseId,
    double? unitPrice,
    String? conditionId,
    List<String>? serialNumbers,
  }) async {
    if (!_hasCompany) {
      throw StateError('Не выбрана активная компания');
    }

    final model = TmcItemModel.fromDomain(item);
    final itemJson = model.toWriteJson(includeId: false);
    itemJson.remove('company_id');

    final payload = <String, dynamic>{
      'company_id': activeCompanyId,
      'item': itemJson,
    };

    if (receiveQuantity > 0 && warehouseId != null && warehouseId.isNotEmpty) {
      final receive = <String, dynamic>{
        'warehouse_id': warehouseId,
        'quantity': receiveQuantity,
      };
      if (unitPrice != null) receive['unit_price'] = unitPrice;
      if (conditionId != null && conditionId.isNotEmpty) {
        receive['condition_id'] = conditionId;
      }
      final sns = (serialNumbers ?? const <String>[])
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList(growable: false);
      if (sns.isNotEmpty) {
        receive['serial_numbers'] = sns;
        receive['serial_number'] = sns.first;
      }
      payload['receive'] = receive;
    }

    final response = await client.rpc(
      'tmc_create_item_with_receipt',
      params: {'p_payload': payload},
    );

    final map = response is Map
        ? Map<String, dynamic>.from(response)
        : <String, dynamic>{};
    final itemId = map['item_id'] as String?;
    if (itemId == null || itemId.isEmpty) {
      throw StateError('RPC не вернул item_id');
    }

    return (await getItem(itemId))!;
  }

  @override
  Future<TmcItem> updateItem(TmcItem item) async {
    final model = TmcItemModel.fromDomain(item);
    final payload = model.toWriteJson(includeId: false);

    final row = await client
        .from('tmc_items')
        .update(payload)
        .eq('id', item.id)
        .eq('company_id', activeCompanyId)
        .select(_itemSelect)
        .single();

    return TmcItemModel.fromJson(Map<String, dynamic>.from(row)).toDomain();
  }

  @override
  Future<List<TmcUnit>> listUnits({String? itemId, String? status}) async {
    if (!_hasCompany) return [];

    var query = client
        .from('tmc_units')
        .select(_unitSelect)
        .eq('company_id', activeCompanyId)
        .eq('is_archived', false);

    if (itemId != null && itemId.isNotEmpty) {
      query = query.eq('item_id', itemId);
    }
    if (status != null && status.isNotEmpty) {
      query = query.eq('status', status);
    }

    final response = await query.order('inventory_number');

    return (response as List)
        .map(
          (row) => TmcUnitModel.fromJson(
            Map<String, dynamic>.from(row as Map),
          ).toDomain(),
        )
        .toList();
  }

  @override
  Future<TmcUnit> updateUnit(TmcUnit unit) async {
    // Статус и место меняет только RPC tmc_post_operation.
    final payload = <String, dynamic>{
      'inventory_number': unit.inventoryNumber,
      'serial_number': unit.serialNumber,
      'barcode': unit.barcode,
      'warranty_until': tmcDateOnlyToJson(unit.warrantyUntil),
      'comment': unit.comment,
    };

    final row = await client
        .from('tmc_units')
        .update(payload)
        .eq('id', unit.id)
        .eq('company_id', activeCompanyId)
        .select(_unitSelect)
        .single();

    return TmcUnitModel.fromJson(Map<String, dynamic>.from(row)).toDomain();
  }

  @override
  Future<List<TmcCategory>> listCategories() async {
    if (!_hasCompany) return [];

    final response = await client
        .from('tmc_categories')
        .select()
        .eq('company_id', activeCompanyId)
        .eq('is_archived', false)
        .order('sort_order')
        .order('name');

    return (response as List)
        .map(
          (row) => TmcCategoryModel.fromJson(
            Map<String, dynamic>.from(row as Map),
          ).toDomain(),
        )
        .toList();
  }

  @override
  Future<TmcCategory> createCategory(TmcCategory category) async {
    if (!_hasCompany) {
      throw StateError('Не выбрана активная компания');
    }
    final model = TmcCategoryModel.fromDomain(category);
    final payload = model.toWriteJson(includeId: false);
    payload['company_id'] = activeCompanyId;

    final row = await client
        .from('tmc_categories')
        .insert(payload)
        .select()
        .single();

    return TmcCategoryModel.fromJson(Map<String, dynamic>.from(row)).toDomain();
  }

  @override
  Future<List<TmcCondition>> listConditions() async {
    if (!_hasCompany) return [];

    final response = await client
        .from('tmc_conditions')
        .select()
        .eq('company_id', activeCompanyId)
        .eq('is_archived', false)
        .order('sort_order');

    return (response as List)
        .map(
          (row) => TmcConditionModel.fromJson(
            Map<String, dynamic>.from(row as Map),
          ).toDomain(),
        )
        .toList();
  }

  @override
  Future<List<TmcWarehouse>> listWarehouses() async {
    if (!_hasCompany) return [];

    final response = await client
        .from('tmc_warehouses')
        .select()
        .eq('company_id', activeCompanyId)
        .eq('is_archived', false)
        .order('name');

    return (response as List)
        .map(
          (row) => TmcWarehouseModel.fromJson(
            Map<String, dynamic>.from(row as Map),
          ).toDomain(),
        )
        .toList();
  }

  @override
  Future<List<TmcStockBalance>> listStock({
    String? warehouseId,
    String? search,
  }) async {
    if (!_hasCompany) return [];

    final response = await client.rpc(
      'tmc_list_stock',
      params: {
        'p_company_id': activeCompanyId,
        'p_warehouse_id': warehouseId,
        'p_search': search,
      },
    );

    return (response as List).map((row) {
      final map = Map<String, dynamic>.from(row as Map);
      return TmcStockBalance(
        itemId: map['item_id'] as String,
        itemName: map['item_name'] as String? ?? '',
        accountingType: map['accounting_type'] as String? ?? 'quantitative',
        unitOfMeasure: map['unit_of_measure'] as String? ?? 'шт',
        warehouseId: map['warehouse_id'] as String?,
        warehouseName: map['warehouse_name'] as String?,
        locationType: map['location_type'] as String? ?? 'warehouse',
        quantity: tmcParseDouble(map['quantity']),
        unitId: map['unit_id'] as String?,
        inventoryNumber: map['inventory_number'] as String?,
        unitStatus: map['unit_status'] as String?,
      );
    }).toList();
  }

  @override
  Future<TmcWarehouse> createWarehouse(TmcWarehouse warehouse) async {
    if (!_hasCompany) {
      throw StateError('Не выбрана активная компания');
    }
    final model = TmcWarehouseModel.fromDomain(warehouse);
    final payload = model.toWriteJson(includeId: false);
    payload['company_id'] = activeCompanyId;

    final row = await client
        .from('tmc_warehouses')
        .insert(payload)
        .select()
        .single();

    return TmcWarehouseModel.fromJson(
      Map<String, dynamic>.from(row),
    ).toDomain();
  }

  @override
  Future<List<TmcOperation>> listOperations({
    TmcOperationType? operationType,
    String? itemId,
    int limit = 50,
    int offset = 0,
  }) async {
    if (!_hasCompany) return [];

    final select = itemId != null && itemId.isNotEmpty
        ? '''
    *,
    tmc_operation_items!inner(
      *,
      tmc_items:item_id(name),
      tmc_units:unit_id(inventory_number)
    )
  '''
        : _operationSelect;

    var query = client
        .from('tmc_operations')
        .select(select)
        .eq('company_id', activeCompanyId);

    if (operationType != null) {
      query = query.eq('operation_type', operationType.dbValue);
    }

    if (itemId != null && itemId.isNotEmpty) {
      query = query.eq('tmc_operation_items.item_id', itemId);
    }

    final response = await query
        .order('operated_at', ascending: false)
        .range(offset, offset + limit - 1);

    return (response as List)
        .map(
          (row) => TmcOperationModel.fromJson(
            Map<String, dynamic>.from(row as Map),
          ).toDomain(),
        )
        .toList();
  }

  Future<TmcOperation?> _getOperation(String id) async {
    if (!_hasCompany) return null;

    final row = await client
        .from('tmc_operations')
        .select(_operationSelect)
        .eq('id', id)
        .eq('company_id', activeCompanyId)
        .maybeSingle();

    if (row == null) return null;

    return TmcOperationModel.fromJson(
      Map<String, dynamic>.from(row),
    ).toDomain();
  }

  @override
  Future<TmcOperation> postOperation(Map<String, dynamic> payload) async {
    if (!_hasCompany) {
      throw StateError('Не выбрана активная компания');
    }

    final enriched = Map<String, dynamic>.from(payload)
      ..['company_id'] = activeCompanyId;

    final response = await client.rpc(
      'tmc_post_operation',
      params: {'p_payload': enriched},
    );

    final operationId = response is Map
        ? response['operation_id'] as String?
        : response as String?;

    if (operationId == null || operationId.isEmpty) {
      throw StateError('RPC tmc_post_operation не вернул operation_id');
    }

    final operation = await _getOperation(operationId);
    if (operation == null) {
      throw StateError('Операция $operationId не найдена после проведения');
    }

    return operation;
  }

  @override
  Future<List<TmcAssignment>> listAssignments({String? employeeId}) async {
    if (!_hasCompany) return [];

    var query = client
        .from('tmc_assignments')
        .select(_assignmentSelect)
        .eq('company_id', activeCompanyId);

    if (employeeId != null && employeeId.isNotEmpty) {
      query = query.eq('employee_id', employeeId);
    }

    final response = await query.order('issued_at', ascending: false);

    return (response as List)
        .map(
          (row) => TmcAssignmentModel.fromJson(
            Map<String, dynamic>.from(row as Map),
          ).toDomain(),
        )
        .toList();
  }

  @override
  Future<List<TmcWriteOff>> listWriteOffs({
    int limit = 50,
    int offset = 0,
  }) async {
    if (!_hasCompany) return [];

    final response = await client
        .from('tmc_write_offs')
        .select(_writeOffSelect)
        .eq('company_id', activeCompanyId)
        .order('written_off_at', ascending: false)
        .range(offset, offset + limit - 1);

    return (response as List)
        .map(
          (row) => TmcWriteOffModel.fromJson(
            Map<String, dynamic>.from(row as Map),
          ).toDomain(),
        )
        .toList();
  }

  @override
  Future<List<TmcNotification>> listNotifications({
    bool unreadOnly = false,
  }) async {
    if (!_hasCompany) return [];

    final uid = client.auth.currentUser?.id;
    if (uid == null) return [];

    var query = client
        .from('tmc_notifications')
        .select()
        .eq('company_id', activeCompanyId)
        .eq('user_id', uid);

    if (unreadOnly) {
      query = query.eq('is_read', false);
    }

    final response = await query.order('created_at', ascending: false);

    return (response as List)
        .map(
          (row) => TmcNotificationModel.fromJson(
            Map<String, dynamic>.from(row as Map),
          ).toDomain(),
        )
        .toList();
  }

  @override
  Future<void> markNotificationRead(String id) async {
    if (!_hasCompany) return;

    await client
        .from('tmc_notifications')
        .update({'is_read': true})
        .eq('id', id)
        .eq('company_id', activeCompanyId);
  }
}
