import 'package:projectgt/core/utils/formatters.dart';

/// Базовый класс для группировки данных по месяцам.
///
/// Используется как основа для списков смен, планов работ и других
/// сущностей, требующих отображения с группировкой по календарным месяцам.
abstract class BaseMonthGroup<T> {
  /// Дата начала месяца (первое число).
  final DateTime month;

  /// Общее количество элементов в группе.
  final int count;

  /// Суммарный финансовый показатель группы.
  final double total;

  /// Флаг развернутого состояния группы в UI.
  bool isExpanded;

  /// Список элементов группы (загружается лениво).
  List<T>? items;

  /// Создает базовую группу месяца.
  BaseMonthGroup({
    required this.month,
    required this.count,
    required this.total,
    this.isExpanded = false,
    this.items,
  });

  /// Возвращает локализованное название месяца и год.
  /// Использует единый форматтер проекта.
  String get monthName => GtFormatters.formatMonthYear(month);

  /// Возвращает true, если группа относится к текущему календарному месяцу.
  bool get isCurrentMonth {
    final now = DateTime.now();
    return month.year == now.year && month.month == now.month;
  }
}
