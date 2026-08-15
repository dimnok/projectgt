import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:projectgt/features/tmc/data/models/tmc_json_utils.dart';
import 'package:projectgt/features/tmc/domain/entities/tmc_enums.dart';
import 'package:projectgt/features/tmc/domain/entities/tmc_operation.dart';

part 'tmc_operation_model.freezed.dart';
part 'tmc_operation_model.g.dart';

/// Модель строки операции ТМЦ.
@freezed
abstract class TmcOperationItemModel with _$TmcOperationItemModel {
  /// Создаёт модель.
  @JsonSerializable(fieldRename: FieldRename.snake)
  const factory TmcOperationItemModel({
    required String id,
    required String companyId,
    required String operationId,
    required String itemId,
    String? unitId,
    @Default(1) double quantity,
    double? unitPrice,
    String? conditionId,
    String? completenessNote,
    String? comment,
    String? clothingSize,
    double? heightCm,
    String? season,
    int? serviceLifeDays,
    @JsonKey(fromJson: tmcParseDate, toJson: tmcDateOnlyToJson)
    DateTime? nextReplacementDate,
    DateTime? createdAt,
    @JsonKey(includeToJson: false) String? itemName,
    @JsonKey(includeToJson: false) String? inventoryNumber,
  }) = _TmcOperationItemModel;

  const TmcOperationItemModel._();

  /// JSON для записи в БД.
  Map<String, dynamic> toJson() =>
      _$TmcOperationItemModelToJson(this as _TmcOperationItemModel);

  /// Из JSON.
  factory TmcOperationItemModel.fromJson(Map<String, dynamic> json) {
    return _$TmcOperationItemModelFromJson({
      ...json,
      'item_name': json['item_name'] ?? json['tmc_items']?['name'],
      'inventory_number':
          json['inventory_number'] ?? json['tmc_units']?['inventory_number'],
    });
  }

  /// В доменную сущность.
  TmcOperationItem toDomain() => TmcOperationItem(
        id: id,
        companyId: companyId,
        operationId: operationId,
        itemId: itemId,
        unitId: unitId,
        quantity: quantity,
        unitPrice: unitPrice,
        conditionId: conditionId,
        completenessNote: completenessNote,
        comment: comment,
        clothingSize: clothingSize,
        heightCm: heightCm,
        season: season,
        serviceLifeDays: serviceLifeDays,
        nextReplacementDate: nextReplacementDate,
        createdAt: createdAt,
        itemName: itemName,
        inventoryNumber: inventoryNumber,
      );
}

/// Модель операции ТМЦ для Supabase.
@freezed
abstract class TmcOperationModel with _$TmcOperationModel {
  /// Создаёт модель.
  @JsonSerializable(fieldRename: FieldRename.snake)
  const factory TmcOperationModel({
    required String id,
    required String companyId,
    required TmcOperationType operationType,
    required DateTime operatedAt,
    String? documentNumber,
    String? basis,
    String? comment,
    TmcLocationType? fromLocationType,
    String? fromWarehouseId,
    String? fromObjectId,
    String? fromEmployeeId,
    String? fromLocationNote,
    TmcLocationType? toLocationType,
    String? toWarehouseId,
    String? toObjectId,
    String? toEmployeeId,
    String? toLocationNote,
    String? responsibleEmployeeId,
    String? objectId,
    String? reversesOperationId,
    @JsonKey(fromJson: tmcParseDate, toJson: tmcDateOnlyToJson)
    DateTime? plannedReturnDate,
    String? conditionId,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
    @JsonKey(includeToJson: false)
    @Default([])
    List<TmcOperationItemModel> items,
  }) = _TmcOperationModel;

  const TmcOperationModel._();

  /// JSON для записи в БД.
  Map<String, dynamic> toJson() =>
      _$TmcOperationModelToJson(this as _TmcOperationModel);

  /// Из JSON с вложенными строками.
  factory TmcOperationModel.fromJson(Map<String, dynamic> json) {
    final itemsRaw = json['tmc_operation_items'] ?? json['items'];
    final items = itemsRaw is List
        ? itemsRaw
            .map(
              (e) => TmcOperationItemModel.fromJson(
                Map<String, dynamic>.from(e as Map),
              ),
            )
            .toList()
        : <TmcOperationItemModel>[];

    final normalized = Map<String, dynamic>.from(json)
      ..remove('tmc_operation_items')
      ..remove('items');

    return _$TmcOperationModelFromJson(normalized).copyWith(items: items);
  }

  /// В доменную сущность.
  TmcOperation toDomain() => TmcOperation(
        id: id,
        companyId: companyId,
        operationType: operationType,
        operatedAt: operatedAt,
        documentNumber: documentNumber,
        basis: basis,
        comment: comment,
        fromLocationType: fromLocationType,
        fromWarehouseId: fromWarehouseId,
        fromObjectId: fromObjectId,
        fromEmployeeId: fromEmployeeId,
        fromLocationNote: fromLocationNote,
        toLocationType: toLocationType,
        toWarehouseId: toWarehouseId,
        toObjectId: toObjectId,
        toEmployeeId: toEmployeeId,
        toLocationNote: toLocationNote,
        responsibleEmployeeId: responsibleEmployeeId,
        objectId: objectId,
        reversesOperationId: reversesOperationId,
        plannedReturnDate: plannedReturnDate,
        conditionId: conditionId,
        createdAt: createdAt,
        updatedAt: updatedAt,
        createdBy: createdBy,
        items: items.map((e) => e.toDomain()).toList(),
      );
}
