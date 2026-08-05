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

  /// Итоговая сумма счетов (к оплате).
  double get totalAmount => operations.totalAmount;

  /// Сумма оплат по всем счетам.
  double get totalPaid => operations.totalPaid;

  /// Остаток долга (только положительные остатки).
  double get totalDebt => operations.totalDebt;
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
    SettlementOperation? created;
    try {
      created = await _repository.createOperation(operation);
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return null;
    }
    _upsertOperation(created);
    await _reloadQuietly();
    return created;
  }

  /// Обновить операцию.
  Future<SettlementOperation?> update(SettlementOperation operation) async {
    SettlementOperation? updated;
    try {
      updated = await _repository.updateOperation(operation);
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return null;
    }
    _upsertOperation(updated);
    await _reloadQuietly();
    return updated;
  }

  /// Удалить операцию.
  Future<bool> delete(String id) async {
    try {
      await _repository.deleteOperation(id);
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
    _removeOperation(id);
    await _reloadQuietly();
    return true;
  }

  void _upsertOperation(SettlementOperation operation) {
    final list = [...state.operations];
    final index = list.indexWhere((o) => o.id == operation.id);
    if (index >= 0) {
      list[index] = operation;
    } else {
      list.insert(0, operation);
    }
    state = state.copyWith(operations: list, clearError: true);
  }

  void _removeOperation(String id) {
    state = state.copyWith(
      operations: state.operations.where((o) => o.id != id).toList(),
      clearError: true,
    );
  }

  Future<void> _reloadQuietly() async {
    try {
      await load(quiet: true);
    } catch (_) {
      // Сохраняем оптимистичное состояние, если фоновая перезагрузка упала.
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
