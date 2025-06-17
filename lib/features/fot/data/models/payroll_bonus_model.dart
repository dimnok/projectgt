import 'package:freezed_annotation/freezed_annotation.dart';
import '../../domain/entities/payroll_transaction.dart';

part 'payroll_bonus_model.freezed.dart';
part 'payroll_bonus_model.g.dart';

/// Data-модель премии, связанной с расчётом ФОТ.
/// 
/// Позволяет хранить детализацию по видам премий для сотрудника за расчётный период.
@freezed
abstract class PayrollBonusModel with _$PayrollBonusModel implements PayrollTransaction {
  /// Создаёт экземпляр data-модели премии.
  ///
  /// [id] — уникальный идентификатор премии
  /// [employeeId] — идентификатор сотрудника (employee_id)
  /// [type] — тип премии (ручная/автоматическая/поощрительная и т.д.)
  /// [amount] — сумма премии
  /// [reason] — причина или комментарий
  /// [date] — дата премии
  /// [createdAt] — дата создания записи
  /// [objectId] — идентификатор объекта
  const factory PayrollBonusModel({
    /// Уникальный идентификатор премии
    required String id,
    /// Идентификатор сотрудника
    @JsonKey(name: 'employee_id') required String employeeId,
    /// Тип премии (ручная/авто/поощрительная)
    required String type,
    /// Сумма премии
    required num amount,
    /// Причина или комментарий
    String? reason,
    /// Дата премии
    DateTime? date,
    /// Дата создания записи
    @JsonKey(name: 'created_at') DateTime? createdAt,
    /// Идентификатор объекта
    @JsonKey(name: 'object_id') String? objectId,
  }) = _PayrollBonusModel;

  /// Создаёт data-модель из JSON.
  factory PayrollBonusModel.fromJson(Map<String, dynamic> json) => _$PayrollBonusModelFromJson(json);
} 