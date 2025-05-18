import 'package:freezed_annotation/freezed_annotation.dart';

part 'work_hour_model.freezed.dart';
part 'work_hour_model.g.dart';

/// Data-модель учёта часов сотрудника в смене для хранения и передачи данных между слоями data и источником данных.
@freezed
abstract class WorkHourModel with _$WorkHourModel {
  @JsonSerializable(fieldRename: FieldRename.snake)
  /// Создаёт data-модель учёта часов сотрудника в смене.
  ///
  /// [id] — идентификатор записи
  /// [workId] — идентификатор смены
  /// [employeeId] — идентификатор сотрудника
  /// [hours] — количество часов
  /// [comment] — комментарий (опционально)
  /// [createdAt] — дата создания записи (опционально)
  /// [updatedAt] — дата последнего обновления (опционально)
  const factory WorkHourModel({
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
  }) = _WorkHourModel;

  /// Создаёт data-модель учёта часов сотрудника в смене из JSON.
  factory WorkHourModel.fromJson(Map<String, dynamic> json) => _$WorkHourModelFromJson(json);
} 