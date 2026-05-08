import 'package:projectgt/domain/entities/estimate.dart';
import 'package:projectgt/features/contractors/presentation/providers/subcontractors_contractor_unit_prices_provider.dart';
import 'package:projectgt/features/contractors/presentation/providers/subcontractors_execution_progress_provider.dart';
import 'package:projectgt/features/contractors/presentation/widgets/subcontractors_estimate_table_mode.dart';
import 'package:projectgt/features/estimates/presentation/utils/estimate_sorter.dart';

/// Расчёты плана, расценки подрядчика и факта для таблицы «Подрядчики».
///
/// Не содержит виджетов и [BuildContext]; пригодно для юнит-тестов.
class SubcontractorsEstimateTableMath {
  /// Создаёт калькулятор для текущих карт цен и выполнения.
  const SubcontractorsEstimateTableMath({
    required this.subcontractorPricingByEstimateId,
    required this.executionByEstimateId,
  });

  /// Расценка и объём подрядчика по [Estimate.id].
  final Map<String, SubcontractorPricingForEstimate>?
  subcontractorPricingByEstimateId;

  /// Факт выполнения по [Estimate.id].
  final Map<String, SubcontractorExecutionProgress>? executionByEstimateId;

  /// Позиции, отображаемые в таблице (в режиме [SubcontractorsEstimateTableMode.execution]
  /// — только с ценой/объёмом суба или ненулевым фактом).
  List<Estimate> tableItems({
    required SubcontractorsEstimateTableMode mode,
    required List<Estimate> items,
  }) {
    if (mode == SubcontractorsEstimateTableMode.rates) {
      return items;
    }
    return items.where((estimate) {
      final hasPricing =
          subcontractorPricingByEstimateId?.containsKey(estimate.id) ?? false;
      final hasExecution =
          (executionByEstimateId?[estimate.id]?.completedQuantity ?? 0) > 0;
      return hasPricing || hasExecution;
    }).toList();
  }

  /// Сортировка ключей групп: пустые в конце, далее [String.compareTo] в нижнем регистре.
  static int compareEstimateTitleKeys(String a, String b) {
    if (a.isEmpty && b.isNotEmpty) return 1;
    if (a.isNotEmpty && b.isEmpty) return -1;
    return a.toLowerCase().compareTo(b.toLowerCase());
  }

  /// Ключ группировки: [Estimate.estimateTitle] без пробелов по краям.
  static String estimateTitleSortKey(Estimate e) =>
      e.estimateTitle?.trim() ?? '';

  /// Подпись группы для пустого ключа.
  static String estimateTitleLabel(String sortKey) =>
      sortKey.isEmpty ? 'Без названия сметы' : sortKey;

  /// Группы позиций по названию сметы; внутри группы — [EstimateSorter] по номеру.
  List<({String sortKey, List<Estimate> estimates})> buildEstimateTitleGroups(
    List<Estimate> source,
  ) {
    final byKey = <String, List<Estimate>>{};
    for (final e in source) {
      final k = estimateTitleSortKey(e);
      (byKey[k] ??= []).add(e);
    }
    final keys = byKey.keys.toList()..sort(compareEstimateTitleKeys);
    return [
      for (final k in keys)
        (
          sortKey: k,
          estimates: byKey[k]!..sort(EstimateSorter.compareByNumber),
        ),
    ];
  }

  /// Сумма плановых [Estimate.total] по позициям раздела.
  double sectionPlanTotalSum(List<Estimate> estimates) {
    return estimates.fold<double>(0, (a, e) => a + e.total);
  }

  /// Σ (расценка × объём суба, иначе сметный объём), только где расценка задана.
  double sectionSubcontractorMoneySum(List<Estimate> estimates) {
    final pricing = subcontractorPricingByEstimateId;
    if (pricing == null) return 0;
    var s = 0.0;
    for (final e in estimates) {
      final up = pricing[e.id]?.unitPrice;
      if (up == null) continue;
      final q = pricing[e.id]?.contractorQuantity ?? e.quantity;
      s += up * q;
    }
    return s;
  }

  /// Сумма плановых объёмов подрядчика по строкам (см. [effectiveSubQuantity]).
  double sectionSubcontractorQuantitySum(List<Estimate> estimates) {
    return estimates.fold<double>(
      0,
      (sum, estimate) => sum + (effectiveSubQuantity(estimate) ?? 0),
    );
  }

  /// True, если хотя бы у одной позиции задана расценка подрядчика.
  bool sectionHasAnySubcontractorPrice(List<Estimate> estimates) {
    final pricing = subcontractorPricingByEstimateId;
    if (pricing == null) return false;
    for (final e in estimates) {
      if (pricing[e.id]?.unitPrice != null) return true;
    }
    return false;
  }

