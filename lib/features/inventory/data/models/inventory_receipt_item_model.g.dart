// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'inventory_receipt_item_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_InventoryReceiptItemModel _$InventoryReceiptItemModelFromJson(
        Map<String, dynamic> json) =>
    _InventoryReceiptItemModel(
      id: json['id'] as String,
      receiptId: json['receipt_id'] as String,
      name: json['name'] as String,
      categoryId: json['category_id'] as String,
      unit: json['unit'] as String,
      quantity: (json['quantity'] as num).toDouble(),
      price: (json['price'] as num?)?.toDouble(),
      total: (json['total'] as num?)?.toDouble(),
      serialNumber: json['serial_number'] as String?,
      photoUrl: json['photo_url'] as String?,
      notes: json['notes'] as String?,
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
    );

Map<String, dynamic> _$InventoryReceiptItemModelToJson(
        _InventoryReceiptItemModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'receipt_id': instance.receiptId,
      'name': instance.name,
      'category_id': instance.categoryId,
      'unit': instance.unit,
      'quantity': instance.quantity,
      'price': instance.price,
      'total': instance.total,
      'serial_number': instance.serialNumber,
      'photo_url': instance.photoUrl,
      'notes': instance.notes,
      'created_at': instance.createdAt?.toIso8601String(),
    };
