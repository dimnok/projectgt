import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:projectgt/features/contractors/domain/entities/contractor_bank_account.dart';

part 'contractor_bank_account_model.freezed.dart';
part 'contractor_bank_account_model.g.dart';

/// Модель данных банковского счета контрагента.
@freezed
abstract class ContractorBankAccountModel with _$ContractorBankAccountModel {
  /// Создает экземпляр модели банковского счета контрагента.
  @JsonSerializable(explicitToJson: true, fieldRename: FieldRename.snake)
  const factory ContractorBankAccountModel({
    required String id,
    @JsonKey(name: 'company_id') required String companyId,
    @JsonKey(name: 'contractor_id') required String contractorId,
    @JsonKey(name: 'bank_name') required String bankName,
    @JsonKey(name: 'bank_city') String? bankCity,
    String? bik,
    @JsonKey(name: 'corr_account') String? corrAccount,
    @JsonKey(name: 'account_number') required String accountNumber,
    @Default(false) bool isPrimary,
    @JsonKey(name: 'created_at') DateTime? createdAt,
    @JsonKey(name: 'updated_at') DateTime? updatedAt,
  }) = _ContractorBankAccountModel;

  const ContractorBankAccountModel._();

  /// Создаёт модель из JSON.
  factory ContractorBankAccountModel.fromJson(Map<String, dynamic> json) =>
      _$ContractorBankAccountModelFromJson(json);

  /// Создаёт модель из доменной сущности.
  factory ContractorBankAccountModel.fromDomain(
    ContractorBankAccount account,
  ) => ContractorBankAccountModel(
    id: account.id,
    companyId: account.companyId,
    contractorId: account.contractorId,
    bankName: account.bankName,
    bankCity: account.bankCity,
    bik: account.bik,
    corrAccount: account.corrAccount,
    accountNumber: account.accountNumber,
    isPrimary: account.isPrimary,
    createdAt: account.createdAt,
    updatedAt: account.updatedAt,
  );

  /// Преобразует модель в доменную сущность.
  ContractorBankAccount toDomain() => ContractorBankAccount(
    id: id,
    companyId: companyId,
    contractorId: contractorId,
    bankName: bankName,
    bankCity: bankCity,
    bik: bik,
    corrAccount: corrAccount,
    accountNumber: accountNumber,
    isPrimary: isPrimary,
    createdAt: createdAt,
    updatedAt: updatedAt,
  );
}
