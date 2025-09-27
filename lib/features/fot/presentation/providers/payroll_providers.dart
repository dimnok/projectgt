import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/payroll_calculation.dart';
import 'package:projectgt/core/di/providers.dart';
import 'payroll_filter_provider.dart';
import 'package:collection/collection.dart';
import 'package:projectgt/features/fot/presentation/providers/penalty_providers.dart';
import 'package:projectgt/features/fot/presentation/providers/bonus_providers.dart';
import 'package:projectgt/features/fot/data/models/payroll_payout_model.dart';
import '../../data/repositories/payroll_payout_repository.dart';
import '../../data/repositories/payroll_payout_repository_impl.dart';
import 'payroll_payout_filter_provider.dart';
import '../../domain/usecases/create_payout_usecase.dart';
import '../../domain/usecases/update_payout_usecase.dart';
import '../../domain/usecases/delete_payout_usecase.dart';

/// Провайдер для независимой загрузки данных work_hours по периоду ФОТ.
///
/// Загружает данные work_hours напрямую из Supabase по выбранному в ФОТ периоду,
/// не зависит от модуля табеля.
final payrollWorkHoursProvider = FutureProvider<List<dynamic>>((ref) async {
  final filterState = ref.watch(payrollFilterProvider);
  final startDate = filterState.startDate;
  final endDate = filterState.endDate;

  try {
    final client = ref.watch(supabaseClientProvider);

    // Загружаем данные work_hours с связанными данными works и employees
    final response = await client
        .from('work_hours')
        .select('''
          id,
          work_id,
          employee_id,
          hours,
          works:work_id (
            date,
            object_id
          ),
          employees:employee_id (
            position
          )
        ''')
        .gte('works.date', startDate.toIso8601String())
        .lte('works.date', endDate.toIso8601String());

    // Преобразуем в плоский формат для совместимости
    final workHours = response
        .map<dynamic>((record) {
          final works = record['works'] as Map<String, dynamic>?;
          final employee = record['employees'] as Map<String, dynamic>?;

          if (works == null ||
              record['employee_id'] == null ||
              record['hours'] == null ||
              works['date'] == null) {
            return null; // Пропускаем неполные записи
          }

          return WorkHourEntry(
            id: record['id'],
            workId: record['work_id'],
            employeeId: record['employee_id'],
            hours: record['hours'],
            date: DateTime.parse(works['date']),
            objectId: works['object_id'] ?? '',
            employeePosition: employee?['position'],
          );
        })
        .where((entry) => entry != null)
        .toList();

    return workHours;
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
/// Теперь не зависит от модуля табеля.
final payrollDataReadyProvider = Provider<bool>((ref) {
  // Проверяем состояние данных work_hours для ФОТ
  final workHoursState = ref.watch(payrollWorkHoursProvider);

  // Получаем состояние фильтров - проверяем, загружены ли employees и objects
  final filterState = ref.watch(payrollFilterProvider);

  // Проверяем, загружены ли все необходимые данные
  final workHoursLoaded = !workHoursState.isLoading && workHoursState.hasValue;
  final employeesLoaded = filterState.employees.isNotEmpty;
  final objectsLoaded = filterState.objects.isNotEmpty;

  // Готовность данных для отображения
  return workHoursLoaded && employeesLoaded && objectsLoaded;
});

/// Провайдер отфильтрованных расчетов ФОТ с защитой от множественного обновления.
///
/// Теперь использует независимые данные work_hours вместо данных табеля.
final filteredPayrollsProvider =
    FutureProvider<List<PayrollCalculation>>((ref) async {
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

    // Используем независимые данные work_hours вместо timesheetEntries
    final workHoursAsync = await ref.watch(payrollWorkHoursProvider.future);
    final workHours = workHoursAsync;

    // --- Фильтрация записей по выбранным критериям ---
    final filteredEntries = workHours.where((entry) {
      final entryDate = entry.date;
      final inPeriod =
          entryDate.isAfter(startDate.subtract(const Duration(days: 1))) &&
              entryDate.isBefore(endDate.add(const Duration(days: 1)));
      final byObject = objectIds.isEmpty || objectIds.contains(entry.objectId);

      // Для фильтрации по должности нужно получить данные из employees
      bool byPosition = true;
      if (positionNames.isNotEmpty) {
        final employee = filterState.employees
            .firstWhereOrNull((e) => e.id == entry.employeeId);
        byPosition = employee != null &&
            employee.position != null &&
            positionNames.contains(employee.position);
      }

      return inPeriod && byObject && byPosition;
    }).toList();

    // 2. Группируем по сотруднику
    final Map<String, List<dynamic>> employeeEntries = {};
    for (final entry in filteredEntries) {
      employeeEntries.putIfAbsent(entry.employeeId, () => []).add(entry);
    }

    // 3. Получаем список сотрудников для фильтра
    List<String> filteredEmployeeIds = employeeEntries.keys.toList();
    if (employeeIds.isNotEmpty) {
      filteredEmployeeIds =
          filteredEmployeeIds.where((id) => employeeIds.contains(id)).toList();
    }

    // --- Получаем все штрафы и премии за период ---
    final penaltiesAsyncRaw = await ref.watch(allPenaltiesProvider.future);
    final bonusesAsyncRaw = await ref.watch(allBonusesProvider.future);
    final penaltiesAsync = penaltiesAsyncRaw;
    final bonusesAsync = bonusesAsyncRaw;

    // 4. Формируем PayrollCalculation для каждого сотрудника
    final List<PayrollCalculation> payrolls = [];
    for (final employeeId in filteredEmployeeIds) {
      final entries = employeeEntries[employeeId]!;
      double hours = 0;
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

      final objectTripMap = {
        for (final obj in filterState.objects)
          if (obj.businessTripAmount != null && obj.businessTripAmount > 0)
            obj.id: obj.businessTripAmount.toDouble(),
      };

      double businessTripTotal = 0;
      objectShiftCount.forEach((objectId, shiftCount) {
        final tripAmount = objectTripMap[objectId] ?? 0;
        if (tripAmount > 0) {
          businessTripTotal += tripAmount * shiftCount;
        }
      });

      final employee =
          filterState.employees.firstWhereOrNull((e) => e.id == employeeId);
      final hourlyRate = employee?.hourlyRate ?? 0.0;
      final baseSalary = hours * hourlyRate;

      // --- Расчёт штрафов из базы ---
      final penaltiesTotal = (penaltiesAsync)
          .where((p) =>
              p.employeeId == employeeId &&
              p.date != null &&
              p.date!.year == year &&
              p.date!.month == month)
          .fold<double>(0, (sum, p) => sum + p.amount);

      // --- Расчёт премий из базы ---
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
        hourlyRate: hourlyRate,
        baseSalary: baseSalary,
        bonusesTotal: bonusesTotal,
        penaltiesTotal: penaltiesTotal,
        businessTripTotal: businessTripTotal,
        netSalary: netSalary,
      );

      payrolls.add(calculation);
    }

    // Сортировка по алфавиту
    payrolls.sort((a, b) {
      final empA =
          filterState.employees.firstWhereOrNull((e) => e.id == a.employeeId);
      final empB =
          filterState.employees.firstWhereOrNull((e) => e.id == b.employeeId);
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
});

/// Провайдер получения выплат по месяцу (DateTime — первый день месяца).
final payrollPayoutsByMonthProvider =
    FutureProvider.family<List<PayrollPayoutModel>, DateTime>(
        (ref, month) async {
  final client = ref.watch(supabaseClientProvider);
  final startDate = DateTime(month.year, month.month, 1);
  final endDate = DateTime(month.year, month.month + 1, 0);
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

/// Провайдер usecase создания выплаты.
final createPayoutUseCaseProvider = Provider<CreatePayoutUseCase>((ref) {
  return CreatePayoutUseCase(ref.watch(payrollPayoutRepositoryProvider));
});

/// Провайдер usecase обновления выплаты.
final updatePayoutUseCaseProvider = Provider<UpdatePayoutUseCase>((ref) {
  return UpdatePayoutUseCase(ref.watch(payrollPayoutRepositoryProvider));
});

/// Провайдер usecase удаления выплаты.
final deletePayoutUseCaseProvider = Provider<DeletePayoutUseCase>((ref) {
  return DeletePayoutUseCase(ref.watch(payrollPayoutRepositoryProvider));
});

/// Провайдер отфильтрованных выплат по ФОТ с использованием специальных фильтров выплат.
///
/// Использует фильтры из payrollPayoutFilterProvider для фильтрации выплат по диапазону дат,
/// способу выплаты и сотрудникам.
final filteredPayrollPayoutsProvider =
    FutureProvider<List<PayrollPayoutModel>>((ref) async {
  try {
    final filterState = ref.watch(payrollPayoutFilterProvider);

    final client = ref.watch(supabaseClientProvider);

    // Базовый запрос выплат
    var query = client.from('payroll_payout').select();

    // Фильтр по диапазону дат выплат
    query = query
        .gte('payout_date', filterState.startDate.toIso8601String())
        .lte('payout_date', filterState.endDate.toIso8601String());

    // Фильтр по сотрудникам
    if (filterState.employeeIds.isNotEmpty) {
      query = query.filter('employee_id', 'in', filterState.employeeIds);
    }

    // Фильтр по способу выплаты
    if (filterState.payoutMethods.isNotEmpty) {
      query = query.filter('method', 'in', filterState.payoutMethods);
    }

    final response = await query;

    final payouts = (response as List)
        .map(
            (json) => PayrollPayoutModel.fromJson(json as Map<String, dynamic>))
        .toList();

    // Получаем данные о сотрудниках для сортировки
    final payrollFilterState = ref.watch(payrollFilterProvider);
    final employees = payrollFilterState.employees;

    // Сортируем по алфавиту (ФИО сотрудников)
    payouts.sort((a, b) {
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
    payouts.sort((a, b) => b.payoutDate.compareTo(a.payoutDate));

    return payouts;
  } catch (e) {
    return [];
  }
});
