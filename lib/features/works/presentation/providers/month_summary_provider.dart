import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/work_data_source_impl.dart';
import 'repositories_providers.dart';

/// Провайдер для получения полной статистики по объектам за месяц.
final objectsSummaryProvider =
    FutureProvider.family<List<ObjectSummary>, DateTime>((ref, month) async {
  final repository = ref.watch(workRepositoryProvider);
  return repository.getObjectsSummary(month);
});

/// Провайдер для получения полной статистики по системам за месяц.
final systemsSummaryProvider =
    FutureProvider.family<List<SystemSummary>, DateTime>((ref, month) async {
  final repository = ref.watch(workRepositoryProvider);
  return repository.getSystemsSummary(month);
});

/// Провайдер для получения общего количества часов за месяц.
final monthTotalHoursProvider =
    FutureProvider.family<MonthHoursSummary, DateTime>((ref, month) async {
  final repository = ref.watch(workRepositoryProvider);
  return repository.getTotalHours(month);
});

/// Провайдер для получения количества сотрудников за месяц.
final monthTotalEmployeesProvider =
    FutureProvider.family<MonthEmployeesSummary, DateTime>((ref, month) async {
  final repository = ref.watch(workRepositoryProvider);
  return repository.getTotalEmployees(month);
});
