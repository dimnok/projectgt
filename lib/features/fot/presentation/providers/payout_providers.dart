import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/payroll_payout_model.dart';
import '../../data/repositories/payroll_payout_repository.dart';
import '../../domain/usecases/get_payouts_by_payroll_id_usecase.dart';
import '../../domain/usecases/create_payout_usecase.dart';
import '../../domain/usecases/update_payout_usecase.dart';
import '../../domain/usecases/delete_payout_usecase.dart';

/// Провайдер репозитория выплат (реализация должна быть внедрена выше по дереву).
final payrollPayoutRepositoryProvider = Provider<PayrollPayoutRepository>((ref) {
  throw UnimplementedError();
});

/// Провайдер usecase получения выплат по payrollId.
final getPayoutsByPayrollIdUseCaseProvider = Provider<GetPayoutsByPayrollIdUseCase>((ref) {
  return GetPayoutsByPayrollIdUseCase(ref.watch(payrollPayoutRepositoryProvider));
});

/// Провайдер получения списка выплат по payrollId.
final payoutsByPayrollIdProvider = FutureProvider.family<List<PayrollPayoutModel>, String>((ref, payrollId) async {
  final useCase = ref.watch(getPayoutsByPayrollIdUseCaseProvider);
  return useCase(payrollId);
});

/// Провайдер usecase создания выплаты.
final createPayoutUseCaseProvider = Provider<CreatePayoutUseCase>((ref) {
  return CreatePayoutUseCase(ref.watch(payrollPayoutRepositoryProvider));
});

/// Провайдер usecase обновления выплаты.
final updatePayoutUseCaseProvider = Provider<UpdatePayoutUseCase>((ref) {
  return UpdatePayoutUseCase(ref.watch(payrollPayoutRepositoryProvider));
});

/// Провайдер usecase удаления выплаты.
final deletePayoutUseCaseProvider = Provider<DeletePayoutUseCase>((ref) {
  return DeletePayoutUseCase(ref.watch(payrollPayoutRepositoryProvider));
}); 