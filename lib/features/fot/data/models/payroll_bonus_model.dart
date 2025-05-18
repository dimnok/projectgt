import 'package:freezed_annotation/freezed_annotation.dart';

part 'payroll_bonus_model.freezed.dart';
part 'payroll_bonus_model.g.dart';

/// Data-модель премии, связанной с расчётом ФОТ.
/// 
/// Позволяет хранить детализацию по видам премий для сотрудника за расчётный период.
@freezed
abstract class PayrollBonusModel with _$PayrollBonusModel {
  /// Создаёт экземпляр data-модели премии.
  ///
  /// [id] — уникальный идентификатор премии
  /// [payrollId] — идентификатор расчёта ФОТ
  /// [type] — тип премии (ручная/автоматическая/поощрительная и т.д.)
  /// [amount] — сумма премии
  /// [reason] — причина или комментарий
  /// [createdAt] — дата создания записи
  const factory PayrollBonusModel({
    /// Уникальный идентификатор премии
    required String id,
    /// Идентификатор расчёта ФОТ
    required String payrollId,
    /// Тип премии (ручная/авто/поощрительная)
    required String type,
    /// Сумма премии
    required num amount,
    /// Причина или комментарий
    String? reason,
    /// Дата создания записи
    DateTime? createdAt,
  }) = _PayrollBonusModel;

  /// Создаёт data-модель из JSON.
  factory PayrollBonusModel.fromJson(Map<String, dynamic> json) => _$PayrollBonusModelFromJson(json);
} 