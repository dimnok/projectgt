// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'timesheet_summary_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_TimesheetSummaryModel _$TimesheetSummaryModelFromJson(
        Map<String, dynamic> json) =>
    _TimesheetSummaryModel(
      employeeId: json['employee_id'] as String,
      employeeName: json['employee_name'] as String,
      hoursByDate: Map<String, num>.from(json['hours_by_date'] as Map),
      hoursByObject: Map<String, num>.from(json['hours_by_object'] as Map),
      totalHours: json['total_hours'] as num,
    );

Map<String, dynamic> _$TimesheetSummaryModelToJson(
        _TimesheetSummaryModel instance) =>
    <String, dynamic>{
      'employee_id': instance.employeeId,
      'employee_name': instance.employeeName,
      'hours_by_date': instance.hoursByDate,
      'hours_by_object': instance.hoursByObject,
      'total_hours': instance.totalHours,
    };
