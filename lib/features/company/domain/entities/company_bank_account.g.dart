// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'company_bank_account.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_CompanyBankAccount _$CompanyBankAccountFromJson(Map<String, dynamic> json) =>
    _CompanyBankAccount(
      id: json['id'] as String,
      companyId: json['company_id'] as String,
      bankName: json['bank_name'] as String,
      bankCity: json['bank_city'] as String?,
      accountNumber: json['account_number'] as String,
      corrAccount: json['corr_account'] as String?,
      bik: json['bik'] as String?,
      isPrimary: json['is_primary'] as bool? ?? false,
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
    );

Map<String, dynamic> _$CompanyBankAccountToJson(_CompanyBankAccount instance) =>
    <String, dynamic>{
      'id': instance.id,
      'company_id': instance.companyId,
      'bank_name': instance.bankName,
      'bank_city': instance.bankCity,
      'account_number': instance.accountNumber,
      'corr_account': instance.corrAccount,
      'bik': instance.bik,
      'is_primary': instance.isPrimary,
      'created_at': instance.createdAt?.toIso8601String(),
    };
