import 'package:freezed_annotation/freezed_annotation.dart';

part 'available_filters.freezed.dart';
part 'available_filters.g.dart';

/// Сущность, содержащая списки ID объектов, контрагентов и договоров,
/// для которых есть данные в выбранном периоде.
@freezed
abstract class AvailableFilters with _$AvailableFilters {
  /// Создаёт экземпляр [AvailableFilters].
  const factory AvailableFilters({
    /// Список ID объектов.
    @Default({}) Set<String> objectIds,

    /// Список ID контрагентов.
    @Default({}) Set<String> contractorIds,

    /// Список ID договоров.
    @Default({}) Set<String> contractIds,
  }) = _AvailableFilters;

  /// Создаёт экземпляр [AvailableFilters] из JSON.
  factory AvailableFilters.fromJson(Map<String, dynamic> json) =>
      _$AvailableFiltersFromJson(json);
}
