import 'package:supabase_flutter/supabase_flutter.dart';

/// Сервис для расчета выработки по договорам
class ContractWorksService {
  final SupabaseClient _supabase;

  /// Создаёт сервис для расчета выработки по договорам.
  ///
  /// [supabaseClient] - клиент Supabase (опционально, для тестов).
  ContractWorksService({SupabaseClient? supabaseClient})
      : _supabase = supabaseClient ?? Supabase.instance.client;

  /// Рассчитывает общую сумму выработки по договору
  ///
  /// [contractId] - ID договора
  /// [objectId] - ID объекта (опционально, для дополнительной фильтрации)
  ///
  /// Использует SQL функцию для расчета на стороне БД.
  /// Возвращает общую сумму всех work_items из закрытых смен,
  /// которые относятся к сметам данного договора.
  Future<double> calculateContractWorksAmount({
    required String contractId,
    String? objectId,
  }) async {
    try {
      // Используем RPC функцию для расчета на стороне БД
      final response = await _supabase.rpc(
        'calculate_contract_works',
        params: {
          'contract_id': contractId,
          'object_id': objectId,
        },
      );

      return (response as num?)?.toDouble() ?? 0.0;
    } catch (e) {
      // При ошибке RPC используем fallback на обычный запрос
      return _calculateContractWorksAmountFallback(
        contractId: contractId,
        objectId: objectId,
      );
    }
  }

  /// Fallback метод для расчета выработки через обычные запросы
  Future<double> _calculateContractWorksAmountFallback({
    required String contractId,
    String? objectId,
  }) async {
    try {
      // Оптимизированный запрос с использованием JOIN
      final query = _supabase
          .from('work_items')
          .select('''
            total,
            estimates!inner(contract_id),
            works!inner(status, object_id)
          ''')
          .eq('estimates.contract_id', contractId)
          .eq('works.status', 'closed');

      if (objectId != null && objectId.isNotEmpty) {
        query.eq('works.object_id', objectId);
      }

      final response = await query;

      // Подсчитываем сумму
      double totalAmount = 0.0;

      for (final item in response) {
        totalAmount += (item['total'] as num?)?.toDouble() ?? 0.0;
      }

      return totalAmount;
    } catch (e) {
      throw Exception('Ошибка расчета выработки по договору: $e');
    }
  }

  /// Рассчитывает выработку для нескольких договоров одним запросом
  ///
  /// Использует агрегацию на стороне БД для максимальной производительности.
  /// Полезно для пакетной обработки и отчетов.
  Future<Map<String, double>> calculateMultipleContractsWorks({
    required List<String> contractIds,
    String? objectId,
  }) async {
    if (contractIds.isEmpty) return {};

    try {
      // Используем RPC функцию для агрегации на стороне БД
      // Это намного эффективнее, чем множественные запросы
      final query = _supabase.rpc(
        'calculate_contracts_works',
        params: {
          'contract_ids': contractIds,
          'object_id': objectId,
        },
      );

      final response = await query;

      // Преобразуем результат в Map
      final results = <String, double>{};
      for (final row in response as List) {
        results[row['contract_id'] as String] =
            (row['total_amount'] as num?)?.toDouble() ?? 0.0;
      }

      // Заполняем нулями договоры без выработки
      for (final contractId in contractIds) {
        results.putIfAbsent(contractId, () => 0.0);
      }

      return results;
    } catch (e) {
      // При ошибке RPC функции используем fallback на последовательные запросы
      return _calculateMultipleContractsWorksFallback(
        contractIds: contractIds,
        objectId: objectId,
      );
    }
  }

  /// Fallback метод для расчета выработки по нескольким договорам
  Future<Map<String, double>> _calculateMultipleContractsWorksFallback({
    required List<String> contractIds,
    String? objectId,
  }) async {
    final results = <String, double>{};

    for (final contractId in contractIds) {
      try {
        final amount = await calculateContractWorksAmount(
          contractId: contractId,
          objectId: objectId,
        );
        results[contractId] = amount;
      } catch (e) {
        // Логируем ошибку, но продолжаем для остальных договоров
        results[contractId] = 0.0;
      }
    }

    return results;
  }
}
