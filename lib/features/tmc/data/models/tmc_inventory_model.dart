import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:projectgt/features/tmc/domain/entities/tmc_inventory.dart';

part 'tmc_inventory_model.freezed.dart';
part 'tmc_inventory_model.g.dart';

/// Модель строки инвентаризации ТМЦ.
@freezed
abstract class TmcInventoryItemModel with _$TmcInventoryItemModel {
  /// Создаёт модель.
  @JsonSerializable(fieldRename: FieldRename.snake)
  const factory TmcInventoryItemModel({
    required String id,
    required String companyId,
    required String inventoryId,
    required String itemId,
    String? unitId,
    @Default(0) double systemQuantity,
    double? actualQuantity,
    double? surplus,
    double? shortage,
    String? conditionId,
    String? comment,
    DateTime? createdAt,
    DateTime? updatedAt,
    @JsonKey(includeToJson: false) String? itemName,
    @JsonKey(includeToJson: false) String? inventoryNumber,
  }) = _TmcInventoryItemModel;

  const TmcInventoryItemModel._();

  /// JSON для записи в БД.
  Map<String, dynamic> toJson() =>
      _$TmcInventoryItemModelToJson(this as _TmcInventoryItemModel);

  /// Из JSON.
  factory TmcInventoryItemModel.fromJson(Map<String, dynamic> json) {
    return _$TmcInventoryItemModelFromJson({
      ...json,
      'item_name': json['item_name'] ?? json['tmc_items']?['name'],
      'inventory_number':
          json['inventory_number'] ?? json['tmc_units']?['inventory_number'],
    });
  }

  /// Из доменной сущности.
  factory TmcInventoryItemModel.fromDomain(TmcInventoryItem item) =>
      TmcInventoryItemModel(
        id: item.id,
        companyId: item.companyId,
        inventoryId: item.inventoryId,
        itemId: item.itemId,
        unitId: item.unitId,
        systemQuantity: item.systemQuantity,
        actualQuantity: item.actualQuantity,
        surplus: item.surplus,
        shortage: item.shortage,
        conditionId: item.conditionId,
        comment: item.comment,
        createdAt: item.createdAt,
        updatedAt: item.updatedAt,
        itemName: item.itemName,
        inventoryNumber: item.inventoryNumber,
      );

  /// В доменную сущность.
  TmcInventoryItem toDomain() => TmcInventoryItem(
        id: id,
        companyId: companyId,
        inventoryId: inventoryId,
        itemId: itemId,
        unitId: unitId,
        systemQuantity: systemQuantity,
        actualQuantity: actualQuantity,
        surplus: surplus,
        shortage: shortage,
        conditionId: conditionId,
        comment: comment,
        createdAt: createdAt,
        updatedAt: updatedAt,
        itemName: itemName,
        inventoryNumber: inventoryNumber,
      );

  /// JSON для update.
  Map<String, dynamic> toWriteJson() {
    final json = toJson();
    json.remove('surplus');
    json.remove('shortage');
    json.remove('created_at');
    return json;
  }
}

/// Модель инвентаризации ТМЦ для Supabase.
@freezed
abstract class TmcInventoryModel with _$TmcInventoryModel {
  /// Создаёт модель.
  @JsonSerializable(fieldRename: FieldRename.snake)
  const factory TmcInventoryModel({
    required String id,
    required String companyId,
    required String title,
    @Default(TmcInventoryScopeType.company) TmcInventoryScopeType scopeType,
    String? warehouseId,
    String? objectId,
    String? employeeId,
    String? categoryId,
    @Default(TmcInventoryStatus.draft) TmcInventoryStatus status,
    required DateTime startedAt,
    DateTime? completedAt,
    String? comment,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
    @JsonKey(includeToJson: false)
    @Default([])
    List<TmcInventoryItemModel> items,
  }) = _TmcInventoryModel;

  const TmcInventoryModel._();

  /// JSON для записи в БД.
  Map<String, dynamic> toJson() =>
      _$TmcInventoryModelToJson(this as _TmcInventoryModel);

  /// Из JSON с вложенными строками.
  factory TmcInventoryModel.fromJson(Map<String, dynamic> json) {
    final itemsRaw = json['tmc_inventory_items'] ?? json['items'];
    final items = itemsRaw is List
        ? itemsRaw
            .map(
              (e) => TmcInventoryItemModel.fromJson(
                Map<String, dynamic>.from(e as Map),
              ),
            )
            .toList()
        : <TmcInventoryItemModel>[];

    final normalized = Map<String, dynamic>.from(json)
      ..remove('tmc_inventory_items')
      ..remove('items');

    return _$TmcInventoryModelFromJson(normalized).copyWith(items: items);
  }

  /// Из доменной сущности.
  factory TmcInventoryModel.fromDomain(TmcInventory inventory) =>
      TmcInventoryModel(
        id: inventory.id,
        companyId: inventory.companyId,
        title: inventory.title,
        scopeType: inventory.scopeType,
        warehouseId: inventory.warehouseId,
        objectId: inventory.objectId,
        employeeId: inventory.employeeId,
        categoryId: inventory.categoryId,
        status: inventory.status,
        startedAt: inventory.startedAt,
        completedAt: inventory.completedAt,
        comment: inventory.comment,
        createdAt: inventory.createdAt,
        updatedAt: inventory.updatedAt,
        createdBy: inventory.createdBy,
        items: inventory.items.map(TmcInventoryItemModel.fromDomain).toList(),
      );

  /// В доменную сущность.
  TmcInventory toDomain() => TmcInventory(
        id: id,
        companyId: companyId,
        title: title,
        scopeType: scopeType,
        warehouseId: warehouseId,
        objectId: objectId,
        employeeId: employeeId,
        categoryId: categoryId,
        status: status,
        startedAt: startedAt,
        completedAt: completedAt,
        comment: comment,
        createdAt: createdAt,
        updatedAt: updatedAt,
        createdBy: createdBy,
        items: items.map((e) => e.toDomain()).toList(),
      );

  /// JSON для insert.
  Map<String, dynamic> toWriteJson({required bool includeId}) {
    final json = toJson();
    json.remove('created_at');
    json.remove('updated_at');
    if (!includeId || id.isEmpty) {
      json.remove('id');
    }
    return json;
  }
}
