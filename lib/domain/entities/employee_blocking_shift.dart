/// Смена, в которой у сотрудника есть учёт часов и из‑за этого нельзя удалить карточку.
///
/// Используется при разборе ошибки FK на `work_hours` для показа пользователю списка смен.
class EmployeeBlockingShift {
  /// Создаёт описание блокирующей смены.
  const EmployeeBlockingShift({
    required this.workId,
    required this.date,
    required this.objectName,
  });

  /// Идентификатор смены (`works.id`).
  final String workId;

  /// Дата смены.
  final DateTime date;

  /// Название объекта для отображения (уже локализованное «Объект не указан», если нужно).
  final String objectName;
}
