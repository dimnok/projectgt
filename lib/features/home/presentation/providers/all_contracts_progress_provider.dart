import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:projectgt/core/di/providers.dart';
import 'package:projectgt/features/company/presentation/providers/company_providers.dart';

/// Агрегированные суммы по одному договору (сметы и выполнение).
class ContractProgressEntry {
  /// Сумма по сметам.
  final double estimatesTotal;

  /// Сумма выполненных работ.
  final double executedTotal;

  /// Создаёт запись прогресса по договору.
  const ContractProgressEntry({
    required this.estimatesTotal,
    required this.executedTotal,
  });
}

/// Прогресс выполнения по всем договорам компании (данные RPC).
class AllContractsProgress {
  /// Прогресс по идентификатору договора.
  final Map<String, ContractProgressEntry> byContract;

  /// Договор с максимальной долей выполнения (по сумме).
  final String? bestContractId;

  /// Создаёт сводку по договорам.
  const AllContractsProgress({
    required this.byContract,
    required this.bestContractId,
  });

  /// Взвешенный процент выполнения по суммам смет (0–100), или null если объём смет нулевой.
  double? get companyWeightedExecutionPercent {
    double sumEst = 0;
    double sumExec = 0;
    for (final e in byContract.values) {
      sumEst += e.estimatesTotal;
      sumExec += e.executedTotal;
    }
    if (sumEst <= 0) return null;
    return (sumExec / sumEst * 100).clamp(0, 100);
  }
}

/// Прогресс выполнения по всем договорам.
///
/// Использует RPC [get_all_contracts_progress] для масштабируемой загрузки.
final allContractsProgressProvider =
    FutureProvider<AllContractsProgress>((ref) async {
  final client = ref.watch(supabaseClientProvider);
  final activeCompanyId = ref.watch(activeCompanyIdProvider);

  if (activeCompanyId == null) {
    return const AllContractsProgress(byContract: {}, bestContractId: null);
  }

  late final Map<String, double> estimatesTotalByContract;
  late final Map<String, double> executedTotalByContract;

  try {
    final rpcFuture = client.rpc('get_all_contracts_progress', params: {
      'p_company_id': activeCompanyId,
    });
    final List<dynamic> rpcResult = await rpcFuture.timeout(
      const Duration(seconds: 30),
      onTimeout: () => throw Exception(
        'RPC get_all_contracts_progress timeout after 30 seconds',
      ),
    );

    estimatesTotalByContract = {};
    executedTotalByContract = {};

    for (final row in rpcResult) {
      final String? contractId = row['contract_id'] as String?;
      if (contractId == null) continue;

      final dynamic estTotal = row['estimate_total'];
      final dynamic execTotal = row['executed_total'];

      final double estimateTotal =
          (estTotal is num) ? estTotal.toDouble() : 0.0;
      final double executedTotal =
          (execTotal is num) ? execTotal.toDouble() : 0.0;

      estimatesTotalByContract[contractId] = estimateTotal;
      executedTotalByContract[contractId] = executedTotal;
    }
  } catch (e) {
    throw Exception('Не удалось получить данные по договорам: $e');
  }

  final Map<String, ContractProgressEntry> byContract = {};
  for (final entry in estimatesTotalByContract.entries) {
    final String contractId = entry.key;
    final double est = entry.value;
    final double done = executedTotalByContract[contractId] ?? 0;
    byContract[contractId] = ContractProgressEntry(
      estimatesTotal: est,
      executedTotal: done,
    );
  }

  String? best;
  double bestRatio = -1;
  byContract.forEach((cid, prog) {
    final double ratio = prog.estimatesTotal > 0
        ? (prog.executedTotal / prog.estimatesTotal)
        : 0;
    if (ratio > bestRatio) {
      bestRatio = ratio;
      best = cid;
    }
  });

  return AllContractsProgress(byContract: byContract, bestContractId: best);
});
