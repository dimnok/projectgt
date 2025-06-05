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
  /// [objectId] — идентификатор объекта (опционально)
  /// [contractId] — идентификатор договора (опционально)
  /// [system] — система (опционально)
  /// [subsystem] — подсистема (опционально)
  const factory ExportFilter({
    /// Дата начала периода.
    required DateTime dateFrom,
    /// Дата окончания периода.
    required DateTime dateTo,
    /// Идентификатор объекта для фильтрации.
    String? objectId,
    /// Идентификатор договора для фильтрации.
    String? contractId,
    /// Система для фильтрации.
    String? system,
    /// Подсистема для фильтрации.
    String? subsystem,
  }) = _ExportFilter;

  /// Создаёт сущность из JSON.
  factory ExportFilter.fromJson(Map<String, dynamic> json) => _$ExportFilterFromJson(json);
} 