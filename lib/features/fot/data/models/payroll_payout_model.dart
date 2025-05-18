import 'package:freezed_annotation/freezed_annotation.dart';

part 'payroll_payout_model.freezed.dart';
part 'payroll_payout_model.g.dart';

/// Модель выплаты по расчёту ФОТ.
/// 
/// Используется для представления информации о выплате, связанной с расчётом фонда оплаты труда (ФОТ).
/// Содержит идентификаторы, сумму, дату выплаты, способ, статус и дату создания.
@freezed
abstract class PayrollPayoutModel with _$PayrollPayoutModel {
  /// Конструктор модели выплаты.
  /// 
  /// [id] — уникальный идентификатор выплаты.
  /// [payrollId] — идентификатор расчёта ФОТ.
  /// [amount] — сумма выплаты.
  /// [payoutDate] — дата выплаты.
  /// [method] — способ выплаты (например, "bank_transfer").
  /// [status] — статус выплаты (по умолчанию 'pending').
  /// [createdAt] — дата и время создания записи (опционально).
  const factory PayrollPayoutModel({
    required String id,
    required String payrollId,
    required num amount,
    required DateTime payoutDate,
    required String method,
    @Default('pending') String status,
    DateTime? createdAt,
  }) = _PayrollPayoutModel;

  /// Создаёт экземпляр [PayrollPayoutModel] из JSON.
  factory PayrollPayoutModel.fromJson(Map<String, dynamic> json) => _$PayrollPayoutModelFromJson(json);
} 