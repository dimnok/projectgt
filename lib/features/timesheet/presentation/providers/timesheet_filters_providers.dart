import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:projectgt/core/di/providers.dart';
import 'package:projectgt/features/objects/domain/entities/object.dart';
import 'package:projectgt/features/timesheet/domain/timesheet_position_filter.dart';
import 'package:projectgt/features/timesheet/presentation/providers/timesheet_provider.dart';

/// Выбранные ключи должностей (клиентский фильтр сетки; Excel не использует).
final timesheetSelectedPositionKeysProvider =
    StateProvider<Set<String>>((ref) => const {});

/// Должности из каталога сотрудников табеля для выпадающего фильтра.
final availablePositionsForTimesheetProvider =
    Provider<List<TimesheetPositionFilterOption>>((ref) {
      final employees = ref.watch(timesheetProvider.select((s) => s.employees));
      return buildTimesheetPositionFilterOptions(employees);
    });

/// Объекты компании для фильтра табеля.
///
/// Источник — [objectProvider] (RLS: `timesheet.read` или `objects.read`,
/// без ограничения по `profiles.object_ids`).
final availableObjectsForTimesheetProvider = Provider<List<ObjectEntity>>((ref) {
  final objects = ref.watch(objectProvider).objects;
  return List<ObjectEntity>.from(objects)
    ..sort((a, b) => a.name.compareTo(b.name));
});
