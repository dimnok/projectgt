import 'package:projectgt/features/settlements/domain/entities/settlement_operation.dart';
import 'package:projectgt/features/settlements/domain/entities/settlement_payment.dart';

/// Контракт репозитория операций взаиморасчётов.
abstract class SettlementRepository {
  /// Список операций компании; при [contractId] — только по договору.
  Future<List<SettlementOperation>> getOperations({String? contractId});

  /// Одна операция по идентификатору.
  Future<SettlementOperation?> getOperation(String id);

  /// Создать операцию.
  Future<SettlementOperation> createOperation(SettlementOperation operation);

  /// Обновить операцию.
  Future<SettlementOperation> updateOperation(SettlementOperation operation);

  /// Удалить операцию.
  Future<void> deleteOperation(String id);

  /// Следующий номер счёта для договора (max + 1) с сохранением префикса.
  /// Если у последнего счёта был префикс (например «сч-13»), вернётся «сч-14».
  Future<String> getNextInvoiceNumber(String contractId);

  /// Оплаты по счёту.
  Future<List<SettlementPayment>> getPayments(String settlementOperationId);

  /// Создать оплату.
  Future<SettlementPayment> createPayment(SettlementPayment payment);

  /// Обновить оплату.
  Future<SettlementPayment> updatePayment(SettlementPayment payment);

  /// Удалить оплату.
  Future<void> deletePayment(String id);
}
