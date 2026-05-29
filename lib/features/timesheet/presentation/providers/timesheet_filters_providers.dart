import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:projectgt/core/di/providers.dart';
import 'package:projectgt/features/objects/domain/entities/object.dart';

/// Объекты компании для фильтра табеля.
///
/// Источник — [objectProvider] (RLS: `timesheet.read` или `objects.read`,
/// без ограничения по `profiles.object_ids`).
final availableObjectsForTimesheetProvider = Provider<List<ObjectEntity>>((ref) {
  final objects = ref.watch(objectProvider).objects;
  return List<ObjectEntity>.from(objects)
    ..sort((a, b) => a.name.compareTo(b.name));
});
