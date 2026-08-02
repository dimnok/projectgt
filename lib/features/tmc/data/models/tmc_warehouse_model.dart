import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:projectgt/features/tmc/domain/entities/tmc_warehouse.dart';

part 'tmc_warehouse_model.freezed.dart';
part 'tmc_warehouse_model.g.dart';

/// Модель склада ТМЦ для Supabase.
@freezed
abstract class TmcWarehouseModel with _$TmcWarehouseModel {
  /// Создаёт модель.
  @JsonSerializable(fieldRename: FieldRename.snake)
  const factory TmcWarehouseModel({
    required String id,
    required String companyId,
    required String name,
    String? address,
    String? description,
    @Default(false) bool isArchived,
    DateTime? archivedAt,
    @Default(false) bool isMain,
    @Default(false) bool isSystem,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
  }) = _TmcWarehouseModel;

  const TmcWarehouseModel._();

  /// JSON для записи в БД.
  @override
  Map<String, dynamic> toJson() =>
      _$TmcWarehouseModelToJson(this as _TmcWarehouseModel);

  /// Из JSON.
  factory TmcWarehouseModel.fromJson(Map<String, dynamic> json) =>
      _$TmcWarehouseModelFromJson(json);

  /// Из доменной сущности.
  factory TmcWarehouseModel.fromDomain(TmcWarehouse warehouse) =>
      TmcWarehouseModel(
        id: warehouse.id,
        companyId: warehouse.companyId,
        name: warehouse.name,
        address: warehouse.address,
        description: warehouse.description,
        isArchived: warehouse.isArchived,
        archivedAt: warehouse.archivedAt,
        isMain: warehouse.isMain,
        isSystem: warehouse.isSystem,
        createdAt: warehouse.createdAt,
        updatedAt: warehouse.updatedAt,
        createdBy: warehouse.createdBy,
      );

  /// В доменную сущность.
  TmcWarehouse toDomain() => TmcWarehouse(
        id: id,
        companyId: companyId,
        name: name,
        address: address,
        description: description,
        isArchived: isArchived,
        archivedAt: archivedAt,
        isMain: isMain,
        isSystem: isSystem,
        createdAt: createdAt,
        updatedAt: updatedAt,
        createdBy: createdBy,
      );

  /// JSON для insert/update.
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
