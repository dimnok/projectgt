import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:projectgt/core/common/month_group_controller.dart';
import 'package:projectgt/core/error/failure.dart';
import 'package:projectgt/features/works/data/models/month_group.dart';
import 'package:projectgt/features/works/domain/entities/work.dart';
import 'package:projectgt/features/works/domain/repositories/work_repository.dart';
import 'repositories_providers.dart';

/// AsyncNotifier для управления группами месяцев смен.
///
/// Управляет загрузкой групп месяцев, раскрытием/сворачиванием групп
/// и ленивой загрузкой смен при раскрытии группы.
class MonthGroupsNotifier extends AsyncNotifier<List<MonthGroup>>
    with MonthGroupController<MonthGroup> {
  @override
  FutureOr<List<MonthGroup>> build() async {
    // Автоматически загружаем месяцы при создании провайдера
    return await _loadMonths();
  }

  WorkRepository get _repository => ref.read(workRepositoryProvider);

  /// Внутренний метод для загрузки заголовков групп месяцев.
  Future<List<MonthGroup>> _loadMonths() async {
    return await _repository.getMonthsHeaders();
  }

  /// Загружает заголовки групп месяцев.
  ///
  /// Загружает только сводку по месяцам без загрузки смен.
  /// Все группы свёрнуты, смены загружаются лениво при клике.
  Future<void> loadMonths() async {
    state = const AsyncLoading();
    try {
      final groups = await _loadMonths();
      state = AsyncData(groups);
    } catch (e, stack) {
      state = AsyncError(Failure.fromException(e), stack);
    }
  }

  /// Раскрывает группу месяца и загружает смены (если ещё не загружены).
  ///
  /// [month] — дата начала месяца для раскрытия.
  Future<void> expandMonth(DateTime month) async {
    final groups = state.valueOrNull ?? [];

    final updatedGroups = expandInList(
      groups,
      month,
      copyWith: (group, isExpanded) => group.copyWith(
        isExpanded: isExpanded,
        works: isExpanded ? group.works : null,
      ),
    );

    if (updatedGroups == groups) return;

    state = AsyncData(updatedGroups);

    // Если смены ещё не загружены в раскрытой группе, загружаем
    final group = updatedGroups.firstWhere((g) => g.month == month);
    if (group.isExpanded && group.works == null) {
      await _loadMonthWorks(month);
    }
  }

  /// Сворачивает группу месяца и освобождает память (works = null).
  ///
  /// [month] — дата начала месяца для сворачивания.
  void collapseMonth(DateTime month) {
    final groups = state.valueOrNull ?? [];

    final updatedGroups = collapseInList(
      groups,
      month,
      copyWith: (group, isExpanded) =>
          group.copyWith(isExpanded: isExpanded, works: null),
    );

    if (updatedGroups == groups) return;
    state = AsyncData(updatedGroups);
  }

  /// Переключает состояние группы (раскрыть/свернуть).
  ///
  /// [month] — дата начала месяца.
  Future<void> toggleMonth(DateTime month) async {
    if (isMonthExpanded(month)) {
      collapseMonth(month);
    } else {
      await expandMonth(month);
    }
  }

  /// Проверяет, раскрыта ли группа месяца.
  bool isMonthExpanded(DateTime month) {
    return isExpanded(state.valueOrNull ?? [], month);
  }

  /// Загружает смены конкретного месяца.
  ///
  /// [month] — дата начала месяца.
  /// [offset] — смещение для пагинации (по умолчанию 0).
  /// [limit] — лимит записей (по умолчанию 30).
  Future<void> _loadMonthWorks(
    DateTime month, {
    int offset = 0,
    int limit = 30,
  }) async {
    try {
      // Загружаем смены месяца
      final works = await _repository.getMonthWorks(
        month,
        offset: offset,
        limit: limit,
      );

      final groups = state.valueOrNull ?? [];
      // Находим группу и обновляем её смены
      final groupIndex = groups.indexWhere((g) => g.month == month);
      if (groupIndex == -1) return;

      final updatedGroups = List<MonthGroup>.from(groups);
      final group = updatedGroups[groupIndex];

      // Если это первая загрузка, заменяем works
      // Если это подгрузка (пагинация), добавляем к существующим
      final existingWorks = group.works ?? [];
      final allWorks = offset == 0 ? works : [...existingWorks, ...works];

      updatedGroups[groupIndex] = group.copyWith(works: allWorks);
      state = AsyncData(updatedGroups);
    } catch (e, stack) {
      state = AsyncError(Failure.fromException(e), stack);
    }
  }

  /// Загружает дополнительные смены месяца (для infinite scroll).
  ///
  /// [month] — дата начала месяца.
  Future<void> loadMoreMonthWorks(DateTime month) async {
    final groups = state.valueOrNull ?? [];
    final groupIndex = groups.indexWhere((g) => g.month == month);
    if (groupIndex == -1) return;

    final group = groups[groupIndex];
    if (group.works == null) return;

    // Проверяем, не загружены ли уже все смены месяца
    if (group.works!.length >= group.worksCount) {
      return; // Все смены уже загружены
    }

    final offset = group.works!.length;
    await _loadMonthWorks(month, offset: offset);
  }

  /// Перезагружает данные (pull-to-refresh).
  Future<void> refresh() async {
    await loadMonths();
  }

  /// Обновляет работу в месячной группе (без полной инвалидации провайдера).
  ///
  /// Находит месячную группу по ID работы и обновляет работу в ней.
  /// Это предотвращает временную потерю данных при инвалидации.
  void updateWorkInGroup(dynamic updatedWork) {
    final groups = state.valueOrNull ?? [];
    // Ищем группу, содержащую эту работу
    int? groupIndex;
    int? workIndex;

    for (int g = 0; g < groups.length; g++) {
      if (groups[g].works != null) {
        for (int w = 0; w < groups[g].works!.length; w++) {
          if (groups[g].works![w].id == updatedWork.id) {
            groupIndex = g;
            workIndex = w;
            break;
          }
        }
      }
      if (groupIndex != null) break;
    }

    if (groupIndex == null || workIndex == null) {
      return;
    }

    // Обновляем работу в группе
    final updatedGroups = List<MonthGroup>.from(groups);
    final group = updatedGroups[groupIndex];
    final updatedWorks = List<Work>.from(group.works!);
    updatedWorks[workIndex] = updatedWork;
    updatedGroups[groupIndex] = group.copyWith(works: updatedWorks);

    state = AsyncData(updatedGroups);
  }
}

/// Провайдер для управления группами месяцев смен.
final monthGroupsProvider =
    AsyncNotifierProvider<MonthGroupsNotifier, List<MonthGroup>>(() {
      return MonthGroupsNotifier();
    });
