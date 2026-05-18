import 'package:projectgt/domain/entities/contract_act.dart';
import 'package:projectgt/domain/entities/contract_act_payment_status.dart';
import 'package:projectgt/domain/entities/contract_act_workflow_status.dart';
import 'package:projectgt/domain/repositories/contract_act_repository.dart';

/// Обновление акта по договору.
class UpdateContractActUseCase {
  /// Репозиторий актов.
  final ContractActRepository _repository;

  /// Создаёт use case.
  UpdateContractActUseCase(this._repository);

  /// Сохраняет изменения и возвращает акт из БД.
  Future<ContractAct> call({
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
  }) {
    return _repository.update(
      id: id,
      companyId: companyId,
      contractId: contractId,
      title: title,
      number: number,
      actDate: actDate,
      periodFrom: periodFrom,
      periodTo: periodTo,
      amount: amount,
      vatAmount: vatAmount,
      advanceRetention: advanceRetention,
      warrantyRetention: warrantyRetention,
      otherRetentions: otherRetentions,
      note: note,
      workflowStatus: workflowStatus,
      paymentStatus: paymentStatus,
    );
  }
}
