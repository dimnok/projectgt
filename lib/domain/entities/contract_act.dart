import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:projectgt/domain/entities/contract_act_kind.dart';
import 'package:projectgt/domain/entities/contract_act_payment_status.dart';
import 'package:projectgt/domain/entities/contract_act_workflow_status.dart';

part 'contract_act.freezed.dart';

/// Акт по договору: ручной реестр или КС-2 по ВОР (`contract_acts`).
@freezed
abstract class ContractAct with _$ContractAct {
  /// Создаёт сущность акта договора.
  const factory ContractAct({
    required String id,
    required String companyId,
    required String contractId,
    required ContractActKind actKind,
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
    required ContractActAmountSource amountSource,
    String? note,
    required ContractActWorkflowStatus workflowStatus,
    required ContractActPaymentStatus paymentStatus,
    String? vorId,
    String? vorNumber,
    String? excelPath,
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

/// Поведение акта в UI и операциях удаления/редактирования.
extension ContractActBehavior on ContractAct {
  /// Акт сформирован по ВОР (КС-2).
  bool get isKs2 => actKind == ContractActKind.ks2;

  /// Ручной акт реестра.
  bool get isManual => actKind == ContractActKind.manual;

  /// Черновик КС-2 (на согласовании).
  bool get isKs2Draft =>
      isKs2 && workflowStatus == ContractActWorkflowStatus.pendingApproval;

  /// Удаление разрешено: ручной акт всегда; КС-2 — только черновик.
  bool get canDelete => isManual || isKs2Draft;

  /// Полное редактирование формы (суммы, ВОР): ручной или черновик КС-2.
  bool get canEditFull => isManual || isKs2Draft;

  /// Сохранённый файл Excel в Storage.
  bool get hasExcel => excelPath != null && excelPath!.trim().isNotEmpty;
}
