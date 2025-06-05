import 'package:freezed_annotation/freezed_annotation.dart';

part 'payroll_penalty_model.freezed.dart';
part 'payroll_penalty_model.g.dart';

/// Data-модель штрафа, связанного с расчётом ФОТ.
/// 
/// Позволяет хранить детализацию по видам штрафов для сотрудника за расчётный период.
@freezed
abstract class PayrollPenaltyModel with _$PayrollPenaltyModel {
  /// Создаёт экземпляр data-модели штрафа.
  ///
  /// [id] — уникальный идентификатор штрафа
  /// [payrollId] — идентификатор расчёта ФОТ
  /// [type] — тип штрафа (дисциплинарный/автоматический и т.д.)
  /// [amount] — сумма штрафа
  /// [reason] — причина или комментарий
  /// [createdAt] — дата создания записи
  /// [objectId] — идентификатор объекта
  /// [date] — дата штрафа
  /// [employeeId] — идентификатор сотрудника
  const factory PayrollPenaltyModel({
    /// Уникальный идентификатор штрафа
    required String id,
    /// Идентификатор сотрудника
    @JsonKey(name: 'employee_id') String? employeeId,
    /// Тип штрафа (опоздание/прогул/нарушение и т.д.)
    required String type,
    /// Сумма штрафа
    required num amount,
    /// Причина или комментарий
    String? reason,
    /// Дата штрафа
    DateTime? date,
    /// Дата создания записи
    @JsonKey(name: 'created_at') DateTime? createdAt,
    /// Идентификатор объекта
    @JsonKey(name: 'object_id') String? objectId,
  }) = _PayrollPenaltyModel;

  /// Создаёт data-модель из JSON.
  factory PayrollPenaltyModel.fromJson(Map<String, dynamic> json) => _$PayrollPenaltyModelFromJson(json);
} 