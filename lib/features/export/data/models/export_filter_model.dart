import 'package:freezed_annotation/freezed_annotation.dart';

part 'export_filter_model.freezed.dart';
part 'export_filter_model.g.dart';

/// Data-модель фильтра выгрузки для хранения и передачи данных между слоями data и источником данных.
@freezed
abstract class ExportFilterModel with _$ExportFilterModel {
  /// Создаёт data-модель фильтра выгрузки.
  ///
  /// [dateFrom] — дата начала периода
  /// [dateTo] — дата окончания периода
  /// [objectId] — идентификатор объекта (опционально)
  /// [contractId] — идентификатор договора (опционально)
  /// [system] — система (опционально)
  /// [subsystem] — подсистема (опционально)
  const factory ExportFilterModel({
    /// Дата начала периода.
    @JsonKey(name: 'date_from') required DateTime dateFrom,
    /// Дата окончания периода.
    @JsonKey(name: 'date_to') required DateTime dateTo,
    /// Идентификатор объекта для фильтрации.
    @JsonKey(name: 'object_id') String? objectId,
    /// Идентификатор договора для фильтрации.
    @JsonKey(name: 'contract_id') String? contractId,
    /// Система для фильтрации.
    String? system,
    /// Подсистема для фильтрации.
    String? subsystem,
  }) = _ExportFilterModel;

  /// Создаёт data-модель фильтра выгрузки из JSON.
  factory ExportFilterModel.fromJson(Map<String, dynamic> json) => _$ExportFilterModelFromJson(json);
} 