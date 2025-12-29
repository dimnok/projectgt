// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'company_document.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_CompanyDocument _$CompanyDocumentFromJson(Map<String, dynamic> json) =>
    _CompanyDocument(
      id: json['id'] as String,
      companyId: json['company_id'] as String,
      type: json['type'] as String,
      title: json['title'] as String,
      number: json['number'] as String?,
      issueDate: json['issue_date'] == null
          ? null
          : DateTime.parse(json['issue_date'] as String),
      expiryDate: json['expiry_date'] == null
          ? null
          : DateTime.parse(json['expiry_date'] as String),
      fileUrl: json['file_url'] as String?,
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
    );

Map<String, dynamic> _$CompanyDocumentToJson(_CompanyDocument instance) =>
    <String, dynamic>{
      'id': instance.id,
      'company_id': instance.companyId,
      'type': instance.type,
      'title': instance.title,
      'number': instance.number,
      'issue_date': instance.issueDate?.toIso8601String(),
      'expiry_date': instance.expiryDate?.toIso8601String(),
      'file_url': instance.fileUrl,
      'created_at': instance.createdAt?.toIso8601String(),
    };
