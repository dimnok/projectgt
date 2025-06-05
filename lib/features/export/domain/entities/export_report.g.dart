// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'export_report.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ExportReport _$ExportReportFromJson(Map<String, dynamic> json) =>
    _ExportReport(
      workDate: DateTime.parse(json['workDate'] as String),
      objectName: json['objectName'] as String,
      contractName: json['contractName'] as String,
      system: json['system'] as String,
      subsystem: json['subsystem'] as String,
      workName: json['workName'] as String,
      section: json['section'] as String,
      floor: json['floor'] as String,
      unit: json['unit'] as String,
      quantity: json['quantity'] as num,
      price: (json['price'] as num?)?.toDouble(),
      total: (json['total'] as num?)?.toDouble(),
      employeeName: json['employeeName'] as String?,
      hours: json['hours'] as num?,
      materials: json['materials'] as String?,
    );

Map<String, dynamic> _$ExportReportToJson(_ExportReport instance) =>
    <String, dynamic>{
      'workDate': instance.workDate.toIso8601String(),
      'objectName': instance.objectName,
      'contractName': instance.contractName,
      'system': instance.system,
      'subsystem': instance.subsystem,
      'workName': instance.workName,
      'section': instance.section,
      'floor': instance.floor,
      'unit': instance.unit,
      'quantity': instance.quantity,
      'price': instance.price,
      'total': instance.total,
      'employeeName': instance.employeeName,
      'hours': instance.hours,
      'materials': instance.materials,
    };
