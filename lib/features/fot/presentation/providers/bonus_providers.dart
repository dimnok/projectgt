import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/payroll_bonus_model.dart';
import '../../data/repositories/payroll_bonus_repository.dart';
import '../../data/repositories/payroll_bonus_repository_impl.dart';
import 'payroll_filter_provider.dart';
import 'package:projectgt/core/di/providers.dart';
import 'package:collection/collection.dart';

/// Провайдер репозитория премий (реализация внедряется выше).
///
/// Используется для доступа к CRUD-операциям с премиями через Supabase.
/// @returns PayrollBonusRepository — репозиторий премий.
final payrollBonusRepositoryProvider = Provider<PayrollBonusRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return PayrollBonusRepositoryImpl(client);
});

/// Провайдер получения всех премий из базы.
///
/// Используется для отображения всех премий без фильтрации по payrollId.
/// @returns FutureProvider<List<PayrollBonusModel>> — все премии.
final allBonusesProvider = FutureProvider<List<PayrollBonusModel>>((ref) async {
  final repo = ref.watch(payrollBonusRepositoryProvider);
  // Получаем все премии из базы
  return await repo.getAllBonuses();
});

/// Провайдер отфильтрованных премий по выбранному периоду и сотрудникам.
///
/// Фильтрует премии по дате, сотруднику, объекту и должности (если реализовано).
/// Используется для отображения премий в таблице премий.
/// @returns List<PayrollBonusModel> — отфильтрованные премии.
final filteredBonusesProvider = Provider<List<PayrollBonusModel>>((ref) {
  final bonusesAsync = ref.watch(allBonusesProvider);
  final filter = ref.watch(payrollFilterProvider);
  final employees = filter.employees;
  return bonusesAsync.maybeWhen(
    data: (allBonuses) {
      final filteredBonuses = allBonuses.where((bonus) {
        // Фильтр по дате
        final date = bonus.createdAt;
        final inMonth = date != null &&
            date.year == filter.year &&
            date.month == filter.month;
        // Фильтр по сотруднику
        final byEmployee = filter.employeeIds.isEmpty ||
            (bonus.employeeId.isNotEmpty &&
                filter.employeeIds.contains(bonus.employeeId));
        // Фильтр по объекту
        final byObject = filter.objectIds.isEmpty ||
            (bonus.objectId != null &&
                filter.objectIds.contains(bonus.objectId));
        // Фильтр по должности
        final byPosition = filter.positionNames.isEmpty ||
            (() {
              final emp =
                  employees.firstWhereOrNull((e) => e.id == bonus.employeeId);
              return emp != null && filter.positionNames.contains(emp.position);
            })();
        return inMonth && byEmployee && byObject && byPosition;
      }).toList();

      // Сортируем по алфавиту (ФИО сотрудников)
      filteredBonuses.sort((a, b) {
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

      return filteredBonuses;
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
