import 'package:projectgt/domain/entities/contract_act.dart';
import 'package:projectgt/domain/entities/contract_act_payment_status.dart';
import 'package:projectgt/domain/entities/contract_act_workflow_status.dart';

/// Репозиторий реестра актов по договору.
abstract class ContractActRepository {
  /// Список актов [contractId], от новых к старым по дате акта.
  Future<List<ContractAct>> listByContract(String contractId);

  /// Создаёт акт; [companyId] должен совпадать с компанией договора.
  Future<ContractAct> create({
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
    String? note,
    required ContractActWorkflowStatus workflowStatus,
    required ContractActPaymentStatus paymentStatus,
  });

  /// Обновляет акт; [companyId] — компания договора, должна совпадать с активной.
  Future<ContractAct> update({
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
    String? note,
    required ContractActWorkflowStatus workflowStatus,
    required ContractActPaymentStatus paymentStatus,
  });

  /// Удаляет акт по идентификатору в рамках договора и компании.
  Future<void> delete({
    required String id,
    required String companyId,
    required String contractId,
  });
}
