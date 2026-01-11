import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:projectgt/core/error/failure.dart';
import 'package:projectgt/presentation/state/profile_state.dart';
import '../../domain/entities/work.dart';
import '../../domain/repositories/work_repository.dart';
import 'month_groups_provider.dart';
import 'repositories_providers.dart';

/// AsyncNotifier для управления операциями со сменами (add/update/delete).
///
/// ⚠️ НЕ загружает список смен автоматически в методе [build]!
/// Использует [AsyncValue] для управления состоянием.
/// Для списка смен в UI предпочтительно использовать [monthGroupsProvider].
class WorksNotifier extends AsyncNotifier<List<Work>> {
  @override
  FutureOr<List<Work>> build() {
    // По умолчанию возвращаем пустой список, так как основная загрузка идет через monthGroupsProvider
    return [];
  }

  WorkRepository get _repository => ref.read(workRepositoryProvider);

  /// Добавляет новую смену.
  ///
  /// Возвращает созданную смену или null в случае ошибки.
  Future<Work?> addWork({
    required String companyId,
    required DateTime date,
    required String objectId,
    required String openedBy,
    required String status,
    String? photoUrl,
    String? eveningPhotoUrl,
  }) async {
    final previousState = state;
    state = const AsyncLoading();
    
    try {
      final id = DateTime.now().millisecondsSinceEpoch.toString();
      final work = Work(
        id: id,
        companyId: companyId,
        date: date,
        objectId: objectId,
        openedBy: openedBy,
        status: status,
        photoUrl: photoUrl,
        eveningPhotoUrl: eveningPhotoUrl,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        totalAmount: 0,
        itemsCount: 0,
        employeesCount: 0,
      );
      
      final created = await _repository.addWork(work);
      
      final currentList = previousState.valueOrNull ?? [];
      state = AsyncData([...currentList, created]);
      
      // Инвалидируем проверку наличия открытой смены
      ref.invalidate(hasOpenWorkProvider);
      return created;
    } catch (e, stack) {
      state = AsyncError(Failure.fromException(e), stack);
      return null;
    }
  }

  /// Обновляет данные смены [work] в репозитории и состоянии.
  Future<void> updateWork(Work work) async {
    final previousState = state;
    state = const AsyncLoading();
    
    try {
      final updated = await _repository.updateWork(work);
      final currentList = previousState.valueOrNull ?? [];
      
      state = AsyncData([
        for (final w in currentList)
          if (w.id == updated.id) updated else w,
      ]);
      
      // Инвалидируем проверку наличия открытой смены (статус мог измениться на closed)
      ref.invalidate(hasOpenWorkProvider);
    } catch (e, stack) {
      state = AsyncError(Failure.fromException(e), stack);
    }
  }

  /// Удаляет смену по [id] из репозитория и состояния.
  Future<void> deleteWork(String id) async {
    final previousState = state;
    state = const AsyncLoading();
    
    try {
      await _repository.deleteWork(id);
      final currentList = previousState.valueOrNull ?? [];
      
      state = AsyncData(
        currentList.where((w) => w.id != id).toList(),
      );
      
      // Инвалидируем проверку наличия открытой смены
      ref.invalidate(hasOpenWorkProvider);
    } catch (e, stack) {
      state = AsyncError(Failure.fromException(e), stack);
    }
  }
}

/// Провайдер для операций со сменами (add/update/delete).
///
/// ⚠️ Используйте только для операций! Для списка смен используйте monthGroupsProvider.
final worksProvider = AsyncNotifierProvider<WorksNotifier, List<Work>>(() {
  return WorksNotifier();
});

/// Провайдер, создающий Map всех загруженных смен для быстрого доступа по ID.
final allLoadedWorksMapProvider = Provider<Map<String, Work>>((ref) {
  final monthGroupsAsync = ref.watch(monthGroupsProvider);
  return monthGroupsAsync.maybeWhen(
    data: (groups) {
      final Map<String, Work> map = {};
      for (final group in groups) {
        if (group.works != null) {
          for (final work in group.works!) {
            if (work.id != null) {
              map[work.id!] = work;
            }
          }
        }
      }
      return map;
    },
    orElse: () => {},
  );
});

/// Провайдер для получения конкретной смены по [id].
///
/// Пытается найти смену в monthGroupsProvider сначала, иначе загружает из БД.
final workProvider = Provider.family<Work?, String>((ref, id) {
  final worksMap = ref.watch(allLoadedWorksMapProvider);
  return worksMap[id];
});

/// Провайдер для проверки наличия открытой смены у текущего пользователя.
final hasOpenWorkProvider = FutureProvider<bool>((ref) async {
  final repository = ref.watch(workRepositoryProvider);
  final profile = ref.watch(currentUserProfileProvider).profile;

  if (profile == null) return false;

  return await repository.hasAnyOpenWork(profile.id);
});
