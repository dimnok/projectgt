import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:projectgt/features/contracts/services/contract_works_service.dart';

/// Провайдер для сервиса расчета выработки
final contractWorksServiceProvider = Provider<ContractWorksService>((ref) {
  return ContractWorksService();
});

/// Провайдер для получения суммы выработки по договору
///
/// Получает сумму всех work_items из закрытых смен, связанных с договором через estimates
/// Параметр: "contractId|objectId"
final contractWorksSummaryProvider =
    FutureProvider.family<Map<String, dynamic>, String>((ref, params) async {
  final service = ref.read(contractWorksServiceProvider);

  // Разбираем параметры
  final parts = params.split('|');
  final contractId = parts[0];
  final objectId = parts.length > 1 && parts[1].isNotEmpty ? parts[1] : null;

  try {
    final totalAmount = await service.calculateContractWorksAmount(
      contractId: contractId,
      objectId: objectId,
    );

    return {
      'totalAmount': totalAmount,
    };
  } catch (e) {
    throw Exception('Ошибка загрузки данных по выработке: $e');
  }
});
