// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'timesheet_summary.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_TimesheetSummary _$TimesheetSummaryFromJson(Map<String, dynamic> json) =>
    _TimesheetSummary(
      employeeId: json['employee_id'] as String,
      employeeName: json['employee_name'] as String,
      hoursByDate: Map<String, num>.from(json['hours_by_date'] as Map),
      hoursByObject: Map<String, num>.from(json['hours_by_object'] as Map),
      totalHours: json['total_hours'] as num,
    );

Map<String, dynamic> _$TimesheetSummaryToJson(_TimesheetSummary instance) =>
    <String, dynamic>{
      'employee_id': instance.employeeId,
      'employee_name': instance.employeeName,
      'hours_by_date': instance.hoursByDate,
      'hours_by_object': instance.hoursByObject,
      'total_hours': instance.totalHours,
    };
