import 'package:freezed_annotation/freezed_annotation.dart';

part 'work_hour.freezed.dart';
part 'work_hour.g.dart';

/// Сущность "Часы сотрудника в смене".
///
/// Описывает количество отработанных часов сотрудника в рамках конкретной смены.
@freezed
abstract class WorkHour with _$WorkHour {
  @JsonSerializable(fieldRename: FieldRename.snake)
  /// Создаёт сущность учёта часов сотрудника в смене.
  ///
  /// [id] — идентификатор записи
  /// [workId] — идентификатор смены
  /// [employeeId] — идентификатор сотрудника
  /// [hours] — количество часов
  /// [comment] — комментарий (опционально)
  /// [createdAt] — дата создания записи (опционально)
  /// [updatedAt] — дата последнего обновления (опционально)
  const factory WorkHour({
    /// Идентификатор записи.
    required String id,
    /// Идентификатор смены.
    required String workId,
    /// Идентификатор сотрудника.
    required String employeeId,
    /// Количество часов.
    required num hours,
    /// Комментарий к записи.
    String? comment,
    /// Дата создания записи.
    DateTime? createdAt,
    /// Дата последнего обновления.
    DateTime? updatedAt,
  }) = _WorkHour;

  /// Создаёт сущность из JSON.
  factory WorkHour.fromJson(Map<String, dynamic> json) => _$WorkHourFromJson(json);
} 