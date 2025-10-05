import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:projectgt/data/models/business_trip_rate_model.dart';

/// DataSource для работы с ставками командировочных выплат в Supabase.
///
/// Предоставляет методы для CRUD операций с таблицей business_trip_rates.
/// Все методы работают с [BusinessTripRateModel] и возвращают Future.
///
/// Пример использования:
/// ```dart
/// final dataSource = BusinessTripRateDataSource();
/// final rates = await dataSource.getAllRates();
/// ```
class BusinessTripRateDataSource {
  /// Клиент Supabase для выполнения запросов к БД.
  final SupabaseClient _client = Supabase.instance.client;

  /// Название таблицы в БД.
  static const String _tableName = 'business_trip_rates';

  /// Получает все ставки командировочных выплат.
  ///
  /// Возвращает список всех ставок, отсортированных по дате создания (новые первыми).
  ///
  /// Пример:
  /// ```dart
  /// final rates = await dataSource.getAllRates();
  /// ```
  Future<List<BusinessTripRateModel>> getAllRates() async {
    try {
      final response = await _client
          .from(_tableName)
          .select()
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => BusinessTripRateModel.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Ошибка получения ставок командировочных: $e');
    }
  }

  /// Получает ставки командировочных для конкретного объекта.
  ///
  /// [objectId] — идентификатор объекта.
  /// Возвращает список ставок для указанного объекта, отсортированных по дате начала действия.
  ///
  /// Пример:
  /// ```dart
  /// final rates = await dataSource.getRatesByObjectId('object-id');
  /// ```
  Future<List<BusinessTripRateModel>> getRatesByObjectId(
      String objectId) async {
    try {
      final response = await _client
          .from(_tableName)
          .select()
          .eq('object_id', objectId)
          .order('valid_from', ascending: false);

      return (response as List)
          .map((json) => BusinessTripRateModel.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Ошибка получения ставок для объекта $objectId: $e');
    }
  }

  /// Получает активную ставку командировочных для объекта на указанную дату.
  ///
  /// [objectId] — идентификатор объекта.
  /// [date] — дата, на которую нужно получить ставку.
  /// Возвращает ставку, действующую на указанную дату, или null если такой нет.
  ///
  /// Пример:
  /// ```dart
  /// final rate = await dataSource.getActiveRateForDate('object-id', DateTime.now());
  /// ```
  Future<BusinessTripRateModel?> getActiveRateForDate(
    String objectId,
    DateTime date,
  ) async {
    try {
      final dateStr = date.toIso8601String().split('T')[0]; // YYYY-MM-DD

      final response = await _client
          .from(_tableName)
          .select()
          .eq('object_id', objectId)
          .lte('valid_from', dateStr)
          .or('valid_to.is.null,valid_to.gte.$dateStr')
          .order('valid_from', ascending: false)
          .limit(1)
          .maybeSingle();

      if (response == null) return null;

      return BusinessTripRateModel.fromJson(response);
    } catch (e) {
      throw Exception(
          'Ошибка получения активной ставки для объекта $objectId на дату $date: $e');
    }
  }

  /// Получает активную ставку командировочных для сотрудника на объекте на указанную дату.
  ///
  /// Алгоритм (приоритет):
  /// 1. Ищет индивидуальную ставку для конкретного сотрудника (employee_id = employeeId)
  /// 2. Если нет индивидуальной, ищет общую ставку для объекта (employee_id IS NULL)
  /// 3. Фильтрует по датам: valid_from <= date AND (valid_to IS NULL OR valid_to >= date)
  /// 4. Проверяет minimum_hours (если hours < minimum_hours, возвращает null)
  /// 5. Сортирует по valid_from DESC (самая новая ставка первой)
  ///
  /// [employeeId] — идентификатор сотрудника.
  /// [objectId] — идентификатор объекта.
  /// [date] — дата, на которую нужно получить ставку.
  /// [hours] — количество отработанных часов (для проверки minimum_hours).
  /// Возвращает активную ставку или null.
  ///
  /// Пример:
  /// ```dart
  /// final rate = await dataSource.getActiveRateForEmployeeAndDate(
  ///   'employee-id', 'object-id', DateTime.now(), 8.0
  /// );
  /// ```
  Future<BusinessTripRateModel?> getActiveRateForEmployeeAndDate(
    String employeeId,
    String objectId,
    DateTime date,
    double hours,
  ) async {
    try {
      final dateStr = date.toIso8601String().split('T')[0]; // YYYY-MM-DD

      // Сначала ищем индивидуальную ставку для сотрудника
      final individualResponse = await _client
          .from(_tableName)
          .select()
          .eq('object_id', objectId)
          .eq('employee_id', employeeId)
          .lte('valid_from', dateStr)
          .or('valid_to.is.null,valid_to.gte.$dateStr')
          .order('valid_from', ascending: false)
          .limit(1)
          .maybeSingle();

      if (individualResponse != null) {
        final rate = BusinessTripRateModel.fromJson(individualResponse);
        // Проверяем минимальное количество часов
        if (hours >= rate.minimumHours) {
          return rate;
        }
        return null; // Не достигнут минимум часов
      }

      // Если нет индивидуальной ставки, ищем общую для объекта
      final generalResponse = await _client
          .from(_tableName)
          .select()
          .eq('object_id', objectId)
          .filter('employee_id', 'is', 'null') // Проверка employee_id IS NULL
          .lte('valid_from', dateStr)
          .or('valid_to.is.null,valid_to.gte.$dateStr')
          .order('valid_from', ascending: false)
          .limit(1)
          .maybeSingle();

      if (generalResponse == null) return null;

      final rate = BusinessTripRateModel.fromJson(generalResponse);
      // Проверяем минимальное количество часов
      if (hours >= rate.minimumHours) {
        return rate;
      }
      return null; // Не достигнут минимум часов
    } catch (e) {
      throw Exception(
          'Ошибка получения активной ставки для сотрудника $employeeId на объекте $objectId на дату $date: $e');
    }
  }

  /// Получает текущую активную ставку для объекта.
  ///
  /// [objectId] — идентификатор объекта.
  /// Возвращает ставку, действующую на текущую дату, или null если такой нет.
  ///
  /// Пример:
  /// ```dart
  /// final rate = await dataSource.getCurrentRate('object-id');
  /// ```
  Future<BusinessTripRateModel?> getCurrentRate(String objectId) async {
    return getActiveRateForDate(objectId, DateTime.now());
  }

  /// Создаёт новую ставку командировочных выплат.
  ///
  /// [rate] — модель ставки для создания.
  /// Возвращает созданную ставку с заполненными системными полями.
  ///
  /// Пример:
  /// ```dart
  /// final newRate = BusinessTripRateModel(
  ///   id: 'new-id',
  ///   objectId: 'object-id',
  ///   rate: 1500.0,
  ///   validFrom: DateTime.now(),
  /// );
  /// final created = await dataSource.createRate(newRate);
  /// ```
  Future<BusinessTripRateModel> createRate(BusinessTripRateModel rate) async {
    try {
      final data = rate.toJson();

      // Убираем системные поля, которые заполняются автоматически
      data.remove('created_at');
      data.remove('updated_at');

      // Добавляем created_by если есть текущий пользователь
      final user = _client.auth.currentUser;
      if (user != null) {
        data['created_by'] = user.id;
      }

      final response =
          await _client.from(_tableName).insert(data).select().single();

      return BusinessTripRateModel.fromJson(response);
    } catch (e) {
      throw Exception('Ошибка создания ставки командировочных: $e');
    }
  }

  /// Обновляет существующую ставку командировочных выплат.
  ///
  /// [rate] — модель ставки с обновлёнными данными.
  /// Возвращает обновлённую ставку.
  ///
  /// Пример:
  /// ```dart
  /// final updatedRate = existingRate.copyWith(rate: 2000.0);
  /// final result = await dataSource.updateRate(updatedRate);
  /// ```
  Future<BusinessTripRateModel> updateRate(BusinessTripRateModel rate) async {
    try {
      final data = rate.toJson();

      // Убираем поля, которые не должны обновляться
      data.remove('id');
      data.remove('created_at');
      data.remove('created_by');
      data.remove('updated_at'); // Обновляется автоматически триггером

      final response = await _client
          .from(_tableName)
          .update(data)
          .eq('id', rate.id)
          .select()
          .single();

      return BusinessTripRateModel.fromJson(response);
    } catch (e) {
      throw Exception('Ошибка обновления ставки командировочных: $e');
    }
  }

  /// Удаляет ставку командировочных выплат.
  ///
  /// [id] — идентификатор ставки для удаления.
  ///
  /// Пример:
  /// ```dart
  /// await dataSource.deleteRate('rate-id');
  /// ```
  Future<void> deleteRate(String id) async {
    try {
      await _client.from(_tableName).delete().eq('id', id);
    } catch (e) {
      throw Exception('Ошибка удаления ставки командировочных: $e');
    }
  }

  /// Получает ставку по идентификатору.
  ///
  /// [id] — идентификатор ставки.
  /// Возвращает ставку или null, если не найдена.
  ///
  /// Пример:
  /// ```dart
  /// final rate = await dataSource.getRateById('rate-id');
  /// ```
  Future<BusinessTripRateModel?> getRateById(String id) async {
    try {
      final response =
          await _client.from(_tableName).select().eq('id', id).maybeSingle();

      if (response == null) return null;

      return BusinessTripRateModel.fromJson(response);
    } catch (e) {
      throw Exception('Ошибка получения ставки по ID $id: $e');
    }
  }

  /// Проверяет, есть ли пересекающиеся периоды для объекта и сотрудника.
  ///
  /// [objectId] — идентификатор объекта.
  /// [employeeId] — идентификатор сотрудника.
  /// [validFrom] — дата начала нового периода.
  /// [validTo] — дата окончания нового периода (может быть null).
  /// [excludeId] — идентификатор ставки, которую нужно исключить из проверки (для обновления).
  ///
  /// Возвращает true, если есть пересекающиеся периоды.
  ///
  /// Пример:
  /// ```dart
  /// final hasOverlap = await dataSource.hasOverlappingPeriods(
  ///   'object-id',
  ///   'employee-id',
  ///   DateTime(2025, 1, 1),
  ///   DateTime(2025, 12, 31),
  /// );
  /// ```
  Future<bool> hasOverlappingPeriods(
    String objectId,
    String? employeeId,
    DateTime validFrom,
    DateTime? validTo, [
    String? excludeId,
  ]) async {
    try {
      var query =
          _client.from(_tableName).select('id').eq('object_id', objectId);

      // Фильтруем по сотруднику, если указан
      if (employeeId != null) {
        query = query.eq('employee_id', employeeId);
      }

      // Исключаем текущую ставку при обновлении
      if (excludeId != null) {
        query = query.neq('id', excludeId);
      }

      final fromStr = validFrom.toIso8601String().split('T')[0];
      final toStr = validTo?.toIso8601String().split('T')[0];

      // Проверяем пересечения периодов
      if (validTo != null) {
        // Новый период имеет конечную дату
        query = query.or(
            'and(valid_from.lte.$toStr,or(valid_to.is.null,valid_to.gte.$fromStr))');
      } else {
        // Новый период бессрочный
        query = query.or('valid_to.is.null,valid_to.gte.$fromStr');
      }

      final response = await query.limit(1);
      return (response as List).isNotEmpty;
    } catch (e) {
      throw Exception('Ошибка проверки пересекающихся периодов: $e');
    }
  }
}
