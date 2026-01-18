import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import '../../../../core/utils/formatters.dart';
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
          totalQuantity: 0,
          currentPage: page,
          pageSize: pageSize,
        );
      }

      final from = (page - 1) * pageSize;
      final to = from + pageSize - 1;

      // Параметры для RPC и запросов
      final startDateStr = startDate != null
          ? GtFormatters.formatDateForApi(startDate)
          : null;
      final endDateStr = endDate != null
          ? GtFormatters.formatDateForApi(endDate)
          : null;

      // Шаг 1: Получаем агрегаты (общее кол-во, количество материалов и сумму) через RPC
      final aggregatesResponse = await client.rpc(
        'get_work_items_aggregates',
        params: {
          'p_object_id': objectId,
          'p_start_date': startDateStr,
          'p_end_date': endDateStr,
          'p_system_filters': (systemFilters?.isEmpty ?? true)
              ? null
              : systemFilters,
          'p_section_filters': (sectionFilters?.isEmpty ?? true)
              ? null
              : sectionFilters,
          'p_floor_filters': (floorFilters?.isEmpty ?? true)
              ? null
              : floorFilters,
          'p_search_query': searchQuery,
        },
      );

      final List<dynamic> aggList = aggregatesResponse as List<dynamic>;
      final int totalCount = aggList.isNotEmpty
          ? (aggList[0]['total_count'] as num? ?? 0).toInt()
          : 0;
      final num totalQuantity = aggList.isNotEmpty
          ? (aggList[0]['total_quantity'] as num? ?? 0)
          : 0;
      final double totalSum = aggList.isNotEmpty
          ? (aggList[0]['total_sum'] as num? ?? 0).toDouble()
          : 0.0;

      // Шаг 2: Получаем пагинированные данные через новый RPC для корректной сортировки
      final dataResponse = await client.rpc(
        'search_work_items_paginated',
        params: {
          'p_object_id': objectId,
          'p_start_date': startDateStr,
          'p_end_date': endDateStr,
          'p_system_filters': (systemFilters?.isEmpty ?? true)
              ? null
              : systemFilters,
          'p_section_filters': (sectionFilters?.isEmpty ?? true)
              ? null
              : sectionFilters,
          'p_floor_filters': (floorFilters?.isEmpty ?? true)
              ? null
              : floorFilters,
          'p_search_query': searchQuery,
          'p_from': from,
          'p_to': to,
        },
      );

      final List<dynamic> data = dataResponse as List<dynamic>;

      final results = data.map((item) {
        final price = item['price'] as num?;
        final quantity = item['quantity'] as num? ?? 0;
        final total = price != null ? (price * quantity).toDouble() : null;

        return WorkSearchResult(
          workDate: DateTime.parse(item['work_date'] as String),
          objectName: item['object_name'] as String? ?? 'Неизвестный объект',
          system: item['system'] as String? ?? '',
          subsystem: item['subsystem'] as String? ?? '',
          section: item['section'] as String? ?? '',
          floor: item['floor'] as String? ?? '',
          workName: item['work_name'] as String? ?? '',
          materialName: item['work_name'] as String? ?? '',
          unit: item['unit'] as String? ?? '',
          quantity: quantity,
          workItemId: item['work_item_id'] as String?,
          workId: item['work_id'] as String?,
          objectId: item['object_id'] as String?,
          workStatus: item['work_status'] as String?,
          estimateId: item['estimate_id'] as String?,
          price: price?.toDouble(),
          total: total,
          positionNumber: item['position_number'] as String?,
          contractNumber: item['contract_number'] as String?,
        );
      }).toList();

      return WorkSearchPaginatedResult(
        results: results,
        totalCount: totalCount,
        totalQuantity: totalQuantity,
        totalSum: totalSum,
        currentPage: page,
        pageSize: pageSize,
      );
    } catch (e) {
      debugPrint('❌ [WorkSearch] Ошибка поиска работ: $e');
      throw Exception('Ошибка поиска работ: $e');
    }
  }

  @override
  Future<WorkSearchFilterValues> getFilterValues({
    required String objectId,
    DateTime? startDate,
    DateTime? endDate,
    List<String>? systemFilters,
    List<String>? sectionFilters,
    String? searchQuery,
  }) async {
    try {
      if (objectId.isEmpty) {
        return const WorkSearchFilterValues(
          systems: [],
          sections: [],
          floors: [],
        );
      }

      // Используем новый RPC для получения доступных фильтров с учетом каскада
      final response = await client.rpc(
        'get_work_items_available_filters',
        params: {
          'p_object_id': objectId,
          'p_start_date': startDate != null
              ? GtFormatters.formatDateForApi(startDate)
              : null,
          'p_end_date': endDate != null
              ? GtFormatters.formatDateForApi(endDate)
              : null,
          'p_system_filters': (systemFilters?.isEmpty ?? true)
              ? null
              : systemFilters,
          'p_section_filters': (sectionFilters?.isEmpty ?? true)
              ? null
              : sectionFilters,
          'p_search_query': searchQuery,
        },
      );

      if ((response as List).isEmpty) {
        return const WorkSearchFilterValues(
          systems: [],
          sections: [],
          floors: [],
        );
      }

      final data = response[0] as Map<String, dynamic>;

      final systems = (data['systems'] as List?)?.cast<String>() ?? [];
      final sections = (data['sections'] as List?)?.cast<String>() ?? [];
      final floors = (data['floors'] as List?)?.cast<String>() ?? [];

      // Сортируем результаты для удобства
      systems.sort();
      sections.sort();
      floors.sort();

      return WorkSearchFilterValues(
        systems: systems,
        sections: sections,
        floors: floors,
      );
    } catch (e) {
      debugPrint('❌ [WorkSearch] Ошибка получения значений фильтров: $e');
      throw Exception('Ошибка получения значений фильтров: $e');
    }
  }
}
