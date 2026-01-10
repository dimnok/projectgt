import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:projectgt/features/cash_flow/domain/entities/bank_statement_entry.dart';
import 'package:projectgt/features/cash_flow/domain/entities/cash_flow_transaction.dart';

part 'bank_statement_entry_model.freezed.dart';
part 'bank_statement_entry_model.g.dart';

/// Модель данных записи банковской выписки для Supabase.
@freezed
abstract class BankStatementEntryModel with _$BankStatementEntryModel {
  /// Создает экземпляр [BankStatementEntryModel].
  const factory BankStatementEntryModel({
    required String id,
    @JsonKey(name: 'company_id') required String companyId,
    @JsonKey(name: 'bank_account_id') required String bankAccountId,
    required DateTime date,
    required double amount,
    required String type,
    @JsonKey(name: 'contractor_name') String? contractorName,
    @JsonKey(name: 'contractor_inn') String? contractorInn,
    String? comment,
    @JsonKey(name: 'transaction_number') String? transactionNumber,
    @JsonKey(name: 'is_imported') @Default(false) bool isImported,
    @JsonKey(name: 'linked_transaction_id') String? linkedTransactionId,
    @JsonKey(name: 'operation_hash') String? operationHash,
  }) = _BankStatementEntryModel;

  const BankStatementEntryModel._();

  /// Создает модель из сущности.
  factory BankStatementEntryModel.fromEntity(BankStatementEntry entity) =>
      BankStatementEntryModel(
        id: entity.id,
        companyId: entity.companyId,
        bankAccountId: entity.bankAccountId,
        date: entity.date,
        amount: entity.amount,
        type: entity.type.name,
        contractorName: entity.contractorName,
        contractorInn: entity.contractorInn,
        comment: entity.comment,
        transactionNumber: entity.transactionNumber,
        isImported: entity.isImported,
        linkedTransactionId: entity.linkedTransactionId,
        operationHash: entity.operationHash,
      );

  /// Преобразует модель в сущность.
  BankStatementEntry toEntity() => BankStatementEntry(
    id: id,
    companyId: companyId,
    bankAccountId: bankAccountId,
    date: date,
    amount: amount,
    type: type == 'income' ? CashFlowType.income : CashFlowType.expense,
    contractorName: contractorName,
    contractorInn: contractorInn,
    comment: comment,
    transactionNumber: transactionNumber,
    isImported: isImported,
    linkedTransactionId: linkedTransactionId,
    operationHash: operationHash,
  );

  /// Создает модель из JSON.
  factory BankStatementEntryModel.fromJson(Map<String, dynamic> json) =>
      _$BankStatementEntryModelFromJson(json);
}
