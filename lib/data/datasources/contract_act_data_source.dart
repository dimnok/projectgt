import 'package:projectgt/data/models/contract_act_line_model.dart';
import 'package:projectgt/data/models/contract_act_model.dart';
import 'package:projectgt/domain/utils/vat_calc.dart';
import 'package:projectgt/domain/entities/contract_act_kind.dart';
import 'package:projectgt/domain/entities/contract_act_payment_status.dart';
import 'package:projectgt/domain/entities/contract_act_workflow_status.dart';

/// Источник данных таблицы `contract_acts`.
abstract class ContractActDataSource {
  /// Список актов по договору (с join номера ВОР).
  Future<List<ContractActModel>> listByContract({
    required String contractId,
    required String companyId,
  });

  /// Вставка строки акта.
  Future<ContractActModel> insert({
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
    required ContractActAmountSource amountSource,
    String? note,
    required ContractActWorkflowStatus workflowStatus,
    required ContractActPaymentStatus paymentStatus,
    String? vorId,
    String? excelPath,
  });

  /// Обновляет только статусы согласования и оплаты.
  Future<ContractActModel> updateStatusesRow({
    required String id,
    required String companyId,
    required String contractId,
    required ContractActWorkflowStatus workflowStatus,
    required ContractActPaymentStatus paymentStatus,
  });

  /// Обновление строки акта.
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
    required ContractActAmountSource amountSource,
    String? note,
    required ContractActWorkflowStatus workflowStatus,
    required ContractActPaymentStatus paymentStatus,
  });

  /// Обновляет только путь к Excel.
  Future<void> updateExcelPath({
    required String actId,
    required String companyId,
    required String excelPath,
  });

  /// Удаление строки акта.
  Future<void> deleteRow({
    required String id,
    required String companyId,
    required String contractId,
  });

  /// Снимает привязку работ к акту.
  Future<void> unlinkWorkItems({required String actId, required String companyId});

  /// Путь к Excel перед удалением.
  Future<String?> fetchExcelPath({
    required String actId,
    required String companyId,
  });

  /// Строки акта КС-2 из `contract_act_lines`.
  Future<List<ContractActLineModel>> listLinesByActId({
    required String actId,
    required String companyId,
  });

  /// Обновляет количество и сумму строки акта.
  Future<void> updateActLineQuantities({
    required String lineId,
    required String companyId,
    required double quantity,
    required double amount,
    required double backlogQuantity,
    required double currentPeriodQuantity,
  });

  /// Сбрасывает путь к Excel (после правки строк нужна пересборка файла).
  Future<void> clearActExcelPath({
    required String actId,
    required String companyId,
  });

  /// Удаляет строку акта.
  Future<void> deleteActLine({
    required String lineId,
    required String companyId,
  });

  /// Ставка и режим НДС договора для пересчёта акта.
  Future<ContractVatTerms> fetchContractVatTerms({
    required String contractId,
    required String companyId,
  });
}
