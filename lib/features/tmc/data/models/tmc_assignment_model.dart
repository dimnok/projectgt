import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:projectgt/features/tmc/data/models/tmc_json_utils.dart';
import 'package:projectgt/features/tmc/domain/entities/tmc_assignment.dart';

part 'tmc_assignment_model.freezed.dart';
part 'tmc_assignment_model.g.dart';

/// Модель выдачи ТМЦ для Supabase.
@freezed
abstract class TmcAssignmentModel with _$TmcAssignmentModel {
  /// Создаёт модель.
  @JsonSerializable(fieldRename: FieldRename.snake)
  const factory TmcAssignmentModel({
    required String id,
    required String companyId,
    required String itemId,
    String? unitId,
    required String employeeId,
    String? objectId,
    @Default(1) double quantity,
    required DateTime issuedAt,
    @JsonKey(fromJson: tmcParseDate, toJson: tmcDateOnlyToJson)
    DateTime? plannedReturnDate,
    String? conditionId,
    String? issueOperationId,
    String? clothingSize,
    double? heightCm,
    String? season,
    int? serviceLifeDays,
    @JsonKey(fromJson: tmcParseDate, toJson: tmcDateOnlyToJson)
    DateTime? nextReplacementDate,
    String? comment,
    DateTime? returnedAt,
    @Default(true) bool isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
    @JsonKey(includeToJson: false) String? itemName,
    @JsonKey(includeToJson: false) String? inventoryNumber,
    @JsonKey(includeToJson: false) String? employeeName,
    @JsonKey(includeToJson: false) String? objectName,
    @JsonKey(includeToJson: false, fromJson: tmcParseNullableDouble)
    double? unitPrice,
  }) = _TmcAssignmentModel;

  const TmcAssignmentModel._();

  /// JSON для записи в БД.
  Map<String, dynamic> toJson() =>
      _$TmcAssignmentModelToJson(this as _TmcAssignmentModel);

  /// Из JSON с join-полями.
  factory TmcAssignmentModel.fromJson(Map<String, dynamic> json) {
    final rawPrice = json['unit_price'] ?? json['tmc_items']?['unit_price'];
    return _$TmcAssignmentModelFromJson({
      ...json,
      'item_name': json['item_name'] ?? json['tmc_items']?['name'],
      'inventory_number':
          json['inventory_number'] ?? json['tmc_units']?['inventory_number'],
      'employee_name':
          json['employee_name'] ?? tmcEmployeeNameFromJson(json['employees']),
      'object_name': json['object_name'] ?? json['objects']?['name'],
      'unit_price': rawPrice,
    }).copyWith(unitPrice: tmcParseNullableDouble(rawPrice));
  }

  /// В доменную сущность.
  TmcAssignment toDomain() => TmcAssignment(
        id: id,
        companyId: companyId,
        itemId: itemId,
        unitId: unitId,
        employeeId: employeeId,
        objectId: objectId,
        quantity: quantity,
        issuedAt: issuedAt,
        plannedReturnDate: plannedReturnDate,
        conditionId: conditionId,
        issueOperationId: issueOperationId,
        clothingSize: clothingSize,
        heightCm: heightCm,
        season: season,
        serviceLifeDays: serviceLifeDays,
        nextReplacementDate: nextReplacementDate,
        comment: comment,
        returnedAt: returnedAt,
        isActive: isActive,
        createdAt: createdAt,
        updatedAt: updatedAt,
        createdBy: createdBy,
        itemName: itemName,
        inventoryNumber: inventoryNumber,
        employeeName: employeeName,
        objectName: objectName,
        unitPrice: unitPrice,
      );
}
