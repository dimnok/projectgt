import 'package:projectgt/features/contractors/domain/entities/contractor.dart';
import 'package:projectgt/features/contractors/domain/entities/contractor_bank_account.dart';

/// Абстракция репозитория для работы с подрядчиками.
abstract class ContractorRepository {
  /// Получи список всех подрядчиков для указанной компании.
  ///
  /// Возвращает список [Contractor]. Бросает [Exception] при ошибке.
  Future<List<Contractor>> getContractors(String companyId);

  /// Получи подрядчика по [id].
  ///
  /// Возвращает [Contractor] или null, если не найден. Бросает [Exception] при ошибке.
  Future<Contractor?> getContractor(String id);

  /// Создай нового подрядчика [contractor] в источнике данных.
  ///
  /// Возвращает созданного [Contractor]. Бросает [Exception] при ошибке.
  Future<Contractor> createContractor(Contractor contractor);

  /// Обнови подрядчика [contractor] в источнике данных.
  ///
  /// Возвращает обновлённого [Contractor]. Бросает [Exception] при ошибке.
  Future<Contractor> updateContractor(Contractor contractor);

  /// Удали подрядчика по [id].
  ///
  /// Возвращает void. Бросает [Exception] при ошибке.
  Future<void> deleteContractor(String id);

  /// Получает список банковских счетов для контрагента в рамках компании.
  Future<List<ContractorBankAccount>> getBankAccounts(String contractorId, String companyId);

  /// Добавляет новый банковский счет.
  Future<ContractorBankAccount> addBankAccount(ContractorBankAccount account);

  /// Обновляет существующий банковский счет.
  Future<ContractorBankAccount> updateBankAccount(ContractorBankAccount account);

  /// Удаляет банковский счет.
  Future<void> deleteBankAccount(String id);
}
