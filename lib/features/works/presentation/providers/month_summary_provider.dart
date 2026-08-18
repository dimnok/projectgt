import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/work_summaries.dart';
import 'repositories_providers.dart';

/// Параметры сводки месяца: период и необязательный фильтр по объекту.
class MonthSummaryQuery {
  /// Месяц сводки.
  final DateTime month;

  /// ID объекта или `null`, если нужны данные по всем объектам.
  final String? objectId;

  /// Создаёт ключ запроса сводки месяца.
  const MonthSummaryQuery({required this.month, this.objectId});

  @override
  bool operator ==(Object other) {
    return other is MonthSummaryQuery &&
        other.month == month &&
        other.objectId == objectId;
  }

  @override
  int get hashCode => Object.hash(month, objectId);
}

/// Провайдер для получения полной статистики по объектам за месяц.
final objectsSummaryProvider =
    FutureProvider.family<List<ObjectSummary>, DateTime>((ref, month) async {
      final repository = ref.watch(workRepositoryProvider);
      return repository.getObjectsSummary(month);
    });

/// Провайдер для получения полной статистики по системам за месяц.
final systemsSummaryProvider =
    FutureProvider.family<List<SystemSummary>, MonthSummaryQuery>((
      ref,
      query,
    ) async {
      final repository = ref.watch(workRepositoryProvider);
      return repository.getSystemsSummary(
        query.month,
        objectId: query.objectId,
      );
    });

/// Провайдер для получения общего количества часов за месяц.
final monthTotalHoursProvider =
    FutureProvider.family<MonthHoursSummary, MonthSummaryQuery>((
      ref,
      query,
    ) async {
      final repository = ref.watch(workRepositoryProvider);
      return repository.getTotalHours(query.month, objectId: query.objectId);
    });

/// Провайдер для получения общего количества специалистов за месяц.
final monthTotalEmployeesProvider =
    FutureProvider.family<MonthEmployeesSummary, MonthSummaryQuery>((
      ref,
      query,
    ) async {
      final repository = ref.watch(workRepositoryProvider);
      return repository.getTotalEmployees(
        query.month,
        objectId: query.objectId,
      );
    });
