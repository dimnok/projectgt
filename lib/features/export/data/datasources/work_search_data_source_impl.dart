import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import '../../domain/entities/work_search_result.dart';
import 'work_search_data_source.dart';

/// Реализация источника данных для поиска работ через Supabase.
class WorkSearchDataSourceImpl implements WorkSearchDataSource {
  /// Клиент Supabase.
  final SupabaseClient client;

  /// Создаёт реализацию источника данных.
  WorkSearchDataSourceImpl(this.client);

  @override
  Future<WorkSearchPaginatedResult> searchMaterials({
    String? searchQuery,
    DateTime? startDate,
    DateTime? endDate,
    String? objectId,
    int page = 1,
    int pageSize = 250,
    List<String>? systemFilters,
    List<String>? sectionFilters,
    List<String>? floorFilters,
  }) async {
    try {
      // Объект обязателен для поиска
      if (objectId == null || objectId.isEmpty) {
        return WorkSearchPaginatedResult(
          results: const [],
          totalCount: 0,
          currentPage: page,
          pageSize: pageSize,
        );
      }

      // Шаг 1: Получаем все смены объекта с серверной сортировкой по дате (новые сверху)
      // Используем индекс idx_works_date_desc для оптимизации
      var worksQuery = client
          .from('works')
          .select('*, objects(name)')
          .eq('object_id', objectId);

      // Применяем фильтры по дате
      if (startDate != null) {
        worksQuery =
            worksQuery.gte('date', startDate.toIso8601String().split('T')[0]);
      }
      if (endDate != null) {
        worksQuery =
            worksQuery.lte('date', endDate.toIso8601String().split('T')[0]);
      }

      // Серверная сортировка по дате (использует индекс idx_works_date_desc)
      final worksResponse = await worksQuery.order('date', ascending: false);

      debugPrint(
          '🔍 [WorkSearch] Найдено смен (works): ${worksResponse.length}');

      if (worksResponse.isEmpty) {
        debugPrint('⚠️ [WorkSearch] Нет смен для объекта: $objectId');
        return WorkSearchPaginatedResult(
          results: const [],
          totalCount: 0,
          currentPage: page,
          pageSize: pageSize,
        );
      }

      // Создаем мапу works для быстрого доступа (уже отсортирована по дате)
      final worksMap = <String, Map<String, dynamic>>{};
      final sortedWorkIds = <String>[];

      for (final work in worksResponse) {
        final workId = work['id'] as String;
        worksMap[workId] = work;
        sortedWorkIds.add(workId);
      }

      debugPrint('🔍 [WorkSearch] WorkIds для поиска: ${sortedWorkIds.length}');

      // Шаг 2: Загружаем все work_items с пагинацией (Supabase лимит 1000)
      // Для правильной сортировки по дате смены нужно загрузить все и отсортировать
      if (searchQuery != null && searchQuery.trim().isNotEmpty) {
        debugPrint('🔍 [WorkSearch] Поиск по запросу: "$searchQuery"');
      }

      final allWorkItems = <Map<String, dynamic>>[];
      int workItemsOffset = 0;
      const int supabaseLimit = 1000;
      bool hasMoreWorkItems = true;
      int pageNum = 1;

      while (hasMoreWorkItems) {
        var pageQuery = client
            .from('work_items')
            .select('*, estimates(price, number, contracts(number))')
            .inFilter('work_id', sortedWorkIds);

        if (searchQuery != null && searchQuery.trim().isNotEmpty) {
          pageQuery = pageQuery.ilike('name', '%${searchQuery.trim()}%');
        }

        // Применяем фильтры на сервере
        if (systemFilters != null && systemFilters.isNotEmpty) {
          pageQuery = pageQuery.inFilter('system', systemFilters);
        }

        if (sectionFilters != null && sectionFilters.isNotEmpty) {
          pageQuery = pageQuery.inFilter('section', sectionFilters);
        }

        if (floorFilters != null && floorFilters.isNotEmpty) {
          pageQuery = pageQuery.inFilter('floor', floorFilters);
        }

        final pageData = await pageQuery.range(
            workItemsOffset, workItemsOffset + supabaseLimit - 1);

        debugPrint(
            '📄 [WorkSearch] WorkItems страница $pageNum: offset=$workItemsOffset, получено ${pageData.length}');

        if (pageData.isEmpty) {
          hasMoreWorkItems = false;
        } else {
          allWorkItems.addAll(pageData.cast<Map<String, dynamic>>());
          workItemsOffset += pageData.length;

          if (pageData.length < supabaseLimit) {
            hasMoreWorkItems = false;
          } else {
            pageNum++;
          }
        }
      }

      final totalCount = allWorkItems.length;
      debugPrint('🔍 [WorkSearch] Всего загружено work_items: $totalCount');

      if (totalCount == 0) {
        return WorkSearchPaginatedResult(
          results: [],
          totalCount: 0,
          currentPage: page,
          pageSize: pageSize,
        );
      }

      // Шаг 3: Формируем все результаты с сохранением порядка из works (уже отсортированы)
      // Группируем work_items по work_id для сохранения порядка дат
      final workItemsByWorkId = <String, List<Map<String, dynamic>>>{};
      for (final workItem in allWorkItems) {
        final workId = workItem['work_id'] as String;
        workItemsByWorkId.putIfAbsent(workId, () => []).add(workItem);
      }

      final results = <WorkSearchResult>[];

      // Проходим по works в отсортированном порядке (новые сверху)
      for (final workId in sortedWorkIds) {
        final work = worksMap[workId];
        if (work == null) continue;

        final workItems = workItemsByWorkId[workId];
        if (workItems == null || workItems.isEmpty) continue;

        final workDate = DateTime.parse(work['date'] as String);
        final object = work['objects'] as Map<String, dynamic>?;

        // Добавляем все work_items для этой смены
        for (final workItem in workItems) {
          // Извлекаем данные из связанного estimate
          final estimateData = workItem['estimates'] as Map<String, dynamic>?;
          final price = estimateData?['price'] as num?;
          final positionNumber = estimateData?['number'] as String?;
          
          // Получаем номер договора через estimate -> contracts
          final contractData = estimateData?['contracts'] as Map<String, dynamic>?;
          final contractNumber = contractData?['number'] as String?;
          
          final quantity = workItem['quantity'] as num? ?? 0;
          final total = price != null ? (price * quantity).toDouble() : null;

          results.add(WorkSearchResult(
            workDate: workDate,
            objectName: object?['name'] as String? ?? 'Неизвестный объект',
            system: workItem['system'] as String? ?? '',
            subsystem: workItem['subsystem'] as String? ?? '',
            section: workItem['section'] as String? ?? '',
            floor: workItem['floor'] as String? ?? '',
            workName: workItem['name'] as String? ?? '',
            materialName: workItem['name'] as String? ?? '',
            unit: workItem['unit'] as String? ?? '',
            quantity: quantity,
            workItemId: workItem['id'] as String?,
            workId: workId,
            objectId: work['object_id'] as String?,
            workStatus: work['status'] as String?,
            estimateId: workItem['estimate_id'] as String?,
            price: price?.toDouble(),
            total: total,
            positionNumber: positionNumber,
            contractNumber: contractNumber,
          ));
        }
      }

      // Результаты уже отсортированы по дате смены (используется порядок из sortedWorkIds)

      // Шаг 4: Применяем пагинацию к отсортированным результатам
      final offset = (page - 1) * pageSize;
      final end = (offset + pageSize).clamp(0, results.length);
      final paginatedResults = offset < results.length
          ? results.sublist(offset.clamp(0, results.length), end)
          : <WorkSearchResult>[];

      debugPrint(
          '✅ [WorkSearch] Сформировано результатов для страницы $page: ${paginatedResults.length} из $totalCount');

      return WorkSearchPaginatedResult(
        results: paginatedResults,
        totalCount: totalCount,
        currentPage: page,
        pageSize: pageSize,
      );
    } catch (e) {
      throw Exception('Ошибка поиска работ: $e');
    }
  }

