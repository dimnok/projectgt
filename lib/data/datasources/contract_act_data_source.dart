import 'package:projectgt/data/models/contract_act_model.dart';
import 'package:projectgt/domain/entities/contract_act_payment_status.dart';
import 'package:projectgt/domain/entities/contract_act_workflow_status.dart';

/// Источник данных таблицы `contract_acts`.
abstract class ContractActDataSource {
  /// Список актов по договору.
  Future<List<ContractActModel>> listByContract({
    required String contractId,
    required String companyId,
  });

  /// Вставка строки акта.
  Future<ContractActModel> insert({
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

  /// Обновление строки акта (без смены договора/компании).
  Future<ContractActModel> updateRow({
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

  /// Удаление строки акта.
  Future<void> deleteRow({
    required String id,
    required String companyId,
    required String contractId,
  });
}
