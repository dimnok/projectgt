import 'package:projectgt/features/company/domain/entities/company_profile.dart';
import 'package:projectgt/features/company/domain/entities/company_bank_account.dart';
import 'package:projectgt/features/company/domain/entities/company_document.dart';

/// Репозиторий для управления данными компании.
abstract class CompanyRepository {
  /// Получает профиль компании.
  /// [companyId] - ID компании для фильтрации (если null, используется активная компания).
  Future<CompanyProfile?> getCompanyProfile({String? companyId});

  /// Возвращает список банковских счетов компании.
  /// [companyId] - ID компании для фильтрации (если null, используется активная компания).
  Future<List<CompanyBankAccount>> getBankAccounts({String? companyId});

  /// Возвращает список документов компании.
  /// [companyId] - ID компании для фильтрации (если null, используется активная компания).
  Future<List<CompanyDocument>> getDocuments({String? companyId});
  
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

  /// Создает новую компанию и делает текущего пользователя владельцем.
  Future<CompanyProfile> createCompany({
    required String name,
    Map<String, dynamic>? additionalData,
  });

  /// Добавляет пользователя в компанию по коду приглашения.
  Future<void> joinCompany({required String invitationCode});

  /// Получает список компаний пользователя.
  Future<List<CompanyProfile>> getMyCompanies();

  /// Ищет данные компании по ИНН.
  Future<Map<String, dynamic>?> searchCompanyByInn(String inn);

  /// Обновляет данные участника компании.
  Future<void> updateMember({
    required String userId,
    required String companyId,
    String? roleId,
    bool? isActive,
  });
}

