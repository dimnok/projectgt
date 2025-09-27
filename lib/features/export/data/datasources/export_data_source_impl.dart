import 'package:supabase_flutter/supabase_flutter.dart';
// logger removed
import '../models/export_filter_model.dart';
import '../models/export_report_model.dart';
import 'export_data_source.dart';

/// Реализация источника данных для работы с выгрузкой через Supabase.
class ExportDataSourceImpl implements ExportDataSource {
  /// Клиент Supabase для работы с базой данных.
  final SupabaseClient supabaseClient;

  // logger removed

  /// Создаёт реализацию источника данных выгрузки.
  ExportDataSourceImpl({
    required this.supabaseClient,
  });

  @override
  Future<List<ExportReportModel>> getExportData(
      ExportFilterModel filter) async {
    try {
      // start

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
                number,
                contracts!inner(number)
              )
            )
          ''')
          .gte('date', filter.dateFrom.toIso8601String())
          .lte('date', filter.dateTo.toIso8601String());

      // Применяем фильтры по спискам
      if (filter.objectIds.isNotEmpty) {
        query = query.inFilter('object_id', filter.objectIds);
      }

      if (filter.contractIds.isNotEmpty) {
        query = query.inFilter(
            'work_items.estimates.contracts.id', filter.contractIds);
      }

      if (filter.systems.isNotEmpty) {
        query = query.inFilter('work_items.system', filter.systems);
      }

      if (filter.subsystems.isNotEmpty) {
        query = query.inFilter('work_items.subsystem', filter.subsystems);
      }

      // Добавляем сортировку и выполняем запрос
      final response = await query.order('date');

      // Убираем ненужную проверку на null
      final List<dynamic> data = response as List<dynamic>;
      // count

      // Преобразуем данные в нужный формат
      final List<ExportReportModel> reports = [];

      for (final workData in data) {
        final work = workData as Map<String, dynamic>;
        final workDate = DateTime.parse(work['date'] as String);
        final objectName =
            (work['objects'] as Map<String, dynamic>)['name'] as String;

        final workItems = work['work_items'] as List<dynamic>? ?? [];

        // Создаем записи только для work_items (работы)
        for (final workItemData in workItems) {
          final workItem = workItemData as Map<String, dynamic>;
          final estimates = workItem['estimates'] as Map<String, dynamic>?;
          final contracts = estimates?['contracts'] as Map<String, dynamic>?;
          final contractNumber = contracts?['number'] as String? ?? '';
          final positionNumber = estimates?['number'] as String? ?? '';

          reports.add(ExportReportModel(
            workDate: workDate,
            objectName: objectName,
            contractName: contractNumber,
            system: workItem['system'] as String? ?? '',
            subsystem: workItem['subsystem'] as String? ?? '',
            positionNumber: positionNumber,
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

      // processed

      // Группируем записи по всем полям кроме quantity, при этом учитываем дату (по дням)
      final Map<String, ExportReportModel> groupedReports = {};

      for (final report in reports) {
        // Создаем ключ группировки из всех полей кроме quantity и total,
        // НО с учётом даты (по дню), чтобы не смешивать суммы между разными датами
        final String dateKey = DateTime(
          report.workDate.year,
          report.workDate.month,
          report.workDate.day,
        ).toIso8601String();

        final groupKey = '${dateKey}_'
            '${report.objectName}_'
            '${report.contractName}_'
            '${report.system}_'
            '${report.subsystem}_'
            '${report.positionNumber}_'
            '${report.workName}_'
            '${report.section}_'
            '${report.floor}_'
            '${report.unit}_'
            '${report.price ?? 0}';

        if (groupedReports.containsKey(groupKey)) {
          // Если запись с таким ключом уже есть, суммируем quantity
          final existing = groupedReports[groupKey]!;
          final newQuantity = existing.quantity + report.quantity;
          final newTotal =
              report.price != null ? newQuantity * report.price! : null;

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
      // grouped

      return groupedList;
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getAvailableObjects() async {
    try {
      // get objects

      final response =
          await supabaseClient.from('objects').select('id, name').order('name');

      // objects count
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getAvailableContracts() async {
    try {
      // get contracts

      final response = await supabaseClient
          .from('contracts')
          .select('id, name')
          .order('name');

      // contracts count
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<List<String>> getAvailableSystems() async {
    try {
      // get systems

      final response = await supabaseClient
          .from('work_items')
          .select('system')
          .not('system', 'is', null);

      final systems = response
          .map((item) => item['system'] as String)
          .toSet()
          .toList()
        ..sort();

      // systems count
      return systems;
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<List<String>> getAvailableSubsystems() async {
    try {
      // get subsystems

      final response = await supabaseClient
          .from('work_items')
          .select('subsystem')
          .not('subsystem', 'is', null);

      final subsystems = response
          .map((item) => item['subsystem'] as String)
          .toSet()
          .toList()
        ..sort();

      // subsystems count
      return subsystems;
    } catch (e) {
      rethrow;
    }
  }
}
