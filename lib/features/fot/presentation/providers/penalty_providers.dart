import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/payroll_penalty_model.dart';
import '../../domain/repositories/payroll_penalty_repository.dart';
import '../../data/repositories/payroll_penalty_repository_impl.dart';
import 'package:projectgt/features/company/presentation/providers/company_providers.dart';
import 'package:projectgt/core/di/providers.dart';
import 'package:collection/collection.dart';
import 'package:projectgt/presentation/state/employee_state.dart';
import 'payroll_filter_providers.dart';

/// Провайдер репозитория штрафов (реализация Supabase).
final payrollPenaltyRepositoryProvider =
    Provider<PayrollPenaltyRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  final activeCompanyId = ref.watch(activeCompanyIdProvider);
  return PayrollPenaltyRepositoryImpl(client, activeCompanyId ?? '');
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

/// Провайдер получения штрафов с учетом фильтров.
///
/// Если поиск пустой — грузит за выбранный месяц.
/// Если поиск не пустой — грузит за все время для фильтрации по ФИО.
final penaltiesByFilterProvider = FutureProvider<List<PayrollPenaltyModel>>((ref) async {
  final client = ref.watch(supabaseClientProvider);
  final filterState = ref.watch(payrollFilterProvider);
  final searchQuery = ref.watch(payrollSearchQueryProvider);
  final activeCompanyId = ref.watch(activeCompanyIdProvider);

  if (activeCompanyId == null) return [];

  var query = client.from('payroll_penalty').select().eq('company_id', activeCompanyId);

  // 1. Фильтрация по периоду или поиску
  if (searchQuery.trim().isEmpty) {
    // Если поиск пустой — грузим за выбранный месяц
    final startDate =
        DateTime(filterState.selectedYear, filterState.selectedMonth, 1);
    final endDate =
        DateTime(filterState.selectedYear, filterState.selectedMonth + 1, 0);
    
    query = query
        .gte('date', startDate.toIso8601String())
        .lte('date', endDate.toIso8601String());
  } else {
    // Если поиск не пустой — грузим за все время, но только для подходящих сотрудников
    final queryText = searchQuery.trim().toLowerCase();
    final matchingEmployeeIds = ref.read(employeeProvider).employees
        .where((e) {
          final fullName = '${e.lastName} ${e.firstName} ${e.middleName ?? ''}'
              .toLowerCase();
          return fullName.contains(queryText);
        })
        .map((e) => e.id)
        .toList();

    if (matchingEmployeeIds.isEmpty) return [];
    
    query = query.inFilter('employee_id', matchingEmployeeIds);
  }

  // 2. Фильтрация по объектам
  if (filterState.selectedObjectIds.isNotEmpty) {
    // Штрафы могут быть не привязаны к объекту (object_id IS NULL)
    final objectIdsStr = filterState.selectedObjectIds.map((id) => '"$id"').join(',');
    query = query.or('object_id.in.($objectIdsStr),object_id.is.null');
  }

  final response = await query.order('date', ascending: false);
  
  return (response as List)
      .map((json) => PayrollPenaltyModel.fromJson(json as Map<String, dynamic>))
      .toList();
});

/// Провайдер всех штрафов с опциональной фильтрацией.
final filteredPenaltiesProvider = Provider<List<PayrollPenaltyModel>>((ref) {
  final penaltiesAsync = ref.watch(penaltiesByFilterProvider);
  final employeeState = ref.watch(employeeProvider);
  final employees = employeeState.employees;
  final searchQuery = ref.watch(payrollSearchQueryProvider);

  return penaltiesAsync.maybeWhen(
    data: (allPenalties) {
      // Если есть поиск по ФИО, фильтруем на клиенте
      var result = allPenalties;
      if (searchQuery.trim().isNotEmpty) {
        final query = searchQuery.trim().toLowerCase();
        result = result.where((penalty) {
          final emp = employees.firstWhereOrNull((e) => e.id == penalty.employeeId);
          if (emp == null) return false;
          final fullName = '${emp.lastName} ${emp.firstName} ${emp.middleName ?? ''}'
              .toLowerCase();
          return fullName.contains(query);
        }).toList();
      }

      // Сортируем по алфавиту (ФИО сотрудников)
      result.sort((a, b) {
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

      return result;
    },
    orElse: () => [],
  );
});
