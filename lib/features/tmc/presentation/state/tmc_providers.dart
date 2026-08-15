import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:projectgt/core/di/providers.dart';
import 'package:projectgt/features/company/presentation/providers/company_providers.dart';
import 'package:projectgt/features/tmc/data/repositories/tmc_repository_impl.dart';
import 'package:projectgt/features/tmc/domain/entities/tmc_dashboard_stats.dart';
import 'package:projectgt/features/tmc/domain/entities/tmc_enums.dart';
import 'package:projectgt/features/tmc/domain/entities/tmc_item.dart';
import 'package:projectgt/features/tmc/domain/entities/tmc_operation.dart';
import 'package:projectgt/features/tmc/domain/repositories/tmc_repository.dart';
import 'package:projectgt/features/tmc/domain/entities/tmc_category.dart';
import 'package:projectgt/features/tmc/domain/entities/tmc_condition.dart';
import 'package:projectgt/features/tmc/domain/entities/tmc_assignment.dart';
import 'package:projectgt/features/tmc/domain/entities/tmc_unit.dart';
import 'package:projectgt/features/tmc/domain/entities/tmc_warehouse.dart';
import 'package:projectgt/features/tmc/domain/entities/tmc_stock_balance.dart';

/// Провайдер репозитория ТМЦ.
final tmcRepositoryProvider = Provider<TmcRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  final companyId = ref.watch(activeCompanyIdProvider);
  return TmcRepositoryImpl(client, companyId ?? '');
});

/// KPI дашборда ТМЦ.
final tmcDashboardProvider = FutureProvider<TmcDashboardStats>((ref) async {
  final repo = ref.watch(tmcRepositoryProvider);
  return repo.getDashboardStats();
});

/// Фильтры реестра позиций ТМЦ.
class TmcItemsListFilters {
  /// Поисковая строка.
  final String? search;

  /// Категория.
  final String? categoryId;

  /// Тип учёта.
  final TmcAccountingType? accountingType;

  /// Размер страницы.
  final int limit;

  /// Смещение.
  final int offset;

  /// Создаёт фильтры.
  const TmcItemsListFilters({
    this.search,
    this.categoryId,
    this.accountingType,
    this.limit = 50,
    this.offset = 0,
  });

  /// Копия с изменениями.
  TmcItemsListFilters copyWith({
    String? search,
    String? categoryId,
    TmcAccountingType? accountingType,
    int? limit,
    int? offset,
    bool clearSearch = false,
    bool clearCategoryId = false,
    bool clearAccountingType = false,
  }) {
    return TmcItemsListFilters(
      search: clearSearch ? null : (search ?? this.search),
      categoryId: clearCategoryId ? null : (categoryId ?? this.categoryId),
      accountingType: clearAccountingType
          ? null
          : (accountingType ?? this.accountingType),
      limit: limit ?? this.limit,
      offset: offset ?? this.offset,
    );
  }
}

/// Состояние пагинированного списка позиций ТМЦ.
class TmcItemsListState {
  /// Позиции.
  final List<TmcItem> items;

  /// Общее количество записей.
  final int totalCount;

  /// Идёт загрузка.
  final bool isLoading;

  /// Ошибка.
  final String? error;

  /// Активные фильтры.
  final TmcItemsListFilters filters;

  /// Создаёт состояние.
  const TmcItemsListState({
    this.items = const [],
    this.totalCount = 0,
    this.isLoading = false,
    this.error,
    this.filters = const TmcItemsListFilters(),
  });

  /// Копия с изменениями.
  TmcItemsListState copyWith({
    List<TmcItem>? items,
    int? totalCount,
    bool? isLoading,
    String? error,
    TmcItemsListFilters? filters,
    bool clearError = false,
  }) {
    return TmcItemsListState(
      items: items ?? this.items,
      totalCount: totalCount ?? this.totalCount,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      filters: filters ?? this.filters,
    );
  }
}

/// Notifier реестра позиций ТМЦ.
class TmcItemsListNotifier extends StateNotifier<TmcItemsListState> {
  final TmcRepository _repository;

  /// Создаёт notifier.
  TmcItemsListNotifier(this._repository) : super(const TmcItemsListState()) {
    load();
  }

