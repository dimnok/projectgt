import 'package:projectgt/features/company/domain/entities/company_profile.dart';
import 'package:projectgt/features/company/domain/entities/company_bank_account.dart';
import 'package:projectgt/features/company/domain/entities/company_document.dart';

/// Репозиторий для управления данными компании.
abstract class CompanyRepository {
  /// Получает профиль компании.
  Future<CompanyProfile?> getCompanyProfile();

  /// Возвращает список банковских счетов компании.
  Future<List<CompanyBankAccount>> getBankAccounts();

  /// Возвращает список документов компании.
  Future<List<CompanyDocument>> getDocuments();
  
  /// Обновляет профиль компании.
  Future<void> updateCompanyProfile(CompanyProfile profile);

  /// Добавляет новый банковский счет.
  Future<void> addBankAccount(CompanyBankAccount account);

  /// Обновляет существующий банковский счет.
  Future<void> updateBankAccount(CompanyBankAccount account);

  /// Удаляет банковский счет по его идентификатору.
  Future<void> deleteBankAccount(String id);
  
  /// Добавляет новый документ.
  Future<void> addDocument(CompanyDocument document);

  /// Обновляет существующий документ.
  Future<void> updateDocument(CompanyDocument document);

  /// Удаляет документ по его идентификатору.
  Future<void> deleteDocument(String id);
}

