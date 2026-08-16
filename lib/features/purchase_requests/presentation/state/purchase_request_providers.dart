import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:projectgt/core/di/providers.dart';
import 'package:projectgt/core/utils/supabase_error_message.dart';
import 'package:projectgt/features/company/presentation/providers/company_providers.dart';
import 'package:projectgt/features/purchase_requests/data/repositories/purchase_request_repository_impl.dart';
import 'package:projectgt/features/purchase_requests/domain/entities/purchase_request.dart';
import 'package:projectgt/features/purchase_requests/domain/entities/purchase_request_history_entry.dart';
import 'package:projectgt/features/purchase_requests/domain/entities/purchase_request_invoice.dart';
import 'package:projectgt/features/purchase_requests/domain/entities/purchase_request_item.dart';
import 'package:projectgt/features/purchase_requests/domain/entities/purchase_request_list_item.dart';
import 'package:projectgt/features/purchase_requests/domain/entities/purchase_request_company_user.dart';
import 'package:projectgt/features/purchase_requests/domain/entities/purchase_request_settings.dart';
import 'package:projectgt/features/purchase_requests/domain/entities/purchase_request_status.dart';
import 'package:projectgt/features/purchase_requests/domain/repositories/purchase_request_repository.dart';

/// Лимит записей в одной загрузке списка заявок.
const kPurchaseRequestListLimit = 50;

/// Репозиторий заявок на закупку.
final purchaseRequestRepositoryProvider =
    Provider<PurchaseRequestRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  final companyId = ref.watch(activeCompanyIdProvider);
  return PurchaseRequestRepositoryImpl(client, companyId ?? '');
});

/// Состояние списка заявок.
class PurchaseRequestListState {
  /// Создаёт состояние.
  const PurchaseRequestListState({
    this.items = const [],
    this.isLoading = false,
    this.error,
    this.filter = PurchaseRequestListFilter.onMe,
    this.search,
    this.isTruncatedByLimit = false,
  });

  /// Элементы реестра.
  final List<PurchaseRequestListItem> items;

  /// Загрузка.
  final bool isLoading;

  /// Ошибка.
  final String? error;

  /// Активный фильтр.
  final PurchaseRequestListFilter filter;

  /// Строка поиска.
  final String? search;

  /// Список обрезан лимитом [kPurchaseRequestListLimit].
  final bool isTruncatedByLimit;

  /// Копия с изменениями.
  PurchaseRequestListState copyWith({
    List<PurchaseRequestListItem>? items,
    bool? isLoading,
    String? error,
    PurchaseRequestListFilter? filter,
    String? search,
    bool? isTruncatedByLimit,
    bool clearError = false,
    bool clearSearch = false,
  }) {
    return PurchaseRequestListState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      filter: filter ?? this.filter,
      search: clearSearch ? null : (search ?? this.search),
      isTruncatedByLimit: isTruncatedByLimit ?? this.isTruncatedByLimit,
    );
  }
}

/// Notifier списка заявок.
class PurchaseRequestListNotifier extends StateNotifier<PurchaseRequestListState> {
  /// Создаёт notifier.
  PurchaseRequestListNotifier(this._repository)
      : super(const PurchaseRequestListState(isLoading: true)) {
    load();
  }

  final PurchaseRequestRepository _repository;
  Timer? _searchDebounce;

  /// Освобождает ресурсы.
  void disposeResources() {
    _searchDebounce?.cancel();
  }

  /// Сменить фильтр вкладки.
  Future<void> setFilter(PurchaseRequestListFilter filter) async {
    if (state.filter == filter) return;
    state = state.copyWith(
      filter: filter,
      items: const [],
      isLoading: true,
      clearError: true,
    );
    await load(quiet: true);
  }

  /// Сменить поиск с debounce.
  void setSearchQuery(String query) {
    _searchDebounce?.cancel();
    final normalized = query.trim().isEmpty ? null : query.trim();
    if (state.search == normalized) return;

    if (normalized == null) {
      state = state.copyWith(clearSearch: true, clearError: true);
      load();
      return;
    }

    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      state = state.copyWith(search: normalized, clearError: true);
      load();
    });
  }

  /// Загрузить список.
  Future<void> load({bool quiet = false}) async {
    if (!quiet) {
      state = state.copyWith(isLoading: true, clearError: true);
    }
    try {
      final items = await _repository.list(
        filter: state.filter,
        search: state.search,
        limit: kPurchaseRequestListLimit,
      );
      state = state.copyWith(
        items: items,
        isLoading: false,
        isTruncatedByLimit: items.length >= kPurchaseRequestListLimit,
        clearError: true,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: formatSupabaseErrorMessage(e),
      );
    }
  }
}

/// Список заявок (единый notifier без family — без пересоздания при смене фильтра).
final purchaseRequestListProvider = StateNotifierProvider.autoDispose<
    PurchaseRequestListNotifier,
    PurchaseRequestListState>((ref) {
  final repo = ref.watch(purchaseRequestRepositoryProvider);
  final notifier = PurchaseRequestListNotifier(repo);
  ref.onDispose(notifier.disposeResources);
  return notifier;
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

/// Счета заявки.
final purchaseRequestInvoicesProvider = FutureProvider.autoDispose
    .family<List<PurchaseRequestInvoice>, String>((ref, requestId) async {
  final repo = ref.watch(purchaseRequestRepositoryProvider);
  return repo.getInvoices(requestId);
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

/// Сбрасывает кэш деталей, истории, позиций и списка заявок.
void invalidatePurchaseRequestCaches(WidgetRef ref, String requestId) {
  ref.invalidate(purchaseRequestDetailsProvider(requestId));
  ref.invalidate(purchaseRequestHistoryProvider(requestId));
  ref.invalidate(purchaseRequestItemsProvider(requestId));
  ref.invalidate(purchaseRequestInvoicesProvider(requestId));
  ref.invalidate(purchaseRequestListProvider);
}
