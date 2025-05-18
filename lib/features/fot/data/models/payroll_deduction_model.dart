import 'package:freezed_annotation/freezed_annotation.dart';

part 'payroll_deduction_model.freezed.dart';
part 'payroll_deduction_model.g.dart';

/// Data-модель удержания, связанного с расчётом ФОТ.
/// 
/// Позволяет хранить детализацию по видам удержаний для сотрудника за расчётный период (налоги, авансы и др.).
@freezed
abstract class PayrollDeductionModel with _$PayrollDeductionModel {
  /// Создаёт экземпляр data-модели удержания.
  ///
  /// [id] — уникальный идентификатор удержания
  /// [payrollId] — идентификатор расчёта ФОТ
  /// [type] — тип удержания (налог, аванс, прочее)
  /// [amount] — сумма удержания
  /// [comment] — комментарий
  /// [createdAt] — дата создания записи
  const factory PayrollDeductionModel({
    /// Уникальный идентификатор удержания
    required String id,
    /// Идентификатор расчёта ФОТ
    required String payrollId,
    /// Тип удержания (налог, аванс, прочее)
    required String type,
    /// Сумма удержания
    required num amount,
    /// Комментарий
    String? comment,
    /// Дата создания записи
    DateTime? createdAt,
  }) = _PayrollDeductionModel;

  /// Создаёт data-модель из JSON.
  factory PayrollDeductionModel.fromJson(Map<String, dynamic> json) => _$PayrollDeductionModelFromJson(json);
} 