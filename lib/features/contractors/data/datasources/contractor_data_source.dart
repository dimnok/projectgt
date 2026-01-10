import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:projectgt/features/contractors/data/models/contractor_model.dart';
import 'package:projectgt/features/contractors/data/models/contractor_bank_account_model.dart';
import 'package:logger/logger.dart';

/// Абстракция для источника данных по контрагентам.
///
/// Определяет контракт для получения, создания, обновления и удаления контрагентов.
abstract class ContractorDataSource {
  /// Получает список всех контрагентов для указанной компании.
  ///
  /// Возвращает список [ContractorModel].
  /// Генерирует исключение при ошибке.
  Future<List<ContractorModel>> getContractors(String companyId);

  /// Получает контрагента по идентификатору.
  ///
  /// [id] — идентификатор контрагента.
  /// Возвращает [ContractorModel], если найден, иначе null.
  /// Генерирует исключение при ошибке.
  Future<ContractorModel?> getContractor(String id);

  /// Создаёт нового контрагента.
  ///
  /// [contractor] — модель контрагента.
  /// Возвращает созданный [ContractorModel].
  /// Генерирует исключение при ошибке.
  Future<ContractorModel> createContractor(ContractorModel contractor);

  /// Обновляет существующего контрагента.
  ///
  /// [contractor] — модель контрагента для обновления.
  /// Возвращает обновлённый [ContractorModel].
  /// Генерирует исключение при ошибке.
  Future<ContractorModel> updateContractor(ContractorModel contractor);

  /// Удаляет контрагента по идентификатору.
  ///
  /// [id] — идентификатор контрагента.
  /// Генерирует исключение при ошибке.
  Future<void> deleteContractor(String id);

  /// Получает список банковских счетов для контрагента.
  Future<List<ContractorBankAccountModel>> getBankAccounts(String contractorId, String companyId);

  /// Добавляет новый банковский счет.
  Future<ContractorBankAccountModel> addBankAccount(ContractorBankAccountModel account);

  /// Обновляет существующий банковский счет.
  Future<ContractorBankAccountModel> updateBankAccount(ContractorBankAccountModel account);

  /// Удаляет банковский счет.
  Future<void> deleteBankAccount(String id);
}

/// Реализация [ContractorDataSource] через Supabase.
///
/// Использует Supabase для CRUD-операций с таблицей contractors.
class SupabaseContractorDataSource implements ContractorDataSource {
  /// Экземпляр клиента Supabase.
  final SupabaseClient client;

  /// Статический логгер для отладки.
  static final _logger = Logger();

  /// Создаёт источник данных по контрагентам через Supabase.
  ///
  /// [client] — экземпляр [SupabaseClient].
  SupabaseContractorDataSource(this.client);

  @override
  Future<List<ContractorModel>> getContractors(String companyId) async {
    final response = await client
        .from('contractors')
        .select('*')
        .eq('company_id', companyId)
        .order('full_name');
    return response
        .map<ContractorModel>((json) => ContractorModel.fromJson(json))
        .toList();
  }

  @override
  Future<ContractorModel?> getContractor(String id) async {
    final response =
        await client.from('contractors').select('*').eq('id', id).maybeSingle();
    if (response == null) return null;
    return ContractorModel.fromJson(response);
  }

  @override
  Future<ContractorModel> createContractor(ContractorModel contractor) async {
    final contractorJson = contractor.toJson();
    // Удаляем null-поля, чтобы сработали default значения в БД
    contractorJson.removeWhere((key, value) => value == null);
    
    _logger.d('[DEBUG] contractorJson to insert: $contractorJson');
    
    final response = await client
        .from('contractors')
        .insert(contractorJson)
        .select()
        .maybeSingle();
        
    if (response == null) {
      throw Exception('Ошибка создания контрагента');
    }
    return ContractorModel.fromJson(response);
  }

  @override
  Future<ContractorModel> updateContractor(ContractorModel contractor) async {
    final contractorJson = contractor.toJson();
    
    final response = await client
        .from('contractors')
        .update(contractorJson)
        .eq('id', contractor.id)
        .select()
        .maybeSingle();
        
    if (response == null) {
      throw Exception('Контрагент не найден для обновления');
    }
    return ContractorModel.fromJson(response);
  }

  @override
  Future<void> deleteContractor(String id) async {
    await client.from('contractors').delete().eq('id', id);
  }

  @override
  Future<List<ContractorBankAccountModel>> getBankAccounts(String contractorId, String companyId) async {
    final response = await client
        .from('contractor_bank_accounts')
        .select('*')
        .eq('contractor_id', contractorId)
        .eq('company_id', companyId)
        .order('is_primary', ascending: false);
    return response
        .map<ContractorBankAccountModel>((json) => ContractorBankAccountModel.fromJson(json))
        .toList();
  }

  @override
  Future<ContractorBankAccountModel> addBankAccount(ContractorBankAccountModel account) async {
    final data = account.toJson();
    data.remove('id');
    data.remove('created_at');
    data.remove('updated_at');
    
    final response = await client
        .from('contractor_bank_accounts')
        .insert(data)
        .select()
        .single();
    return ContractorBankAccountModel.fromJson(response);
  }

  @override
  Future<ContractorBankAccountModel> updateBankAccount(ContractorBankAccountModel account) async {
    final data = account.toJson();
    data.remove('created_at');
    data.remove('updated_at');
    
    final response = await client
        .from('contractor_bank_accounts')
        .update(data)
        .eq('id', account.id)
        .select()
        .single();
    return ContractorBankAccountModel.fromJson(response);
  }

  @override
  Future<void> deleteBankAccount(String id) async {
    await client.from('contractor_bank_accounts').delete().eq('id', id);
  }
}
