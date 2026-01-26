import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:projectgt/core/di/providers.dart';
import 'package:projectgt/features/company/presentation/providers/company_providers.dart';
import 'package:projectgt/features/fot/domain/entities/payroll_calculation.dart';
import 'package:projectgt/features/fot/data/models/payroll_payout_model.dart';
import 'package:projectgt/features/fot/presentation/services/payroll_pdf_service.dart';
import 'package:projectgt/features/fot/presentation/providers/payroll_providers.dart';
import 'package:collection/collection.dart';

/// Сервис для формирования данных финансового отчета по конкретному сотруднику.
/// 
/// Инкапсулирует логику сбора данных из разных источников:
/// - История ставок (employee_rates)
/// - Отработанные часы (work_hours + employee_attendance)
/// - Выплаты (payroll_payout)
/// - Расчеты через RPC (calculate_payroll_for_month)
class EmployeeFinancialReportService {
  final SupabaseClient _client;
  final String? _activeCompanyId;

  /// Создает экземпляр [EmployeeFinancialReportService].
  EmployeeFinancialReportService(this._client, this._activeCompanyId);

  /// Собирает полные данные за год для формирования PDF-отчета.
  Future<List<MonthlyReportData>> getYearlyReportData({
    required String employeeId,
    required int year,
    PayrollEmployeeFIFOData? fifoData,
  }) async {
    final startDate = DateTime(year, 1, 1);
    final endDate = DateTime(year, 12, 31, 23, 59, 59);

    // 1. История ставок
    final ratesResponse = await _client
        .from('employee_rates')
        .select()
        .eq('employee_id', employeeId)
        .order('valid_from');
    final List<Map<String, dynamic>> rates = List<Map<String, dynamic>>.from(ratesResponse);

    // 2. Все отработанные часы (смены + табель)
    final results = await Future.wait([
      _client.from('work_hours').select('''
        hours,
        works!inner(date, status)
      ''')
          .eq('employee_id', employeeId)
          .eq('works.status', 'closed')
          .gte('works.date', startDate.toIso8601String())
          .lte('works.date', endDate.toIso8601String()),
      _client.from('employee_attendance').select('hours, date')
          .eq('employee_id', employeeId)
          .gte('date', startDate.toIso8601String())
          .lte('date', endDate.toIso8601String()),
    ]);

    final allWorkEntries = [
      ...(results[0] as List).map((row) => {
        'hours': (row['hours'] as num).toDouble(),
        'date': DateTime.parse(row['works']['date']),
      }),
      ...(results[1] as List).map((row) => {
        'hours': (row['hours'] as num).toDouble(),
        'date': DateTime.parse(row['date']),
      }),
    ];

    // 3. Выплаты за год
    final payoutsResponse = await _client
        .from('payroll_payout')
        .select()
        .eq('employee_id', employeeId)
        .gte('payout_date', startDate.toIso8601String())
        .lte('payout_date', endDate.toIso8601String())
        .order('payout_date');
    final allPayouts = (payoutsResponse as List)
        .map((json) => PayrollPayoutModel.fromJson(json))
        .toList();

    // 4. Расчеты ФОТ через RPC за каждый месяц
    final List<Future<dynamic>> payrollFutures = List.generate(12, (i) => 
      _client.rpc('calculate_payroll_for_month', params: {
        'p_year': year,
        'p_month': i + 1,
        'p_company_id': _activeCompanyId,
      })
    );
    final payrollResults = await Future.wait(payrollFutures);

    // 5. Группировка по месяцам
    final List<MonthlyReportData> monthlyReportData = [];
    for (int i = 0; i < 12; i++) {
      final month = i + 1;
      final monthResults = payrollResults[i] as List;
      final monthRow = monthResults.firstWhereOrNull((row) => row['employee_id'] == employeeId);

      PayrollCalculation? calc;
      if (monthRow != null) {
        calc = PayrollCalculation(
          employeeId: employeeId,
          periodMonth: DateTime(year, month, 1),
          hoursWorked: (monthRow['total_hours'] as num).toDouble(),
          hourlyRate: (monthRow['current_hourly_rate'] as num).toDouble(),
          baseSalary: (monthRow['base_salary'] as num).toDouble(),
          bonusesTotal: (monthRow['bonuses_total'] as num).toDouble(),
          penaltiesTotal: (monthRow['penalties_total'] as num).toDouble(),
          businessTripTotal: (monthRow['business_trip_total'] as num).toDouble(),
          netSalary: (monthRow['net_salary'] as num).toDouble(),
        );
      }

      // Детализация по ставкам для месяца
      final Map<double, double> rateHoursMap = {};
      final monthEntries = allWorkEntries.where((e) {
        final d = e['date'] as DateTime;
        return d.year == year && d.month == month;
      });

      for (final entry in monthEntries) {
        final date = entry['date'] as DateTime;
        final hours = entry['hours'] as double;
        double activeRate = 0;
        for (final rate in rates) {
          final validFrom = DateTime.parse(rate['valid_from']);
          final validTo = rate['valid_to'] != null ? DateTime.parse(rate['valid_to']) : null;
          if ((date.isAfter(validFrom) || date.isAtSameMomentAs(validFrom)) &&
              (validTo == null || date.isBefore(validTo) || date.isAtSameMomentAs(validTo))) {
            activeRate = (rate['hourly_rate'] as num).toDouble();
            break;
          }
        }
        if (activeRate > 0) {
          rateHoursMap[activeRate] = (rateHoursMap[activeRate] ?? 0) + hours;
        }
      }

      final List<RateBreakdown> breakdowns = rateHoursMap.entries
          .map((entry) => RateBreakdown(
                rate: entry.key,
                hours: entry.value,
                amount: entry.key * entry.value,
              ))
          .toList();

      // Если переданы данные FIFO — берем выплаты и баланс оттуда
      List<PayrollPayoutModel> monthPayouts;
      double monthBalance = 0;

      if (fifoData != null) {
        final fifoAmount = fifoData.payouts[month] ?? 0.0;
        monthBalance = fifoData.balances[month] ?? 0.0;
        
        // Для детального отчета нам все равно нужны объекты PayrollPayoutModel
        // Но мы берем только те, что фактически относятся к этому месяцу по дате,
        // ИЛИ (более корректно для PDF) показываем все выплаты, но помечаем их.
        // Пока оставим фильтрацию по дате для списка транзакций, но баланс будет из FIFO.
        monthPayouts = allPayouts.where((p) => p.payoutDate.year == year && p.payoutDate.month == month).toList();
      } else {
        monthPayouts = allPayouts.where((p) => p.payoutDate.year == year && p.payoutDate.month == month).toList();
        final monthEarned = calc?.netSalary ?? 0;
        final monthPaid = monthPayouts.fold<double>(0, (sum, p) => sum + p.amount);
        monthBalance = monthEarned - monthPaid;
      }

      if (calc != null || monthPayouts.isNotEmpty) {
        monthlyReportData.add(MonthlyReportData(
          month: month,
          year: year,
          calculation: calc,
          payouts: monthPayouts,
          rateBreakdowns: breakdowns,
          balance: monthBalance,
        ));
      }
    }

    return monthlyReportData;
  }
}

/// Провайдер сервиса финансовых отчетов сотрудников.
final employeeFinancialReportServiceProvider = Provider((ref) {
  final client = ref.watch(supabaseClientProvider);
  final activeCompanyId = ref.watch(activeCompanyIdProvider);
  return EmployeeFinancialReportService(client, activeCompanyId);
});
