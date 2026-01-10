// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bank_statement_entry_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_BankStatementEntryModel _$BankStatementEntryModelFromJson(
  Map<String, dynamic> json,
) => _BankStatementEntryModel(
  id: json['id'] as String,
  companyId: json['company_id'] as String,
  bankAccountId: json['bank_account_id'] as String,
  date: DateTime.parse(json['date'] as String),
  amount: (json['amount'] as num).toDouble(),
  type: json['type'] as String,
  contractorName: json['contractor_name'] as String?,
  contractorInn: json['contractor_inn'] as String?,
  comment: json['comment'] as String?,
  transactionNumber: json['transaction_number'] as String?,
  isImported: json['is_imported'] as bool? ?? false,
  linkedTransactionId: json['linked_transaction_id'] as String?,
  operationHash: json['operation_hash'] as String?,
);

Map<String, dynamic> _$BankStatementEntryModelToJson(
  _BankStatementEntryModel instance,
) => <String, dynamic>{
  'id': instance.id,
  'company_id': instance.companyId,
  'bank_account_id': instance.bankAccountId,
  'date': instance.date.toIso8601String(),
  'amount': instance.amount,
  'type': instance.type,
  'contractor_name': instance.contractorName,
  'contractor_inn': instance.contractorInn,
  'comment': instance.comment,
  'transaction_number': instance.transactionNumber,
  'is_imported': instance.isImported,
  'linked_transaction_id': instance.linkedTransactionId,
  'operation_hash': instance.operationHash,
};
