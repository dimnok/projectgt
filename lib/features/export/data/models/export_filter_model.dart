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
  /// [objectIds] — список идентификаторов объектов (опционально)
  /// [contractIds] — список идентификаторов договоров (опционально)
  /// [systems] — список систем (опционально)
  /// [subsystems] — список подсистем (опционально)
  const factory ExportFilterModel({
    /// Дата начала периода.
    @JsonKey(name: 'date_from') required DateTime dateFrom,
    /// Дата окончания периода.
    @JsonKey(name: 'date_to') required DateTime dateTo,
    /// Список идентификаторов объектов для фильтрации.
    @JsonKey(name: 'object_ids') @Default([]) List<String> objectIds,
    /// Список идентификаторов договоров для фильтрации.
    @JsonKey(name: 'contract_ids') @Default([]) List<String> contractIds,
    /// Список систем для фильтрации.
    @Default([]) List<String> systems,
    /// Список подсистем для фильтрации.
    @Default([]) List<String> subsystems,
  }) = _ExportFilterModel;

  /// Создаёт data-модель фильтра выгрузки из JSON.
  factory ExportFilterModel.fromJson(Map<String, dynamic> json) => _$ExportFilterModelFromJson(json);
} 