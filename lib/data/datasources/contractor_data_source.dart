import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:projectgt/data/models/contractor_model.dart';
import 'package:logger/logger.dart';

/// Абстракция для источника данных по контрагентам.
///
/// Определяет контракт для получения, создания, обновления и удаления контрагентов.
abstract class ContractorDataSource {
  /// Получает список всех контрагентов.
  ///
  /// Возвращает список [ContractorModel].
  /// Генерирует исключение при ошибке.
  Future<List<ContractorModel>> getContractors();

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
}

/// Реализация [ContractorDataSource] через Supabase.
///
/// Использует Supabase для CRUD-операций с таблицей contractors.
class SupabaseContractorDataSource implements ContractorDataSource {
  /// Экземпляр клиента Supabase.
  final SupabaseClient client;

  /// Создаёт источник данных по контрагентам через Supabase.
  ///
  /// [client] — экземпляр [SupabaseClient].
  SupabaseContractorDataSource(this.client);

  @override
  Future<List<ContractorModel>> getContractors() async {
    final response =
        await client.from('contractors').select('*').order('full_name');
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
    final now = DateTime.now().toIso8601String();
    final contractorJson = contractor.toJson();
    contractorJson['created_at'] = now;
    contractorJson['updated_at'] = now;
    Logger().d('[DEBUG] contractorJson to insert:');
    Logger().d(contractorJson);
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
    final now = DateTime.now().toIso8601String();
    final contractorJson = contractor.toJson();
    contractorJson['updated_at'] = now;
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
}
