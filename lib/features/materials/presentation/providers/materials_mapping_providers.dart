import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:projectgt/core/di/providers.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'materials_providers.dart';
import '../widgets/materials_search.dart';

/// Строка таблицы сопоставления: позиция сметы + количество алиасов (+ предзагруженные алиасы)
class EstimateMappingRow {
  /// Идентификатор строки сметы.
  final String id;

  /// Номер позиции сметы.
  final String number;

  /// Наименование позиции сметы.
  final String name;

  /// Единица измерения сметной позиции.
  final String unit;

  /// Количество связанных алиасов.
  final int aliasCount;

  /// Предзагруженные алиасы для строки.
  final List<MaterialAliasRow> aliases;

  /// Создаёт строку сметного сопоставления.
  const EstimateMappingRow({
    required this.id,
    required this.number,
    required this.name,
    required this.unit,
    required this.aliasCount,
    required this.aliases,
  });
}

// Удалён дублирующий estimatesMappingProvider — вся логика загрузки/фильтрации в пагинаторе ниже

/// Модель алиаса материала
class MaterialAliasRow {
  /// Идентификатор алиаса.
  final String id;

  /// Исходный текст алиаса.
  final String aliasRaw;

  /// Исходная единица измерения (если есть).
  final String? uomRaw;

  /// Поставщик (если есть).
  final String? supplierId;

  /// Количество на комплект (только для компонентов комплекта).
  final double? qtyPerKit;

  /// Коэффициент конверсии единиц измерения (для обычных связей).
  final double? multiplier;

  /// Является ли компонентом комплекта.
  final bool isKitComponent;

  /// Создаёт модель алиаса материала.
  const MaterialAliasRow({
    required this.id,
    required this.aliasRaw,
    this.uomRaw,
    this.supplierId,
    this.qtyPerKit,
    this.multiplier,
    this.isKitComponent = false,
  });
}

// Провайдер estimateAliasesProvider больше не требуется, так как алиасы предзагружаются в estimatesMappingProvider

/// Список раскрытых строк (id смет), чтобы показывать алиасы под строкой
final expandedEstimatesProvider =
    StateProvider<Set<String>>((ref) => <String>{});

