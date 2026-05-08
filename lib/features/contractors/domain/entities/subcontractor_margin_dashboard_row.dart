import 'package:flutter/foundation.dart';

/// Сводка «Подрядчики»: объект × договор × [Estimate.estimateTitle] (и суб в строке).
///
/// **План:** [ourAmount] — полная сумма `SUM(estimates.total)` по группе; при нескольких
/// субах в одной смете дублируется на строках — в итогах UI берётся один раз на группу.
/// [subcontractorPlannedAmount] — план оплаты субу по расценкам по строке группы.
///
/// **Факт** (закрытые смены): [factOwnAmount], [factSubcontractorRevenueAmount],
/// [factSubcontractorCostAmount] одинаковы для всех строк той же группы (объект, договор,
/// название сметы); в итогах — как для [ourAmount].
@immutable
class SubcontractorMarginDashboardRow {
  /// Создаёт строку сводки.
  const SubcontractorMarginDashboardRow({
    required this.objectId,
    required this.contractId,
    required this.estimateTitle,
    this.contractorId,
    required this.ourAmount,
    required this.subcontractorPlannedAmount,
    required this.unpricedLines,
    this.factOwnAmount = 0,
    this.factSubcontractorRevenueAmount = 0,
    this.factSubcontractorCostAmount = 0,
  });

  /// Идентификатор строительного объекта.
  final String objectId;

  /// Идентификатор договора; может отсутствовать у позиции сметы.
  final String? contractId;

  /// Название сметы (группировка как в модуле смет).
  final String estimateTitle;

  /// Подрядчик с максимальной строкой плана в группе; `null` если нет расценок.
  final String? contractorId;

  /// Сумма «с заказчика» по смете на объём в сменах.
  final double ourAmount;

  /// Плановая сумма оплаты подрядчику по расценке.
  final double subcontractorPlannedAmount;

  /// Число позиций сметы в группе без расценки суб (план 0).
  final int unpricedLines;

  /// Сумма `work_items.total` по закрытым сменам для строк без подрядчика, группа сметы.
  final double factOwnAmount;

  /// Сумма `work_items.total` по закрытым сменам для строк с подрядчиком (выручка с заказчика).
  final double factSubcontractorRevenueAmount;

  /// Оплата подрядчику по факту: `quantity × unit_price` из [estimate_contractor_prices].
  final double factSubcontractorCostAmount;

  /// Плановая маржа: наша сумма минус стоимость подрядчика.
  double get plannedMargin => ourAmount - subcontractorPlannedAmount;

  /// Маржа по факту: выручка (свои + суб) минус оплата субу по расценке.
  double get factMargin =>
      factOwnAmount +
      factSubcontractorRevenueAmount -
      factSubcontractorCostAmount;

  /// Доля маржи от [ourAmount], 0..100; [null] если [ourAmount] == 0.
  double? get marginSharePercent {
    if (ourAmount == 0) {
      return null;
    }
    return (plannedMargin / ourAmount) * 100;
  }

  /// Доля [factMargin] от суммарной выручки по факту; [null] если выручка 0.
  double? get factMarginSharePercent {
    final rev = factOwnAmount + factSubcontractorRevenueAmount;
    if (rev == 0) {
      return null;
    }
    return (factMargin / rev) * 100;
  }
}
