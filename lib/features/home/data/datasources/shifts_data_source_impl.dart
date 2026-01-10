import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:logger/logger.dart';

import 'shifts_data_source.dart';

final _log = Logger();

/// Реализация источника данных для календаря смен.
///
/// Получает работы из Supabase и агрегирует их по датам для отображения
/// в календаре. Отдельна от модуля выгрузки для независимости реализаций.
class ShiftsDataSourceImpl implements ShiftsDataSource {
  /// Клиент Supabase для работы с БД.
  final SupabaseClient supabaseClient;

  /// ID текущей активной компании для фильтрации данных (Multi-tenancy).
  final String? activeCompanyId;

  /// Создаёт реализацию источника данных календаря смен.
  ShiftsDataSourceImpl({
    required this.supabaseClient,
    this.activeCompanyId,
  });

  @override
  Future<List<Map<String, dynamic>>> getShiftsForMonth(DateTime month) async {
    try {
      if (activeCompanyId == null) {
        return [];
      }

      /// Правильно обрабатываем границы месяца.
      final monthStart = DateTime(month.year, month.month, 1);
      final monthEnd = month.month == 12
          ? DateTime(month.year + 1, 1, 1).subtract(const Duration(days: 1))
          : DateTime(month.year, month.month + 1, 1)
              .subtract(const Duration(days: 1));

      /// Форматируем даты для Supabase (YYYY-MM-DD).
      final dateFromStr =
          '${monthStart.year}-${monthStart.month.toString().padLeft(2, '0')}-${monthStart.day.toString().padLeft(2, '0')}';
      final dateToStr =
          '${monthEnd.year}-${monthEnd.month.toString().padLeft(2, '0')}-${monthEnd.day.toString().padLeft(2, '0')}';

      /// Получаем все работы за месяц с детальной информацией.
      final response = await supabaseClient.from('works').select('''
            date,
            total_amount,
            company_id,
            objects(name),
            work_items(
              system,
              total
            )
          ''').gte('date', dateFromStr).lte('date', dateToStr).eq('company_id', activeCompanyId!).order('date');

      final responseList = response as List;

      /// Агрегируем данные по датам.
      final Map<String, dynamic> aggregated = {};

      for (final work in responseList) {
        final workDate = DateTime.parse(work['date'] as String);
        final dateKey =
            '${workDate.year}-${workDate.month.toString().padLeft(2, '0')}-${workDate.day.toString().padLeft(2, '0')}';

        if (!aggregated.containsKey(dateKey)) {
          aggregated[dateKey] = {
            'date': workDate,
            'total': 0.0,
          };
        }

        /// Суммируем total_amount по датам.
        final itemAmount = (work['total_amount'] as num?)?.toDouble() ?? 0.0;
        aggregated[dateKey]['total'] =
            (aggregated[dateKey]['total'] as num).toDouble() + itemAmount;
      }

      final result = aggregated.values.cast<Map<String, dynamic>>().toList();

      if (aggregated.isEmpty) {
        _log.w(
            '⚠️ ВНИМАНИЕ: Нет данных за месяц ${monthStart.month}/${monthStart.year}');
      }

      return result;
    } catch (e, stack) {
      _log.e('❌ ОШИБКА в getShiftsForMonth: $e\n$stack',
          error: e, stackTrace: stack);
      rethrow;
    }
  }

  @override
  Future<Map<String, dynamic>> getShiftsForDate(DateTime date) async {
    try {
      if (activeCompanyId == null) {
        return {
          'date': date,
          'totalAmount': 0.0,
          'objectTotals': <String, double>{},
          'systemsByObject': <String, Map<String, double>>{},
        };
      }

      /// Форматируем дату в формат YYYY-MM-DD.
      final dateStr =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      final dateEndStr =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

      /// Получаем все работы за конкретный день с деталями по объектам и системам.
      final response = await supabaseClient.from('works').select('''
            date,
            total_amount,
            company_id,
            objects(name),
            work_items(
              system,
              total
            )
          ''').gte('date', dateStr).lte('date', dateEndStr).eq('company_id', activeCompanyId!);

      final responseList = response as List;

      /// Группируем по объектам и системам.
      final Map<String, dynamic> objectTotals = {};
      final Map<String, Map<String, double>> systemsByObject = {};
      double totalAmount = 0;

      for (final work in responseList) {
        final objectName = work['objects']?['name'] ?? 'Неизвестный объект';
        final workItems = work['work_items'] as List? ?? [];

        for (final item in workItems) {
          final system = item['system'] ?? 'Неизвестная система';
          final itemTotal = (item['total'] as num?)?.toDouble() ?? 0.0;

          objectTotals[objectName] =
              (objectTotals[objectName] as num? ?? 0).toDouble() + itemTotal;

          final systems =
              systemsByObject.putIfAbsent(objectName, () => <String, double>{});
          systems[system] = (systems[system] ?? 0) + itemTotal;

          totalAmount += itemTotal;
        }
      }

      return {
        'date': date,
        'totalAmount': totalAmount,
        'objectTotals': objectTotals,
        'systemsByObject': systemsByObject,
      };
    } catch (e, stack) {
      _log.e('❌ ОШИБКА в getShiftsForDate: $e\n$stack',
          error: e, stackTrace: stack);
      rethrow;
    }
  }
}
