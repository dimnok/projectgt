// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'inventory_receipt_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_InventoryReceiptModel _$InventoryReceiptModelFromJson(
        Map<String, dynamic> json) =>
    _InventoryReceiptModel(
      id: json['id'] as String,
      receiptNumber: json['receipt_number'] as String,
      receiptDate: DateTime.parse(json['receipt_date'] as String),
      supplierId: json['supplier_id'] as String,
      fileUrl: json['file_url'] as String?,
      comment: json['comment'] as String?,
      totalAmount: (json['total_amount'] as num?)?.toDouble(),
      itemsCount: (json['items_count'] as num?)?.toInt() ?? 0,
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] == null
          ? null
          : DateTime.parse(json['updated_at'] as String),
      createdBy: json['created_by'] as String?,
    );

Map<String, dynamic> _$InventoryReceiptModelToJson(
        _InventoryReceiptModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'receipt_number': instance.receiptNumber,
      'receipt_date': instance.receiptDate.toIso8601String(),
      'supplier_id': instance.supplierId,
      'file_url': instance.fileUrl,
      'comment': instance.comment,
      'total_amount': instance.totalAmount,
      'items_count': instance.itemsCount,
      'created_at': instance.createdAt?.toIso8601String(),
      'updated_at': instance.updatedAt?.toIso8601String(),
      'created_by': instance.createdBy,
    };