/// Пагинация списка сметных позиций с предзагруженными алиасами
class EstimatesMappingPager
    extends StateNotifier<AsyncValue<List<EstimateMappingRow>>> {
  final SupabaseClient _client;

  /// Размер страницы пагинации.
  final int pageSize;
  bool _isLoading = false;
  int _offset = 0;

  /// Есть ли ещё данные для дозагрузки.
  bool hasMore = true;
  bool _initialized = false;

  /// Отфильтрованный номер договора.
  final String? contractNumber;
  String _query = '';

  /// Создаёт пагинатор сопоставления смет с алиасами.
  EstimatesMappingPager(this._client, {this.pageSize = 50, this.contractNumber})
      : super(const AsyncValue.loading());

  /// Загружает первую страницу данных.
  Future<void> loadInitial() async {
    if (_initialized) return;
    _initialized = true;
    state = const AsyncValue.loading();
    _offset = 0;
    hasMore = true;
    await _loadPage(reset: true);
  }

  /// Догружает следующую страницу (если доступна).
  Future<void> loadMore() async {
    if (_isLoading || !hasMore) return;
    await _loadPage(reset: false);
  }

  /// Перезагружает данные с обнулением пагинации.
  Future<void> refresh() async {
    _initialized = false;
    await loadInitial();
  }

  Future<void> _loadPage({required bool reset}) async {
    _isLoading = true;
    try {
      final from = _offset;
      final to = _offset + pageSize - 1;

      String? contractId;
      if (contractNumber != null && contractNumber!.trim().isNotEmpty) {
        final c = await _client
            .from('contracts')
            .select('id')
            .eq('number', contractNumber!.trim())
            .maybeSingle();
        contractId = c != null ? c['id']?.toString() : null;
        if (contractId == null) {
          // Нет такого договора — пустая выборка
          state = AsyncValue.data(reset
              ? <EstimateMappingRow>[]
              : (state.value ?? <EstimateMappingRow>[]));
          hasMore = false;
          _offset = from; // не двигаем
          return;
        }
      }

      var builder = _client.from('estimates').select('id,number,name,unit');
      if (contractId != null) {
        builder = builder.eq('contract_id', contractId);
      }
      if (_query.trim().isNotEmpty) {
        final term = _query.trim();
        // ignore: deprecated_member_use
        final normalized = term.replaceAll(RegExp('\\s+'), ' ');
        final escaped = normalized.replaceAll('"', '""');
        final pattern = '%$escaped%';
        builder = builder.or('name.ilike."$pattern",unit.ilike."$pattern"');
      }
      final estimates =
          await builder.order('name', ascending: true).range(from, to);

      final page = (estimates as List)
          .map((e) => {
                'id': e['id']?.toString() ?? '',
                'number': e['number']?.toString() ?? '',
                'name': e['name']?.toString() ?? '',
                'unit': e['unit']?.toString() ?? '',
              })
          .where((e) => e['id']!.isNotEmpty)
          .toList();

      hasMore = page.length == pageSize;

      List<EstimateMappingRow> nextList = reset
          ? <EstimateMappingRow>[]
          : (state.value ?? <EstimateMappingRow>[]);

      if (page.isNotEmpty) {
        final ids = page.map((e) => e['id'] as String).toList();

        // Загружаем обычные алиасы
        final aliasRows = await _client
            .from('material_aliases')
            .select(
                'id,estimate_id,alias_raw,uom_raw,supplier_id,multiplier_to_estimate')
            .inFilter('estimate_id', ids)
            .order('alias_raw');

        final Map<String, List<MaterialAliasRow>> aliasesByEstimate = {};

        // 1. Добавляем обычные алиасы
        for (final row in aliasRows as List) {
          final id = row['estimate_id']?.toString();
          if (id == null || id.isEmpty) continue;
          final list =
              aliasesByEstimate.putIfAbsent(id, () => <MaterialAliasRow>[]);
          list.add(MaterialAliasRow(
            id: (row['id'] ?? '').toString(),
            aliasRaw: (row['alias_raw'] ?? '').toString(),
            uomRaw: row['uom_raw']?.toString(),
            supplierId: row['supplier_id']?.toString(),
            multiplier: double.tryParse(
                row['multiplier_to_estimate']?.toString() ?? '1'),
            isKitComponent: false,
          ));
        }

        // 2. Загружаем компоненты комплектов через PostgreSQL функцию
        try {
          final kitComponentsData =
              await _client.rpc('get_kit_components_with_names', params: {
            'parent_ids': ids,
          });

          if (kitComponentsData != null) {
            for (final row in kitComponentsData as List) {
              final parentId = row['parent_estimate_id']?.toString();
              if (parentId == null || parentId.isEmpty) continue;

              final list = aliasesByEstimate.putIfAbsent(
                  parentId, () => <MaterialAliasRow>[]);
              list.add(MaterialAliasRow(
                id: (row['id'] ?? '').toString(),
                aliasRaw: (row['component_name'] ?? 'Без названия').toString(),
                uomRaw: row['uom_component']?.toString(),
                qtyPerKit:
                    double.tryParse(row['qty_per_kit']?.toString() ?? '1'),
                isKitComponent: true,
              ));
            }
          }
        } catch (e, st) {
          // Ошибка загрузки компонентов - продолжаем без них
          debugPrint('Error loading kit components: $e\n$st');
        }

        final mapped = page.map((e) {
          final id = e['id'] as String;
          final list = aliasesByEstimate[id] ?? const <MaterialAliasRow>[];
          return EstimateMappingRow(
            id: id,
            number: e['number'] as String,
            name: e['name'] as String,
            unit: e['unit'] as String,
            aliasCount: list.length,
            aliases: list,
          );
        }).toList();

        nextList = [...nextList, ...mapped];
      }

      state = AsyncValue.data(nextList);
      _offset += page.length;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    } finally {
      _isLoading = false;
    }
  }
}

/// Провайдер пагинатора сопоставления смет и алиасов.
final estimatesMappingPagerProvider = StateNotifierProvider<
    EstimatesMappingPager, AsyncValue<List<EstimateMappingRow>>>((ref) {
  final client = ref.watch(supabaseClientProvider);
  final contractNumber = ref.watch(selectedContractNumberProvider);
  final pager = EstimatesMappingPager(client, contractNumber: contractNumber);
  ref.listen<String>(materialsSearchQueryProvider('mapping'), (prev, next) {
    // Сброс пагинации и мягкая перезагрузка
    pager
      .._query = next
      .._offset = 0
      ..hasMore = true
      .._initialized = true;
    // ignore: discarded_futures
    pager._loadPage(reset: true);
  });
  pager._query = ref.read(materialsSearchQueryProvider('mapping'));
  // стартовая загрузка произойдет при первом вызове loadInitial снаружи
  return pager;
});
