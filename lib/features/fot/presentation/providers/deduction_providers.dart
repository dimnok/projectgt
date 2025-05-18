import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/payroll_deduction_model.dart';
import '../../data/repositories/payroll_deduction_repository.dart';
import '../../domain/usecases/get_deductions_by_payroll_id_usecase.dart';
import '../../domain/usecases/create_deduction_usecase.dart';
import '../../domain/usecases/update_deduction_usecase.dart';
import '../../domain/usecases/delete_deduction_usecase.dart';

/// Провайдер репозитория удержаний (реализация должна быть внедрена выше по дереву).
final payrollDeductionRepositoryProvider = Provider<PayrollDeductionRepository>((ref) {
  throw UnimplementedError();
});

/// Провайдер usecase получения удержаний по payrollId.
final getDeductionsByPayrollIdUseCaseProvider = Provider<GetDeductionsByPayrollIdUseCase>((ref) {
  return GetDeductionsByPayrollIdUseCase(ref.watch(payrollDeductionRepositoryProvider));
});

/// Провайдер получения списка удержаний по payrollId.
final deductionsByPayrollIdProvider = FutureProvider.family<List<PayrollDeductionModel>, String>((ref, payrollId) async {
  final useCase = ref.watch(getDeductionsByPayrollIdUseCaseProvider);
  return useCase(payrollId);
});

/// Провайдер usecase создания удержания.
final createDeductionUseCaseProvider = Provider<CreateDeductionUseCase>((ref) {
  return CreateDeductionUseCase(ref.watch(payrollDeductionRepositoryProvider));
});

/// Провайдер usecase обновления удержания.
final updateDeductionUseCaseProvider = Provider<UpdateDeductionUseCase>((ref) {
  return UpdateDeductionUseCase(ref.watch(payrollDeductionRepositoryProvider));
});

/// Провайдер usecase удаления удержания.
final deleteDeductionUseCaseProvider = Provider<DeleteDeductionUseCase>((ref) {
  return DeleteDeductionUseCase(ref.watch(payrollDeductionRepositoryProvider));
}); 