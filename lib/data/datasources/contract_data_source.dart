import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:projectgt/data/models/contract_model.dart';
import 'package:projectgt/domain/entities/contract.dart';
import 'package:logger/logger.dart';

/// Источник данных для работы с договорами через Supabase.
///
/// Реализует CRUD-операции с таблицей contracts, а также подгружает связанные данные
/// по контрагенту (contractors.short_name) и объекту (objects.name) через join-запросы.
/// Все методы выбрасывают исключения при ошибках работы с сетью или БД.
///
/// Пример использования:
/// ```dart
/// final dataSource = SupabaseContractDataSource(Supabase.instance.client);
/// final contracts = await dataSource.getContracts();
/// ```
abstract class ContractDataSource {
  /// Получает список всех договоров с подгруженными названиями контрагента и объекта.
  ///
  /// Возвращает список [ContractModel].
  /// Выбрасывает исключение при ошибке сети или БД.
  Future<List<ContractModel>> getContracts();

  /// Получает договор по идентификатору.
  ///
  /// [id] — идентификатор договора.
  /// Возвращает [ContractModel], если найден, иначе null.
  /// Выбрасывает исключение при ошибке.
  Future<ContractModel?> getContract(String id);

  /// Создаёт новый договор в базе данных.
  ///
  /// [contract] — доменная сущность договора.
  /// Возвращает созданный [ContractModel].
  /// Выбрасывает исключение при ошибке.
  Future<ContractModel> createContract(Contract contract);

  /// Обновляет существующий договор в базе данных.
  ///
  /// [contract] — модель договора для обновления.
  /// Возвращает обновлённый [ContractModel].
  /// Выбрасывает исключение при ошибке.
  Future<ContractModel> updateContract(ContractModel contract);

  /// Удаляет договор по идентификатору.
  ///
  /// [id] — идентификатор договора.
  /// Выбрасывает исключение при ошибке.
  Future<void> deleteContract(String id);
}

/// Реализация [ContractDataSource] через Supabase.
///
/// Использует Supabase для CRUD-операций с таблицей contracts.
/// Для метода [getContracts] выполняет join с таблицами contractors и objects,
/// чтобы получать сокращённое наименование контрагента и название объекта.
class SupabaseContractDataSource implements ContractDataSource {
  /// Экземпляр клиента Supabase для выполнения запросов.
  final SupabaseClient client;

  /// ID активной компании.
  final String activeCompanyId;

  /// Логгер для отладочной информации.
  final Logger _logger = Logger();

  /// Создаёт источник данных по договорам через Supabase.
  ///
  /// [client] — экземпляр [SupabaseClient].
  /// [activeCompanyId] — ID активной компании.
  SupabaseContractDataSource(this.client, this.activeCompanyId);

  /// Получает список всех договоров с названиями контрагента и объекта.
  ///
  /// Использует join-запрос:
  ///   - contractor:contractors(short_name)
  ///   - object:objects(name)
  ///
  /// Возвращает список [ContractModel].
  /// Выбрасывает исключение при ошибке сети или БД.
  @override
  Future<List<ContractModel>> getContracts() async {
    final response = await client
        .from('contracts')
        .select('*, contractor:contractors(short_name), object:objects(name)')
        .eq('company_id', activeCompanyId)
        .order('date', ascending: false);
    return response
        .map<ContractModel>((json) => ContractModel.fromJson(json))
        .toList();
  }

  /// Получает договор по идентификатору без join-данных.
  ///
  /// [id] — идентификатор договора.
  /// Возвращает [ContractModel], если найден, иначе null.
  /// Выбрасывает исключение при ошибке.
  @override
  Future<ContractModel?> getContract(String id) async {
    final response = await client
        .from('contracts')
        .select('*')
        .eq('id', id)
        .eq('company_id', activeCompanyId)
        .maybeSingle();
    if (response == null) return null;
    return ContractModel.fromJson(response);
  }

  /// Создаёт новый договор в базе данных.
  ///
  /// [contract] — доменная сущность договора.
  /// Возвращает созданный [ContractModel].
  /// Выбрасывает исключение при ошибке.
  @override
  Future<ContractModel> createContract(Contract contract) async {
    final now = DateTime.now().toIso8601String();
    final contractJson = ContractModel.fromDomain(contract).toJson();
    contractJson['company_id'] = activeCompanyId;
    contractJson['created_at'] = now;
    contractJson['updated_at'] = now;
    _logger.d('[CONTRACTS][SEND TO SUPABASE] $contractJson');
    final response = await client
        .from('contracts')
        .insert(contractJson)
        .select()
        .maybeSingle();
    _logger.d('[CONTRACTS][INSERT] response: $response');
    if (response == null) {
      throw Exception('Ошибка создания договора: пустой ответ');
    }
    return ContractModel.fromJson(response);
  }

  /// Обновляет существующий договор в базе данных.
  ///
  /// [contract] — модель договора для обновления.
  /// Возвращает обновлённый [ContractModel].
  /// Выбрасывает исключение при ошибке.
  @override
  Future<ContractModel> updateContract(ContractModel contract) async {
    final now = DateTime.now().toIso8601String();
    final contractJson = contract.toJson();
    contractJson['company_id'] = activeCompanyId;
    contractJson['updated_at'] = now;
    final response = await client
        .from('contracts')
        .update(contractJson)
        .eq('id', contract.id)
        .eq('company_id', activeCompanyId)
        .select()
        .maybeSingle();
    if (response == null) {
      throw Exception('Договор не найден для обновления');
    }
    return ContractModel.fromJson(response);
  }

  /// Удаляет договор по идентификатору.
  ///
  /// [id] — идентификатор договора.
  /// Выбрасывает исключение при ошибке.
  @override
  Future<void> deleteContract(String id) async {
    await client
        .from('contracts')
        .delete()
        .eq('id', id)
        .eq('company_id', activeCompanyId);
  }
}
