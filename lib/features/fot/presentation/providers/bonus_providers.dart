import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/payroll_bonus_model.dart';
import '../../data/repositories/payroll_bonus_repository.dart';
import '../../domain/usecases/get_bonuses_by_payroll_id_usecase.dart';

/// Провайдер репозитория премий (реализация внедряется выше).
final payrollBonusRepositoryProvider = Provider<PayrollBonusRepository>((ref) {
  throw UnimplementedError();
});

/// Провайдер usecase получения премий по payrollId.
final getBonusesByPayrollIdUseCaseProvider = Provider<GetBonusesByPayrollIdUseCase>((ref) {
  return GetBonusesByPayrollIdUseCase(ref.watch(payrollBonusRepositoryProvider));
});

/// Провайдер получения списка премий по payrollId.
final bonusesByPayrollIdProvider = FutureProvider.family<List<PayrollBonusModel>, String>((ref, payrollId) async {
  final useCase = ref.watch(getBonusesByPayrollIdUseCaseProvider);
  return useCase(payrollId);
});

// TODO: Добавить провайдеры для создания, обновления, удаления премий после реализации соответствующих usecase-ов. 