import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:projectgt/core/di/providers.dart';
import 'package:projectgt/domain/entities/contract_act.dart';

/// Список актов по договору.
final contractActsProvider =
    FutureProvider.family<List<ContractAct>, String>((ref, contractId) async {
  final useCase = ref.watch(getContractActsUseCaseProvider);
  return useCase(contractId);
});
