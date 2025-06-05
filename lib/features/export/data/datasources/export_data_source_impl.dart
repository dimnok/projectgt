import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:logger/logger.dart';
import '../models/export_filter_model.dart';
import '../models/export_report_model.dart';
import 'export_data_source.dart';

/// Реализация источника данных для работы с выгрузкой через Supabase.
class ExportDataSourceImpl implements ExportDataSource {
  /// Клиент Supabase для работы с базой данных.
  final SupabaseClient supabaseClient;
  /// Логгер для отслеживания операций.
  final Logger logger;

  /// Создаёт реализацию источника данных выгрузки.
  ExportDataSourceImpl({
    required this.supabaseClient,
    required this.logger,
  });

  @override
  Future<List<ExportReportModel>> getExportData(ExportFilterModel filter) async {
    try {
      logger.i('Получение данных для выгрузки с фильтром: $filter');

      // Используем стандартные методы Supabase, получаем только work_items
      var query = supabaseClient
          .from('works')
          .select('''
            date,
            objects!inner(name),
            work_items!inner(
              system,
              subsystem,
              name,
              section,
              floor,
              unit,
              quantity,
              price,
              total,
              estimates!inner(
                contracts!inner(number)
              )
            )
          ''')
          .gte('date', filter.dateFrom.toIso8601String())
          .lte('date', filter.dateTo.toIso8601String());

      // Применяем дополнительные фильтры
      if (filter.objectId != null) {
        query = query.eq('object_id', filter.objectId!);
      }

      if (filter.contractId != null) {
        query = query.eq('work_items.estimates.contracts.id', filter.contractId!);
      }

      if (filter.system != null) {
        query = query.eq('work_items.system', filter.system!);
      }

      if (filter.subsystem != null) {
        query = query.eq('work_items.subsystem', filter.subsystem!);
      }

      // Добавляем сортировку и выполняем запрос
      final response = await query.order('date');

      // Убираем ненужную проверку на null
      final List<dynamic> data = response as List<dynamic>;
      logger.i('Получено ${data.length} записей для выгрузки');

      // Преобразуем данные в нужный формат
      final List<ExportReportModel> reports = [];
      
      for (final workData in data) {
        final work = workData as Map<String, dynamic>;
        final workDate = DateTime.parse(work['date'] as String);
        final objectName = (work['objects'] as Map<String, dynamic>)['name'] as String;
        
        final workItems = work['work_items'] as List<dynamic>? ?? [];

        // Создаем записи только для work_items (работы)
        for (final workItemData in workItems) {
          final workItem = workItemData as Map<String, dynamic>;
          final estimates = workItem['estimates'] as Map<String, dynamic>?;
          final contracts = estimates?['contracts'] as Map<String, dynamic>?;
          final contractNumber = contracts?['number'] as String? ?? '';
          
          reports.add(ExportReportModel(
            workDate: workDate,
            objectName: objectName,
            contractName: contractNumber,
            system: workItem['system'] as String? ?? '',
            subsystem: workItem['subsystem'] as String? ?? '',
            workName: workItem['name'] as String? ?? '',
            section: workItem['section'] as String? ?? '',
            floor: workItem['floor'] as String? ?? '',
            unit: workItem['unit'] as String? ?? '',
            quantity: workItem['quantity'] as num? ?? 0,
            price: (workItem['price'] as num?)?.toDouble(),
            total: (workItem['total'] as num?)?.toDouble(),
            employeeName: null,
            hours: null,
            materials: null,
          ));
        }
      }

      logger.i('Обработано ${reports.length} записей для выгрузки');
      
      // Группируем записи по всем полям кроме quantity
      final Map<String, ExportReportModel> groupedReports = {};
      
      for (final report in reports) {
        // Создаем ключ группировки из всех полей кроме quantity, total и workDate
        final groupKey = '${report.objectName}_'
            '${report.contractName}_'
            '${report.system}_'
            '${report.subsystem}_'
            '${report.workName}_'
            '${report.section}_'
            '${report.floor}_'
            '${report.unit}_'
            '${report.price ?? 0}';
        
        if (groupedReports.containsKey(groupKey)) {
          // Если запись с таким ключом уже есть, суммируем quantity
          final existing = groupedReports[groupKey]!;
          final newQuantity = existing.quantity + report.quantity;
          final newTotal = report.price != null ? newQuantity * report.price! : null;
          
          groupedReports[groupKey] = existing.copyWith(
            quantity: newQuantity,
            total: newTotal,
          );
        } else {
          // Если записи с таким ключом нет, добавляем новую
          groupedReports[groupKey] = report;
        }
      }
      
      final groupedList = groupedReports.values.toList();
      logger.i('После группировки: ${groupedList.length} записей (было ${reports.length})');
      
      return groupedList;
    } catch (e, stackTrace) {
      logger.e('Ошибка при получении данных для выгрузки', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getAvailableObjects() async {
    try {
      logger.i('Получение списка доступных объектов');

      final response = await supabaseClient
          .from('objects')
          .select('id, name')
          .order('name');

      logger.i('Получено ${response.length} объектов');
      return List<Map<String, dynamic>>.from(response);
    } catch (e, stackTrace) {
      logger.e('Ошибка при получении списка объектов', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getAvailableContracts() async {
    try {
      logger.i('Получение списка доступных договоров');

      final response = await supabaseClient
          .from('contracts')
          .select('id, name')
          .order('name');

      logger.i('Получено ${response.length} договоров');
      return List<Map<String, dynamic>>.from(response);
    } catch (e, stackTrace) {
      logger.e('Ошибка при получении списка договоров', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  @override
  Future<List<String>> getAvailableSystems() async {
    try {
      logger.i('Получение списка доступных систем');

      final response = await supabaseClient
          .from('work_items')
          .select('system')
          .not('system', 'is', null);

      final systems = response
          .map((item) => item['system'] as String)
          .toSet()
          .toList();

      systems.sort();
      logger.i('Получено ${systems.length} уникальных систем');
      return systems;
    } catch (e, stackTrace) {
      logger.e('Ошибка при получении списка систем', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  @override
  Future<List<String>> getAvailableSubsystems() async {
    try {
      logger.i('Получение списка доступных подсистем');

      final response = await supabaseClient
          .from('work_items')
          .select('subsystem')
          .not('subsystem', 'is', null);

      final subsystems = response
          .map((item) => item['subsystem'] as String)
          .toSet()
          .toList();

      subsystems.sort();
      logger.i('Получено ${subsystems.length} уникальных подсистем');
      return subsystems;
    } catch (e, stackTrace) {
      logger.e('Ошибка при получении списка подсистем', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }
} 