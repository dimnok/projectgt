import 'package:freezed_annotation/freezed_annotation.dart';

part 'tmc_dashboard_stats.freezed.dart';

/// KPI дашборда модуля ТМЦ.
@freezed
abstract class TmcDashboardStats with _$TmcDashboardStats {
  /// Создаёт [TmcDashboardStats].
  const factory TmcDashboardStats({
    /// Всего позиций каталога.
    @Default(0) int totalItems,

    /// Всего единиц (без списанных).
    @Default(0) num totalUnits,

    /// На складе.
    @Default(0) num inStock,

    /// На объекте.
    @Default(0) num onObject,

    /// Выдано.
    @Default(0) num issued,

    /// В ремонте.
    @Default(0) int inRepair,

    /// Требует ремонта.
    @Default(0) int needsRepair,

    /// Утеряно.
    @Default(0) int lost,

    /// Списано за текущий месяц.
    @Default(0) int writtenOff,

    /// Общая стоимость (null, если нет права view_cost).
    double? totalCost,
  }) = _TmcDashboardStats;
}
