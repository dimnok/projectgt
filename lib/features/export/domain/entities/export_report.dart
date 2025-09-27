import 'package:freezed_annotation/freezed_annotation.dart';

part 'export_report.freezed.dart';
part 'export_report.g.dart';

/// Сущность "Строка отчета по работам".
///
/// Описывает агрегированную строку данных для выгрузки.
@freezed
abstract class ExportReport with _$ExportReport {
  /// Создаёт сущность строки отчета.
  ///
  /// [workDate] — дата смены
  /// [objectName] — название объекта
  /// [contractName] — название договора
  /// [system] — система
  /// [subsystem] — подсистема
  /// [positionNumber] — номер позиции в смете
  /// [workName] — наименование работы
  /// [section] — секция
  /// [floor] — этаж
  /// [unit] — единица измерения
  /// [quantity] — количество
  /// [price] — цена за единицу
  /// [total] — итоговая сумма
  /// [employeeName] — имя сотрудника
  /// [hours] — количество часов
  /// [materials] — список материалов
  const factory ExportReport({
    /// Дата смены.
    required DateTime workDate,

    /// Название объекта.
    required String objectName,

    /// Название договора.
    required String contractName,

    /// Система.
    required String system,

    /// Подсистема.
    required String subsystem,

    /// Номер позиции в смете.
    required String positionNumber,

    /// Наименование работы.
    required String workName,

    /// Секция.
    required String section,

    /// Этаж.
    required String floor,

    /// Единица измерения.
    required String unit,

    /// Количество.
    required num quantity,

    /// Цена за единицу.
    double? price,

    /// Итоговая сумма.
    double? total,

    /// Имя сотрудника.
    String? employeeName,

    /// Количество часов.
    num? hours,

    /// Список материалов (JSON строка).
    String? materials,
  }) = _ExportReport;

  /// Создаёт сущность из JSON.
  factory ExportReport.fromJson(Map<String, dynamic> json) =>
      _$ExportReportFromJson(json);
}
