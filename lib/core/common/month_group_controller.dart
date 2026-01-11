import 'models/base_month_group.dart';

/// Миксин для унификации логики управления группами месяцев.
///
/// Предоставляет общие методы для раскрытия, сворачивания и переключения
/// состояния групп месяцев в списках.
mixin MonthGroupController<T extends BaseMonthGroup> {
  /// Раскрывает указанную группу в списке и сворачивает остальные.
  ///
  /// [groups] — текущий список групп.
  /// [month] — дата начала месяца целевой группы.
  /// [copyWith] — функция для создания копии группы с новым состоянием.
  List<T> expandInList(
    List<T> groups,
    DateTime month, {
    required T Function(T group, bool isExpanded) copyWith,
  }) {
    final groupIndex = groups.indexWhere((g) => g.month == month);
    if (groupIndex == -1) return groups;

    final group = groups[groupIndex];
    if (group.isExpanded) return groups;

    final updatedGroups = List<T>.from(groups);

    // Сворачиваем остальные группы
    for (int i = 0; i < updatedGroups.length; i++) {
      if (i != groupIndex && updatedGroups[i].isExpanded) {
        updatedGroups[i] = copyWith(updatedGroups[i], false);
      }
    }

    // Раскрываем целевую группу
    updatedGroups[groupIndex] = copyWith(group, true);
    return updatedGroups;
  }

  /// Сворачивает указанную группу в списке.
  ///
  /// [groups] — текущий список групп.
  /// [month] — дата начала месяца целевой группы.
  /// [copyWith] — функция для создания копии группы с новым состоянием.
  List<T> collapseInList(
    List<T> groups,
    DateTime month, {
    required T Function(T group, bool isExpanded) copyWith,
  }) {
    final groupIndex = groups.indexWhere((g) => g.month == month);
    if (groupIndex == -1) return groups;

    final group = groups[groupIndex];
    if (!group.isExpanded) return groups;

    final updatedGroups = List<T>.from(groups);
    updatedGroups[groupIndex] = copyWith(group, false);
    return updatedGroups;
  }

  /// Переключает состояние группы (раскрыть/свернуть).
  bool isExpanded(List<T> groups, DateTime month) {
    final group = groups.where((g) => g.month == month).firstOrNull;
    return group?.isExpanded ?? false;
  }
}
