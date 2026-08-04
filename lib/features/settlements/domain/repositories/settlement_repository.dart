import 'package:projectgt/features/settlements/domain/entities/settlement_operation.dart';

/// Контракт репозитория операций взаиморасчётов.
abstract class SettlementRepository {
  /// Список операций компании; при [contractId] — только по договору.
  Future<List<SettlementOperation>> getOperations({String? contractId});

  /// Создать операцию.
  Future<SettlementOperation> createOperation(SettlementOperation operation);

  /// Обновить операцию.
  Future<SettlementOperation> updateOperation(SettlementOperation operation);

  /// Удалить операцию.
  Future<void> deleteOperation(String id);

  /// Следующий номер счёта для договора (max + 1) с сохранением префикса.
  /// Если у последнего счёта был префикс (например «сч-13»), вернётся «сч-14».
  Future<String> getNextInvoiceNumber(String contractId);
}
