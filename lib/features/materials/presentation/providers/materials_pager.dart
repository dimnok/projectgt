import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/di/providers.dart';
import '../../../../features/company/presentation/providers/company_providers.dart';
import '../../data/models/material_item.dart';
import 'materials_providers.dart';

/// Пагинатор списка материалов с серверной фильтрацией и поиском.
class MaterialsPager extends StateNotifier<AsyncValue<List<MaterialItem>>> {
  final SupabaseClient _client;
  final String _activeCompanyId;

  /// Размер страницы пагинации.
  final int pageSize;

  /// Номер договора для фильтрации.
  final String? contractNumber;
  Map<String, String> _columnFilters = {};
  bool _isLoading = false;
  int _offset = 0;

  /// Есть ли ещё данные для дозагрузки.
  bool hasMore = true;
  bool _initialized = false;

  /// Создаёт пагинатор материалов.
  MaterialsPager(this._client, this._activeCompanyId,
      {this.pageSize = 50, this.contractNumber})
      : super(const AsyncValue.loading());

  /// Загружает первую страницу данных.
  Future<void> loadInitial() async {
    if (_initialized) return;
    _initialized = true;
    await _loadPage(reset: true);
  }

  /// Перезагружает данные с обнулением пагинации.
  Future<void> refresh() async {
    _initialized = false;
    await _loadPage(reset: true);
  }

  /// Обновляет фильтры по колонкам и перезагружает первую страницу.
  void updateColumnFilters(Map<String, String> filters) {
    if (mapEquals(_columnFilters, filters) && _initialized) return;
    _columnFilters = Map.from(filters);
    _initialized = true;
    _loadPage(reset: true);
  }

  /// Догружает следующую страницу (если доступна).
  Future<void> loadMore() async {
    if (_isLoading || !hasMore) return;
    await _loadPage(reset: false);
  }

  Future<void> _loadPage({required bool reset}) async {
    if (reset) {
      _offset = 0;
      hasMore = true;
    }

    _isLoading = true;
    try {
      final from = _offset;

      final rows = await _client.rpc('get_materials_with_usage_v3', params: {
        'p_company_id': _activeCompanyId,
        'p_contract_number': contractNumber,
        'p_search_name': _columnFilters['name'],
        'p_search_unit': _columnFilters['unit'],
        'p_search_receipt_number': _columnFilters['receipt_number'],
        'p_limit': pageSize,
        'p_offset': from,
      });

      final page = (rows as List<dynamic>)
          .map((e) => MaterialItem.fromJson(e as Map<String, dynamic>))
          .toList();

      if (!mounted) return;
      hasMore = page.length == pageSize;

      if (reset) {
        state = AsyncValue.data(page);
        _offset = page.length;
      } else {
        final current = state.value ?? [];
        state = AsyncValue.data([...current, ...page]);
        _offset += page.length;
      }
    } catch (e, st) {
      if (!mounted) return;
      state = AsyncValue.error(e, st);
    } finally {
      if (mounted) {
        _isLoading = false;
      }
    }
  }
}

/// Провайдер пагинатора материалов.
final materialsPagerProvider =
    StateNotifierProvider<MaterialsPager, AsyncValue<List<MaterialItem>>>(
        (ref) {
  final client = ref.watch(supabaseClientProvider);
  final activeId = ref.watch(activeCompanyIdProvider);
  final contract = ref.watch(selectedContractNumberProvider);
  final pager = MaterialsPager(client, activeId ?? '', contractNumber: contract);
  // Живое обновление фильтров по колонкам
  ref.listen<Map<String, String>>(materialsColumnFiltersProvider, (prev, next) {
    pager.updateColumnFilters(next);
  });
  // Стартовое применение
  pager.updateColumnFilters(ref.read(materialsColumnFiltersProvider));
  return pager;
});
