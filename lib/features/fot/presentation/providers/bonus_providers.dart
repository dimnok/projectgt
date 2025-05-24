import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/payroll_bonus_model.dart';
import '../../data/repositories/payroll_bonus_repository.dart';
import '../../data/repositories/payroll_bonus_repository_impl.dart';
import 'payroll_filter_provider.dart';
import 'package:projectgt/core/di/providers.dart';
import '../../domain/usecases/get_bonuses_by_payroll_id_usecase.dart';

/// Провайдер репозитория премий (реализация внедряется выше).
///
/// Используется для доступа к CRUD-операциям с премиями через Supabase.
/// @returns PayrollBonusRepository — репозиторий премий.
final payrollBonusRepositoryProvider = Provider<PayrollBonusRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return PayrollBonusRepositoryImpl(client);
});

/// Провайдер usecase для получения премий по payrollId.
///
/// Инкапсулирует бизнес-логику получения премий по расчёту ФОТ.
/// @returns GetBonusesByPayrollIdUseCase — usecase получения премий по payrollId.
final getBonusesByPayrollIdUseCaseProvider = Provider<GetBonusesByPayrollIdUseCase>((ref) {
  return GetBonusesByPayrollIdUseCase(ref.watch(payrollBonusRepositoryProvider));
});

/// Провайдер получения списка премий по payrollId.
///
/// @param payrollId — идентификатор расчёта ФОТ
/// @returns FutureProvider<List<PayrollBonusModel>> — список премий по payrollId.
final bonusesByPayrollIdProvider = FutureProvider.family<List<PayrollBonusModel>, String>((ref, payrollId) async {
  final useCase = ref.watch(getBonusesByPayrollIdUseCaseProvider);
  return useCase(payrollId);
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
      return allBonuses.where((bonus) {
        // Фильтр по дате
        final date = bonus.createdAt;
        final inMonth = date != null &&
          date.year == filter.year &&
          date.month == filter.month;
        // Фильтр по сотруднику
        final byEmployee = filter.employeeIds.isEmpty ||
          (bonus.payrollId != null && filter.employeeIds.contains(bonus.payrollId));
        // TODO: добавить фильтр по объекту и должности, если структура позволяет
        return inMonth && byEmployee;
      }).toList();
    },
    orElse: () => [],
  );
});

/// Провайдер usecase для создания премии.
///
/// @returns Future<void> Function(PayrollBonusModel) — функция создания премии.
final createBonusUseCaseProvider = Provider<Future<void> Function(PayrollBonusModel)>((ref) {
  final repo = ref.watch(payrollBonusRepositoryProvider);
  return (PayrollBonusModel bonus) async {
    await repo.createBonus(bonus);
  };
});

/// Провайдер usecase для обновления премии.
///
/// @returns Future<void> Function(PayrollBonusModel) — функция обновления премии.
final updateBonusUseCaseProvider = Provider<Future<void> Function(PayrollBonusModel)>((ref) {
  final repo = ref.watch(payrollBonusRepositoryProvider);
  return (PayrollBonusModel bonus) async {
    await repo.updateBonus(bonus);
  };
});

/// Провайдер usecase для удаления премии по id.
///
/// @returns Future<void> Function(String) — функция удаления премии по id.
final deleteBonusUseCaseProvider = Provider<Future<void> Function(String)>((ref) {
  final repo = ref.watch(payrollBonusRepositoryProvider);
  return (String id) async {
    await repo.deleteBonus(id);
  };
});

// TODO: Добавить провайдеры для создания, обновления, удаления премий после реализации соответствующих usecase-ов. 