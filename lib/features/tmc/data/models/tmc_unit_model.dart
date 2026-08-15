import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:projectgt/features/tmc/data/models/tmc_json_utils.dart';
import 'package:projectgt/features/tmc/domain/entities/tmc_enums.dart';
import 'package:projectgt/features/tmc/domain/entities/tmc_unit.dart';

part 'tmc_unit_model.freezed.dart';
part 'tmc_unit_model.g.dart';

/// Модель единицы ТМЦ для Supabase.
@freezed
abstract class TmcUnitModel with _$TmcUnitModel {
  /// Создаёт модель.
  @JsonSerializable(fieldRename: FieldRename.snake)
  const factory TmcUnitModel({
    required String id,
    required String companyId,
    required String itemId,
    required String inventoryNumber,
    String? serialNumber,
    String? barcode,
    @JsonKey(fromJson: tmcParseDate, toJson: tmcDateOnlyToJson)
    DateTime? purchaseDate,
    @Default(0) double purchasePrice,
    String? conditionId,
    @Default(TmcUnitStatus.inStock) TmcUnitStatus status,
    @Default(TmcLocationType.warehouse) TmcLocationType locationType,
    String? warehouseId,
    String? objectId,
    String? employeeId,
    String? locationNote,
    String? usageObjectId,
    String? responsibleEmployeeId,
    @JsonKey(fromJson: tmcParseDate, toJson: tmcDateOnlyToJson)
    DateTime? lastIssueDate,
    @JsonKey(fromJson: tmcParseDate, toJson: tmcDateOnlyToJson)
    DateTime? nextInspectionDate,
    @JsonKey(fromJson: tmcParseDate, toJson: tmcDateOnlyToJson)
    DateTime? warrantyUntil,
    String? comment,
    String? photoUrl,
    @Default(false) bool isArchived,
    DateTime? archivedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
    @JsonKey(includeToJson: false) String? itemName,
    @JsonKey(includeToJson: false) String? conditionName,
    @JsonKey(includeToJson: false) String? warehouseName,
    @JsonKey(includeToJson: false) String? objectName,
    @JsonKey(includeToJson: false) String? employeeName,
  }) = _TmcUnitModel;

  const TmcUnitModel._();

  /// JSON для записи в БД.
  Map<String, dynamic> toJson() => _$TmcUnitModelToJson(this as _TmcUnitModel);

  /// Из JSON с поддержкой join-полей.
  factory TmcUnitModel.fromJson(Map<String, dynamic> json) {
    return _$TmcUnitModelFromJson({
      ...json,
      'item_name': json['item_name'] ?? json['tmc_items']?['name'],
      'condition_name':
          json['condition_name'] ?? json['tmc_conditions']?['name'],
      'warehouse_name':
          json['warehouse_name'] ?? json['tmc_warehouses']?['name'],
      'object_name': json['object_name'] ?? json['objects']?['name'],
      'employee_name':
          json['employee_name'] ?? tmcEmployeeNameFromJson(json['employees']),
    });
  }

  /// В доменную сущность.
  TmcUnit toDomain() => TmcUnit(
    id: id,
    companyId: companyId,
    itemId: itemId,
    inventoryNumber: inventoryNumber,
    serialNumber: serialNumber,
    barcode: barcode,
    purchaseDate: purchaseDate,
    purchasePrice: purchasePrice,
    conditionId: conditionId,
    status: status,
    locationType: locationType,
    warehouseId: warehouseId,
    objectId: objectId,
    employeeId: employeeId,
    locationNote: locationNote,
    usageObjectId: usageObjectId,
    responsibleEmployeeId: responsibleEmployeeId,
    lastIssueDate: lastIssueDate,
    nextInspectionDate: nextInspectionDate,
    warrantyUntil: warrantyUntil,
    comment: comment,
    photoUrl: photoUrl,
    isArchived: isArchived,
    archivedAt: archivedAt,
    createdAt: createdAt,
    updatedAt: updatedAt,
    createdBy: createdBy,
    itemName: itemName,
    conditionName: conditionName,
    warehouseName: warehouseName,
    objectName: objectName,
    employeeName: employeeName,
  );
}
