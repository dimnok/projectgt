import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/di/providers.dart';
import '../../../../features/company/presentation/providers/company_providers.dart';
import '../../data/models/material_item.dart';
import 'materials_providers.dart';
import '../widgets/materials_search.dart';

/// Пагинатор списка материалов с серверной фильтрацией и поиском.
class MaterialsPager extends StateNotifier<AsyncValue<List<MaterialItem>>> {
  final SupabaseClient _client;
  final String _activeCompanyId;

  /// Размер страницы пагинации.
  final int pageSize;

  /// Номер договора для фильтрации.
  final String? contractNumber;
  String _query = '';
  bool _isLoading = false;
  int _offset = 0;

  /// Есть ли ещё данные для дозагрузки.
  bool hasMore = true;
  bool _initialized = false;

  /// Создаёт пагинатор материалов.
  MaterialsPager(this._client, this._activeCompanyId,
      {this.pageSize = 50, this.contractNumber})
      : super(const AsyncValue.loading()) {
    // Автоинициализация первой страницы сразу после создания
    Future.microtask(() => loadInitial());
  }

  /// Загружает первую страницу данных.
  Future<void> loadInitial() async {
    if (_initialized) return;
    _initialized = true;
    if (!mounted) return;
    state = const AsyncValue.loading();
    _offset = 0;
    hasMore = true;
    await _loadPage(reset: true);
  }

  /// Перезагружает данные с обнулением пагинации.
  Future<void> refresh() async {
    _initialized = false;
    await loadInitial();
  }

  /// Обновляет поисковый запрос и перезагружает первую страницу.
  void updateQuery(String q) {
    final next = q;
    if (_query == next) return;
    _query = next;
    // Мягкая перезагрузка первой страницы без мигания loading
    _offset = 0;
    hasMore = true;
    _initialized = true;
    // ignore: discarded_futures
    _loadPage(reset: true);
  }

  /// Догружает следующую страницу (если доступна).
  Future<void> loadMore() async {
    if (_isLoading || !hasMore) return;
    await _loadPage(reset: false);
  }

  Future<void> _loadPage({required bool reset}) async {
    _isLoading = true;
    try {
      final from = _offset;
      final to = _offset + pageSize - 1;

      var builder = _client
          .from('v_materials_with_usage')
          .select()
          .eq('company_id', _activeCompanyId);

      if (contractNumber != null && contractNumber!.trim().isNotEmpty) {
        builder = builder.eq('contract_number', contractNumber!.trim());
      }
      if (_query.trim().isNotEmpty) {
        final q = '%${_query.trim()}%';
        builder = builder
            .or('name.ilike."$q",unit.ilike."$q",receipt_number.ilike."$q"');
      }
      final rows = await builder
          .order('receipt_date', ascending: false)
          .order('name', ascending: true)
          .range(from, to);

      final page = (rows as List<dynamic>)
          .map((e) => MaterialItem.fromJson(e as Map<String, dynamic>))
          .toList();

      if (!mounted) return;
      hasMore = page.length == pageSize;

      List<MaterialItem> next =
          reset ? <MaterialItem>[] : (state.value ?? <MaterialItem>[]);
      next = [...next, ...page];
      state = AsyncValue.data(next);
      _offset += page.length;
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
  // Живое обновление при наборе
  ref.listen<String>(materialsSearchQueryProvider('materials'), (prev, next) {
    pager.updateQuery(next);
  });
  // Стартовое применение
  pager.updateQuery(ref.read(materialsSearchQueryProvider('materials')));
  return pager;
});
