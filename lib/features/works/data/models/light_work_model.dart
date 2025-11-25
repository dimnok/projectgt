import 'package:freezed_annotation/freezed_annotation.dart';

part 'light_work_model.freezed.dart';
part 'light_work_model.g.dart';

/// Облегченная модель смены для графиков (только дата и сумма).
@freezed
abstract class LightWorkModel with _$LightWorkModel {
  /// Создаёт облегченную модель.
  const factory LightWorkModel({
    /// Идентификатор смены.
    required String id,

    /// Дата смены.
    required DateTime date,

    /// Общая сумма выработки.
    @JsonKey(name: 'total_amount') required double totalAmount,

    /// Количество сотрудников.
    @JsonKey(name: 'employees_count') @Default(0) int employeesCount,
  }) = _LightWorkModel;

  /// Создаёт модель из JSON.
  factory LightWorkModel.fromJson(Map<String, dynamic> json) =>
      _$LightWorkModelFromJson(json);
}
