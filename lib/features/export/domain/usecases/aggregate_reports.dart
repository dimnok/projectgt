import '../entities/export_report.dart';

/// Уровни агрегации данных выгрузки.
enum AggregationLevel {
  /// Детальная группировка по всем полям: объект + договор + система + подсистема + участок + этаж + позиция + работа + ед. изм.
  detailed,

  /// Сокращённая группировка по основным полям: объект + договор + система + подсистема + позиция + работа
  summary,
}

/// Внутренняя модель для агрегированной записи.
class _AggregatedReportData {
  final String objectName;
  final String contractName;
  final String system;
  final String subsystem;
  final String section;
  final String floor;
  final String positionNumber;
  final String workName;
  final String unit;

  DateTime? firstWorkDate;
  num quantitySum = 0;
  double? priceConsistent;
  double? totalSum;

  _AggregatedReportData({
    required this.objectName,
    required this.contractName,
    required this.system,
    required this.subsystem,
    required this.section,
    required this.floor,
    required this.positionNumber,
    required this.workName,
    required this.unit,
  });

  /// Генерирует ключ для группировки (детальный).
  static String generateDetailedKey({
    required String objectName,
    required String contractName,
    required String system,
    required String subsystem,
    required String section,
    required String floor,
    required String positionNumber,
    required String workName,
    required String unit,
  }) =>
      [
        objectName,
        contractName,
        system,
        subsystem,
        section,
        floor,
        positionNumber,
        workName,
        unit,
      ].join('||');

  /// Генерирует ключ для группировки (сокращённый).
  static String generateSummaryKey({
    required String objectName,
    required String contractName,
    required String system,
    required String subsystem,
    required String positionNumber,
    required String workName,
  }) =>
      [
        objectName,
        contractName,
        system,
        subsystem,
        positionNumber,
        workName,
      ].join('||');
}

/// Агрегирует отчёты по заданному уровню детализации.
///
/// [level] определяет какие поля использовать для группировки:
/// - [AggregationLevel.detailed] — по всем 9 полям (по умолчанию)
/// - [AggregationLevel.summary] — по 6 основным полям
///
/// При агрегации:
/// - Суммируются количества
/// - Цена сохраняется, если одинаковая, иначе null
/// - Суммируется итоговая сумма
/// - Берётся первая дата работы
/// - Сотрудник и часы очищаются (агрегированные данные)
List<ExportReport> aggregateReports(
  List<ExportReport> reports, {
  AggregationLevel level = AggregationLevel.detailed,
}) {
  if (reports.isEmpty) return [];

  final Map<String, _AggregatedReportData> aggregated = {};

  for (final report in reports) {
    // Выбираем ключ в зависимости от уровня агрегации
    final key = level == AggregationLevel.detailed
        ? _AggregatedReportData.generateDetailedKey(
            objectName: report.objectName,
            contractName: report.contractName,
            system: report.system,
            subsystem: report.subsystem,
            section: report.section,
            floor: report.floor,
            positionNumber: report.positionNumber,
            workName: report.workName,
            unit: report.unit,
          )
        : _AggregatedReportData.generateSummaryKey(
            objectName: report.objectName,
            contractName: report.contractName,
            system: report.system,
            subsystem: report.subsystem,
            positionNumber: report.positionNumber,
            workName: report.workName,
          );

    if (!aggregated.containsKey(key)) {
      final data = _AggregatedReportData(
        objectName: report.objectName,
        contractName: report.contractName,
        system: report.system,
        subsystem: report.subsystem,
        section: report.section,
        floor: report.floor,
        positionNumber: report.positionNumber,
        workName: report.workName,
        unit: report.unit,
      );

      data.firstWorkDate = report.workDate;
      data.quantitySum = report.quantity;
      data.priceConsistent = report.price;
      data.totalSum = report.total?.toDouble();

      aggregated[key] = data;
    } else {
      final current = aggregated[key]!;

      // Суммируем количество
      current.quantitySum += report.quantity;

      // Проверяем консистентность цены
      if (current.priceConsistent != null && report.price != null) {
        if (current.priceConsistent != report.price) {
          current.priceConsistent = null;
        }
      } else if (report.price == null) {
        current.priceConsistent = null;
      }

      // Суммируем итоговую сумму
      if (report.total != null) {
        current.totalSum = (current.totalSum ?? 0) + report.total!.toDouble();
      }
    }
  }

  // Преобразуем агрегированные данные в список отчётов
  return aggregated.values.map((data) {
    return ExportReport(
      workDate: data.firstWorkDate ?? DateTime.now(),
      objectName: data.objectName,
      contractName: data.contractName,
      system: data.system,
      subsystem: data.subsystem,
      positionNumber: data.positionNumber,
      workName: data.workName,
      section: data.section,
      floor: data.floor,
      unit: data.unit,
      quantity: data.quantitySum,
      price: data.priceConsistent,
      total: data.totalSum,
      employeeName: null, // Очищаем при агрегации
      hours: null,
      materials: null,
    );
  }).toList();
}
