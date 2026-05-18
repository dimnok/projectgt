import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:projectgt/domain/entities/contract_act_payment_status.dart';
import 'package:projectgt/domain/entities/contract_act_workflow_status.dart';

part 'contract_act.freezed.dart';

/// Акт по договору (реестр; не КС-2).
@freezed
abstract class ContractAct with _$ContractAct {
  /// Создаёт сущность акта договора.
  const factory ContractAct({
    required String id,
    required String companyId,
    required String contractId,
    required String title,
    required String number,
    required DateTime actDate,
    required DateTime periodFrom,
    required DateTime periodTo,
    required double amount,
    required double vatAmount,
    required double advanceRetention,
    required double warrantyRetention,
    required double otherRetentions,
    required double totalToPay,
    String? note,
    required ContractActWorkflowStatus workflowStatus,
    required ContractActPaymentStatus paymentStatus,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
  }) = _ContractAct;
}

/// Итого к оплате: сумма акта + НДС − удержания (не ниже нуля).
///
/// Совпадает с выражением GENERATED в БД для колонки `total_to_pay`.
double computeContractActTotalToPay({
  required double amount,
  required double vatAmount,
  required double advanceRetention,
  required double warrantyRetention,
  required double otherRetentions,
}) {
  final raw = amount +
      vatAmount -
      advanceRetention -
      warrantyRetention -
      otherRetentions;
  if (raw.isNaN) return 0;
  return raw < 0 ? 0 : raw;
}
