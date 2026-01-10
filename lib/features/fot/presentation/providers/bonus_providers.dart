import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/payroll_bonus_model.dart';
import '../../domain/repositories/payroll_bonus_repository.dart';
import '../../data/repositories/payroll_bonus_repository_impl.dart';
import 'package:projectgt/features/company/presentation/providers/company_providers.dart';
import 'package:projectgt/core/di/providers.dart';
import 'package:collection/collection.dart';
import 'package:projectgt/presentation/state/employee_state.dart';
import 'payroll_filter_providers.dart';

/// Провайдер репозитория премий (реализация внедряется выше).
///
/// Используется для доступа к CRUD-операциям с премиями через Supabase.
/// @returns PayrollBonusRepository — репозиторий премий.
final payrollBonusRepositoryProvider = Provider<PayrollBonusRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  final activeCompanyId = ref.watch(activeCompanyIdProvider);
  return PayrollBonusRepositoryImpl(client, activeCompanyId ?? '');
});

/// Провайдер получения премий с учетом фильтров.
///
/// Если поиск пустой — грузит за выбранный месяц.
/// Если поиск не пустой — грузит за все время для фильтрации по ФИО.
final bonusesByFilterProvider = FutureProvider<List<PayrollBonusModel>>((ref) async {
  final client = ref.watch(supabaseClientProvider);
  final filterState = ref.watch(payrollFilterProvider);
  final searchQuery = ref.watch(payrollSearchQueryProvider);
  final activeCompanyId = ref.watch(activeCompanyIdProvider);

  if (activeCompanyId == null) return [];

  var query = client.from('payroll_bonus').select().eq('company_id', activeCompanyId);

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
    // Премии могут быть не привязаны к объекту (object_id IS NULL)
    // В Supabase OR фильтр пишется так:
    final objectIdsStr = filterState.selectedObjectIds.map((id) => '"$id"').join(',');
    query = query.or('object_id.in.($objectIdsStr),object_id.is.null');
  }

  final response = await query.order('date', ascending: false);
  
  return (response as List)
      .map((json) => PayrollBonusModel.fromJson(json as Map<String, dynamic>))
      .toList();
});

/// Провайдер всех премий с опциональной фильтрацией.
final filteredBonusesProvider = Provider<List<PayrollBonusModel>>((ref) {
  final bonusesAsync = ref.watch(bonusesByFilterProvider);
  final employeeState = ref.watch(employeeProvider);
  final employees = employeeState.employees;
  final searchQuery = ref.watch(payrollSearchQueryProvider);

  return bonusesAsync.maybeWhen(
    data: (allBonuses) {
      // Если есть поиск по ФИО, фильтруем на клиенте
      var result = allBonuses;
      if (searchQuery.trim().isNotEmpty) {
        final query = searchQuery.trim().toLowerCase();
        result = result.where((bonus) {
          final emp = employees.firstWhereOrNull((e) => e.id == bonus.employeeId);
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

/// Провайдер usecase для создания премии.
///
/// @returns Future<void> Function(PayrollBonusModel) — функция создания премии.
final createBonusUseCaseProvider =
    Provider<Future<void> Function(PayrollBonusModel)>((ref) {
  final repo = ref.watch(payrollBonusRepositoryProvider);
  return (PayrollBonusModel bonus) async {
    await repo.createBonus(bonus);
  };
});

/// Провайдер usecase для обновления премии.
///
/// @returns Future<void> Function(PayrollBonusModel) — функция обновления премии.
final updateBonusUseCaseProvider =
    Provider<Future<void> Function(PayrollBonusModel)>((ref) {
  final repo = ref.watch(payrollBonusRepositoryProvider);
  return (PayrollBonusModel bonus) async {
    await repo.updateBonus(bonus);
  };
});

/// Провайдер usecase для удаления премии по id.
///
/// @returns Future<void> Function(String) — функция удаления премии по id.
final deleteBonusUseCaseProvider =
    Provider<Future<void> Function(String)>((ref) {
  final repo = ref.watch(payrollBonusRepositoryProvider);
  return (String id) async {
    await repo.deleteBonus(id);
  };
});