  /// Объём строки суба: явный объём подрядчика или сметный, если задана только расценка.
  double? effectiveSubQuantity(Estimate e) {
    final m = subcontractorPricingByEstimateId;
    if (m == null) return null;
    final p = m[e.id];
    if (p?.contractorQuantity != null) return p!.contractorQuantity;
    if (p?.unitPrice != null) return e.quantity;
    return null;
  }

  /// Цена подрядчика за единицу по позиции или null.
  double? subUnitPrice(Estimate e) =>
      subcontractorPricingByEstimateId?[e.id]?.unitPrice;

  /// Сумма по строке: расценка × объём суба (или сметный объём).
  double? subLineAmount(Estimate e) {
    final up = subUnitPrice(e);
    if (up == null) return null;
    final q =
        subcontractorPricingByEstimateId?[e.id]?.contractorQuantity ??
        e.quantity;
    return up * q;
  }

  /// Фактически выполненное количество по позиции.
  double completedQuantity(Estimate e) {
    return executionByEstimateId?[e.id]?.completedQuantity ?? 0;
  }

  /// Сумма выполнения в деньгах (факт × расценка), если расценка известна.
  double? completedAmount(Estimate e) {
    final up = subUnitPrice(e);
    if (up == null) return null;
    return up * completedQuantity(e);
  }

  /// Остаток объёма: план подрядчика минус факт.
  ///
  /// [null], только если план не задан ([effectiveSubQuantity] == [null]).
  /// План **0** — валидное значение: показывается отрицательный остаток при факте больше нуля
  /// (допработка без объёма в договоре). Денежный остаток в этом случае см. [remainingAmount].
  double? remainingQuantity(Estimate e) {
    final planQuantity = effectiveSubQuantity(e);
    if (planQuantity == null) return null;
    return planQuantity - completedQuantity(e);
  }

  /// Остаток в деньгах (расценка × [remainingQuantity]).
  ///
  /// [null], если нет расценки, нет плана ([effectiveSubQuantity] == [null]) **или план равен
  /// нулю**: при нулевом объёме в договоре нельзя интерпретировать цену × «остаток» как
  /// сумму к завершению — иначе в итог «Сумма ост.» попадают отрицательные величины. Колонка
  /// «Остаток» при этом по-прежнему может быть отрицательной.
  double? remainingAmount(Estimate e) {
    final up = subUnitPrice(e);
    if (up == null) return null;
    final planQuantity = effectiveSubQuantity(e);
    if (planQuantity == null || planQuantity == 0) return null;
    final rem = planQuantity - completedQuantity(e);
    return up * rem;
  }

  /// Процент выполнения по объёму плана подрядчика; null если план не задан или ноль.
  double? completionPercent(Estimate e) {
    final planQuantity = effectiveSubQuantity(e);
    if (planQuantity == null || planQuantity == 0) return null;
    return completedQuantity(e) / planQuantity * 100;
  }

  /// В режиме выполнения — показать предупреждение у наименования: отрицательный остаток
  /// по плану подрядчика ([remainingQuantity] < 0) или факт больше объёма позиции в смете.
  bool executionVolumeAlert(Estimate e) {
    final rem = remainingQuantity(e);
    if (rem != null && rem < 0) return true;
    return completedQuantity(e) > e.quantity;
  }

  /// Σ фактического количества по списку позиций.
  double sectionCompletedQuantitySum(List<Estimate> estimates) {
    return estimates.fold<double>(0, (a, e) => a + completedQuantity(e));
  }

  /// Σ суммы выполнения в деньгах (где известна расценка).
  double sectionCompletedAmountSum(List<Estimate> estimates) {
    return estimates.fold<double>(0, (a, e) => a + (completedAmount(e) ?? 0));
  }

  /// Σ остатков по объёму (нулевые [remainingQuantity] дают 0).
  double sectionRemainingQuantitySum(List<Estimate> estimates) {
    return estimates.fold<double>(0, (a, e) => a + (remainingQuantity(e) ?? 0));
  }

  /// Σ остатков в деньгах.
  double sectionRemainingAmountSum(List<Estimate> estimates) {
    return estimates.fold<double>(0, (a, e) => a + (remainingAmount(e) ?? 0));
  }

  /// Процент выполнения по суммарному плановому объёму подрядчика в группе.
  double? sectionCompletionPercent(List<Estimate> estimates) {
    final planQuantity = estimates.fold<double>(
      0,
      (a, e) => a + (effectiveSubQuantity(e) ?? 0),
    );
    if (planQuantity == 0) return null;
    return sectionCompletedQuantitySum(estimates) / planQuantity * 100;
  }
}
