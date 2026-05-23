import 'package:projectgt/domain/entities/contract_act.dart';
import 'package:projectgt/domain/entities/contract_act_kind.dart';
import 'package:projectgt/domain/entities/contract_act_ks2_preview.dart';
import 'package:projectgt/domain/entities/contract_act_payment_status.dart';
import 'package:projectgt/domain/entities/contract_act_workflow_status.dart';

/// Репозиторий актов по договору (ручные и КС-2).
abstract class ContractActRepository {
  /// Список актов [contractId], от новых к старым по дате акта.
  Future<List<ContractAct>> listByContract(String contractId);

  /// Создаёт ручной акт; [companyId] должен совпадать с компанией договора.
  Future<ContractAct> createManual({
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

  /// Обновляет акт; [companyId] — компания договора.
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
    ContractActAmountSource? amountSource,
  });

  /// Удаляет акт (для КС-2 — только черновик; снимает Excel и связи работ).
  Future<void> delete({
    required String id,
    required String companyId,
    required String contractId,
  });

  /// Предпросмотр состава КС-2 по утверждённой ВОР.
  Future<ContractActKs2Preview> previewKs2({
    required String contractId,
    required String vorId,
  });

  /// Создаёт акт КС-2 через Edge Function; возвращает id записи `contract_acts`.
  Future<String> createKs2Act({
    required String contractId,
    required String vorId,
    required String number,
    required DateTime actDate,
    required DateTime periodFrom,
    required DateTime periodTo,
  });

  /// Загружает Excel в Storage и записывает путь в [ContractAct.excelPath].
  Future<void> attachKs2Excel({
    required String actId,
    required String contractId,
    required List<int> bytes,
    required String displayFileName,
  });

  /// Скачивает байты Excel из Storage.
  Future<List<int>> downloadKs2Excel(String actId);
}
