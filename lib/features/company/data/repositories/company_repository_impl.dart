import 'package:projectgt/features/company/data/datasources/company_data_source.dart';
import 'package:projectgt/features/company/domain/entities/company_profile.dart';
import 'package:projectgt/features/company/domain/entities/company_bank_account.dart';
import 'package:projectgt/features/company/domain/entities/company_document.dart';
import 'package:projectgt/features/company/domain/repositories/company_repository.dart';

/// Реализация [CompanyRepository] для работы с данными компании.
class CompanyRepositoryImpl implements CompanyRepository {
  /// Источник данных для операций с профилем компании.
  final CompanyDataSource dataSource;

  /// Создает экземпляр [CompanyRepositoryImpl].
  CompanyRepositoryImpl(this.dataSource);

  @override
  Future<CompanyProfile?> getCompanyProfile() => dataSource.getCompanyProfile();

  @override
  Future<List<CompanyBankAccount>> getBankAccounts() => dataSource.getBankAccounts();

  @override
  Future<List<CompanyDocument>> getDocuments() => dataSource.getDocuments();

  @override
  Future<void> updateCompanyProfile(CompanyProfile profile) =>
      dataSource.updateCompanyProfile(profile);

  @override
  Future<void> addBankAccount(CompanyBankAccount account) async {
    if (account.isPrimary) {
      await _ensureOnlyOnePrimary(account.companyId, null);
    }
    return dataSource.addBankAccount(account);
  }

  @override
  Future<void> updateBankAccount(CompanyBankAccount account) async {
    if (account.isPrimary) {
      await _ensureOnlyOnePrimary(account.companyId, account.id);
    }
    return dataSource.updateBankAccount(account);
  }

  @override
  Future<void> deleteBankAccount(String id) async {
    final accounts = await dataSource.getBankAccounts();

    await dataSource.deleteBankAccount(id);

    final remaining = accounts.where((a) => a.id != id).toList();
    if (remaining.isNotEmpty) {
      // Если остался только один счет ИЛИ если мы удалили основной счет
      // - нужно убедиться, что у нас есть основной счет
      final hasPrimary = remaining.any((a) => a.isPrimary);
      if (!hasPrimary || remaining.length == 1) {
        final newPrimary = remaining.first.copyWith(isPrimary: true);
        await dataSource.updateBankAccount(newPrimary);
      }
    }
  }

  Future<void> _ensureOnlyOnePrimary(String companyId, String? excludeId) async {
    final accounts = await dataSource.getBankAccounts();
    for (final account in accounts) {
      if (account.isPrimary && account.id != excludeId) {
        await dataSource.updateBankAccount(account.copyWith(isPrimary: false));
      }
    }
  }

  @override
  Future<void> addDocument(CompanyDocument document) =>
      dataSource.addDocument(document);

  @override
  Future<void> updateDocument(CompanyDocument document) =>
      dataSource.updateDocument(document);

  @override
  Future<void> deleteDocument(String id) => dataSource.deleteDocument(id);
}

