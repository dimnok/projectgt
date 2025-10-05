import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:projectgt/core/di/providers.dart';

/// Доступные объекты для фильтрации табеля (берём из общего состояния объектов)
final availableObjectsForTimesheetProvider = Provider<List<dynamic>>((ref) {
  final objectState = ref.watch(objectProvider);
  return objectState.objects;
});

/// Доступные должности для фильтрации (загружаем напрямую из репозитория сотрудников)
final availablePositionsForTimesheetProvider =
    FutureProvider<List<String>>((ref) async {
  final repository = ref.watch(employeeRepositoryProvider);

  try {
    final employees = await repository.getEmployees();
    final positions = employees
        .map((e) => e.position)
        .whereType<String>()
        .where((p) => p.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    return positions;
  } catch (e) {
    return <String>[];
  }
});
