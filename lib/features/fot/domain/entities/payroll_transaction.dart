/// Базовый абстрактный класс для транзакций ФОТ (премии и штрафы).
///
/// Определяет общий интерфейс для всех типов транзакций в модуле ФОТ,
/// обеспечивая единообразную работу с данными.
abstract class PayrollTransaction {
  /// Уникальный идентификатор транзакции
  String get id;

  /// Идентификатор сотрудника
  String get employeeId;

  /// Тип транзакции (manual, automatic и т.д.)
  String get type;

  /// Сумма транзакции
  num get amount;

  /// Причина или комментарий
  String? get reason;

  /// Дата транзакции
  DateTime? get date;

  /// Дата создания записи
  DateTime? get createdAt;

  /// Идентификатор объекта
  String? get objectId;
}

/// Тип транзакции ФОТ
enum PayrollTransactionType {
  /// Премия
  bonus('bonus', 'Премия', 'Премии'),

  /// Штраф
  penalty('penalty', 'Штраф', 'Штрафы');

  const PayrollTransactionType(this.value, this.singular, this.plural);

  /// Значение для API
  final String value;

  /// Единственное число
  final String singular;

  /// Множественное число
  final String plural;

  /// Заголовок для добавления
  String get addTitle => 'Добавить ${singular.toLowerCase()}';

  /// Заголовок для редактирования
  String get editTitle => 'Редактировать ${singular.toLowerCase()}';

  /// Лейбл для суммы
  String get amountLabel =>
      this == PayrollTransactionType.bonus ? 'Сумма' : 'Сумма штрафа';

  /// Сообщение об успешном добавлении
  String get addedMessage =>
      '$singular добавлен${this == PayrollTransactionType.bonus ? 'а' : ''}';

  /// Сообщение об успешном обновлении
  String get updatedMessage =>
      '$singular обновлен${this == PayrollTransactionType.bonus ? 'а' : ''}';
}
