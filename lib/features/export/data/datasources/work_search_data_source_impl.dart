import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/work_search_result.dart';
import 'work_search_data_source.dart';

/// Реализация источника данных для поиска работ через Supabase.
class WorkSearchDataSourceImpl implements WorkSearchDataSource {
  /// Клиент Supabase.
  final SupabaseClient client;

  /// Создаёт реализацию источника данных.
  WorkSearchDataSourceImpl(this.client);

  @override
  Future<List<WorkSearchResult>> searchMaterials({
    required String searchQuery,
    DateTime? startDate,
    DateTime? endDate,
    String? objectId,
  }) async {
    try {
      // Сначала получаем все work_items, которые соответствуют поисковому запросу
      var workItemsQuery =
          client.from('work_items').select('*').ilike('name', '%$searchQuery%');

      final workItemsResponse = await workItemsQuery;

      if (workItemsResponse.isEmpty) {
        return [];
      }

      // Получаем workIds из найденных work_items
      final workIds = workItemsResponse
          .map((item) => item['work_id'] as String)
          .toSet()
          .toList();

      // Получаем информацию о сменах с фильтрацией
      var worksQuery = client
          .from('works')
          .select('*, objects(name)')
          .inFilter('id', workIds);

      // Применяем фильтры по дате
      if (startDate != null) {
        worksQuery =
            worksQuery.gte('date', startDate.toIso8601String().split('T')[0]);
      }
      if (endDate != null) {
        worksQuery =
            worksQuery.lte('date', endDate.toIso8601String().split('T')[0]);
      }

      // Применяем фильтр по объекту
      if (objectId != null && objectId.isNotEmpty) {
        worksQuery = worksQuery.eq('object_id', objectId);
      }

      final worksResponse = await worksQuery;

      if (worksResponse.isEmpty) {
        return [];
      }

      // Получаем финальный список workIds после фильтрации
      final filteredWorkIds =
          worksResponse.map((work) => work['id'] as String).toSet().toList();

      // Создаем карты для быстрого поиска
      final worksMap = <String, Map<String, dynamic>>{};
      for (final work in worksResponse) {
        worksMap[work['id'] as String] = work;
      }

      // Формируем результаты из work_items
      final results = <WorkSearchResult>[];

      for (final workItem in workItemsResponse) {
        final workId = workItem['work_id'] as String;

        // Проверяем, что смена прошла фильтрацию
        if (!filteredWorkIds.contains(workId)) continue;

        final work = worksMap[workId];
        if (work == null) continue;

        // Проверяем, что work_item соответствует поисковому запросу
        final itemName = workItem['name'] as String? ?? '';
        if (!itemName.toLowerCase().contains(searchQuery.toLowerCase())) {
          continue;
        }

        final object = work['objects'] as Map<String, dynamic>?;

        results.add(WorkSearchResult(
          workDate: DateTime.parse(work['date'] as String),
          objectName: object?['name'] as String? ?? 'Неизвестный объект',
          system: workItem['system'] as String? ?? '',
          subsystem: workItem['subsystem'] as String? ?? '',
          section: workItem['section'] as String? ?? '',
          floor: workItem['floor'] as String? ?? '',
          workName: workItem['name'] as String? ?? '',
          materialName: workItem['name'] as String? ??
              '', // Используем название работы как "материал"
          unit: workItem['unit'] as String? ?? '',
          quantity: workItem['quantity'] as num? ?? 0,
        ));
      }

      return results;
    } catch (e) {
      throw Exception('Ошибка поиска работ: $e');
    }
  }
}
