// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tmc_item_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_TmcItemModel _$TmcItemModelFromJson(Map<String, dynamic> json) =>
    _TmcItemModel(
      id: json['id'] as String,
      companyId: json['company_id'] as String,
      name: json['name'] as String,
      categoryId: json['category_id'] as String?,
      subcategoryId: json['subcategory_id'] as String?,
      accountingType:
          $enumDecodeNullable(
            _$TmcAccountingTypeEnumMap,
            json['accounting_type'],
          ) ??
          TmcAccountingType.individual,
      sku: json['sku'] as String?,
      manufacturer: json['manufacturer'] as String?,
      model: json['model'] as String?,
      unitOfMeasure: json['unit_of_measure'] as String? ?? 'шт',
      description: json['description'] as String?,
      photoUrl: json['photo_url'] as String?,
      status:
          $enumDecodeNullable(_$TmcItemStatusEnumMap, json['status']) ??
          TmcItemStatus.active,
      deliveryDate: tmcParseDate(json['delivery_date']),
      acceptanceDate: tmcParseDate(json['acceptance_date']),
      supplierId: json['supplier_id'] as String?,
      documentNumber: json['document_number'] as String?,
      unitPrice: (json['unit_price'] as num?)?.toDouble() ?? 0,
      quantity: (json['quantity'] as num?)?.toDouble() ?? 0,
      totalCost: (json['total_cost'] as num?)?.toDouble() ?? 0,
      vatAmount: (json['vat_amount'] as num?)?.toDouble() ?? 0,
      warrantyUntil: tmcParseDate(json['warranty_until']),
      isArchived: json['is_archived'] as bool? ?? false,
      archivedAt: json['archived_at'] == null
          ? null
          : DateTime.parse(json['archived_at'] as String),
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] == null
          ? null
          : DateTime.parse(json['updated_at'] as String),
      createdBy: json['created_by'] as String?,
      categoryName: json['category_name'] as String?,
      subcategoryName: json['subcategory_name'] as String?,
      supplierName: json['supplier_name'] as String?,
    );

Map<String, dynamic> _$TmcItemModelToJson(_TmcItemModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'company_id': instance.companyId,
      'name': instance.name,
      'category_id': instance.categoryId,
      'subcategory_id': instance.subcategoryId,
      'accounting_type': _$TmcAccountingTypeEnumMap[instance.accountingType]!,
      'sku': instance.sku,
      'manufacturer': instance.manufacturer,
      'model': instance.model,
      'unit_of_measure': instance.unitOfMeasure,
      'description': instance.description,
      'photo_url': instance.photoUrl,
      'status': _$TmcItemStatusEnumMap[instance.status]!,
      'delivery_date': tmcDateOnlyToJson(instance.deliveryDate),
      'acceptance_date': tmcDateOnlyToJson(instance.acceptanceDate),
      'supplier_id': instance.supplierId,
      'document_number': instance.documentNumber,
      'unit_price': instance.unitPrice,
      'quantity': instance.quantity,
      'total_cost': instance.totalCost,
      'vat_amount': instance.vatAmount,
      'warranty_until': tmcDateOnlyToJson(instance.warrantyUntil),
      'is_archived': instance.isArchived,
      'archived_at': instance.archivedAt?.toIso8601String(),
      'created_at': instance.createdAt?.toIso8601String(),
      'updated_at': instance.updatedAt?.toIso8601String(),
      'created_by': instance.createdBy,
    };

const _$TmcAccountingTypeEnumMap = {
  TmcAccountingType.individual: 'individual',
  TmcAccountingType.quantitative: 'quantitative',
};

const _$TmcItemStatusEnumMap = {
  TmcItemStatus.active: 'active',
  TmcItemStatus.archived: 'archived',
};
