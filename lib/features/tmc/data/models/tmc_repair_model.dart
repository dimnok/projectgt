import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:projectgt/features/tmc/data/models/tmc_json_utils.dart';
import 'package:projectgt/features/tmc/domain/entities/tmc_repair.dart';

part 'tmc_repair_model.freezed.dart';
part 'tmc_repair_model.g.dart';

/// Модель ремонта ТМЦ для Supabase.
@freezed
abstract class TmcRepairModel with _$TmcRepairModel {
  /// Создаёт модель.
  @JsonSerializable(fieldRename: FieldRename.snake)
  const factory TmcRepairModel({
    required String id,
    required String companyId,
    required String itemId,
    String? unitId,
    @JsonKey(fromJson: tmcParseRequiredDate, toJson: tmcDateOnlyToJson)
    required DateTime sentAt,
    String? reason,
    String? faultDescription,
    String? repairOrgName,
    String? responsibleEmployeeId,
    double? estimatedCost,
    double? actualCost,
    @JsonKey(fromJson: tmcParseDate, toJson: tmcDateOnlyToJson)
    DateTime? completedAt,
    String? result,
    String? conditionAfterId,
    @JsonKey(fromJson: tmcParseDate, toJson: tmcDateOnlyToJson)
    DateTime? repairWarrantyUntil,
    @Default(TmcRepairStatus.open) TmcRepairStatus status,
    String? sendOperationId,
    String? returnOperationId,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
    @JsonKey(includeToJson: false) String? itemName,
    @JsonKey(includeToJson: false) String? inventoryNumber,
  }) = _TmcRepairModel;

  const TmcRepairModel._();

  /// JSON для записи в БД.
  Map<String, dynamic> toJson() =>
      _$TmcRepairModelToJson(this as _TmcRepairModel);

  /// Из JSON с join-полями.
  factory TmcRepairModel.fromJson(Map<String, dynamic> json) {
    return _$TmcRepairModelFromJson({
      ...json,
      'item_name': json['item_name'] ?? json['tmc_items']?['name'],
      'inventory_number':
          json['inventory_number'] ?? json['tmc_units']?['inventory_number'],
    });
  }

  /// Из доменной сущности.
  factory TmcRepairModel.fromDomain(TmcRepair repair) => TmcRepairModel(
        id: repair.id,
        companyId: repair.companyId,
        itemId: repair.itemId,
        unitId: repair.unitId,
        sentAt: repair.sentAt,
        reason: repair.reason,
        faultDescription: repair.faultDescription,
        repairOrgName: repair.repairOrgName,
        responsibleEmployeeId: repair.responsibleEmployeeId,
        estimatedCost: repair.estimatedCost,
        actualCost: repair.actualCost,
        completedAt: repair.completedAt,
        result: repair.result,
        conditionAfterId: repair.conditionAfterId,
        repairWarrantyUntil: repair.repairWarrantyUntil,
        status: repair.status,
        sendOperationId: repair.sendOperationId,
        returnOperationId: repair.returnOperationId,
        createdAt: repair.createdAt,
        updatedAt: repair.updatedAt,
        createdBy: repair.createdBy,
        itemName: repair.itemName,
        inventoryNumber: repair.inventoryNumber,
      );

  /// В доменную сущность.
  TmcRepair toDomain() => TmcRepair(
        id: id,
        companyId: companyId,
        itemId: itemId,
        unitId: unitId,
        sentAt: sentAt,
        reason: reason,
        faultDescription: faultDescription,
        repairOrgName: repairOrgName,
        responsibleEmployeeId: responsibleEmployeeId,
        estimatedCost: estimatedCost,
        actualCost: actualCost,
        completedAt: completedAt,
        result: result,
        conditionAfterId: conditionAfterId,
        repairWarrantyUntil: repairWarrantyUntil,
        status: status,
        sendOperationId: sendOperationId,
        returnOperationId: returnOperationId,
        createdAt: createdAt,
        updatedAt: updatedAt,
        createdBy: createdBy,
        itemName: itemName,
        inventoryNumber: inventoryNumber,
      );
}
