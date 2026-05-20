import 'dart:convert';

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

      final startDateStr = startDate != null
          ? GtFormatters.formatDateForApi(startDate)
          : null;
      final endDateStr = endDate != null
          ? GtFormatters.formatDateForApi(endDate)
          : null;

      final response = await client.rpc(
        'search_work_items_with_aggregates',
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

      final payload = _parseAggregatesRpcPayload(response);
      final totalCount = (payload['total_count'] as num? ?? 0).toInt();
      final totalQuantity = payload['total_quantity'] as num? ?? 0;
      final totalSum = (payload['total_sum'] as num?)?.toDouble() ?? 0.0;

      final List<dynamic> data = payload['items'] is List
          ? payload['items'] as List<dynamic>
          : const [];

      final results = data.map((item) {
        final row = Map<String, dynamic>.from(item as Map);
        final price = row['price'] as num?;
        final quantity = row['quantity'] as num? ?? 0;
        final total = price != null ? (price * quantity).toDouble() : null;

        return WorkSearchResult(
          workDate: DateTime.parse(row['work_date'] as String),
          objectName: row['object_name'] as String? ?? 'Неизвестный объект',
          system: row['system'] as String? ?? '',
          subsystem: row['subsystem'] as String? ?? '',
          section: row['section'] as String? ?? '',
          floor: row['floor'] as String? ?? '',
          workName: row['work_name'] as String? ?? '',
          materialName: row['work_name'] as String? ?? '',
          unit: row['unit'] as String? ?? '',
          quantity: quantity,
          workItemId: row['work_item_id'] as String?,
          workId: row['work_id'] as String?,
          objectId: row['object_id'] as String?,
          workStatus: row['work_status'] as String?,
          estimateId: row['estimate_id'] as String?,
          price: price?.toDouble(),
          total: total,
          positionNumber: row['position_number'] as String?,
          contractNumber: row['contract_number'] as String?,
          m15Name: row['m15_name'] as String?,
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

  /// Разбирает ответ RPC [search_work_items_with_aggregates] (JSONB).
  Map<String, dynamic> _parseAggregatesRpcPayload(dynamic response) {
    if (response is Map<String, dynamic>) {
      return response;
    }
    if (response is Map) {
      return Map<String, dynamic>.from(response);
    }
    if (response is String) {
      return jsonDecode(response) as Map<String, dynamic>;
    }
    throw Exception(
      'Неизвестный формат ответа search_work_items_with_aggregates: '
      '${response.runtimeType}',
    );
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
