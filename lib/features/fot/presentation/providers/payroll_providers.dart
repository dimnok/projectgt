import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/payroll_calculation.dart';
import 'package:projectgt/core/di/providers.dart';
import 'package:collection/collection.dart';
import 'package:projectgt/features/fot/presentation/providers/penalty_providers.dart';
import 'package:projectgt/features/fot/presentation/providers/bonus_providers.dart';
import 'package:projectgt/features/fot/data/models/payroll_payout_model.dart';
import '../../domain/repositories/payroll_payout_repository.dart';
import '../../data/repositories/payroll_payout_repository_impl.dart';
import 'package:projectgt/presentation/state/employee_state.dart';
import 'payroll_filter_providers.dart';

/// Провайдер для независимой загрузки данных work_hours и employee_attendance за выбранный месяц.
///
/// Загружает данные из work_hours (смены) и employee_attendance (ручной ввод) напрямую из Supabase
/// за выбранный период из фильтров, не зависит от модуля табеля.
final payrollWorkHoursProvider = FutureProvider<List<dynamic>>((ref) async {
  final filterState = ref.watch(payrollFilterProvider);
  final startDate =
      DateTime(filterState.selectedYear, filterState.selectedMonth, 1);
  final endDate =
      DateTime(filterState.selectedYear, filterState.selectedMonth + 1, 0);

  try {
    final client = ref.watch(supabaseClientProvider);

    // 1️⃣ Загружаем часы из смен (work_hours)
    // ⚠️ ВАЖНО: Учитываем только закрытые смены (status = 'closed')
    final workHoursResponse = await client.from('work_hours').select('''
          id,
          work_id,
          employee_id,
          hours,
          works!inner(
            date,
            object_id,
            status
          )
        ''').eq('works.status', 'closed');

    // 2️⃣ Загружаем часы из ручного ввода (employee_attendance)
    final attendanceResponse = await client
        .from('employee_attendance')
        .select('id, employee_id, object_id, date, hours')
        .gte('date', startDate.toIso8601String())
        .lte('date', endDate.toIso8601String());

    // 3️⃣ Преобразуем work_hours в WorkHourEntry и фильтруем по датам
    final workHoursEntries = workHoursResponse
        .map<dynamic>((record) {
          final works = record['works'] as Map<String, dynamic>?;

          if (works == null ||
              record['employee_id'] == null ||
              record['hours'] == null ||
              works['date'] == null) {
            return null; // Пропускаем неполные записи
          }

          final workDate = DateTime.parse(works['date']);
          // Фильтруем по текущему месяцу
          if (workDate.isBefore(startDate) || workDate.isAfter(endDate)) {
            return null;
          }

          return WorkHourEntry(
            id: record['id'],
            workId: record['work_id'],
            employeeId: record['employee_id'],
            hours: record['hours'],
            date: workDate,
            objectId: works['object_id'] ?? '',
            employeePosition: null,
          );
        })
        .where((entry) => entry != null)
        .toList();

    // 4️⃣ Преобразуем employee_attendance в WorkHourEntry
    final attendanceEntries = attendanceResponse
        .map<dynamic>((record) {
          if (record['employee_id'] == null ||
              record['hours'] == null ||
              record['date'] == null) {
            return null;
          }

          return WorkHourEntry(
            id: record['id'],
            workId: '', // Нет work_id для ручного ввода
            employeeId: record['employee_id'],
            hours: record['hours'],
            date: DateTime.parse(record['date']),
            objectId: record['object_id'] ?? '',
            employeePosition: null,
          );
        })
        .where((entry) => entry != null)
        .toList();

    // 5️⃣ Объединяем данные из обеих таблиц
    return [...workHoursEntries, ...attendanceEntries];
  } catch (e) {
    return [];
  }
});

/// Временная модель для представления записи о рабочих часах сотрудника в рамках смены.
/// Используется для совместимости с существующим кодом и агрегации данных из Supabase.
class WorkHourEntry {
  /// Уникальный идентификатор записи work_hours (UUID).
  final String id;

  /// Идентификатор смены (work_id), к которой относится запись (UUID).
  final String workId;

