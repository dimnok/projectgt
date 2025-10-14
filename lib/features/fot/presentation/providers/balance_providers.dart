import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:projectgt/core/di/providers.dart';

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

  try {
    // 🚀 ОПТИМИЗАЦИЯ: Один запрос вместо 5 отдельных
    final response = await client.rpc('calculate_employee_balances');

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
    // Возвращаем пустой результат при ошибке
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
