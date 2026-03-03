// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'vor_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_VorModel _$VorModelFromJson(Map<String, dynamic> json) => _VorModel(
  id: json['id'] as String,
  companyId: json['company_id'] as String,
  contractId: json['contract_id'] as String,
  number: json['number'] as String,
  startDate: DateTime.parse(json['start_date'] as String),
  endDate: DateTime.parse(json['end_date'] as String),
  status: $enumDecode(_$VorStatusEnumMap, json['status']),
  excelUrl: json['excel_url'] as String?,
  pdfUrl: json['pdf_url'] as String?,
  createdAt: DateTime.parse(json['created_at'] as String),
  createdBy: json['created_by'] as String?,
  systems:
      (json['systems'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const [],
  statusHistory:
      (json['statusHistory'] as List<dynamic>?)
          ?.map(
            (e) => VorStatusHistoryModel.fromJson(e as Map<String, dynamic>),
          )
          .toList() ??
      const [],
);

Map<String, dynamic> _$VorModelToJson(_VorModel instance) => <String, dynamic>{
  'id': instance.id,
  'company_id': instance.companyId,
  'contract_id': instance.contractId,
  'number': instance.number,
  'start_date': instance.startDate.toIso8601String(),
  'end_date': instance.endDate.toIso8601String(),
  'status': _$VorStatusEnumMap[instance.status]!,
  'excel_url': instance.excelUrl,
  'pdf_url': instance.pdfUrl,
  'created_at': instance.createdAt.toIso8601String(),
  'created_by': instance.createdBy,
  'systems': instance.systems,
  'statusHistory': instance.statusHistory.map((e) => e.toJson()).toList(),
};

const _$VorStatusEnumMap = {
  VorStatus.draft: 'draft',
  VorStatus.pending: 'pending',
  VorStatus.approved: 'approved',
};

_VorItemModel _$VorItemModelFromJson(Map<String, dynamic> json) =>
    _VorItemModel(
      id: json['id'] as String,
      vorId: json['vor_id'] as String,
      estimateItemId: json['estimate_item_id'] as String?,
      name: json['name'] as String?,
      unit: json['unit'] as String?,
      quantity: (json['quantity'] as num).toDouble(),
      isExtra: json['is_extra'] as bool? ?? false,
      sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$VorItemModelToJson(_VorItemModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'vor_id': instance.vorId,
      'estimate_item_id': instance.estimateItemId,
      'name': instance.name,
      'unit': instance.unit,
      'quantity': instance.quantity,
      'is_extra': instance.isExtra,
      'sort_order': instance.sortOrder,
    };

_VorStatusHistoryModel _$VorStatusHistoryModelFromJson(
  Map<String, dynamic> json,
) => _VorStatusHistoryModel(
  id: json['id'] as String,
  status: $enumDecode(_$VorStatusEnumMap, json['status']),
  userId: json['user_id'] as String?,
  comment: json['comment'] as String?,
  createdAt: DateTime.parse(json['created_at'] as String),
);

Map<String, dynamic> _$VorStatusHistoryModelToJson(
  _VorStatusHistoryModel instance,
) => <String, dynamic>{
  'id': instance.id,
  'status': _$VorStatusEnumMap[instance.status]!,
  'user_id': instance.userId,
  'comment': instance.comment,
  'created_at': instance.createdAt.toIso8601String(),
};
