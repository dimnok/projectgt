import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/work_hour.dart';
import '../../domain/repositories/work_hour_repository.dart';
import 'repositories_providers.dart';

/// StateNotifier для управления часами сотрудников в смене.
///
/// Позволяет загружать, добавлять, обновлять и удалять часы для конкретной смены [workId].
class WorkHoursNotifier extends StateNotifier<AsyncValue<List<WorkHour>>> {
  /// Репозиторий для работы с часами смены.
  final WorkHourRepository repository;

  /// Идентификатор смены, для которой ведётся учёт часов.
  final String workId;

  /// Создаёт [WorkHoursNotifier] и сразу инициирует загрузку часов для смены [workId].
  WorkHoursNotifier(this.repository, this.workId)
      : super(const AsyncValue.loading()) {
    fetch();
  }

  /// Загружает список часов для текущей смены.
  Future<void> fetch() async {
    state = const AsyncValue.loading();
    try {
      final items = await repository.fetchWorkHours(workId);
      state = AsyncValue.data(items);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Добавляет новую запись о часах [item] и обновляет список.
  Future<void> add(WorkHour item) async {
    await repository.addWorkHour(item);
    await fetch();
  }

  /// Обновляет запись о часах [item] и обновляет список.
  Future<void> update(WorkHour item) async {
    await repository.updateWorkHour(item);
    await fetch();
  }

  /// Удаляет запись о часах по идентификатору [id] и обновляет список.
  Future<void> delete(String id) async {
    await repository.deleteWorkHour(id);
    await fetch();
  }

  /// Массово обновляет часы одним действием и обновляет список.
  Future<void> updateBulk(List<WorkHour> hours) async {
    await repository.updateWorkHoursBulk(hours);
    await fetch();
  }
}

/// Провайдер для управления и получения списка часов смены по [workId].
final workHoursProvider = StateNotifierProvider.family<WorkHoursNotifier,
    AsyncValue<List<WorkHour>>, String>((ref, workId) {
  final repo = ref.watch(workHourRepositoryProvider);
  return WorkHoursNotifier(repo, workId);
});
