import 'package:projectgt/features/contractors/data/datasources/contractor_data_source.dart';
import 'package:projectgt/features/contractors/data/models/contractor_model.dart';
import 'package:projectgt/features/contractors/data/models/contractor_bank_account_model.dart';
import 'package:projectgt/features/contractors/domain/entities/contractor.dart';
import 'package:projectgt/features/contractors/domain/entities/contractor_bank_account.dart';
import 'package:projectgt/features/contractors/domain/repositories/contractor_repository.dart';

/// Имплементация [ContractorRepository] для работы с контрагентами через data source.
///
/// Инкапсулирует преобразование моделей и делегирует вызовы data-слою.
class ContractorRepositoryImpl implements ContractorRepository {
  /// Data source для работы с контрагентами.
  final ContractorDataSource dataSource;

  /// Создаёт [ContractorRepositoryImpl] с указанным [dataSource].
  ContractorRepositoryImpl(this.dataSource);

  @override
  Future<List<Contractor>> getContractors(String companyId) async {
    final models = await dataSource.getContractors(companyId);
    return models.map((m) => m.toDomain()).toList();
  }

  @override
  Future<Contractor?> getContractor(String id) async {
    final model = await dataSource.getContractor(id);
    return model?.toDomain();
  }

  @override
  Future<Contractor> createContractor(Contractor contractor) async {
    final model = await dataSource
        .createContractor(ContractorModel.fromDomain(contractor));
    return model.toDomain();
  }

  @override
  Future<Contractor> updateContractor(Contractor contractor) async {
    final model = await dataSource
        .updateContractor(ContractorModel.fromDomain(contractor));
    return model.toDomain();
  }

  @override
  Future<void> deleteContractor(String id) async {
    await dataSource.deleteContractor(id);
  }

  @override
  Future<List<ContractorBankAccount>> getBankAccounts(String contractorId, String companyId) async {
    final models = await dataSource.getBankAccounts(contractorId, companyId);
    return models.map((m) => m.toDomain()).toList();
  }

  @override
  Future<ContractorBankAccount> addBankAccount(ContractorBankAccount account) async {
    if (account.isPrimary) {
      await _ensureOnlyOnePrimary(account.contractorId, account.companyId, null);
    }
    final model = await dataSource.addBankAccount(ContractorBankAccountModel.fromDomain(account));
    return model.toDomain();
  }

  @override
  Future<ContractorBankAccount> updateBankAccount(ContractorBankAccount account) async {
    if (account.isPrimary) {
      await _ensureOnlyOnePrimary(account.contractorId, account.companyId, account.id);
    }
    final model = await dataSource.updateBankAccount(ContractorBankAccountModel.fromDomain(account));
    return model.toDomain();
  }

  @override
  Future<void> deleteBankAccount(String id) async {
    await dataSource.deleteBankAccount(id);
  }

  Future<void> _ensureOnlyOnePrimary(String contractorId, String companyId, String? excludeId) async {
    final accounts = await dataSource.getBankAccounts(contractorId, companyId);
    for (final account in accounts) {
      if (account.isPrimary && account.id != excludeId) {
        await dataSource.updateBankAccount(account.copyWith(isPrimary: false));
      }
    }
  }
}
