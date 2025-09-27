import 'package:freezed_annotation/freezed_annotation.dart';

part 'payroll_payout_model.freezed.dart';
part 'payroll_payout_model.g.dart';

/// Модель выплаты по расчёту ФОТ.
///
/// Используется для представления информации о выплате, связанной с расчётом фонда оплаты труда (ФОТ).
/// Содержит идентификаторы, сумму, дату выплаты, способ, тип, статус и дату создания.
@freezed
abstract class PayrollPayoutModel with _$PayrollPayoutModel {
  /// Конструктор модели выплаты.
  ///
  /// [id] — уникальный идентификатор выплаты.
  /// [employeeId] — идентификатор сотрудника.
  /// [amount] — сумма выплаты.
  /// [payoutDate] — дата выплаты.
  /// [method] — способ выплаты (например, "bank_transfer").
  /// [type] — тип оплаты (зарплата/аванс).
  /// [createdAt] — дата и время создания записи (опционально).
  const factory PayrollPayoutModel({
    required String id,
    @JsonKey(name: 'employee_id') required String employeeId,
    required num amount,
    @JsonKey(name: 'payout_date') required DateTime payoutDate,
    required String method,
    required String type,
    @JsonKey(name: 'created_at') DateTime? createdAt,
  }) = _PayrollPayoutModel;

  /// Создаёт экземпляр [PayrollPayoutModel] из JSON.
  factory PayrollPayoutModel.fromJson(Map<String, dynamic> json) =>
      _$PayrollPayoutModelFromJson(json);
}
