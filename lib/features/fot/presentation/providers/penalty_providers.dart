import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/payroll_penalty_model.dart';
import '../../data/repositories/payroll_penalty_repository.dart';
import '../../domain/usecases/get_penalties_by_payroll_id_usecase.dart';
import '../../domain/usecases/create_penalty_usecase.dart';
import '../../domain/usecases/update_penalty_usecase.dart';
import '../../domain/usecases/delete_penalty_usecase.dart';

/// Провайдер репозитория штрафов (реализация должна быть внедрена выше по дереву).
final payrollPenaltyRepositoryProvider = Provider<PayrollPenaltyRepository>((ref) {
  throw UnimplementedError();
});

/// Провайдер usecase получения штрафов по payrollId.
final getPenaltiesByPayrollIdUseCaseProvider = Provider<GetPenaltiesByPayrollIdUseCase>((ref) {
  return GetPenaltiesByPayrollIdUseCase(ref.watch(payrollPenaltyRepositoryProvider));
});

/// Провайдер получения списка штрафов по payrollId.
final penaltiesByPayrollIdProvider = FutureProvider.family<List<PayrollPenaltyModel>, String>((ref, payrollId) async {
  final useCase = ref.watch(getPenaltiesByPayrollIdUseCaseProvider);
  return useCase(payrollId);
});

/// Провайдер usecase создания штрафа.
final createPenaltyUseCaseProvider = Provider<CreatePenaltyUseCase>((ref) {
  return CreatePenaltyUseCase(ref.watch(payrollPenaltyRepositoryProvider));
});

/// Провайдер usecase обновления штрафа.
final updatePenaltyUseCaseProvider = Provider<UpdatePenaltyUseCase>((ref) {
  return UpdatePenaltyUseCase(ref.watch(payrollPenaltyRepositoryProvider));
});

/// Провайдер usecase удаления штрафа.
final deletePenaltyUseCaseProvider = Provider<DeletePenaltyUseCase>((ref) {
  return DeletePenaltyUseCase(ref.watch(payrollPenaltyRepositoryProvider));
}); 