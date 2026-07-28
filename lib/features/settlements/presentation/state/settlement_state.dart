import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:projectgt/core/di/providers.dart';
import 'package:projectgt/features/company/presentation/providers/company_providers.dart';
import 'package:projectgt/features/settlements/data/repositories/settlement_repository_impl.dart';
import 'package:projectgt/features/settlements/domain/entities/settlement_operation.dart';
import 'package:projectgt/features/settlements/domain/repositories/settlement_repository.dart';

/// Провайдер репозитория взаиморасчётов.
final settlementRepositoryProvider = Provider<SettlementRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  final companyId = ref.watch(activeCompanyIdProvider);
  return SettlementRepositoryImpl(client, companyId ?? '');
});

/// Состояние списка операций взаиморасчётов.
class SettlementListState {
  /// Операции.
  final List<SettlementOperation> operations;

  /// Идёт загрузка.
  final bool isLoading;

  /// Ошибка.
  final String? error;

  /// Создаёт состояние.
  const SettlementListState({
    this.operations = const [],
    this.isLoading = false,
    this.error,
  });

  /// Копия с изменениями.
  SettlementListState copyWith({
    List<SettlementOperation>? operations,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return SettlementListState(
      operations: operations ?? this.operations,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }

  /// Сумма «к оплате».
  double get totalInvoiced =>
      operations.fold<double>(0, (s, o) => s + o.totalToPay);

  /// Сумма оплачено.
  double get totalPaid =>
      operations.fold<double>(0, (s, o) => s + o.paidAmount);

  /// Долг (не ниже 0).
  double get totalDebt {
    final d = totalInvoiced - totalPaid;
    return d < 0 ? 0 : d;
  }
}

/// Notifier списка операций.
class SettlementListNotifier extends StateNotifier<SettlementListState> {
  final SettlementRepository _repository;
  final String? _contractId;

  /// Создаёт notifier. [contractId] ограничивает выборку договором.
  SettlementListNotifier(this._repository, {String? contractId})
      : _contractId = contractId,
        super(const SettlementListState()) {
    load();
  }

  /// Загрузить операции.
  Future<void> load({bool quiet = false}) async {
    if (!quiet) {
      state = state.copyWith(isLoading: true, clearError: true);
    }
    try {
      final list =
          await _repository.getOperations(contractId: _contractId);
      state = state.copyWith(
        operations: list,
        isLoading: false,
        clearError: true,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Создать операцию и обновить список.
  Future<SettlementOperation?> create(SettlementOperation operation) async {
    try {
      final created = await _repository.createOperation(operation);
      await load(quiet: true);
      return created;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return null;
    }
  }

  /// Обновить операцию.
  Future<SettlementOperation?> update(SettlementOperation operation) async {
    try {
      final updated = await _repository.updateOperation(operation);
      await load(quiet: true);
      return updated;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return null;
    }
  }

  /// Удалить операцию.
  Future<bool> delete(String id) async {
    try {
      await _repository.deleteOperation(id);
      await load(quiet: true);
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }
}

/// Провайдер общего реестра операций компании.
final settlementListProvider =
    StateNotifierProvider<SettlementListNotifier, SettlementListState>((ref) {
  final repo = ref.watch(settlementRepositoryProvider);
  return SettlementListNotifier(repo);
});

/// Провайдер операций по договору (вкладка «Финансы»).
final contractSettlementsProvider = StateNotifierProvider.family<
    SettlementListNotifier, SettlementListState, String>((ref, contractId) {
  final repo = ref.watch(settlementRepositoryProvider);
  return SettlementListNotifier(repo, contractId: contractId);
});
