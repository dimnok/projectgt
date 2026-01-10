// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'available_filters.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_AvailableFilters _$AvailableFiltersFromJson(Map<String, dynamic> json) =>
    _AvailableFilters(
      objectIds:
          (json['objectIds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toSet() ??
          const {},
      contractorIds:
          (json['contractorIds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toSet() ??
          const {},
      contractIds:
          (json['contractIds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toSet() ??
          const {},
    );

Map<String, dynamic> _$AvailableFiltersToJson(_AvailableFilters instance) =>
    <String, dynamic>{
      'objectIds': instance.objectIds.toList(),
      'contractorIds': instance.contractorIds.toList(),
      'contractIds': instance.contractIds.toList(),
    };
