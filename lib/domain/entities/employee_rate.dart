import 'package:freezed_annotation/freezed_annotation.dart';

part 'employee_rate.freezed.dart';

/// Доменная сущность для ставки сотрудника.
///
/// Представляет почасовую ставку сотрудника с периодом её действия.
/// Позволяет отслеживать историю изменений ставок.
@freezed
abstract class EmployeeRate with _$EmployeeRate {
  /// Создаёт доменную сущность ставки сотрудника.
  ///
  /// [id] — уникальный идентификатор записи ставки
  /// [employeeId] — идентификатор сотрудника
  /// [hourlyRate] — почасовая ставка (в рублях)
  /// [validFrom] — дата начала действия ставки
  /// [validTo] — дата окончания действия ставки (null = текущая ставка)
  /// [createdAt] — дата создания записи
  /// [createdBy] — идентификатор пользователя, создавшего запись
  const factory EmployeeRate({
    /// Уникальный идентификатор записи ставки
    required String id,

    /// Идентификатор сотрудника
    required String employeeId,

    /// Почасовая ставка в рублях
    required double hourlyRate,

    /// Дата начала действия ставки
    required DateTime validFrom,

    /// Дата окончания действия ставки (null означает текущую ставку)
    DateTime? validTo,

    /// Дата создания записи
    DateTime? createdAt,

    /// Идентификатор пользователя, создавшего запись
    String? createdBy,
  }) = _EmployeeRate;

  const EmployeeRate._();

  /// Проверяет, действует ли ставка на указанную дату
  bool isActiveOn(DateTime date) {
    return validFrom.isBefore(date.add(const Duration(days: 1))) &&
        (validTo == null ||
            validTo!.isAfter(date.subtract(const Duration(days: 1))));
  }

  /// Является ли эта ставка текущей (активной)
  bool get isCurrent => validTo == null;

  /// Получить период действия ставки в текстовом виде
  String get periodText {
    final startText =
        '${validFrom.day.toString().padLeft(2, '0')}.${validFrom.month.toString().padLeft(2, '0')}.${validFrom.year}';
    if (validTo == null) {
      return '$startText - по настоящее время';
    }
    final endText =
        '${validTo!.day.toString().padLeft(2, '0')}.${validTo!.month.toString().padLeft(2, '0')}.${validTo!.year}';
    return '$startText - $endText';
  }
}
