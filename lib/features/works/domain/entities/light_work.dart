/// Облегченная сущность смены для графиков (дата, сумма, объект).
class LightWork {
  /// Идентификатор смены.
  final String id;

  /// Дата смены.
  final DateTime date;

  /// Идентификатор объекта смены.
  final String objectId;

  /// Общая сумма выработки.
  final double totalAmount;

  /// Количество сотрудников в смене.
  final int employeesCount;

  /// Создаёт облегченную сущность смены.
  const LightWork({
    required this.id,
    required this.date,
    required this.objectId,
    required this.totalAmount,
    required this.employeesCount,
  });
}
