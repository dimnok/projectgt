import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/payroll_penalty_model.dart';
import '../../data/repositories/payroll_penalty_repository.dart';
import '../../data/repositories/payroll_penalty_repository_impl.dart';
import '../../domain/usecases/create_penalty_usecase.dart';
import '../../domain/usecases/update_penalty_usecase.dart';
import '../../domain/usecases/delete_penalty_usecase.dart';
import 'package:projectgt/core/di/providers.dart';
import 'payroll_filter_provider.dart';
import 'package:collection/collection.dart';

/// Провайдер репозитория штрафов (реализация Supabase).
final payrollPenaltyRepositoryProvider =
    Provider<PayrollPenaltyRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return PayrollPenaltyRepositoryImpl(client);
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

/// Провайдер асинхронной загрузки всех штрафов (PayrollPenaltyModel) из репозитория.
///
/// Используется для получения полного списка штрафов из Supabase через PayrollPenaltyRepository.
/// Возвращает Future<List<PayrollPenaltyModel>> для дальнейшей фильтрации и отображения в UI.
final allPenaltiesProvider =
    FutureProvider<List<PayrollPenaltyModel>>((ref) async {
  final repo = ref.watch(payrollPenaltyRepositoryProvider);
  return await repo.getAllPenalties();
});

/// Провайдер отфильтрованных штрафов по выбранным критериям фильтрации ФОТ.
///
/// Выполняет фильтрацию всех штрафов по периоду (год/месяц), сотрудникам, объектам и должностям,
/// используя состояние payrollFilterProvider и список сотрудников.
/// Возвращает List<PayrollPenaltyModel> для отображения в таблице штрафов.
final filteredPenaltiesProvider = Provider<List<PayrollPenaltyModel>>((ref) {
  final penaltiesAsync = ref.watch(allPenaltiesProvider);
  final filter = ref.watch(payrollFilterProvider);
  final employees = filter.employees;
  return penaltiesAsync.maybeWhen(
    data: (allPenalties) {
      final filteredPenalties = allPenalties.where((penalty) {
        // Фильтр по дате
        final date = penalty.date;
        final inMonth = date != null &&
            date.year == filter.year &&
            date.month == filter.month;
        // Фильтр по сотруднику
        final byEmployee = filter.employeeIds.isEmpty ||
            filter.employeeIds.contains(penalty.employeeId);
        // Фильтр по объекту
        final byObject = filter.objectIds.isEmpty ||
            (penalty.objectId != null &&
                filter.objectIds.contains(penalty.objectId));
        // Фильтр по должности
        final byPosition = filter.positionNames.isEmpty ||
            (() {
              final emp =
                  employees.firstWhereOrNull((e) => e.id == penalty.employeeId);
              return emp != null && filter.positionNames.contains(emp.position);
            })();
        return inMonth && byEmployee && byObject && byPosition;
      }).toList();

      // Сортируем по алфавиту (ФИО сотрудников)
      filteredPenalties.sort((a, b) {
        final empA = employees.firstWhereOrNull((e) => e.id == a.employeeId);
        final empB = employees.firstWhereOrNull((e) => e.id == b.employeeId);
        final nameA = empA != null
            ? ('${empA.lastName} ${empA.firstName} ${empA.middleName ?? ''}')
                .trim()
                .toLowerCase()
            : a.employeeId.toLowerCase();
        final nameB = empB != null
            ? ('${empB.lastName} ${empB.firstName} ${empB.middleName ?? ''}')
                .trim()
                .toLowerCase()
            : b.employeeId.toLowerCase();
        return nameA.compareTo(nameB);
      });

      return filteredPenalties;
    },
    orElse: () => [],
  );
});
