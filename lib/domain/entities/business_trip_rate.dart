import 'package:freezed_annotation/freezed_annotation.dart';

part 'business_trip_rate.freezed.dart';

/// Сущность "Ставка командировочных выплат" (доменная модель).
///
/// Описывает ставку командировочных выплат для объекта с периодом действия.
/// Позволяет настраивать разные ставки для разных периодов времени.
@freezed
abstract class BusinessTripRate with _$BusinessTripRate {
  /// Основной конструктор [BusinessTripRate].
  ///
  /// Все параметры соответствуют полям в таблице business_trip_rates.
  const factory BusinessTripRate({
    /// Уникальный идентификатор ставки.
    required String id,

    /// Идентификатор объекта, к которому относится ставка.
    required String objectId,

    /// Идентификатор сотрудника (null = для всех сотрудников на объекте).
    String? employeeId,

    /// Размер ставки командировочных за смену (в рублях).
    required double rate,

    /// Минимальное количество часов для начисления командировочных.
    @Default(0.0) double minimumHours,

    /// Дата начала действия ставки.
    required DateTime validFrom,

    /// Дата окончания действия ставки (null = бессрочно).
    DateTime? validTo,

    /// Дата и время создания записи.
    DateTime? createdAt,

    /// Дата и время последнего обновления.
    DateTime? updatedAt,

    /// Идентификатор пользователя, создавшего запись.
    String? createdBy,
  }) = _BusinessTripRate;

  /// Приватный конструктор для расширения функциональности через методы.
  const BusinessTripRate._();

  /// Проверяет, действует ли ставка на указанную дату.
  ///
  /// [date] — дата для проверки.
  /// Возвращает true, если ставка действует на эту дату.
  bool isValidForDate(DateTime date) {
    final dateOnly = DateTime(date.year, date.month, date.day);
    final validFromOnly =
        DateTime(validFrom.year, validFrom.month, validFrom.day);

    // Проверяем, что дата не раньше начала действия
    if (dateOnly.isBefore(validFromOnly)) {
      return false;
    }

    // Если нет даты окончания, ставка действует бессрочно
    if (validTo == null) {
      return true;
    }

    final validToOnly = DateTime(validTo!.year, validTo!.month, validTo!.day);

    // Проверяем, что дата не позже окончания действия
    return !dateOnly.isAfter(validToOnly);
  }

  /// Проверяет, удовлетворяет ли количество часов условию для начисления.
  ///
  /// [hoursWorked] — количество отработанных часов.
  /// Возвращает true, если количество часов больше или равно минимальному.
  bool isHoursQualified(double hoursWorked) {
    return hoursWorked >= minimumHours;
  }

  /// Проверяет, является ли ставка активной (действующей на текущую дату).
  bool get isActive => isValidForDate(DateTime.now());

  /// Возвращает строковое представление периода действия ставки.
  String get periodDescription {
    final fromStr =
        '${validFrom.day.toString().padLeft(2, '0')}.${validFrom.month.toString().padLeft(2, '0')}.${validFrom.year}';

    if (validTo == null) {
      return 'с $fromStr (бессрочно)';
    }

    final toStr =
        '${validTo!.day.toString().padLeft(2, '0')}.${validTo!.month.toString().padLeft(2, '0')}.${validTo!.year}';
    return '$fromStr - $toStr';
  }

  /// Возвращает отформатированную строку ставки.
  String get formattedRate => '${rate.toStringAsFixed(0)} ₽';
}