  /// Идентификатор сотрудника (employee_id), для которого зафиксированы часы (UUID).
  final String employeeId;

  /// Количество отработанных часов по данной записи.
  final num hours;

  /// Дата смены, к которой относится запись (поле works.date).
  final DateTime date;

  /// Идентификатор объекта (object_id), на котором велась работа (UUID).
  final String objectId;

  /// Должность сотрудника на момент смены (опционально, может быть null).
  final String? employeePosition;

  /// Конструктор WorkHourEntry.
  ///
  /// [id] — уникальный идентификатор записи work_hours.
  /// [workId] — идентификатор смены.
  /// [employeeId] — идентификатор сотрудника.
  /// [hours] — количество отработанных часов.
  /// [date] — дата смены.
  /// [objectId] — идентификатор объекта.
  /// [employeePosition] — должность сотрудника (опционально).
  WorkHourEntry({
    required this.id,
    required this.workId,
    required this.employeeId,
    required this.hours,
    required this.date,
    required this.objectId,
    this.employeePosition,
  });
}

/// Провайдер, отслеживающий загрузку данных, необходимых для корректного отображения ФОТ.
///
/// Возвращает true, когда все данные загружены и готовы к отображению.
final payrollDataReadyProvider = Provider<bool>((ref) {
  // Проверяем состояние данных work_hours для ФОТ
  final workHoursState = ref.watch(payrollWorkHoursProvider);

  // Проверяем, загружены ли employees
  final employeeState = ref.watch(employeeProvider);

  // Проверяем, загружены ли все необходимые данные
  final workHoursLoaded = !workHoursState.isLoading && workHoursState.hasValue;
  final employeesLoaded = employeeState.employees.isNotEmpty;

  // Готовность данных для отображения
  return workHoursLoaded && employeesLoaded;
});

/// Провайдер расчетов ФОТ за выбранный месяц.
///
/// HYBRID ПОДХОД: Использует PostgreSQL функцию для батч-расчёта.
/// При ошибке откатывается на клиентский расчёт (fallback).
final filteredPayrollsProvider =
    FutureProvider<List<PayrollCalculation>>((ref) async {
  final filterState = ref.watch(payrollFilterProvider);
  final year = filterState.selectedYear;
  final month = filterState.selectedMonth;

  try {
    // 🚀 ОПТИМИЗАЦИЯ: Используем PostgreSQL функцию для батч-расчёта
    final client = ref.watch(supabaseClientProvider);
    final response = await client.rpc('calculate_payroll_for_month', params: {
      'p_year': year,
      'p_month': month,
    });

    // Маппинг данных из БД в PayrollCalculation
    final List<PayrollCalculation> payrolls = [];
    for (final row in response) {
      payrolls.add(PayrollCalculation(
        employeeId: row['employee_id'] as String,
        periodMonth: DateTime(year, month, 1),
        hoursWorked: (row['total_hours'] as num).toDouble(),
        hourlyRate: (row['current_hourly_rate'] as num).toDouble(),
        baseSalary: (row['base_salary'] as num).toDouble(),
        bonusesTotal: (row['bonuses_total'] as num).toDouble(),
        penaltiesTotal: (row['penalties_total'] as num).toDouble(),
        businessTripTotal: (row['business_trip_total'] as num).toDouble(),
        netSalary: (row['net_salary'] as num).toDouble(),
      ));
    }

    return payrolls;
  } catch (e) {
    // 🔄 FALLBACK: Если RPC не работает — используем старую логику
    return _calculatePayrollClientSide(ref, year, month);
  }
});

