import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/work_material.dart';
import '../../domain/repositories/work_material_repository.dart';
import 'repositories_providers.dart';

/// StateNotifier для управления материалами смены.
///
/// Позволяет загружать, добавлять, обновлять и удалять материалы для конкретной смены [workId].
class WorkMaterialsNotifier
    extends StateNotifier<AsyncValue<List<WorkMaterial>>> {
  /// Репозиторий для работы с материалами смены.
  final WorkMaterialRepository repository;

  /// Идентификатор смены, для которой ведётся учёт материалов.
  final String workId;

  /// Создаёт [WorkMaterialsNotifier] и сразу инициирует загрузку материалов для смены [workId].
  WorkMaterialsNotifier(this.repository, this.workId)
      : super(const AsyncValue.loading()) {
    fetch();
  }

  /// Загружает список материалов для текущей смены.
  Future<void> fetch() async {
    state = const AsyncValue.loading();
    try {
      final items = await repository.fetchWorkMaterials(workId);
      state = AsyncValue.data(items);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Добавляет новый материал [item] в смену и обновляет список.
  Future<void> add(WorkMaterial item) async {
    await repository.addWorkMaterial(item);
    await fetch();
  }

  /// Обновляет материал [item] в смене и обновляет список.
  Future<void> update(WorkMaterial item) async {
    await repository.updateWorkMaterial(item);
    await fetch();
  }

  /// Удаляет материал по идентификатору [id] и обновляет список.
  Future<void> delete(String id) async {
    await repository.deleteWorkMaterial(id);
    await fetch();
  }
}

/// Провайдер для управления и получения списка материалов смены по [workId].
final workMaterialsProvider = StateNotifierProvider.family<
    WorkMaterialsNotifier,
    AsyncValue<List<WorkMaterial>>,
    String>((ref, workId) {
  final repo = ref.watch(workMaterialRepositoryProvider);
  return WorkMaterialsNotifier(repo, workId);
});
