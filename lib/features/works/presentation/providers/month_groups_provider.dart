import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:projectgt/features/works/data/models/month_group.dart';
import 'package:projectgt/features/works/domain/entities/work.dart';
import 'package:projectgt/features/works/domain/repositories/work_repository.dart';
import 'repositories_providers.dart';

/// Состояние для управления группами месяцев смен.
class MonthGroupsState {
  /// Список групп месяцев.
  final List<MonthGroup> groups;

  /// Флаг загрузки.
  final bool isLoading;

  /// Сообщение об ошибке (если есть).
  final String? error;

  /// Создаёт состояние для групп месяцев.
  const MonthGroupsState({
    this.groups = const [],
    this.isLoading = false,
    this.error,
  });

  /// Создаёт копию состояния с изменёнными полями.
  MonthGroupsState copyWith({
    List<MonthGroup>? groups,
    bool? isLoading,
    String? error,
  }) {
    return MonthGroupsState(
      groups: groups ?? this.groups,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// StateNotifier для управления группами месяцев смен.
///
/// Управляет загрузкой групп месяцев, раскрытием/сворачиванием групп
/// и ленивой загрузкой смен при раскрытии группы.
class MonthGroupsNotifier extends StateNotifier<MonthGroupsState> {
  /// Репозиторий для работы со сменами.
  final WorkRepository _repository;

  /// Создаёт notifier для групп месяцев.
  MonthGroupsNotifier(this._repository) : super(const MonthGroupsState());

  /// Загружает заголовки групп месяцев.
  ///
  /// Загружает только сводку по месяцам без загрузки смен.
  /// Все группы свёрнуты, смены загружаются лениво при клике.
  Future<void> loadMonths() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final groups = await _repository.getMonthsHeaders();

      // Устанавливаем группы без автоматической загрузки смен
      // Смены загружаются ТОЛЬКО при клике на месяц (expandMonth)
      state = state.copyWith(groups: groups, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Ошибка загрузки групп: $e',
      );
    }
  }

  /// Раскрывает группу месяца и загружает смены (если ещё не загружены).
  ///
  /// [month] — дата начала месяца для раскрытия.
  Future<void> expandMonth(DateTime month) async {
    // Находим группу
    final groupIndex = state.groups.indexWhere((g) => g.month == month);
    if (groupIndex == -1) return;

    final group = state.groups[groupIndex];

    // Если уже развёрнута, ничего не делаем
    if (group.isExpanded) return;

    // Создаем обновленный список групп
    final updatedGroups = List<MonthGroup>.from(state.groups);

    // Сворачиваем все остальные группы
    for (int i = 0; i < updatedGroups.length; i++) {
      if (i != groupIndex && updatedGroups[i].isExpanded) {
        updatedGroups[i] = updatedGroups[i].copyWith(
          isExpanded: false,
          works: null, // Освобождаем память свернутых групп
        );
      }
    }

    // Обновляем состояние: целевая группа развёрнута
    updatedGroups[groupIndex] = group.copyWith(isExpanded: true);
    state = state.copyWith(groups: updatedGroups);

    // Если смены ещё не загружены, загружаем
    if (group.works == null) {
      await _loadMonthWorks(month);
    }
  }

  /// Сворачивает группу месяца и освобождает память (works = null).
  ///
  /// [month] — дата начала месяца для сворачивания.
  void collapseMonth(DateTime month) {
    final groupIndex = state.groups.indexWhere((g) => g.month == month);
    if (groupIndex == -1) return;

    final group = state.groups[groupIndex];

    // Если уже свёрнута, ничего не делаем
    if (!group.isExpanded) return;

    // Обновляем состояние: группа свёрнута, смены очищены
    final updatedGroups = List<MonthGroup>.from(state.groups);
    updatedGroups[groupIndex] = group.copyWith(
      isExpanded: false,
      works: null, // Освобождаем память
    );
    state = state.copyWith(groups: updatedGroups);
  }

  /// Переключает состояние группы (раскрыть/свернуть).
  ///
  /// [month] — дата начала месяца.
  Future<void> toggleMonth(DateTime month) async {
    final group = state.groups.firstWhere((g) => g.month == month);
    if (group.isExpanded) {
      collapseMonth(month);
    } else {
      await expandMonth(month);
    }
  }

  /// Проверяет, раскрыта ли группа месяца.
  bool isMonthExpanded(DateTime month) {
    for (final group in state.groups) {
      if (group.month == month) {
        return group.isExpanded;
      }
    }
    return false;
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

      // Находим группу и обновляем её смены
      final groupIndex = state.groups.indexWhere((g) => g.month == month);
      if (groupIndex == -1) return;

      final updatedGroups = List<MonthGroup>.from(state.groups);
      final group = updatedGroups[groupIndex];

      // Если это первая загрузка, заменяем works
      // Если это подгрузка (пагинация), добавляем к существующим
      final existingWorks = group.works ?? [];
      final allWorks = offset == 0 ? works : [...existingWorks, ...works];

      updatedGroups[groupIndex] = group.copyWith(works: allWorks);
      state = state.copyWith(groups: updatedGroups);
    } catch (e) {
      state = state.copyWith(error: 'Ошибка загрузки смен месяца: $e');
    }
  }

  /// Загружает дополнительные смены месяца (для infinite scroll).
  ///
  /// [month] — дата начала месяца.
  Future<void> loadMoreMonthWorks(DateTime month) async {
    try {
      final groupIndex = state.groups.indexWhere((g) => g.month == month);
      if (groupIndex == -1) return;

      final group = state.groups[groupIndex];
      if (group.works == null) return;

      // Проверяем, не загружены ли уже все смены месяца
      if (group.works!.length >= group.worksCount) {
        return; // Все смены уже загружены
      }

      final offset = group.works!.length;
      await _loadMonthWorks(month, offset: offset);
    } catch (e) {
      state = state.copyWith(error: 'Ошибка подгрузки смен: $e');
    }
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
    // Ищем группу, содержащую эту работу
    int? groupIndex;
    int? workIndex;

    for (int g = 0; g < state.groups.length; g++) {
      if (state.groups[g].works != null) {
        for (int w = 0; w < state.groups[g].works!.length; w++) {
          if (state.groups[g].works![w].id == updatedWork.id) {
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
    final updatedGroups = List<MonthGroup>.from(state.groups);
    final group = updatedGroups[groupIndex];
    final updatedWorks = List<Work>.from(group.works!);
    updatedWorks[workIndex] = updatedWork;
    updatedGroups[groupIndex] = group.copyWith(works: updatedWorks);

    state = state.copyWith(groups: updatedGroups);
  }
}

/// Провайдер для управления группами месяцев смен.
final monthGroupsProvider =
    StateNotifierProvider<MonthGroupsNotifier, MonthGroupsState>((ref) {
  final repository = ref.watch(workRepositoryProvider);
  return MonthGroupsNotifier(repository);
});