/// Fallback-функция: клиентский расчёт ФОТ (старая логика).
///
/// Используется только если PostgreSQL функция недоступна.
Future<List<PayrollCalculation>> _calculatePayrollClientSide(
  Ref ref,
  int year,
  int month,
) async {
  // Получаем данные напрямую без watch для избежания циклических зависимостей
  final workHoursAsync = ref.watch(payrollWorkHoursProvider);
  final employeeState = ref.watch(employeeProvider);

  // Проверяем готовность данных
  if (!workHoursAsync.hasValue || employeeState.employees.isEmpty) {
    return [];
  }

  try {
    // Используем независимые данные work_hours
    final workHours = workHoursAsync.value!;

    // Группируем по сотруднику
    final Map<String, List<dynamic>> employeeEntries = {};
    for (final entry in workHours) {
      employeeEntries.putIfAbsent(entry.employeeId, () => []).add(entry);
    }

    final filteredEmployeeIds = employeeEntries.keys.toList();

    // Получаем все штрафы и премии за период
    final penaltiesAsyncRaw = await ref.watch(allPenaltiesProvider.future);
    final bonusesAsyncRaw = await ref.watch(allBonusesProvider.future);
    final penaltiesAsync = penaltiesAsyncRaw;
    final bonusesAsync = bonusesAsyncRaw;

    // Формируем PayrollCalculation для каждого сотрудника
    final List<PayrollCalculation> payrolls = [];

    // Получаем use case для получения ставок
    final getRateUseCase = ref.read(getEmployeeRateForDateUseCaseProvider);

    for (final employeeId in filteredEmployeeIds) {
      final entries = employeeEntries[employeeId]!;
      double hours = 0;
      double baseSalary = 0;

      // Рассчитываем базовую зарплату с учётом исторических ставок
      for (final entry in entries) {
        if (entry.hours != null) {
          final entryHours =
              (entry.hours is num) ? entry.hours.toDouble() : 0.0;
          hours += entryHours;

          // Получаем ставку на дату конкретной смены
          final rateForDate = await getRateUseCase(employeeId, entry.date);
          baseSalary += entryHours * rateForDate;
        }
      }

      // Получаем ставки суточных для каждого объекта и даты смены
      // с учётом индивидуальных ставок и минимального количества часов
      double businessTripTotal = 0;
      final tripRateDataSource = ref.read(businessTripRateDataSourceProvider);

      for (final entry in entries) {
        final objectId = entry.objectId;
        if (objectId != null && objectId.isNotEmpty) {
          try {
            // Используем новый метод с учётом employee_id и hours
            final rate =
                await tripRateDataSource.getActiveRateForEmployeeAndDate(
              employeeId,
              objectId,
              entry.date,
              entry.hours,
            );
            if (rate != null) {
              businessTripTotal += rate.rate;
            }
          } catch (e) {
            // Игнорируем ошибки получения ставок
          }
        }
      }

      // Получаем текущую ставку из employee_rates
      final currentRateAsync = await ref
          .read(employeeRateDataSourceProvider)
          .getCurrentRate(employeeId);
      final currentHourlyRate = currentRateAsync?.hourlyRate ?? 0.0;

      // Расчёт штрафов из базы
      final penaltiesTotal = (penaltiesAsync)
          .where((p) =>
              p.employeeId == employeeId &&
              p.date != null &&
              p.date!.year == year &&
              p.date!.month == month)
          .fold<double>(0, (sum, p) => sum + p.amount);

      // Расчёт премий из базы
      final bonusesTotal = (bonusesAsync)
          .where((b) =>
              b.employeeId == employeeId &&
              ((b.date != null &&
                      b.date!.year == year &&
                      b.date!.month == month) ||
                  (b.date == null &&
                      b.createdAt != null &&
                      b.createdAt!.year == year &&
                      b.createdAt!.month == month)))
          .fold<double>(0, (sum, b) => sum + b.amount);

      final grossSalary =
          baseSalary + bonusesTotal + businessTripTotal - penaltiesTotal;
      final netSalary = grossSalary;

      final calculation = PayrollCalculation(
        employeeId: employeeId,
        periodMonth: DateTime(year, month, 1),
        hoursWorked: hours,
        hourlyRate: currentHourlyRate,
        baseSalary: baseSalary,
        bonusesTotal: bonusesTotal,
        penaltiesTotal: penaltiesTotal,
        businessTripTotal: businessTripTotal,
        netSalary: netSalary,
      );

      payrolls.add(calculation);
    }

    // Сортировка по алфавиту
    final employeeState = ref.watch(employeeProvider);
    final employees = employeeState.employees;

    payrolls.sort((a, b) {
      final empA = employees.firstWhereOrNull((e) => e.id == a.employeeId);
      final empB = employees.firstWhereOrNull((e) => e.id == b.employeeId);
      final nameA = empA != null
          ? ('${empA.lastName} ${empA.firstName} ${empA.middleName ?? ''}')
              .trim()
              .toLowerCase()
          : '';
      final nameB = empB != null
          ? ('${empB.lastName} ${empB.firstName} ${empB.middleName ?? ''}')
              .trim()
              .toLowerCase()
          : '';
      return nameA.compareTo(nameB);
    });

    return payrolls;
  } catch (e) {
    return [];
  }
}

