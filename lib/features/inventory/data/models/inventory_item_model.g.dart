// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'inventory_item_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_InventoryItemModel _$InventoryItemModelFromJson(Map<String, dynamic> json) =>
    _InventoryItemModel(
      id: json['id'] as String,
      name: json['name'] as String,
      categoryId: json['category_id'] as String,
      serialNumber: json['serial_number'] as String?,
      unit: json['unit'] as String,
      quantity: (json['quantity'] as num?)?.toDouble() ?? 1.0,
      photoUrl: json['photo_url'] as String?,
      status: json['status'] as String,
      condition: json['condition'] as String,
      locationType: json['location_type'] as String,
      locationId: json['location_id'] as String?,
      responsibleId: json['responsible_id'] as String?,
      receiptId: json['receipt_id'] as String?,
      receiptItemId: json['receipt_item_id'] as String?,
      price: (json['price'] as num?)?.toDouble(),
      purchaseDate: json['purchase_date'] == null
          ? null
          : DateTime.parse(json['purchase_date'] as String),
      warrantyExpiresAt: json['warranty_expires_at'] == null
          ? null
          : DateTime.parse(json['warranty_expires_at'] as String),
      serviceLifeMonths: (json['service_life_months'] as num?)?.toInt(),
      issuedAt: json['issued_at'] == null
          ? null
          : DateTime.parse(json['issued_at'] as String),
      notes: json['notes'] as String?,
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] == null
          ? null
          : DateTime.parse(json['updated_at'] as String),
      createdBy: json['created_by'] as String?,
      updatedBy: json['updated_by'] as String?,
    );

Map<String, dynamic> _$InventoryItemModelToJson(_InventoryItemModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'category_id': instance.categoryId,
      'serial_number': instance.serialNumber,
      'unit': instance.unit,
      'quantity': instance.quantity,
      'photo_url': instance.photoUrl,
      'status': instance.status,
      'condition': instance.condition,
      'location_type': instance.locationType,
      'location_id': instance.locationId,
      'responsible_id': instance.responsibleId,
      'receipt_id': instance.receiptId,
      'receipt_item_id': instance.receiptItemId,
      'price': instance.price,
      'purchase_date': instance.purchaseDate?.toIso8601String(),
      'warranty_expires_at': instance.warrantyExpiresAt?.toIso8601String(),
      'service_life_months': instance.serviceLifeMonths,
      'issued_at': instance.issuedAt?.toIso8601String(),
      'notes': instance.notes,
      'created_at': instance.createdAt?.toIso8601String(),
      'updated_at': instance.updatedAt?.toIso8601String(),
      'created_by': instance.createdBy,
      'updated_by': instance.updatedBy,
    };
