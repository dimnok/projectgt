import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/payroll_calculation.dart';
import '../../domain/repositories/payroll_repository.dart';

/// Реализация репозитория для работы с расчетами ФОТ.
///
/// Выполняет динамический расчет ФОТ на основе данных из таблиц
/// табеля, сотрудников, премий, штрафов и удержаний.
class PayrollRepositoryImpl implements PayrollRepository {
  /// Клиент Supabase для взаимодействия с базой данных.
  final SupabaseClient _client;

  /// Создаёт экземпляр репозитория.
  ///
  /// [client] - клиент Supabase.
  PayrollRepositoryImpl(this._client);

  @override
  Future<List<PayrollCalculation>> getPayrollsByMonth(DateTime month) async {
    final startDate = DateTime(month.year, month.month, 1);
    final endDate = DateTime(month.year, month.month + 1, 0);
    
    try {
      // Формируем запрос для получения отработанных часов
      String query = '''
        id,
        work_id,
        employee_id,
        hours,
        works:work_id (
          date,
          object_id
        )
      ''';
      
      // Получаем данные из табеля
      final response = await _client
          .from('work_hours')
          .select(query);
      
      // Если нет данных в табеле, возвращаем пустой список
      if (response.isEmpty) {
        return [];
      }
      
      // Преобразуем результаты в плоский формат
      final timesheetEntries = response.map<Map<String, dynamic>>((record) {
        final works = record['works'] as Map<String, dynamic>?;
        
        // Проверка наличия связанных данных о работе
        if (works == null) {
          return {}; // Пропускаем запись без связи с таблицей works
        }
        
        // Проверяем наличие всех необходимых полей
        if (record['employee_id'] == null || record['hours'] == null || works['date'] == null) {
          return {}; // Пропускаем неполные записи
        }
        
        return {
          'id': record['id'],
          'work_id': record['work_id'],
          'employee_id': record['employee_id'],
          'hours': record['hours'],
          'date': works['date'],
          'object_id': works['object_id'] ?? '',
        };
      }).where((map) => map.isNotEmpty).toList(); // Отфильтровываем пустые записи
      
      // Фильтруем записи по датам (внутри периода)
      final filteredEntries = timesheetEntries.where((entry) {
        final date = DateTime.tryParse(entry['date']);
        if (date == null) return false;
        
        return date.isAfter(startDate.subtract(const Duration(days: 1))) && 
               date.isBefore(endDate.add(const Duration(days: 1)));
      }).toList();
      
      // Формируем суммы часов по каждому сотруднику
      final Map<String, double> employeeHours = {};
      
      for (var entry in filteredEntries) {
        final employeeId = entry['employee_id'] as String;
        
        // Проверка на null и безопасное преобразование в double
        final hoursValue = entry['hours'];
        if (hoursValue == null) continue;
        
        final hours = (hoursValue is num) ? hoursValue.toDouble() : 0.0;
        employeeHours[employeeId] = (employeeHours[employeeId] ?? 0.0) + hours;
      }
      
      // Получаем данные о всех задействованных сотрудниках
      final employeeIds = employeeHours.keys.toList();
      if (employeeIds.isEmpty) {
        return []; // Если нет сотрудников с часами, возвращаем пустой список
      }
      
      final employeesData = await _client
          .from('employees')
          .select('id, hourly_rate')
          .filter('id', 'in', employeeIds);
      
      // Преобразуем данные о сотрудниках в Map для быстрого доступа
      final employeeRates = <String, double>{};
      
      for (var emp in employeesData) {
        final id = emp['id'] as String?;
        final rateValue = emp['hourly_rate'];
        
        if (id != null && rateValue != null && rateValue is num) {
          employeeRates[id] = rateValue.toDouble();
        }
      }
      
      // Получаем данные об объектах (для командировочных)
      final objectsData = await _client.from('objects').select('id, business_trip_amount');
      final objectTripMap = <String, double>{};
      for (var obj in objectsData) {
        final id = obj['id'] as String?;
        final amount = obj['business_trip_amount'];
        if (id != null && amount != null && amount is num && amount > 0) {
          objectTripMap[id] = amount.toDouble();
        }
      }
      // Группируем смены по сотруднику и объекту
      final Map<String, Map<String, int>> employeeObjectShifts = {};
      for (var entry in filteredEntries) {
        final employeeId = entry['employee_id'] as String;
        final objectId = entry['object_id'] as String?;
        if (objectId == null || objectId.isEmpty) continue;
        employeeObjectShifts.putIfAbsent(employeeId, () => {});
        employeeObjectShifts[employeeId]![objectId] = (employeeObjectShifts[employeeId]![objectId] ?? 0) + 1;
      }
      // Формируем список расчетов ФОТ
      final calculations = <PayrollCalculation>[];
      for (var employeeId in employeeHours.keys) {
        final hours = employeeHours[employeeId] ?? 0.0;
        final hourlyRate = employeeRates[employeeId] ?? 0.0;
        final baseSalary = hours * hourlyRate;
        final bonusesTotal = await getEmployeeBonusesForMonth(employeeId, month);
        final penaltiesTotal = await getEmployeePenaltiesForMonth(employeeId, month);
        final deductionsTotal = await getEmployeeDeductionsForMonth(employeeId, month);
        // --- Расчёт командировочных ---
        double businessTripTotal = 0;
        final objectShifts = employeeObjectShifts[employeeId] ?? {};
        objectShifts.forEach((objectId, shiftCount) {
          final tripAmount = objectTripMap[objectId] ?? 0;
          if (tripAmount > 0) {
            businessTripTotal += tripAmount * shiftCount;
          }
        });
        // --- Итоговые суммы ---
        final grossSalary = baseSalary + bonusesTotal + businessTripTotal - penaltiesTotal;
        final netSalary = grossSalary - deductionsTotal;
        final calculation = PayrollCalculation(
          employeeId: employeeId,
          periodMonth: startDate,
          hoursWorked: hours,
          hourlyRate: hourlyRate,
          baseSalary: baseSalary,
          bonusesTotal: bonusesTotal,
          penaltiesTotal: penaltiesTotal,
          deductionsTotal: deductionsTotal,
          businessTripTotal: businessTripTotal,
          grossSalary: grossSalary,
          netSalary: netSalary,
        );
        calculations.add(calculation);
      }
      return calculations;
    } catch (e) {
      throw Exception('Ошибка получения данных ФОТ: $e');
    }
  }

  @override
  Future<double> getEmployeeBonusesForMonth(String employeeId, DateTime month) async {
    // Таблица еще не создана, возвращаем 0
    return 0.0;
  }

  @override
  Future<double> getEmployeePenaltiesForMonth(String employeeId, DateTime month) async {
    // Таблица еще не создана, возвращаем 0
    return 0.0;
  }

  @override
  Future<double> getEmployeeDeductionsForMonth(String employeeId, DateTime month) async {
    // Таблица еще не создана, возвращаем 0
    return 0.0;
  }
} 