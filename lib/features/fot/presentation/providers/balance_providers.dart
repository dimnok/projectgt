import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:projectgt/core/di/providers.dart';
import 'package:projectgt/features/company/presentation/providers/company_providers.dart';

/// Провайдер оптимизированного расчёта агрегированного баланса по сотрудникам за ВСЁ ВРЕМЯ
///
/// **ВАЖНО:** Баланс учитывает ВСЮ историю по сотруднику:
/// - Баланс = Сумма всех "К выплате" за всё время - Сумма всех "Выплаты" за всё время
/// - "К выплате" = baseSalary + bonuses + businessTrip - penalties
///
/// **ОПТИМИЗАЦИЯ:** Использует единую SQL функцию calculate_employee_balances()
/// для мгновенного расчёта баланса всех сотрудников одним запросом.
final employeeAggregatedBalanceProvider =
    FutureProvider<Map<String, double>>((ref) async {
  final client = ref.read(supabaseClientProvider);
  final activeCompanyId = ref.watch(activeCompanyIdProvider);

  if (activeCompanyId == null) return {};

  try {
    // 🚀 ОПТИМИЗАЦИЯ: Один запрос вместо 5 отдельных
    final response = await client.rpc('calculate_employee_balances', params: {
      'p_company_id': activeCompanyId,
    });

    final Map<String, double> balance = {};
    for (final row in response) {
      final employeeId = row['employee_id'] as String?;
      final balanceValue = (row['balance'] as num?)?.toDouble() ?? 0;
      if (employeeId != null) {
        balance[employeeId] = balanceValue;
      }
    }

    return balance;
  } catch (e) {
    return <String, double>{};
  }
});

/// Провайдер баланса конкретного сотрудника.
///
/// **ОПТИМИЗАЦИЯ:** Используется на экране профиля, чтобы не грузить балансы всех сотрудников компании.
final singleEmployeeBalanceProvider =
    FutureProvider.family<double, String>((ref, employeeId) async {
  final client = ref.read(supabaseClientProvider);
  final activeCompanyId = ref.watch(activeCompanyIdProvider);

  if (activeCompanyId == null) return 0.0;

  try {
    final response = await client.rpc('calculate_single_employee_balance', params: {
      'p_employee_id': employeeId,
      'p_company_id': activeCompanyId,
    });
    return (response as num?)?.toDouble() ?? 0.0;
  } catch (e) {
    return 0.0;
  }
});

/// Провайдер расчёта баланса на КОНЕЦ выбранного месяца.
///
/// Учитывает все начисления и выплаты, произведенные ДО конца указанной даты.
/// Позволяет скрывать сотрудников, расчет с которыми был завершен в прошлом.
final employeeBalanceAtDateProvider =
    FutureProvider.family<Map<String, double>, DateTime>((ref, date) async {
  final client = ref.read(supabaseClientProvider);
  final activeCompanyId = ref.watch(activeCompanyIdProvider);

  if (activeCompanyId == null) return {};

  try {
    // Вычисляем конец дня для переданной даты
    final endOfDate = DateTime(date.year, date.month, date.day, 23, 59, 59);

    final response = await client.rpc(
      'calculate_employee_balances_at_date',
      params: {
        'p_date': endOfDate.toIso8601String(),
        'p_company_id': activeCompanyId,
      },
    );

    final Map<String, double> balance = {};
    for (final row in response) {
      final employeeId = row['employee_id'] as String?;
      final balanceValue = (row['balance'] as num?)?.toDouble() ?? 0;
      if (employeeId != null) {
        balance[employeeId] = balanceValue;
      }
    }

    return balance;
  } catch (e) {
    return <String, double>{};
  }
});

/// Провайдер для кеширования баланса с автоматическим обновлением
final cachedEmployeeBalanceProvider =
    FutureProvider.autoDispose<Map<String, double>>((ref) async {
  // Автоматически инвалидируется через 5 минут для обновления данных
  final timer = Timer(const Duration(minutes: 5), () {
    ref.invalidateSelf();
  });

  ref.onDispose(() => timer.cancel());

  return ref.watch(employeeAggregatedBalanceProvider.future);
});
