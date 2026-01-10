import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:projectgt/features/company/domain/entities/company_profile.dart';
import 'package:projectgt/features/company/domain/entities/company_bank_account.dart';
import 'package:projectgt/features/company/domain/entities/company_document.dart';

/// Источник данных для работы с информацией о компании.
abstract class CompanyDataSource {
  /// Получает профиль компании.
  /// [companyId] - ID компании для фильтрации (обязателен для multi-tenancy).
  Future<CompanyProfile?> getCompanyProfile({required String? companyId});

  /// Возвращает список банковских счетов компании.
  /// [companyId] - ID компании для фильтрации (обязателен для multi-tenancy).
  Future<List<CompanyBankAccount>> getBankAccounts({required String? companyId});

  /// Получает банковский счет по его идентификатору.
  Future<CompanyBankAccount?> getBankAccount(String id);

  /// Возвращает список документов компании.
  /// [companyId] - ID компании для фильтрации (обязателен для multi-tenancy).
  Future<List<CompanyDocument>> getDocuments({required String? companyId});

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

  /// Создает новую компанию в базе данных.
  ///
  /// [name] — название организации.
  /// [additionalData] — дополнительные поля (ИНН, КПП, адреса и т.д.).
  /// После создания автоматически делает текущего пользователя владельцем (owner).
  Future<CompanyProfile> createCompany({
    required String name,
    Map<String, dynamic>? additionalData,
  });

  /// Регистрирует текущего пользователя в существующей компании.
  ///
  /// [invitationCode] — уникальный строковый код приглашения организации.
  /// Проверяет существование кода и отсутствие пользователя в списке участников.
  Future<void> joinCompany({required String invitationCode});

  /// Возвращает список всех компаний, участником которых является текущий пользователь.
  ///
  /// Извлекает данные через таблицу связей `company_members`.
  Future<List<CompanyProfile>> getMyCompanies();

  /// Ищет данные компании по ИНН через внешнее API (DaData).
  Future<Map<String, dynamic>?> searchCompanyByInn(String inn);

  /// Обновляет данные участника компании (роль, статус активности).
  Future<void> updateMember({
    required String userId,
    required String companyId,
    String? roleId,
    bool? isActive,
  });
}

/// Реализация [CompanyDataSource] с использованием Supabase.
class SupabaseCompanyDataSource implements CompanyDataSource {
  /// Клиент Supabase для выполнения запросов.
  final SupabaseClient client;

  /// Создает экземпляр [SupabaseCompanyDataSource].
  SupabaseCompanyDataSource(this.client);

  @override
  Future<CompanyProfile?> getCompanyProfile({required String? companyId}) async {
    if (companyId == null) return null;
    
    final response = await client
        .from('companies')
        .select('*')
        .eq('id', companyId)
        .maybeSingle();
    if (response == null) return null;
    return CompanyProfile.fromJson(response);
  }

  @override
  Future<List<CompanyBankAccount>> getBankAccounts({required String? companyId}) async {
    if (companyId == null) return [];
    
    final response = await client
        .from('company_bank_accounts')
        .select('*')
        .eq('company_id', companyId)
        .order('is_primary', ascending: false);
    return response
        .map<CompanyBankAccount>((json) => CompanyBankAccount.fromJson(json))
        .toList();
  }

  @override
  Future<CompanyBankAccount?> getBankAccount(String id) async {
    final response = await client
        .from('company_bank_accounts')
        .select('*')
        .eq('id', id)
        .maybeSingle();
    if (response == null) return null;
    return CompanyBankAccount.fromJson(response);
  }

  @override
  Future<List<CompanyDocument>> getDocuments({required String? companyId}) async {
    if (companyId == null) return [];
    
    final response = await client
        .from('company_documents')
        .select('*')
        .eq('company_id', companyId)
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

    await client.from('companies').update(data).eq('id', profile.id);
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

    await client.from('company_documents').update(data).eq('id', document.id);
  }

  @override
  Future<void> deleteDocument(String id) async {
    await client.from('company_documents').delete().eq('id', id);
  }

  @override
  Future<CompanyProfile> createCompany({
    required String name,
    Map<String, dynamic>? additionalData,
  }) async {
    final user = client.auth.currentUser;
    if (user == null) throw Exception('Пользователь не авторизован');

    final data = {
      'name_full': additionalData?['name_full'] ?? name,
      'name_short': additionalData?['name_short'] ?? name,
      'owner_id': user.id,
      if (additionalData != null) ...additionalData,
    };

    // Удаляем служебные поля, если они попали случайно
    data.remove('id');
    data.remove('created_at');
    data.remove('updated_at');

    final companyData = await client
        .from('companies')
        .insert(data)
        .select()
        .single();

    final company = CompanyProfile.fromJson(companyData);

    // [MULTI-TENANCY REFACTOR] Добавляем создателя в участники как владельца с системной ролью "owner"
    await client.from('company_members').insert({
      'company_id': company.id,
      'user_id': user.id,
      'is_owner': true,
      'system_role': 'owner',
    });

    // 3. Устанавливаем эту компанию как активную в профиле
    await client
        .from('profiles')
        .update({'last_company_id': company.id})
        .eq('id', user.id);

    return company;
  }

  @override
  Future<void> joinCompany({required String invitationCode}) async {
    final user = client.auth.currentUser;
    if (user == null) throw Exception('Пользователь не авторизован');

    // 1. Ищем компанию по коду
    final companyData = await client
        .from('companies')
        .select('id')
        .eq('invitation_code', invitationCode)
        .eq('is_active', true)
        .maybeSingle();

    if (companyData == null) {
      throw Exception('Компания с таким кодом не найдена или неактивна');
    }

    final companyId = companyData['id'];

    // 2. Проверяем, не состоит ли уже пользователь в этой компании
    final existingMember = await client
        .from('company_members')
        .select()
        .eq('company_id', companyId)
        .eq('user_id', user.id)
        .maybeSingle();

    if (existingMember != null) {
      throw Exception('Вы уже являетесь участником этой организации');
    }

    // 3. Добавляем в участники
    await client.from('company_members').insert({
      'company_id': companyId,
      'user_id': user.id,
      'is_owner': false,
    });

    // 4. Устанавливаем компанию как активную в профиле
    await client
        .from('profiles')
        .update({'last_company_id': companyId})
        .eq('id', user.id);
  }

  @override
  Future<List<CompanyProfile>> getMyCompanies() async {
    final user = client.auth.currentUser;
    if (user == null) return [];

    final response = await client
        .from('company_members')
        .select('companies (*)')
        .eq('user_id', user.id)
        .eq('is_active', true);

    final List<dynamic> data = response as List<dynamic>;
    return data
        .map(
          (item) => CompanyProfile.fromJson(
            item['companies'] as Map<String, dynamic>,
          ),
        )
        .toList();
  }

  @override
  Future<Map<String, dynamic>?> searchCompanyByInn(String inn) async {
    try {
      final response = await client.functions.invoke(
        'dadata-proxy',
        body: {'inn': inn},
      );

      if (response.status == 200 && response.data != null) {
        return response.data as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> updateMember({
    required String userId,
    required String companyId,
    String? roleId,
    bool? isActive,
  }) async {
    final updates = <String, dynamic>{};
    if (roleId != null) updates['role_id'] = roleId;
    if (isActive != null) updates['is_active'] = isActive;

    if (updates.isEmpty) return;

    await client
        .from('company_members')
        .update(updates)
        .eq('company_id', companyId)
        .eq('user_id', userId);
  }
}