  /// Загрузить список с текущими фильтрами.
  Future<void> load({bool quiet = false}) async {
    if (!quiet) {
      state = state.copyWith(isLoading: true, clearError: true);
    }

    try {
      final result = await _repository.listItems(
        search: state.filters.search,
        categoryId: state.filters.categoryId,
        accountingType: state.filters.accountingType,
        limit: state.filters.limit,
        offset: state.filters.offset,
      );

      state = state.copyWith(
        items: result.items,
        totalCount: result.totalCount,
        isLoading: false,
        clearError: true,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Обновить фильтры и перезагрузить с первой страницы.
  Future<void> applyFilters(TmcItemsListFilters filters) async {
    state = state.copyWith(
      filters: filters.copyWith(offset: 0),
      clearError: true,
    );
    await load();
  }
}

/// Провайдер списка позиций ТМЦ с фильтрами.
final tmcItemsListProvider =
    StateNotifierProvider<TmcItemsListNotifier, TmcItemsListState>((ref) {
      final repo = ref.watch(tmcRepositoryProvider);
      return TmcItemsListNotifier(repo);
    });

/// Справочник категорий ТМЦ.
final tmcCategoriesProvider = FutureProvider<List<TmcCategory>>((ref) async {
  final repo = ref.watch(tmcRepositoryProvider);
  return repo.listCategories();
});

/// Справочник состояний ТМЦ.
final tmcConditionsProvider = FutureProvider<List<TmcCondition>>((ref) async {
  final repo = ref.watch(tmcRepositoryProvider);
  return repo.listConditions();
});

/// Справочник складов ТМЦ.
final tmcWarehousesProvider = FutureProvider<List<TmcWarehouse>>((ref) async {
  final repo = ref.watch(tmcRepositoryProvider);
  return repo.listWarehouses();
});

/// Параметры запроса остатков по складам.
typedef TmcStockQuery = ({String? warehouseId, String search});

/// Остатки ТМЦ по складам.
final tmcStockProvider =
    FutureProvider.family<List<TmcStockBalance>, TmcStockQuery>((
      ref,
      query,
    ) async {
      final repo = ref.watch(tmcRepositoryProvider);
      return repo.listStock(
        warehouseId: query.warehouseId,
        search: query.search.isEmpty ? null : query.search,
      );
    });

/// Состояние списка операций ТМЦ.
class TmcOperationsListState {
  /// Операции.
  final List<TmcOperation> operations;

  /// Идёт загрузка.
  final bool isLoading;

  /// Ошибка.
  final String? error;

  /// Фильтр по типу операции.
  final TmcOperationType? operationType;

  /// Создаёт состояние.
  const TmcOperationsListState({
    this.operations = const [],
    this.isLoading = false,
    this.error,
    this.operationType,
  });

  /// Копия с изменениями.
  TmcOperationsListState copyWith({
    List<TmcOperation>? operations,
    bool? isLoading,
    String? error,
    TmcOperationType? operationType,
    bool clearError = false,
    bool clearOperationType = false,
  }) {
    return TmcOperationsListState(
      operations: operations ?? this.operations,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      operationType: clearOperationType
          ? null
          : (operationType ?? this.operationType),
    );
  }
}

/// Notifier списка операций ТМЦ.
class TmcOperationsListNotifier extends StateNotifier<TmcOperationsListState> {
  final TmcRepository _repository;

  /// Создаёт notifier.
  TmcOperationsListNotifier(this._repository)
    : super(const TmcOperationsListState()) {
    load();
  }

  /// Загрузить операции.
  Future<void> load({bool quiet = false}) async {
    if (!quiet) {
      state = state.copyWith(isLoading: true, clearError: true);
    }

    try {
      final list = await _repository.listOperations(
        operationType: state.operationType,
      );
      state = state.copyWith(
        operations: list,
        isLoading: false,
        clearError: true,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Установить фильтр по типу операции.
  Future<void> setOperationType(TmcOperationType? type) async {
    state = state.copyWith(
      operationType: type,
      clearOperationType: type == null,
      clearError: true,
    );
    await load();
  }
}

/// Провайдер списка операций ТМЦ.
final tmcOperationsProvider =
    StateNotifierProvider<TmcOperationsListNotifier, TmcOperationsListState>((
      ref,
    ) {
      final repo = ref.watch(tmcRepositoryProvider);
      return TmcOperationsListNotifier(repo);
    });

/// Позиция каталога по id.
final tmcItemProvider = FutureProvider.family<TmcItem?, String>((
  ref,
  id,
) async {
  final repo = ref.watch(tmcRepositoryProvider);
  return repo.getItem(id);
});

/// Единицы позиции.
final tmcItemUnitsProvider = FutureProvider.family<List<TmcUnit>, String>((
  ref,
  itemId,
) async {
  final repo = ref.watch(tmcRepositoryProvider);
  return repo.listUnits(itemId: itemId);
});

/// Выдачи сотрудника (null — все).
final tmcAssignmentsProvider =
    FutureProvider.family<List<TmcAssignment>, String?>((
      ref,
      employeeId,
    ) async {
      final repo = ref.watch(tmcRepositoryProvider);
      return repo.listAssignments(employeeId: employeeId);
    });

/// Операции по позиции.
final tmcItemOperationsProvider =
    FutureProvider.family<List<TmcOperation>, String>((ref, itemId) async {
      final repo = ref.watch(tmcRepositoryProvider);
      return repo.listOperations(itemId: itemId, limit: 200);
    });
