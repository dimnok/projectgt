import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:projectgt/core/di/providers.dart';

/// Доступные объекты для фильтрации табеля (берём из общего состояния объектов)
final availableObjectsForTimesheetProvider = Provider<List<dynamic>>((ref) {
  final objectState = ref.watch(objectProvider);
  return objectState.objects;
});
