import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:projectgt/features/contractors/domain/entities/contractor_bank_account.dart';
import 'package:projectgt/core/di/providers.dart';
import 'package:projectgt/features/company/presentation/providers/company_providers.dart';

part 'contractor_bank_account_state.freezed.dart';

/// Статус состояния банковских счетов.
enum BankAccountStatus { 
  /// Начальное состояние.
  initial, 
  /// Загрузка данных.
  loading, 
  /// Данные успешно загружены.
  loaded, 
  /// Ошибка при работе с данными.
  error 
}

/// Состояние банковских счетов контрагента.
@freezed
abstract class ContractorBankAccountState with _$ContractorBankAccountState {
  /// Создает состояние банковских счетов.
  const factory ContractorBankAccountState({
    @Default([]) List<ContractorBankAccount> accounts,
    @Default(BankAccountStatus.initial) BankAccountStatus status,
    String? errorMessage,
  }) = _ContractorBankAccountState;
}

/// Нотификатор для управления банковскими счетами контрагента.
///
/// Отвечает за загрузку, добавление, обновление и удаление банковских счетов
/// в контексте конкретного контрагента.
class ContractorBankAccountNotifier
    extends StateNotifier<ContractorBankAccountState> {
  /// Идентификатор контрагента.
  final String contractorId;

  /// Ссылка на Riverpod для доступа к зависимостям.
  final Ref ref;

  /// Создаёт [ContractorBankAccountNotifier].
  ContractorBankAccountNotifier(this.contractorId, this.ref)
      : super(const ContractorBankAccountState()) {
    loadAccounts();
  }

  /// Загружает список счетов для указанного контрагента.
  Future<void> loadAccounts() async {
    final activeCompanyId = ref.read(activeCompanyIdProvider);
    if (activeCompanyId == null) return;

    state = state.copyWith(status: BankAccountStatus.loading);
    try {
      final repository = ref.read(contractorRepositoryProvider);
      final accounts = await repository.getBankAccounts(contractorId, activeCompanyId);
      state = state.copyWith(
        accounts: accounts,
        status: BankAccountStatus.loaded,
      );
    } catch (e) {
      state = state.copyWith(
        status: BankAccountStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  /// Добавляет новый банковский счет.
  Future<void> addAccount(ContractorBankAccount account) async {
    state = state.copyWith(status: BankAccountStatus.loading);
    try {
      final repository = ref.read(contractorRepositoryProvider);
      await repository.addBankAccount(account);
      await loadAccounts();
    } catch (e) {
      state = state.copyWith(
        status: BankAccountStatus.error,
        errorMessage: e.toString(),
      );
      rethrow;
    }
  }

  /// Обновляет существующий банковский счет.
  Future<void> updateAccount(ContractorBankAccount account) async {
    state = state.copyWith(status: BankAccountStatus.loading);
    try {
      final repository = ref.read(contractorRepositoryProvider);
      await repository.updateBankAccount(account);
      await loadAccounts();
    } catch (e) {
      state = state.copyWith(
        status: BankAccountStatus.error,
        errorMessage: e.toString(),
      );
      rethrow;
    }
  }

  /// Удаляет банковский счет по ID.
  Future<void> deleteAccount(String accountId) async {
    state = state.copyWith(status: BankAccountStatus.loading);
    try {
      final repository = ref.read(contractorRepositoryProvider);
      await repository.deleteBankAccount(accountId);
      await loadAccounts();
    } catch (e) {
      state = state.copyWith(
        status: BankAccountStatus.error,
        errorMessage: e.toString(),
      );
      rethrow;
    }
  }
}

/// Провайдер нотификатора банковских счетов контрагента.
final contractorBankAccountNotifierProvider = StateNotifierProvider.family<
    ContractorBankAccountNotifier,
    ContractorBankAccountState,
    String>(
  (ref, contractorId) =>
      ContractorBankAccountNotifier(contractorId, ref),
);
