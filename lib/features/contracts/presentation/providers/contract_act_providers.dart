import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:projectgt/core/di/providers.dart';
import 'package:projectgt/domain/entities/contract_act.dart';
import 'package:projectgt/domain/entities/contract_act_line.dart';

/// Список актов по договору.
final contractActsProvider =
    FutureProvider.family<List<ContractAct>, String>((ref, contractId) async {
  final useCase = ref.watch(getContractActsUseCaseProvider);
  return useCase(contractId);
});

/// Строки сохранённого акта КС-2 (`contract_act_lines`).
final contractActLinesProvider =
    FutureProvider.autoDispose.family<List<ContractActLine>, String>((
  ref,
  actId,
) async {
  final repository = ref.watch(contractActRepositoryProvider);
  return repository.listActLines(actId);
});