/// Провайдер получения выплат за выбранный месяц.
final payrollPayoutsByMonthProvider =
    FutureProvider<List<PayrollPayoutModel>>((ref) async {
  final client = ref.watch(supabaseClientProvider);
  final filterState = ref.watch(payrollFilterProvider);
  final startDate =
      DateTime(filterState.selectedYear, filterState.selectedMonth, 1);
  final endDate =
      DateTime(filterState.selectedYear, filterState.selectedMonth + 1, 0);

  final response = await client
      .from('payroll_payout')
      .select()
      .gte('payout_date', startDate.toIso8601String())
      .lte('payout_date', endDate.toIso8601String());

  return (response as List)
      .map((json) => PayrollPayoutModel.fromJson(json as Map<String, dynamic>))
      .toList();
});

/// Провайдер репозитория выплат по ФОТ (Supabase).
final payrollPayoutRepositoryProvider =
    Provider<PayrollPayoutRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return PayrollPayoutRepositoryImpl(client);
});

/// Провайдер функции создания выплаты.
///
/// Используется для создания новых выплат через репозиторий.
/// @returns Future<PayrollPayoutModel> Function(PayrollPayoutModel) — функция создания выплаты.
final createPayoutUseCaseProvider =
    Provider<Future<PayrollPayoutModel> Function(PayrollPayoutModel)>((ref) {
  final repo = ref.watch(payrollPayoutRepositoryProvider);
  return (PayrollPayoutModel payout) async {
    return await repo.createPayout(payout);
  };
});

/// Провайдер функции обновления выплаты.
///
/// Используется для обновления существующих выплат через репозиторий.
/// @returns Future<PayrollPayoutModel> Function(PayrollPayoutModel) — функция обновления выплаты.
final updatePayoutUseCaseProvider =
    Provider<Future<PayrollPayoutModel> Function(PayrollPayoutModel)>((ref) {
  final repo = ref.watch(payrollPayoutRepositoryProvider);
  return (PayrollPayoutModel payout) async {
    return await repo.updatePayout(payout);
  };
});

/// Провайдер функции удаления выплаты по ID.
///
/// Используется для удаления выплат через репозиторий.
/// @returns Future<void> Function(String) — функция удаления выплаты по ID.
final deletePayoutUseCaseProvider =
    Provider<Future<void> Function(String)>((ref) {
  final repo = ref.watch(payrollPayoutRepositoryProvider);
  return (String id) async {
    await repo.deletePayout(id);
  };
});

/// Провайдер всех выплат за текущий месяц с сортировкой.
final filteredPayrollPayoutsProvider =
    FutureProvider<List<PayrollPayoutModel>>((ref) async {
  try {
    final payouts = await ref.watch(payrollPayoutsByMonthProvider.future);

    // Получаем данные о сотрудниках для сортировки
    final employeeState = ref.watch(employeeProvider);
    final employees = employeeState.employees;

    // Создаем копию списка для сортировки
    final sortedPayouts = List<PayrollPayoutModel>.from(payouts);

    // Сортируем по алфавиту (ФИО сотрудников)
    sortedPayouts.sort((a, b) {
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

    // Дополнительная сортировка по дате выплаты (самые новые сверху)
    sortedPayouts.sort((a, b) => b.payoutDate.compareTo(a.payoutDate));

    return sortedPayouts;
  } catch (e) {
    return [];
  }
});
