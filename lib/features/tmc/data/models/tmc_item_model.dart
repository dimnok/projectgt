import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:projectgt/features/tmc/data/models/tmc_json_utils.dart';
import 'package:projectgt/features/tmc/domain/entities/tmc_enums.dart';
import 'package:projectgt/features/tmc/domain/entities/tmc_item.dart';

part 'tmc_item_model.freezed.dart';
part 'tmc_item_model.g.dart';

/// Модель позиции каталога ТМЦ для Supabase.
@freezed
abstract class TmcItemModel with _$TmcItemModel {
  /// Создаёт модель.
  @JsonSerializable(fieldRename: FieldRename.snake)
  const factory TmcItemModel({
    required String id,
    required String companyId,
    required String name,
    String? categoryId,
    String? subcategoryId,
    @Default(TmcAccountingType.individual) TmcAccountingType accountingType,
    String? sku,
    String? manufacturer,
    String? model,
    @Default('шт') String unitOfMeasure,
    String? description,
    String? photoUrl,
    @Default(TmcItemStatus.active) TmcItemStatus status,
    @JsonKey(fromJson: tmcParseDate, toJson: tmcDateOnlyToJson)
    DateTime? deliveryDate,
    @JsonKey(fromJson: tmcParseDate, toJson: tmcDateOnlyToJson)
    DateTime? acceptanceDate,
    String? supplierId,
    String? documentNumber,
    @Default(0) double unitPrice,
    @Default(0) double quantity,
    @Default(0) double totalCost,
    @Default(0) double vatAmount,
    @JsonKey(fromJson: tmcParseDate, toJson: tmcDateOnlyToJson)
    DateTime? warrantyUntil,
    @Default(false) bool isArchived,
    DateTime? archivedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
    @JsonKey(includeToJson: false) String? categoryName,
    @JsonKey(includeToJson: false) String? subcategoryName,
    @JsonKey(includeToJson: false) String? supplierName,
  }) = _TmcItemModel;

  const TmcItemModel._();

  /// JSON для записи в БД.
  Map<String, dynamic> toJson() =>
      _$TmcItemModelToJson(this as _TmcItemModel);

  /// Из JSON таблицы или RPC [tmc_list_items].
  factory TmcItemModel.fromJson(Map<String, dynamic> json) {
    return _$TmcItemModelFromJson({
      ...json,
      'category_name': json['category_name'] ?? json['tmc_categories']?['name'],
      'subcategory_name':
          json['subcategory_name'] ?? json['subcategory']?['name'],
      'supplier_name':
          json['supplier_name'] ?? json['contractors']?['short_name'],
    });
  }

  /// Доменная позиция из строки RPC [tmc_list_items] (с live-остатками).
  static TmcItem domainFromListRpcRow(
    Map<String, dynamic> map, {
    required String companyId,
  }) {
    return TmcItemModel.fromJson({
      ...map,
      'company_id': companyId,
    }).toDomain().copyWith(
      qtyInStock: tmcParseDouble(map['qty_in_stock']),
      qtyIssued: tmcParseDouble(map['qty_issued']),
      qtyOnObject: tmcParseDouble(map['qty_on_object']),
      locationSummary: map['location_summary'] as String?,
    );
  }

  /// Из доменной сущности.
  factory TmcItemModel.fromDomain(TmcItem item) => TmcItemModel(
        id: item.id,
        companyId: item.companyId,
        name: item.name,
        categoryId: item.categoryId,
        subcategoryId: item.subcategoryId,
        accountingType: item.accountingType,
        sku: item.sku,
        manufacturer: item.manufacturer,
        model: item.model,
        unitOfMeasure: item.unitOfMeasure,
        description: item.description,
        photoUrl: item.photoUrl,
        status: item.status,
        deliveryDate: item.deliveryDate,
        acceptanceDate: item.acceptanceDate,
        supplierId: item.supplierId,
        documentNumber: item.documentNumber,
        unitPrice: item.unitPrice,
        quantity: item.quantity,
        totalCost: item.totalCost,
        vatAmount: item.vatAmount,
        warrantyUntil: item.warrantyUntil,
        isArchived: item.isArchived,
        archivedAt: item.archivedAt,
        createdAt: item.createdAt,
        updatedAt: item.updatedAt,
        createdBy: item.createdBy,
        categoryName: item.categoryName,
        subcategoryName: item.subcategoryName,
        supplierName: item.supplierName,
      );

  /// В доменную сущность.
  TmcItem toDomain() => TmcItem(
        id: id,
        companyId: companyId,
        name: name,
        categoryId: categoryId,
        subcategoryId: subcategoryId,
        accountingType: accountingType,
        sku: sku,
        manufacturer: manufacturer,
        model: model,
        unitOfMeasure: unitOfMeasure,
        description: description,
        photoUrl: photoUrl,
        status: status,
        deliveryDate: deliveryDate,
        acceptanceDate: acceptanceDate,
        supplierId: supplierId,
        documentNumber: documentNumber,
        unitPrice: unitPrice,
        quantity: quantity,
        totalCost: totalCost,
        vatAmount: vatAmount,
        warrantyUntil: warrantyUntil,
        isArchived: isArchived,
        archivedAt: archivedAt,
        createdAt: createdAt,
        updatedAt: updatedAt,
        createdBy: createdBy,
        categoryName: categoryName,
        subcategoryName: subcategoryName,
        supplierName: supplierName,
      );

  /// JSON для insert/update без generated/id-полей.
  Map<String, dynamic> toWriteJson({required bool includeId}) {
    final json = toJson();
    // Количество меняется только операциями / триггерами.
    json.remove('quantity');
    json.remove('total_cost');
    json.remove('created_at');
    json.remove('updated_at');
    if (!includeId || id.isEmpty) {
      json.remove('id');
    }
    return json;
  }
}
