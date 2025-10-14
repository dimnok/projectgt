import 'package:freezed_annotation/freezed_annotation.dart';

part 'employee_rate_model.freezed.dart';
part 'employee_rate_model.g.dart';

/// Data-модель для хранения истории ставок сотрудников.
///
/// Позволяет отслеживать изменения почасовых ставок во времени
/// с указанием периода действия каждой ставки.
@freezed
abstract class EmployeeRateModel with _$EmployeeRateModel {
  @JsonSerializable(fieldRename: FieldRename.snake)

  /// Создаёт экземпляр модели ставки сотрудника.
  ///
  /// [id] — уникальный идентификатор записи ставки
  /// [employeeId] — идентификатор сотрудника
  /// [hourlyRate] — почасовая ставка (в рублях)
  /// [validFrom] — дата начала действия ставки
  /// [validTo] — дата окончания действия ставки (null = текущая ставка)
  /// [createdAt] — дата создания записи
  /// [createdBy] — идентификатор пользователя, создавшего запись
  const factory EmployeeRateModel({
    /// Уникальный идентификатор записи ставки
    required String id,

    /// Идентификатор сотрудника
    @JsonKey(name: 'employee_id') required String employeeId,

    /// Почасовая ставка в рублях
    @JsonKey(name: 'hourly_rate') required double hourlyRate,

    /// Дата начала действия ставки
    @JsonKey(name: 'valid_from') required DateTime validFrom,

    /// Дата окончания действия ставки (null означает текущую ставку)
    @JsonKey(name: 'valid_to') DateTime? validTo,

    /// Дата создания записи
    @JsonKey(name: 'created_at') DateTime? createdAt,

    /// Идентификатор пользователя, создавшего запись
    @JsonKey(name: 'created_by') String? createdBy,
  }) = _EmployeeRateModel;

  const EmployeeRateModel._();

  /// Проверяет, действует ли ставка на указанную дату
  bool isActiveOn(DateTime date) {
    return validFrom.isBefore(date.add(const Duration(days: 1))) &&
        (validTo == null ||
            validTo!.isAfter(date.subtract(const Duration(days: 1))));
  }

  /// Является ли эта ставка текущей (активной)
  bool get isCurrent => validTo == null;

  /// Создаёт модель из JSON.
  factory EmployeeRateModel.fromJson(Map<String, dynamic> json) =>
      _$EmployeeRateModelFromJson(json);
}