  @override
  Future<WorkSearchFilterValues> getFilterValues({
    required String objectId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      if (objectId.isEmpty) {
        return const WorkSearchFilterValues(
          systems: [],
          sections: [],
          floors: [],
        );
      }

      // Получаем все смены объекта с фильтрами по дате
      var worksQuery =
          client.from('works').select('id').eq('object_id', objectId);

      if (startDate != null) {
        worksQuery =
            worksQuery.gte('date', startDate.toIso8601String().split('T')[0]);
      }
      if (endDate != null) {
        worksQuery =
            worksQuery.lte('date', endDate.toIso8601String().split('T')[0]);
      }

      final worksResponse = await worksQuery;
      final workIds = worksResponse.map((w) => w['id'] as String).toList();

      if (workIds.isEmpty) {
        return const WorkSearchFilterValues(
          systems: [],
          sections: [],
          floors: [],
        );
      }

      // Загружаем все work_items для получения уникальных значений
      // Используем пагинацию для обхода лимита Supabase
      final allWorkItems = <Map<String, dynamic>>[];
      int offset = 0;
      const int supabaseLimit = 1000;
      bool hasMore = true;

      while (hasMore) {
        final pageData = await client
            .from('work_items')
            .select('system, section, floor')
            .inFilter('work_id', workIds)
            .range(offset, offset + supabaseLimit - 1);

        if (pageData.isEmpty) {
          hasMore = false;
        } else {
          allWorkItems.addAll(pageData.cast<Map<String, dynamic>>());
          offset += pageData.length;

          if (pageData.length < supabaseLimit) {
            hasMore = false;
          }
        }
      }

      // Извлекаем уникальные значения
      final systems = allWorkItems
          .map((item) => item['system'] as String? ?? '')
          .where((s) => s.isNotEmpty)
          .toSet()
          .toList()
        ..sort();

      final sections = allWorkItems
          .map((item) => item['section'] as String? ?? '')
          .where((s) => s.isNotEmpty)
          .toSet()
          .toList()
        ..sort();

      final floors = allWorkItems
          .map((item) => item['floor'] as String? ?? '')
          .where((s) => s.isNotEmpty)
          .toSet()
          .toList()
        ..sort();

      debugPrint(
          '🔍 [WorkSearch] Загружено фильтров: систем=${systems.length}, участков=${sections.length}, этажей=${floors.length}');

      return WorkSearchFilterValues(
        systems: systems,
        sections: sections,
        floors: floors,
      );
    } catch (e) {
      throw Exception('Ошибка получения значений фильтров: $e');
    }
  }
}
