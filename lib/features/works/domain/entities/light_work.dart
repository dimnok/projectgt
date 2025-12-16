/// Облегченная сущность смены для графиков (только дата и сумма).
class LightWork {
  /// Идентификатор смены.
  final String id;

  /// Дата смены.
  final DateTime date;

  /// Общая сумма выработки.
  final double totalAmount;

  /// Количество сотрудников в смене.
  final int employeesCount;

  /// Создаёт облегченную сущность смены.
  const LightWork({
    required this.id,
    required this.date,
    required this.totalAmount,
    required this.employeesCount,
  });
}
