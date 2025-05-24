export 'payroll_providers.dart' show filteredPenaltiesProvider, allPenaltiesProvider;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/payroll_penalty_model.dart';
import '../../data/repositories/payroll_penalty_repository.dart';
import '../../data/repositories/payroll_penalty_repository_impl.dart';
import '../../domain/usecases/get_penalties_by_payroll_id_usecase.dart';
import '../../domain/usecases/create_penalty_usecase.dart';
import '../../domain/usecases/update_penalty_usecase.dart';
import '../../domain/usecases/delete_penalty_usecase.dart';
import 'package:projectgt/core/di/providers.dart';
import 'payroll_filter_provider.dart';
import 'package:collection/collection.dart';

/// Провайдер репозитория штрафов (реализация Supabase).
final payrollPenaltyRepositoryProvider = Provider<PayrollPenaltyRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return PayrollPenaltyRepositoryImpl(client);
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

final allPenaltiesProvider = FutureProvider<List<PayrollPenaltyModel>>((ref) async {
  final repo = ref.watch(payrollPenaltyRepositoryProvider);
  return await repo.getAllPenalties();
});

final filteredPenaltiesProvider = Provider<List<PayrollPenaltyModel>>((ref) {
  final penaltiesAsync = ref.watch(allPenaltiesProvider);
  final filter = ref.watch(payrollFilterProvider);
  final employees = filter.employees;
  return penaltiesAsync.maybeWhen(
    data: (allPenalties) {
      return allPenalties.where((penalty) {
        // Фильтр по дате
        final date = penalty.date;
        final inMonth = date != null &&
          date.year == filter.year &&
          date.month == filter.month;
        // Фильтр по сотруднику
        final byEmployee = filter.employeeIds.isEmpty ||
          (penalty.employeeId != null && filter.employeeIds.contains(penalty.employeeId));
        // Фильтр по объекту
        final byObject = filter.objectIds.isEmpty ||
          (penalty.objectId != null && filter.objectIds.contains(penalty.objectId));
        // Фильтр по должности
        final byPosition = filter.positionNames.isEmpty ||
          (() {
            final emp = employees.firstWhereOrNull((e) => e.id == penalty.employeeId);
            return emp != null && filter.positionNames.contains(emp.position);
          })();
        return inMonth && byEmployee && byObject && byPosition;
      }).toList();
    },
    orElse: () => [],
  );
}); 