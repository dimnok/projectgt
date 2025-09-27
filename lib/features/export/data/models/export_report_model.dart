import 'package:freezed_annotation/freezed_annotation.dart';

part 'export_report_model.freezed.dart';
part 'export_report_model.g.dart';

/// Data-модель строки отчета по работам для хранения и передачи данных между слоями data и источником данных.
@freezed
abstract class ExportReportModel with _$ExportReportModel {
  /// Создаёт data-модель строки отчета.
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
  const factory ExportReportModel({
    /// Дата смены.
    @JsonKey(name: 'work_date') required DateTime workDate,

    /// Название объекта.
    @JsonKey(name: 'object_name') required String objectName,

    /// Название договора.
    @JsonKey(name: 'contract_name') required String contractName,

    /// Система.
    required String system,

    /// Подсистема.
    required String subsystem,

    /// Номер позиции в смете.
    @JsonKey(name: 'position_number') required String positionNumber,

    /// Наименование работы.
    @JsonKey(name: 'work_name') required String workName,

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
    @JsonKey(name: 'employee_name') String? employeeName,

    /// Количество часов.
    num? hours,

    /// Список материалов (JSON строка).
    String? materials,
  }) = _ExportReportModel;

  /// Создаёт data-модель строки отчета из JSON.
  factory ExportReportModel.fromJson(Map<String, dynamic> json) =>
      _$ExportReportModelFromJson(json);
}
