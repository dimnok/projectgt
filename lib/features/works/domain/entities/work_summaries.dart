/// Сводка по объектам за месяц.
class ObjectSummary {
  /// ID объекта
  final String objectId;

  /// Название объекта
  final String objectName;

  /// Количество смен
  final int worksCount;

  /// Общая сумма
  final double totalAmount;

  /// Создаёт сводку по объекту с агрегированными данными.
  const ObjectSummary({
    required this.objectId,
    required this.objectName,
    required this.worksCount,
    required this.totalAmount,
  });
}

/// Сводка по системам за месяц.
class SystemSummary {
  /// Название системы
  final String system;

  /// Количество смен
  final int worksCount;

  /// Количество работ (items)
  final int itemsCount;

  /// Общая сумма
  final double totalAmount;

  /// Создаёт сводку по системе с агрегированными данными.
  const SystemSummary({
    required this.system,
    required this.worksCount,
    required this.itemsCount,
    required this.totalAmount,
  });
}

/// Сводка по часам за месяц.
class MonthHoursSummary {
  /// Общее количество часов
  final double totalHours;

  /// Создаёт сводку с общим количеством часов.
  const MonthHoursSummary({required this.totalHours});
}

/// Сводка по сотрудникам за месяц.
class MonthEmployeesSummary {
  /// Общее количество специалистов
  final int totalEmployees;

  /// Создаёт сводку с общим количеством специалистов.
  const MonthEmployeesSummary({required this.totalEmployees});
}

