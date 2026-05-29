import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:projectgt/core/di/providers.dart';
import 'package:projectgt/features/objects/domain/entities/object.dart';
import 'package:projectgt/presentation/state/profile_state.dart';

/// Объекты компании для выпадающих списков и фильтров модуля «Сотрудники».
///
/// Источник — [objectProvider] (RLS: `objects.read`, `profiles.object_ids`
/// или права `employees.read` / `create` / `update`).
/// Если в профиле заданы [Profile.objectIds], список ограничивается ими.
final employeesModuleObjectsProvider = Provider<List<ObjectEntity>>((ref) {
  final objects = ref.watch(objectProvider).objects;
  final allowedIds = ref.watch(currentUserProfileProvider).profile?.objectIds;
  if (allowedIds == null || allowedIds.isEmpty) {
    return List<ObjectEntity>.from(objects)
      ..sort((a, b) => a.name.compareTo(b.name));
  }
  return objects
      .where((o) => allowedIds.contains(o.id))
      .toList()
    ..sort((a, b) => a.name.compareTo(b.name));
});
