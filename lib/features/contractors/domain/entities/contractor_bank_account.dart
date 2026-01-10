import 'package:freezed_annotation/freezed_annotation.dart';

part 'contractor_bank_account.freezed.dart';
part 'contractor_bank_account.g.dart';

/// Представляет банковский счет контрагента.
@freezed
abstract class ContractorBankAccount with _$ContractorBankAccount {
  /// Создает экземпляр [ContractorBankAccount].
  const factory ContractorBankAccount({
    required String id,
    @JsonKey(name: 'company_id') required String companyId,
    @JsonKey(name: 'contractor_id') required String contractorId,
    @JsonKey(name: 'bank_name') required String bankName,
    @JsonKey(name: 'bank_city') String? bankCity,
    String? bik,
    @JsonKey(name: 'corr_account') String? corrAccount,
    @JsonKey(name: 'account_number') required String accountNumber,
    @JsonKey(name: 'is_primary') @Default(false) bool isPrimary,
    @JsonKey(name: 'created_at') DateTime? createdAt,
    @JsonKey(name: 'updated_at') DateTime? updatedAt,
  }) = _ContractorBankAccount;

  /// Создает экземпляр [ContractorBankAccount] из JSON.
  factory ContractorBankAccount.fromJson(Map<String, dynamic> json) =>
      _$ContractorBankAccountFromJson(json);
}

