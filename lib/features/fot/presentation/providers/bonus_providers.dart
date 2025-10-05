import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/payroll_bonus_model.dart';
import '../../domain/repositories/payroll_bonus_repository.dart';
import '../../data/repositories/payroll_bonus_repository_impl.dart';
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

/// Провайдер всех премий с опциональной фильтрацией.
///
/// По умолчанию показывает ВСЕ премии.
/// Если в фильтрах выбран период (не текущий месяц) - фильтрует по периоду.
/// Используется для отображения премий в таблице премий.
/// @returns List<PayrollBonusModel> — премии (все или отфильтрованные).
final filteredBonusesProvider = Provider<List<PayrollBonusModel>>((ref) {
  final bonusesAsync = ref.watch(allBonusesProvider);
  final employeeState = ref.watch(employeeProvider);
  final employees = employeeState.employees;
  final filterState = ref.watch(payrollFilterProvider);

  // Проверяем, изменен ли период от текущего месяца
  final now = DateTime.now();
  final isPeriodFiltered = filterState.selectedYear != now.year ||
      filterState.selectedMonth != now.month;

  return bonusesAsync.maybeWhen(
    data: (allBonuses) {
      // Применяем фильтр по периоду только если выбран НЕ текущий месяц
      final filteredBonuses = isPeriodFiltered
          ? allBonuses.where((bonus) {
              // Используем bonus.date (дата премии), fallback на createdAt если date == null
              final date = bonus.date ?? bonus.createdAt;
              return date != null &&
                  date.year == filterState.selectedYear &&
                  date.month == filterState.selectedMonth;
            }).toList()
          : allBonuses; // Показываем ВСЕ премии если фильтр не применен

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
