import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:projectgt/core/di/providers.dart';
import 'package:projectgt/core/utils/supabase_error_message.dart';
import 'package:projectgt/features/company/presentation/providers/company_providers.dart';
import 'package:projectgt/features/purchase_requests/data/repositories/purchase_request_repository_impl.dart';
import 'package:projectgt/features/purchase_requests/domain/entities/purchase_request.dart';
import 'package:projectgt/features/purchase_requests/domain/entities/purchase_request_history_entry.dart';
import 'package:projectgt/features/purchase_requests/domain/entities/purchase_request_item.dart';
import 'package:projectgt/features/purchase_requests/domain/entities/purchase_request_list_item.dart';
import 'package:projectgt/features/purchase_requests/domain/entities/purchase_request_company_user.dart';
import 'package:projectgt/features/purchase_requests/domain/entities/purchase_request_settings.dart';
import 'package:projectgt/features/purchase_requests/domain/entities/purchase_request_status.dart';
import 'package:projectgt/features/purchase_requests/domain/repositories/purchase_request_repository.dart';

/// Репозиторий заявок на закупку.
final purchaseRequestRepositoryProvider =
    Provider<PurchaseRequestRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  final companyId = ref.watch(activeCompanyIdProvider);
  return PurchaseRequestRepositoryImpl(client, companyId ?? '');
});

/// Параметры списка заявок.
class PurchaseRequestListParams {
  /// Создаёт параметры.
  const PurchaseRequestListParams({
    this.filter = PurchaseRequestListFilter.onMe,
    this.search,
  });

  /// Активный фильтр вкладки.
  final PurchaseRequestListFilter filter;

  /// Строка поиска.
  final String? search;

  @override
  bool operator ==(Object other) =>
      other is PurchaseRequestListParams &&
      other.filter == filter &&
      other.search == search;

  @override
  int get hashCode => Object.hash(filter, search);
}

/// Состояние списка заявок.
class PurchaseRequestListState {
  /// Создаёт состояние.
  const PurchaseRequestListState({
    this.items = const [],
    this.isLoading = false,
    this.error,
  });

  /// Элементы реестра.
  final List<PurchaseRequestListItem> items;

  /// Загрузка.
  final bool isLoading;

  /// Ошибка.
  final String? error;

  /// Копия с изменениями.
  PurchaseRequestListState copyWith({
    List<PurchaseRequestListItem>? items,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return PurchaseRequestListState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

/// Notifier списка заявок.
class PurchaseRequestListNotifier extends StateNotifier<PurchaseRequestListState> {
  /// Создаёт notifier.
  PurchaseRequestListNotifier(this._repository, this._params)
      : super(const PurchaseRequestListState()) {
    load();
  }

  final PurchaseRequestRepository _repository;
  PurchaseRequestListParams _params;

  /// Обновить параметры и перезагрузить.
  Future<void> setParams(PurchaseRequestListParams params) async {
    _params = params;
    await load();
  }

  /// Загрузить список.
  Future<void> load({bool quiet = false}) async {
    if (!quiet) {
      state = state.copyWith(isLoading: true, clearError: true);
    }
    try {
      final items = await _repository.list(
        filter: _params.filter,
        search: _params.search,
      );
      state = state.copyWith(items: items, isLoading: false, clearError: true);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: formatSupabaseErrorMessage(e));
    }
  }
}

/// Список заявок с фильтром.
final purchaseRequestListProvider = StateNotifierProvider.autoDispose.family<
    PurchaseRequestListNotifier,
    PurchaseRequestListState,
    PurchaseRequestListParams>((ref, params) {
  final repo = ref.watch(purchaseRequestRepositoryProvider);
  return PurchaseRequestListNotifier(repo, params);
});

/// Детали заявки.
final purchaseRequestDetailsProvider = FutureProvider.autoDispose
    .family<PurchaseRequest?, String>((ref, id) async {
  final repo = ref.watch(purchaseRequestRepositoryProvider);
  return repo.getRequest(id);
});

/// Позиции заявки.
final purchaseRequestItemsProvider = FutureProvider.autoDispose
    .family<List<PurchaseRequestItem>, String>((ref, requestId) async {
  final repo = ref.watch(purchaseRequestRepositoryProvider);
  return repo.getItems(requestId);
});

/// История заявки.
final purchaseRequestHistoryProvider = FutureProvider.autoDispose
    .family<List<PurchaseRequestHistoryEntry>, String>((ref, requestId) async {
  final repo = ref.watch(purchaseRequestRepositoryProvider);
  return repo.getHistory(requestId);
});

/// Настройки модуля.
final purchaseRequestSettingsProvider =
    FutureProvider.autoDispose<PurchaseRequestSettings?>((ref) async {
  final repo = ref.watch(purchaseRequestRepositoryProvider);
  return repo.getSettings();
});

/// Пользователи компании для настройки маршрута.
final purchaseRequestCompanyUsersProvider =
    FutureProvider.autoDispose<List<PurchaseRequestCompanyUser>>((ref) async {
  final repo = ref.watch(purchaseRequestRepositoryProvider);
  return repo.getCompanyUsers();
});
