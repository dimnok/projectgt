import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:projectgt/features/company/domain/entities/company_profile.dart';
import 'package:projectgt/features/company/domain/entities/company_bank_account.dart';
import 'package:projectgt/features/company/domain/entities/company_document.dart';

/// Источник данных для работы с информацией о компании.
abstract class CompanyDataSource {
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

/// Реализация [CompanyDataSource] с использованием Supabase.
class SupabaseCompanyDataSource implements CompanyDataSource {
  /// Клиент Supabase для выполнения запросов.
  final SupabaseClient client;

  /// Создает экземпляр [SupabaseCompanyDataSource].
  SupabaseCompanyDataSource(this.client);

  @override
  Future<CompanyProfile?> getCompanyProfile() async {
    final response = await client
        .from('company_profile')
        .select('*')
        .maybeSingle();
    if (response == null) return null;
    return CompanyProfile.fromJson(response);
  }

  @override
  Future<List<CompanyBankAccount>> getBankAccounts() async {
    final response = await client
        .from('company_bank_accounts')
        .select('*')
        .order('is_primary', ascending: false);
    return response
        .map<CompanyBankAccount>((json) => CompanyBankAccount.fromJson(json))
        .toList();
  }

  @override
  Future<List<CompanyDocument>> getDocuments() async {
    final response = await client
        .from('company_documents')
        .select('*')
        .order('created_at', ascending: false);
    return response
        .map<CompanyDocument>((json) => CompanyDocument.fromJson(json))
        .toList();
  }

  @override
  Future<void> updateCompanyProfile(CompanyProfile profile) async {
    final data = profile.toJson();
    data.remove('id');
    data.remove('created_at');
    data['updated_at'] = DateTime.now().toIso8601String();
    
    await client
        .from('company_profile')
        .update(data)
        .eq('id', profile.id);
  }

  @override
  Future<void> addBankAccount(CompanyBankAccount account) async {
    final data = account.toJson();
    data.remove('id');
    data.remove('created_at');
    
    await client.from('company_bank_accounts').insert(data);
  }

  @override
  Future<void> updateBankAccount(CompanyBankAccount account) async {
    final data = account.toJson();
    data.remove('id');
    data.remove('created_at');
    
    await client
        .from('company_bank_accounts')
        .update(data)
        .eq('id', account.id);
  }

  @override
  Future<void> deleteBankAccount(String id) async {
    await client.from('company_bank_accounts').delete().eq('id', id);
  }

  @override
  Future<void> addDocument(CompanyDocument document) async {
    final data = document.toJson();
    data.remove('id');
    data.remove('created_at');
    
    await client.from('company_documents').insert(data);
  }

  @override
  Future<void> updateDocument(CompanyDocument document) async {
    final data = document.toJson();
    data.remove('id');
    data.remove('created_at');
    
    await client
        .from('company_documents')
        .update(data)
        .eq('id', document.id);
  }

  @override
  Future<void> deleteDocument(String id) async {
    await client.from('company_documents').delete().eq('id', id);
  }
}

