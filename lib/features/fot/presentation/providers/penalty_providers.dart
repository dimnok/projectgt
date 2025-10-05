import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/payroll_penalty_model.dart';
import '../../domain/repositories/payroll_penalty_repository.dart';
import '../../data/repositories/payroll_penalty_repository_impl.dart';
import 'package:projectgt/core/di/providers.dart';
import 'package:collection/collection.dart';
import 'package:projectgt/presentation/state/employee_state.dart';
import 'payroll_filter_providers.dart';

/// Провайдер репозитория штрафов (реализация Supabase).
final payrollPenaltyRepositoryProvider =
    Provider<PayrollPenaltyRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return PayrollPenaltyRepositoryImpl(client);
});

/// Провайдер функции создания штрафа.
///
/// Используется для создания новых штрафов через репозиторий.
/// @returns Future<PayrollPenaltyModel> Function(PayrollPenaltyModel) — функция создания штрафа.
final createPenaltyUseCaseProvider =
    Provider<Future<PayrollPenaltyModel> Function(PayrollPenaltyModel)>((ref) {
  final repo = ref.watch(payrollPenaltyRepositoryProvider);
  return (PayrollPenaltyModel penalty) async {
    return await repo.createPenalty(penalty);
  };
});

/// Провайдер функции обновления штрафа.
///
/// Используется для обновления существующих штрафов через репозиторий.
/// @returns Future<PayrollPenaltyModel> Function(PayrollPenaltyModel) — функция обновления штрафа.
final updatePenaltyUseCaseProvider =
    Provider<Future<PayrollPenaltyModel> Function(PayrollPenaltyModel)>((ref) {
  final repo = ref.watch(payrollPenaltyRepositoryProvider);
  return (PayrollPenaltyModel penalty) async {
    return await repo.updatePenalty(penalty);
  };
});

/// Провайдер функции удаления штрафа по ID.
///
/// Используется для удаления штрафов через репозиторий.
/// @returns Future<void> Function(String) — функция удаления штрафа по ID.
final deletePenaltyUseCaseProvider =
    Provider<Future<void> Function(String)>((ref) {
  final repo = ref.watch(payrollPenaltyRepositoryProvider);
  return (String id) async {
    await repo.deletePenalty(id);
  };
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

/// Провайдер всех штрафов с опциональной фильтрацией.
///
/// По умолчанию показывает ВСЕ штрафы.
/// Если в фильтрах выбран период (не текущий месяц) - фильтрует по периоду.
/// Возвращает List<PayrollPenaltyModel> для отображения в таблице штрафов.
final filteredPenaltiesProvider = Provider<List<PayrollPenaltyModel>>((ref) {
  final penaltiesAsync = ref.watch(allPenaltiesProvider);
  final employeeState = ref.watch(employeeProvider);
  final employees = employeeState.employees;
  final filterState = ref.watch(payrollFilterProvider);

  // Проверяем, изменен ли период от текущего месяца
  final now = DateTime.now();
  final isPeriodFiltered = filterState.selectedYear != now.year ||
      filterState.selectedMonth != now.month;

  return penaltiesAsync.maybeWhen(
    data: (allPenalties) {
      // Применяем фильтр по периоду только если выбран НЕ текущий месяц
      final filteredPenalties = isPeriodFiltered
          ? allPenalties.where((penalty) {
              // Используем penalty.date (дата штрафа), fallback на createdAt если date == null
              final date = penalty.date ?? penalty.createdAt;
              return date != null &&
                  date.year == filterState.selectedYear &&
                  date.month == filterState.selectedMonth;
            }).toList()
          : allPenalties; // Показываем ВСЕ штрафы если фильтр не применен

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
