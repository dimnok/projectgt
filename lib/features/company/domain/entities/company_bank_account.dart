import 'package:freezed_annotation/freezed_annotation.dart';

part 'company_bank_account.freezed.dart';
part 'company_bank_account.g.dart';

/// Представляет банковский счет компании.
@freezed
abstract class CompanyBankAccount with _$CompanyBankAccount {
  /// Создает экземпляр [CompanyBankAccount].
  const factory CompanyBankAccount({
    required String id,
    @JsonKey(name: 'company_id') required String companyId,
    @JsonKey(name: 'bank_name') required String bankName,
    @JsonKey(name: 'bank_city') String? bankCity,
    @JsonKey(name: 'account_number') required String accountNumber,
    @JsonKey(name: 'corr_account') String? corrAccount,
    String? bik,
    @JsonKey(name: 'is_primary') @Default(false) bool isPrimary,
    @JsonKey(name: 'created_at') DateTime? createdAt,
  }) = _CompanyBankAccount;

  /// Создает экземпляр [CompanyBankAccount] из JSON.
  factory CompanyBankAccount.fromJson(Map<String, dynamic> json) =>
      _$CompanyBankAccountFromJson(json);
}
