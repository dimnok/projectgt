// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'material_item.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_MaterialItem _$MaterialItemFromJson(Map<String, dynamic> json) =>
    _MaterialItem(
      id: json['id'] as String,
      name: json['name'] as String,
      companyId: json['company_id'] as String,
      unit: json['unit'] as String?,
      quantity: (json['quantity'] as num?)?.toDouble(),
      price: (json['price'] as num?)?.toDouble(),
      total: (json['total'] as num?)?.toDouble(),
      receiptNumber: json['receipt_number'] as String?,
      receiptDate: json['receipt_date'] == null
          ? null
          : DateTime.parse(json['receipt_date'] as String),
      used: (json['used'] as num?)?.toDouble(),
      remaining: (json['remaining'] as num?)?.toDouble(),
      fileUrl: json['file_url'] as String?,
    );

Map<String, dynamic> _$MaterialItemToJson(_MaterialItem instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'company_id': instance.companyId,
      'unit': instance.unit,
      'quantity': instance.quantity,
      'price': instance.price,
      'total': instance.total,
      'receipt_number': instance.receiptNumber,
      'receipt_date': instance.receiptDate?.toIso8601String(),
      'used': instance.used,
      'remaining': instance.remaining,
      'file_url': instance.fileUrl,
    };
