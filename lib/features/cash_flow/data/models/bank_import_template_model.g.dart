// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bank_import_template_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_BankImportTemplateModel _$BankImportTemplateModelFromJson(
  Map<String, dynamic> json,
) => _BankImportTemplateModel(
  id: json['id'] as String,
  companyId: json['company_id'] as String,
  bankName: json['bank_name'] as String,
  columnMapping: Map<String, String>.from(json['column_mapping'] as Map),
  startRow: (json['start_row'] as num?)?.toInt() ?? 1,
  dateFormat: json['date_format'] as String? ?? 'dd.MM.yyyy',
);

Map<String, dynamic> _$BankImportTemplateModelToJson(
  _BankImportTemplateModel instance,
) => <String, dynamic>{
  'id': instance.id,
  'company_id': instance.companyId,
  'bank_name': instance.bankName,
  'column_mapping': instance.columnMapping,
  'start_row': instance.startRow,
  'date_format': instance.dateFormat,
};
