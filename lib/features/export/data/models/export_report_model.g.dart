// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'export_report_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ExportReportModel _$ExportReportModelFromJson(Map<String, dynamic> json) =>
    _ExportReportModel(
      workDate: DateTime.parse(json['work_date'] as String),
      objectName: json['object_name'] as String,
      contractName: json['contract_name'] as String,
      system: json['system'] as String,
      subsystem: json['subsystem'] as String,
      positionNumber: json['position_number'] as String,
      workName: json['work_name'] as String,
      section: json['section'] as String,
      floor: json['floor'] as String,
      unit: json['unit'] as String,
      quantity: json['quantity'] as num,
      price: (json['price'] as num?)?.toDouble(),
      total: (json['total'] as num?)?.toDouble(),
      employeeName: json['employee_name'] as String?,
      hours: json['hours'] as num?,
      materials: json['materials'] as String?,
    );

Map<String, dynamic> _$ExportReportModelToJson(_ExportReportModel instance) =>
    <String, dynamic>{
      'work_date': instance.workDate.toIso8601String(),
      'object_name': instance.objectName,
      'contract_name': instance.contractName,
      'system': instance.system,
      'subsystem': instance.subsystem,
      'position_number': instance.positionNumber,
      'work_name': instance.workName,
      'section': instance.section,
      'floor': instance.floor,
      'unit': instance.unit,
      'quantity': instance.quantity,
      'price': instance.price,
      'total': instance.total,
      'employee_name': instance.employeeName,
      'hours': instance.hours,
      'materials': instance.materials,
    };
