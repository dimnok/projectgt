import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/payroll_calculation.dart';
import 'package:projectgt/features/company/presentation/providers/company_providers.dart';
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
  final activeCompanyId = ref.watch(activeCompanyIdProvider);
  
  if (activeCompanyId == null) return [];

  final startDate =
      DateTime(filterState.selectedYear, filterState.selectedMonth, 1);
  final endDate =
      DateTime(filterState.selectedYear, filterState.selectedMonth + 1, 0);

  try {
    final client = ref.watch(supabaseClientProvider);

    // 1️⃣ Загружаем часы из смен (work_hours)
    // ⚠️ ВАЖНО: Учитываем только закрытые смены (status = 'closed')
    // Фильтруем по датам на сервере, чтобы избежать проблемы "первой тысячи"
    final workHoursResponse = await client.from('work_hours').select('''
          id,
          work_id,
          employee_id,
          hours,
          works!inner(
            date,
            object_id,
            status,
            company_id
          )
        ''')
        .eq('works.status', 'closed')
        .eq('works.company_id', activeCompanyId)
        .gte('works.date', startDate.toIso8601String())
        .lte('works.date', endDate.toIso8601String());

    // 2️⃣ Загружаем часы из ручного ввода (employee_attendance)
    final attendanceResponse = await client
        .from('employee_attendance')
        .select('id, employee_id, object_id, date, hours')
        .eq('company_id', activeCompanyId)
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
  final activeCompanyId = ref.watch(activeCompanyIdProvider);
  
  if (activeCompanyId == null) return [];

  final year = filterState.selectedYear;
  final month = filterState.selectedMonth;

  try {
    // 🚀 ОПТИМИЗАЦИЯ: Используем PostgreSQL функцию для батч-расчёта
    final client = ref.watch(supabaseClientProvider);
    
    // Передаем список объектов для фильтрации на уровне БД
    final objectIds = filterState.selectedObjectIds.isNotEmpty 
        ? filterState.selectedObjectIds 
        : null;

    final response = await client.rpc('calculate_payroll_for_month', params: {
      'p_year': year,
      'p_month': month,
      'p_object_ids': objectIds,
      'p_company_id': activeCompanyId,
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
/// Согласована с Supabase RPC `calculate_payroll_for_month`: включает сотрудников с премиями, штрафами
/// или **выплатами** за выбранный месяц даже без часов (фильтры — из `payrollFilterProvider` / связанных провайдеров).
Future<List<PayrollCalculation>> _calculatePayrollClientSide(
  Ref ref,
  int year,
  int month,
) async {
  final workHoursAsync = ref.watch(payrollWorkHoursProvider);
  final employeeState = ref.watch(employeeProvider);

  if (employeeState.employees.isEmpty) return [];
  if (!workHoursAsync.hasValue) return [];

  try {
    final workHours = workHoursAsync.value!;

    final Map<String, List<dynamic>> employeeEntries = {};
    for (final entry in workHours) {
      employeeEntries.putIfAbsent(entry.employeeId, () => []).add(entry);
    }

    final penaltiesAsyncRaw = await ref.watch(penaltiesByFilterProvider.future);
    final bonusesAsyncRaw = await ref.watch(bonusesByFilterProvider.future);
    final payoutsAsyncRaw = await ref.watch(payrollPayoutsByFilterProvider.future);
    final penaltiesAsync = penaltiesAsyncRaw;
    final bonusesAsync = bonusesAsyncRaw;
    final payoutsAsync = payoutsAsyncRaw;

    final companyEmployeeIds =
        employeeState.employees.map((e) => e.id).toSet();
    final employeeIds = <String>{
      ...employeeEntries.keys,
      for (final b in bonusesAsync)
        if (companyEmployeeIds.contains(b.employeeId)) b.employeeId,
      for (final p in penaltiesAsync)
        if (companyEmployeeIds.contains(p.employeeId)) p.employeeId,
      for (final po in payoutsAsync)
        if (companyEmployeeIds.contains(po.employeeId)) po.employeeId,
    };

    final filteredEmployeeIds = employeeIds.toList();

    final List<PayrollCalculation> payrolls = [];

    final getRateUseCase = ref.read(getEmployeeRateForDateUseCaseProvider);

    for (final employeeId in filteredEmployeeIds) {
      final entries = employeeEntries[employeeId] ?? [];
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

    payrolls.sort((a, b) {
      final empA =
          employeeState.employees.firstWhereOrNull((e) => e.id == a.employeeId);
      final empB =
          employeeState.employees.firstWhereOrNull((e) => e.id == b.employeeId);
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

/// Провайдер получения выплат с учетом фильтров.
///
/// Если поиск пустой — грузит за выбранный месяц.
/// Если поиск не пустой — грузит за все время.
final payrollPayoutsByFilterProvider =
    FutureProvider<List<PayrollPayoutModel>>((ref) async {
  final client = ref.watch(supabaseClientProvider);
  final filterState = ref.watch(payrollFilterProvider);
  final searchQuery = ref.watch(payrollSearchQueryProvider);
  final activeCompanyId = ref.watch(activeCompanyIdProvider);

  if (activeCompanyId == null) return [];

  var query = client.from('payroll_payout').select().eq('company_id', activeCompanyId);

  // 1. Фильтрация по периоду или поиску
  if (searchQuery.trim().isEmpty) {
    // Если поиск пустой — грузим за выбранный месяц
    final startDate =
        DateTime(filterState.selectedYear, filterState.selectedMonth, 1);
    final endDate =
        DateTime(filterState.selectedYear, filterState.selectedMonth + 1, 0);
    
    query = query
        .gte('payout_date', startDate.toIso8601String())
        .lte('payout_date', endDate.toIso8601String());
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

  final response = await query.order('payout_date', ascending: false);

  return (response as List)
      .map((json) => PayrollPayoutModel.fromJson(json as Map<String, dynamic>))
      .toList();
});

/// Провайдер всех выплат за текущий месяц с сортировкой.
final filteredPayrollPayoutsProvider =
    FutureProvider<List<PayrollPayoutModel>>((ref) async {
  try {
    final payouts = await ref.watch(payrollPayoutsByFilterProvider.future);
    final searchQuery = ref.watch(payrollSearchQueryProvider);
    final employeeState = ref.watch(employeeProvider);
    final employees = employeeState.employees;

    var result = payouts;

    // 1. Фильтрация по ФИО на клиенте (если есть поиск)
    if (searchQuery.trim().isNotEmpty) {
      final query = searchQuery.trim().toLowerCase();
      result = result.where((payout) {
        final emp = employees.firstWhereOrNull((e) => e.id == payout.employeeId);
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

    // Дополнительная сортировка по дате выплаты (самые новые сверху)
    result.sort((a, b) => b.payoutDate.compareTo(a.payoutDate));

    return result;
  } catch (e) {
    return [];
  }
});

/// Провайдер получения ВСЕХ выплат (без фильтра по месяцам).
/// Используется для FIFO распределения выплат по месяцам начисления.
final allPayoutsProvider =
    FutureProvider<List<PayrollPayoutModel>>((ref) async {
  final client = ref.watch(supabaseClientProvider);
  final activeCompanyId = ref.watch(activeCompanyIdProvider);

  if (activeCompanyId == null) return [];

  try {
    final response = await client
        .from('payroll_payout')
        .select()
        .eq('company_id', activeCompanyId)
        .order('payout_date', ascending: false);

    return (response as List)
        .map(
            (json) => PayrollPayoutModel.fromJson(json as Map<String, dynamic>))
        .toList();
  } catch (e) {
    return [];
  }
});

/// Результат FIFO распределения выплат для сотрудника за год.
class PayrollEmployeeFIFOData {
  /// Выплаты по месяцам (1-12).
  final Map<int, double> payouts;

  /// Балансы на конец месяца (1-12) с учетом FIFO выплат.
  final Map<int, double> balances;

  /// Конструктор [PayrollEmployeeFIFOData].
  PayrollEmployeeFIFOData({
    required this.payouts,
    required this.balances,
  });
}

/// Провайдер FIFO распределения выплат по месяцам.
/// Возвращает Map<employeeId, PayrollEmployeeFIFOData>
/// где month = 1-12 (январь-декабрь выбранного года).
final payoutsByEmployeeAndMonthFIFOProvider =
    FutureProvider.family<Map<String, PayrollEmployeeFIFOData>, int>((ref, year) async {
  final client = ref.watch(supabaseClientProvider);
  final allPayouts = await ref.watch(allPayoutsProvider.future);
  final activeCompanyId = ref.watch(activeCompanyIdProvider);

  if (activeCompanyId == null) return {};

  final result = <String, PayrollEmployeeFIFOData>{};
  final startOfSelectedYear = DateTime(year, 1, 1).toIso8601String();

  // 1️⃣ Получаем сумму всех начислений ДО начала выбранного года одним запросом
  final Map<String, double> accrualsBeforeYear = {};
  try {
    final historicalAccrualsResponse = await client.rpc('calculate_employee_balances_before_date', params: {
      'p_before_date': startOfSelectedYear,
      'p_company_id': activeCompanyId,
    });
    
    for (final row in (historicalAccrualsResponse as List)) {
      final empId = row['employee_id'] as String;
      accrualsBeforeYear[empId] = (row['accruals_sum'] as num).toDouble();
    }
  } catch (e) {
    // В случае ошибки считаем, что исторических начислений нет
  }

  // 2️⃣ Группируем выплаты по сотрудникам и сортируем их по дате (хронология)
  final payoutsByEmployee = <String, List<PayrollPayoutModel>>{};
  final sortedPayouts = [...allPayouts]..sort((a, b) => a.payoutDate.compareTo(b.payoutDate));
  
  for (final payout in sortedPayouts) {
    payoutsByEmployee.putIfAbsent(payout.employeeId, () => []).add(payout);
  }

  // 3️⃣ Получаем начисления за месяцы ВЫБРАННОГО года ПАРАЛЛЕЛЬНО
  final payrollsByEmployeeAndMonth = <String, Map<int, double>>{};
  
  final monthFutures = List.generate(12, (index) {
    final month = index + 1;
    return client.rpc('calculate_payroll_for_month', params: {
      'p_year': year,
      'p_month': month,
      'p_company_id': activeCompanyId,
    }).then((response) => MapEntry(month, response as List));
  });

  final results = await Future.wait(monthFutures);

  for (final entry in results) {
    final month = entry.key;
    final monthRows = entry.value;

    for (final row in monthRows) {
      final empId = row['employee_id'] as String;
      final netSalary = (row['net_salary'] as num).toDouble();
      
      payrollsByEmployeeAndMonth.putIfAbsent(empId, () => {});
      payrollsByEmployeeAndMonth[empId]![month] = netSalary;
    }
  }

  // 4️⃣ FIFO распределение с учетом исторического долга
  // Для корректного расчета баланса нам нужны ВСЕ сотрудники, у которых были начисления или выплаты
  final allEmployeeIds = {
    ...accrualsBeforeYear.keys,
    ...payoutsByEmployee.keys,
    ...payrollsByEmployeeAndMonth.keys,
  };

  for (final employeeId in allEmployeeIds) {
    final employeePayouts = payoutsByEmployee[employeeId] ?? [];
    final employeePayrolls = payrollsByEmployeeAndMonth[employeeId] ?? {};
    
    // Начальный исторический долг (начисления до начала года)
    var remainingHistoricalDebt = accrualsBeforeYear[employeeId] ?? 0.0;
    
    final payoutsForMonth = <int, double>{};

    // 4.1. Сначала распределяем ВСЕ выплаты (FIFO)
    for (final payout in employeePayouts) {
      var remainingPayout = payout.amount.toDouble();

      // Сначала гасим исторический долг начислениями до этого года
      if (remainingHistoricalDebt > 0) {
        final toApplyToHistory = remainingPayout > remainingHistoricalDebt 
            ? remainingHistoricalDebt 
            : remainingPayout;
        remainingHistoricalDebt -= toApplyToHistory;
        remainingPayout -= toApplyToHistory;
      }

      // Если после гашения исторического долга остались деньги — гасим месяцы ТЕКУЩЕГО года
      if (remainingPayout > 0) {
        for (int month = 1; month <= 12 && remainingPayout > 0; month++) {
          final accrualForMonth = employeePayrolls[month] ?? 0.0;
          if (accrualForMonth <= 0) continue; // Пропускаем месяцы без начисления

          final alreadyPaidInMonth = payoutsForMonth[month] ?? 0.0;
          final remainingInMonth = accrualForMonth - alreadyPaidInMonth;

          if (remainingInMonth > 0) {
            final toApplyToMonth = remainingPayout > remainingInMonth 
                ? remainingInMonth 
                : remainingPayout;

            payoutsForMonth[month] = (payoutsForMonth[month] ?? 0.0) + toApplyToMonth;
            remainingPayout -= toApplyToMonth;
          }
        }
      }

      // Выплаты в БД не привязаны к месяцу начисления: если за год нет положительных
      // net_salary (только нули или нет строки), весь остаток иначе «теряется» для колонки
      // «Выплаты». Относим остаток на календарный месяц даты выплаты в выбранном году.
      if (remainingPayout > 0 && payout.payoutDate.year == year) {
        final m = payout.payoutDate.month;
        payoutsForMonth[m] = (payoutsForMonth[m] ?? 0.0) + remainingPayout;
      }
    }

    // 4.2. Теперь рассчитываем кумулятивный баланс на конец каждого месяца
    // Баланс(М) = Баланс_начала_года + Сумма(Начисления_до_М) - Сумма(Выплаты_до_М_по_FIFO)
    // Что эквивалентно: Баланс(М) = Баланс(М-1) + Начисление(М) - Выплата_FIFO(М)
    final balancesForMonth = <int, double>{};
    var currentRunningBalance = remainingHistoricalDebt; // Остаток долга с прошлых лет после всех выплат

    for (int month = 1; month <= 12; month++) {
      final accrual = employeePayrolls[month] ?? 0.0;
      final payoutFIFO = payoutsForMonth[month] ?? 0.0;
      
      currentRunningBalance += (accrual - payoutFIFO);
      balancesForMonth[month] = currentRunningBalance;
    }

    result[employeeId] = PayrollEmployeeFIFOData(
      payouts: payoutsForMonth,
      balances: balancesForMonth,
    );
  }

  return result;
});

/// Провайдер репозитория выплат по ФОТ (Supabase).
final payrollPayoutRepositoryProvider =
    Provider<PayrollPayoutRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  final activeCompanyId = ref.watch(activeCompanyIdProvider);
  return PayrollPayoutRepositoryImpl(client, activeCompanyId ?? '');
});

/// Провайдер функции создания выплаты.
final createPayoutUseCaseProvider =
    Provider<Future<PayrollPayoutModel> Function(PayrollPayoutModel)>((ref) {
  final repo = ref.watch(payrollPayoutRepositoryProvider);
  return (PayrollPayoutModel payout) async {
    return await repo.createPayout(payout);
  };
});

/// Провайдер функции обновления выплаты.
final updatePayoutUseCaseProvider =
    Provider<Future<PayrollPayoutModel> Function(PayrollPayoutModel)>((ref) {
  final repo = ref.watch(payrollPayoutRepositoryProvider);
  return (PayrollPayoutModel payout) async {
    return await repo.updatePayout(payout);
  };
});

/// Провайдер функции удаления выплаты по ID.
final deletePayoutUseCaseProvider =
    Provider<Future<void> Function(String)>((ref) {
  final repo = ref.watch(payrollPayoutRepositoryProvider);
  return (String id) async {
    await repo.deletePayout(id);
  };
});
