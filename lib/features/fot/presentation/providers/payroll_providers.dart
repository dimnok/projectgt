import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/payroll_calculation.dart';
import '../../domain/repositories/payroll_repository.dart';
import '../../data/repositories/payroll_repository_impl.dart';
import 'package:projectgt/core/di/providers.dart';
import '../../domain/usecases/get_payrolls_by_month_usecase.dart';
import 'payroll_filter_provider.dart';
import 'package:projectgt/features/timesheet/presentation/providers/timesheet_provider.dart';
import 'package:collection/collection.dart';

/// Провайдер репозитория расчётов ФОТ.
final payrollRepositoryProvider = Provider<PayrollRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return PayrollRepositoryImpl(client);
});

/// Провайдер usecase получения расчётов по месяцу.
final getPayrollsByMonthUseCaseProvider = Provider<GetPayrollsByMonthUseCase>((ref) {
  return GetPayrollsByMonthUseCase(ref.watch(payrollRepositoryProvider));
});

/// Провайдер получения списка расчётов по месяцу (DateTime — первый день месяца).
final payrollsByMonthProvider = FutureProvider.family<List<PayrollCalculation>, DateTime>((ref, month) async {
  final useCase = ref.watch(getPayrollsByMonthUseCaseProvider);
  return useCase(month);
});

/// Провайдер, отслеживающий загрузку данных, необходимых для корректного отображения ФОТ.
/// 
/// Возвращает true, когда все данные загружены и готовы к отображению.
/// Используется для предотвращения мигания UI при множественной загрузке зависимостей.
final payrollDataReadyProvider = Provider<bool>((ref) {
  // Получаем состояние табеля - проверяем, есть ли в нем данные
  final timesheetState = ref.watch(timesheetProvider);
  
  // Получаем состояние фильтров - проверяем, загружены ли employees и objects
  final filterState = ref.watch(payrollFilterProvider);
  
  // Проверяем, загружены ли все необходимые данные
  final timesheetLoaded = !timesheetState.isLoading && timesheetState.entries.isNotEmpty;
  final employeesLoaded = filterState.employees.isNotEmpty;
  final objectsLoaded = filterState.objects.isNotEmpty;
  
  // Готовность данных для отображения
  return timesheetLoaded && employeesLoaded && objectsLoaded;
});

/// Провайдер отфильтрованных расчетов ФОТ с защитой от множественного обновления.
/// 
/// Использует кеширование для предотвращения повторных расчетов при незначительных изменениях.
final filteredPayrollsProvider = FutureProvider<List<PayrollCalculation>>((ref) async {
  // Проверяем готовность данных перед запуском тяжелых вычислений
  final isDataReady = ref.watch(payrollDataReadyProvider);
  if (!isDataReady) {
    return [];
  }
  try {
    final filterState = ref.watch(payrollFilterProvider);
    final year = filterState.year;
    final month = filterState.month;
    final employeeIds = filterState.employeeIds;
    final positionNames = filterState.positionNames;
    final objectIds = filterState.objectIds;
    final startDate = filterState.startDate;
    final endDate = filterState.endDate;
    final timesheetEntries = ref.watch(timesheetProvider.select((s) => s.entries));

    // --- Новый этап: агрегация смен только по выбранным объектам ---
    // 1. Фильтруем смены по периоду и выбранным объектам
    final filteredEntries = timesheetEntries.where((entry) {
      final entryDate = entry.date;
      final inPeriod = entryDate.isAfter(startDate.subtract(const Duration(days: 1))) &&
          entryDate.isBefore(endDate.add(const Duration(days: 1)));
      final byObject = objectIds.isEmpty || objectIds.contains(entry.objectId);
      return inPeriod && byObject;
    }).toList();

    // 2. Группируем по сотруднику
    final Map<String, List<dynamic>> employeeEntries = {};
    for (final entry in filteredEntries) {
      employeeEntries.putIfAbsent(entry.employeeId, () => []).add(entry);
    }

    // 3. Получаем список сотрудников для фильтра
    List<String> filteredEmployeeIds = employeeEntries.keys.toList();
    if (employeeIds.isNotEmpty) {
      filteredEmployeeIds = filteredEmployeeIds.where((id) => employeeIds.contains(id)).toList();
    }

    // 4. Формируем PayrollCalculation для каждого сотрудника
    final List<PayrollCalculation> payrolls = [];
    for (final employeeId in filteredEmployeeIds) {
      final entries = employeeEntries[employeeId]!;
      double hours = 0;
      // --- Группировка смен по объекту ---
      final Map<String, int> objectShiftCount = {};
      for (final entry in entries) {
        if (entry.hours != null) {
          hours += (entry.hours is num) ? entry.hours.toDouble() : 0.0;
        }
        final objectId = entry.objectId;
        if (objectId != null && objectId.isNotEmpty) {
          objectShiftCount[objectId] = (objectShiftCount[objectId] ?? 0) + 1;
        }
      }
      // --- Получаем карту objectId -> businessTripAmount ---
      final objectTripMap = {
        for (final obj in filterState.objects)
          if (obj.businessTripAmount != null && obj.businessTripAmount > 0)
            obj.id: obj.businessTripAmount.toDouble(),
      };
      // --- Считаем командировочные ---
      double businessTripTotal = 0;
      objectShiftCount.forEach((objectId, shiftCount) {
        final tripAmount = objectTripMap[objectId] ?? 0;
        if (tripAmount > 0) {
          businessTripTotal += tripAmount * shiftCount;
        }
      });
      // Получаем ставку сотрудника (можно доработать под ваши данные)
      final employee = filterState.employees.firstWhereOrNull((e) => e.id == employeeId);
      final hourlyRate = employee?.hourlyRate ?? 0.0;
      final baseSalary = hours * hourlyRate;
      // TODO: добавить расчёт премий, штрафов и удержаний если нужно
      final grossSalary = baseSalary + businessTripTotal;
      final netSalary = grossSalary;
      final calculation = PayrollCalculation(
        employeeId: employeeId,
        periodMonth: DateTime(year, month, 1),
        hoursWorked: hours,
        hourlyRate: hourlyRate,
        baseSalary: baseSalary,
        bonusesTotal: 0,
        penaltiesTotal: 0,
        deductionsTotal: 0,
        businessTripTotal: businessTripTotal,
        grossSalary: grossSalary,
        netSalary: netSalary,
      );
      payrolls.add(calculation);
    }
    // Сортировка по ФИО (если нужно)
    payrolls.sort((a, b) {
      final empA = filterState.employees.firstWhereOrNull((e) => e.id == a.employeeId);
      final empB = filterState.employees.firstWhereOrNull((e) => e.id == b.employeeId);
      final nameA = empA != null ? ('${empA.lastName} ${empA.firstName} ${empA.middleName ?? ''}').trim().toLowerCase() : '';
      final nameB = empB != null ? ('${empB.lastName} ${empB.firstName} ${empB.middleName ?? ''}').trim().toLowerCase() : '';
      return nameA.compareTo(nameB);
    });
    return payrolls;
  } catch (e) {
    return [];
  }
}); 