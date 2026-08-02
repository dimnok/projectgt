import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:projectgt/features/tmc/data/models/tmc_json_utils.dart';
import 'package:projectgt/features/tmc/domain/entities/tmc_enums.dart';
import 'package:projectgt/features/tmc/domain/entities/tmc_write_off.dart';

part 'tmc_write_off_model.freezed.dart';
part 'tmc_write_off_model.g.dart';

/// Модель списания ТМЦ для Supabase.
@freezed
abstract class TmcWriteOffModel with _$TmcWriteOffModel {
  /// Создаёт модель.
  @JsonSerializable(fieldRename: FieldRename.snake)
  const factory TmcWriteOffModel({
    required String id,
    required String companyId,
    required String itemId,
    String? unitId,
    @JsonKey(fromJson: tmcParseRequiredDate, toJson: tmcDateOnlyToJson)
    required DateTime writtenOffAt,
    required TmcWriteOffReason reason,
    @Default(1) double quantity,
    String? conditionId,
    double? bookValue,
    String? responsibleEmployeeId,
    String? objectId,
    String? actNumber,
    String? comment,
    String? operationId,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
    @JsonKey(includeToJson: false) String? itemName,
    @JsonKey(includeToJson: false) String? inventoryNumber,
  }) = _TmcWriteOffModel;

  const TmcWriteOffModel._();

  /// JSON для записи в БД.
  Map<String, dynamic> toJson() =>
      _$TmcWriteOffModelToJson(this as _TmcWriteOffModel);

  /// Из JSON с join-полями.
  factory TmcWriteOffModel.fromJson(Map<String, dynamic> json) {
    return _$TmcWriteOffModelFromJson({
      ...json,
      'item_name': json['item_name'] ?? json['tmc_items']?['name'],
      'inventory_number':
          json['inventory_number'] ?? json['tmc_units']?['inventory_number'],
    });
  }

  /// Из доменной сущности.
  factory TmcWriteOffModel.fromDomain(TmcWriteOff writeOff) =>
      TmcWriteOffModel(
        id: writeOff.id,
        companyId: writeOff.companyId,
        itemId: writeOff.itemId,
        unitId: writeOff.unitId,
        writtenOffAt: writeOff.writtenOffAt,
        reason: writeOff.reason,
        quantity: writeOff.quantity,
        conditionId: writeOff.conditionId,
        bookValue: writeOff.bookValue,
        responsibleEmployeeId: writeOff.responsibleEmployeeId,
        objectId: writeOff.objectId,
        actNumber: writeOff.actNumber,
        comment: writeOff.comment,
        operationId: writeOff.operationId,
        createdAt: writeOff.createdAt,
        updatedAt: writeOff.updatedAt,
        createdBy: writeOff.createdBy,
        itemName: writeOff.itemName,
        inventoryNumber: writeOff.inventoryNumber,
      );

  /// В доменную сущность.
  TmcWriteOff toDomain() => TmcWriteOff(
        id: id,
        companyId: companyId,
        itemId: itemId,
        unitId: unitId,
        writtenOffAt: writtenOffAt,
        reason: reason,
        quantity: quantity,
        conditionId: conditionId,
        bookValue: bookValue,
        responsibleEmployeeId: responsibleEmployeeId,
        objectId: objectId,
        actNumber: actNumber,
        comment: comment,
        operationId: operationId,
        createdAt: createdAt,
        updatedAt: updatedAt,
        createdBy: createdBy,
        itemName: itemName,
        inventoryNumber: inventoryNumber,
      );
}
