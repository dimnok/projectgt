import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:projectgt/features/tmc/data/models/tmc_json_utils.dart';
import 'package:projectgt/features/tmc/domain/entities/tmc_dashboard_stats.dart';

part 'tmc_dashboard_stats_model.freezed.dart';

/// Модель KPI дашборда ТМЦ из RPC [tmc_dashboard_stats].
@Freezed(fromJson: false, toJson: false)
abstract class TmcDashboardStatsModel with _$TmcDashboardStatsModel {
  /// Создаёт модель.
  const factory TmcDashboardStatsModel({
    @Default(0) int totalItems,
    @Default(0) num totalUnits,
    @Default(0) num inStock,
    @Default(0) num onObject,
    @Default(0) num issued,
    @Default(0) int inRepair,
    @Default(0) int needsRepair,
    @Default(0) int lost,
    @Default(0) int writtenOff,
    double? totalCost,
  }) = _TmcDashboardStatsModel;

  const TmcDashboardStatsModel._();

  /// Из JSON ответа RPC.
  factory TmcDashboardStatsModel.fromJson(Map<String, dynamic> json) =>
      TmcDashboardStatsModel(
        totalItems: tmcParseInt(json['total_items']),
        totalUnits: json['total_units'] ?? 0,
        inStock: json['in_stock'] ?? 0,
        onObject: json['on_object'] ?? 0,
        issued: json['issued'] ?? 0,
        inRepair: tmcParseInt(json['in_repair']),
        needsRepair: tmcParseInt(json['needs_repair']),
        lost: tmcParseInt(json['lost']),
        writtenOff: tmcParseInt(json['written_off']),
        totalCost: json['total_cost'] == null
            ? null
            : tmcParseDouble(json['total_cost']),
      );

  /// В доменную сущность.
  TmcDashboardStats toDomain() => TmcDashboardStats(
        totalItems: totalItems,
        totalUnits: totalUnits,
        inStock: inStock,
        onObject: onObject,
        issued: issued,
        inRepair: inRepair,
        needsRepair: needsRepair,
        lost: lost,
        writtenOff: writtenOff,
        totalCost: totalCost,
      );
}
