import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:projectgt/core/di/providers.dart';

/// Провайдер оптимизированного расчёта агрегированного баланса по сотрудникам за всё время
/// 
/// Использует эффективные запросы вместо множественных обращений к БД
final employeeAggregatedBalanceProvider = FutureProvider<Map<String, double>>((ref) async {
  final client = ref.read(supabaseClientProvider);
  
  try {
    // Пытаемся использовать RPC функции, если они доступны
    dynamic netSalaryResponse;
    dynamic payoutsResponse;
    
    try {
      netSalaryResponse = await client.rpc('get_employee_total_net_salary');
    } catch (e) {
      // RPC функция недоступна, будем использовать fallback
      netSalaryResponse = null;
    }
    
    try {
      payoutsResponse = await client.rpc('get_employee_total_payouts');
    } catch (e) {
      // RPC функция недоступна, будем использовать fallback
      payoutsResponse = null;
    }
    
    final Map<String, double> netSalarySum = {};
    final Map<String, double> payoutsSum = {};
    
    if (netSalaryResponse == null) {
      // Fallback: рассчитываем netSalary с учётом всех компонентов
      
      // 1. Получаем базовую зарплату (часы * ставка)
      final workHoursResponse = await client
          .from('work_hours')
          .select('''
            employee_id,
            hours,
            works!inner(date, object_id),
            employees!inner(hourly_rate)
          ''');
      
      // 2. Получаем командировочные суммы
      final objectsResponse = await client
          .from('objects')
          .select('id, business_trip_amount');
      
      final Map<String, double> objectTripMap = {};
      for (final obj in objectsResponse) {
        final id = obj['id'] as String?;
        final amount = (obj['business_trip_amount'] as num?)?.toDouble();
        if (id != null && amount != null && amount > 0) {
          objectTripMap[id] = amount;
        }
      }
      
      // 3. Получаем премии
      final bonusesResponse = await client
          .from('payroll_bonus')
          .select('employee_id, amount');
      
      // 4. Получаем штрафы
      final penaltiesResponse = await client
          .from('payroll_penalty')
          .select('employee_id, amount');
      
      // Группируем work_hours по сотрудникам
      final Map<String, List<Map<String, dynamic>>> employeeHours = {};
      for (final record in workHoursResponse) {
        final employeeId = record['employee_id'] as String?;
        if (employeeId == null) continue;
        
        employeeHours.putIfAbsent(employeeId, () => []).add(record);
      }
      
      // Группируем командировочные по сотрудникам и объектам
      final Map<String, Map<String, int>> employeeObjectShifts = {};
      for (final record in workHoursResponse) {
        final employeeId = record['employee_id'] as String?;
        final works = record['works'] as Map<String, dynamic>?;
        final objectId = works?['object_id'] as String?;
        
        if (employeeId != null && objectId != null) {
          employeeObjectShifts.putIfAbsent(employeeId, () => {});
          employeeObjectShifts[employeeId]![objectId] = 
              (employeeObjectShifts[employeeId]![objectId] ?? 0) + 1;
        }
      }
      
      // Группируем премии по сотрудникам
      final Map<String, double> employeeBonuses = {};
      for (final bonus in bonusesResponse) {
        final employeeId = bonus['employee_id'] as String?;
        final amount = (bonus['amount'] as num?)?.toDouble() ?? 0;
        if (employeeId != null) {
          employeeBonuses[employeeId] = (employeeBonuses[employeeId] ?? 0) + amount;
        }
      }
      
      // Группируем штрафы по сотрудникам
      final Map<String, double> employeePenalties = {};
      for (final penalty in penaltiesResponse) {
        final employeeId = penalty['employee_id'] as String?;
        final amount = (penalty['amount'] as num?)?.toDouble() ?? 0;
        if (employeeId != null) {
          employeePenalties[employeeId] = (employeePenalties[employeeId] ?? 0) + amount;
        }
      }
      
      // Рассчитываем netSalary для каждого сотрудника
      for (final entry in employeeHours.entries) {
        final employeeId = entry.key;
        final records = entry.value;
        
        double totalHours = 0;
        double hourlyRate = 0;
        
        for (final record in records) {
          final hours = (record['hours'] as num?)?.toDouble() ?? 0;
          totalHours += hours;
          
          final employee = record['employees'] as Map<String, dynamic>?;
          if (employee != null) {
            hourlyRate = (employee['hourly_rate'] as num?)?.toDouble() ?? 0;
          }
        }
        
        // Базовая зарплата
        final baseSalary = totalHours * hourlyRate;
        
        // Командировочные
        double businessTripTotal = 0;
        final objectShifts = employeeObjectShifts[employeeId] ?? {};
        objectShifts.forEach((objectId, shiftCount) {
          final tripAmount = objectTripMap[objectId] ?? 0;
          if (tripAmount > 0) {
            businessTripTotal += tripAmount * shiftCount;
          }
        });
        
        // Премии и штрафы
        final bonusesTotal = employeeBonuses[employeeId] ?? 0;
        final penaltiesTotal = employeePenalties[employeeId] ?? 0;
        
        // NetSalary = базовая зарплата + премии + командировочные - штрафы
        // (удержания пока не учитываем, так как таблица не реализована)
        final netSalary = baseSalary + bonusesTotal + businessTripTotal - penaltiesTotal;
        
        netSalarySum[employeeId] = netSalary;
      }
    } else {
      // Используем результат RPC функции
      for (final record in netSalaryResponse) {
        final employeeId = record['employee_id'] as String?;
        final totalSalary = (record['total_net_salary'] as num?)?.toDouble() ?? 0;
        if (employeeId != null) {
          netSalarySum[employeeId] = totalSalary;
        }
      }
    }
    
    if (payoutsResponse == null) {
      // Fallback: получаем все выплаты одним запросом
      final payoutsResp = await client
          .from('payroll_payout')
          .select('employee_id, amount');
      
      for (final payout in payoutsResp) {
        final employeeId = payout['employee_id'] as String?;
        final amount = (payout['amount'] as num?)?.toDouble() ?? 0;
        if (employeeId != null) {
          payoutsSum[employeeId] = (payoutsSum[employeeId] ?? 0) + amount;
        }
      }
    } else {
      // Используем результат RPC функции
      for (final record in payoutsResponse) {
        final employeeId = record['employee_id'] as String?;
        final totalPayouts = (record['total_payouts'] as num?)?.toDouble() ?? 0;
        if (employeeId != null) {
          payoutsSum[employeeId] = totalPayouts;
        }
      }
    }
    
    // Рассчитываем баланс = netSalarySum - payoutsSum
    final Map<String, double> balance = {};
    final allEmployeeIds = {...netSalarySum.keys, ...payoutsSum.keys};
    
    for (final employeeId in allEmployeeIds) {
      balance[employeeId] = (netSalarySum[employeeId] ?? 0) - (payoutsSum[employeeId] ?? 0);
    }
    
    return balance;
  } catch (e) {
    // Логируем ошибку и возвращаем пустой результат
    return <String, double>{};
  }
});

/// Провайдер для кеширования баланса с автоматическим обновлением
final cachedEmployeeBalanceProvider = FutureProvider.autoDispose<Map<String, double>>((ref) async {
  // Автоматически инвалидируется через 5 минут для обновления данных
  final timer = Timer(const Duration(minutes: 5), () {
    ref.invalidateSelf();
  });
  
  ref.onDispose(() => timer.cancel());
  
  return ref.watch(employeeAggregatedBalanceProvider.future);
}); 