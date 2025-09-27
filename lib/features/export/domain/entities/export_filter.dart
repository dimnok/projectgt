import 'package:freezed_annotation/freezed_annotation.dart';

part 'export_filter.freezed.dart';
part 'export_filter.g.dart';

/// Сущность "Фильтр выгрузки".
///
/// Описывает параметры фильтрации для формирования отчета по работам.
@freezed
abstract class ExportFilter with _$ExportFilter {
  /// Создаёт сущность фильтра выгрузки.
  ///
  /// [dateFrom] — дата начала периода
  /// [dateTo] — дата окончания периода
  /// [objectIds] — список идентификаторов объектов (опционально)
  /// [contractIds] — список идентификаторов договоров (опционально)
  /// [systems] — список систем (опционально)
  /// [subsystems] — список подсистем (опционально)
  const factory ExportFilter({
    /// Дата начала периода.
    required DateTime dateFrom,

    /// Дата окончания периода.
    required DateTime dateTo,

    /// Список идентификаторов объектов для фильтрации.
    @Default([]) List<String> objectIds,

    /// Список идентификаторов договоров для фильтрации.
    @Default([]) List<String> contractIds,

    /// Список систем для фильтрации.
    @Default([]) List<String> systems,

    /// Список подсистем для фильтрации.
    @Default([]) List<String> subsystems,
  }) = _ExportFilter;

  /// Создаёт сущность из JSON.
  factory ExportFilter.fromJson(Map<String, dynamic> json) =>
      _$ExportFilterFromJson(json);
}
