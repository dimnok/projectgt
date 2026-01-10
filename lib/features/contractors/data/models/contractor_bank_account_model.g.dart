// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'contractor_bank_account_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ContractorBankAccountModel _$ContractorBankAccountModelFromJson(
  Map<String, dynamic> json,
) => _ContractorBankAccountModel(
  id: json['id'] as String,
  companyId: json['company_id'] as String,
  contractorId: json['contractor_id'] as String,
  bankName: json['bank_name'] as String,
  bankCity: json['bank_city'] as String?,
  bik: json['bik'] as String?,
  corrAccount: json['corr_account'] as String?,
  accountNumber: json['account_number'] as String,
  isPrimary: json['is_primary'] as bool? ?? false,
  createdAt: json['created_at'] == null
      ? null
      : DateTime.parse(json['created_at'] as String),
  updatedAt: json['updated_at'] == null
      ? null
      : DateTime.parse(json['updated_at'] as String),
);

Map<String, dynamic> _$ContractorBankAccountModelToJson(
  _ContractorBankAccountModel instance,
) => <String, dynamic>{
  'id': instance.id,
  'company_id': instance.companyId,
  'contractor_id': instance.contractorId,
  'bank_name': instance.bankName,
  'bank_city': instance.bankCity,
  'bik': instance.bik,
  'corr_account': instance.corrAccount,
  'account_number': instance.accountNumber,
  'is_primary': instance.isPrimary,
  'created_at': instance.createdAt?.toIso8601String(),
  'updated_at': instance.updatedAt?.toIso8601String(),
};
