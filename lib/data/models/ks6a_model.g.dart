// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ks6a_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Ks6aPeriod _$Ks6aPeriodFromJson(Map<String, dynamic> json) => _Ks6aPeriod(
  id: json['id'] as String,
  startDate: DateTime.parse(json['start_date'] as String),
  endDate: DateTime.parse(json['end_date'] as String),
  status: $enumDecode(_$Ks6aStatusEnumMap, json['status']),
  title: json['title'] as String?,
  totalAmount: (json['total_amount'] as num?)?.toDouble() ?? 0.0,
);

Map<String, dynamic> _$Ks6aPeriodToJson(_Ks6aPeriod instance) =>
    <String, dynamic>{
      'id': instance.id,
      'start_date': instance.startDate.toIso8601String(),
      'end_date': instance.endDate.toIso8601String(),
      'status': _$Ks6aStatusEnumMap[instance.status]!,
      'title': instance.title,
      'total_amount': instance.totalAmount,
    };

const _$Ks6aStatusEnumMap = {
  Ks6aStatus.draft: 'draft',
  Ks6aStatus.approved: 'approved',
};

_Ks6aPeriodItem _$Ks6aPeriodItemFromJson(Map<String, dynamic> json) =>
    _Ks6aPeriodItem(
      id: json['id'] as String,
      periodId: json['period_id'] as String,
      estimateId: json['estimate_id'] as String,
      quantity: (json['quantity'] as num).toDouble(),
      priceSnapshot: (json['price_snapshot'] as num).toDouble(),
      amount: (json['amount'] as num).toDouble(),
    );

Map<String, dynamic> _$Ks6aPeriodItemToJson(_Ks6aPeriodItem instance) =>
    <String, dynamic>{
      'id': instance.id,
      'period_id': instance.periodId,
      'estimate_id': instance.estimateId,
      'quantity': instance.quantity,
      'price_snapshot': instance.priceSnapshot,
      'amount': instance.amount,
    };

_Ks6aContractData _$Ks6aContractDataFromJson(Map<String, dynamic> json) =>
    _Ks6aContractData(
      periods: (json['periods'] as List<dynamic>)
          .map((e) => Ks6aPeriod.fromJson(e as Map<String, dynamic>))
          .toList(),
      items: (json['items'] as List<dynamic>)
          .map((e) => Ks6aPeriodItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$Ks6aContractDataToJson(_Ks6aContractData instance) =>
    <String, dynamic>{
      'periods': instance.periods.map((e) => e.toJson()).toList(),
      'items': instance.items.map((e) => e.toJson()).toList(),
    };
