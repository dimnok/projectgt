import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:projectgt/core/di/providers.dart';
import 'package:projectgt/core/utils/formatters.dart';
import 'package:projectgt/features/contractors/domain/entities/subcontractor_margin_dashboard_row.dart';
import 'package:projectgt/features/contractors/presentation/providers/subcontractor_margin_dashboard_provider.dart';
import 'package:projectgt/features/contractors/presentation/state/contractor_state.dart';

/// Сводка «Подрядчики»: объект → договор → сметы; план (смета, суб, маржа) и факт по закрытым сменам.
class SubcontractorsMarginDashboardView extends ConsumerWidget {
  /// Создаёт виджет.
  const SubcontractorsMarginDashboardView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(subcontractorMarginDashboardProvider);
    final theme = Theme.of(context);
    final sectionBorder = theme.colorScheme.outline.withValues(alpha: 0.2);

    return async.when(
      data: (rows) {
        if (rows.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                'Нет позиций сметы в компании',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          );
        }
        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(subcontractorMarginDashboardProvider);
            await ref.read(subcontractorMarginDashboardProvider.future);
          },
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(10, 4, 10, 8),
                sliver: SliverToBoxAdapter(child: _TotalsHeader(rows: rows)),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                sliver: SliverList(
                  delegate: SliverChildListDelegate(
                    _buildObjectSections(context, ref, rows, sectionBorder),
                  ),
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(strokeWidth: 2.5),
          ),
        ),
      ),
      error: (e, st) => Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Ошибка загрузки: $e',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
              const SizedBox(height: 12),
              FilledButton.tonal(
                onPressed: () {
                  ref.invalidate(subcontractorMarginDashboardProvider);
                },
                child: const Text('Повторить'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildObjectSections(
    BuildContext context,
    WidgetRef ref,
    List<SubcontractorMarginDashboardRow> rows,
    Color borderColor,
  ) {
    final objectState = ref.watch(objectProvider);
    final contractState = ref.watch(contractProvider);
    final contractorState = ref.watch(contractorNotifierProvider);

    String objectName(String id) {
      return objectState.objects.firstWhereOrNull((o) => o.id == id)?.name ??
          id.substring(0, 8);
    }

    String contractLabel(String? id) {
      if (id == null || id.isEmpty) {
        return 'Договор не указан';
      }
      final c = contractState.contracts.firstWhereOrNull((x) => x.id == id);
      return c == null ? '№ ${id.substring(0, 8)}…' : '№ ${c.number}';
    }

    String contractorLabel(String? id) {
      if (id == null || id.isEmpty) {
        return '—';
      }
      final c = contractorState.contractors.firstWhereOrNull((x) => x.id == id);
      if (c == null) {
        return 'Контрагент $id';
      }
      if (c.shortName.isNotEmpty) {
        return c.shortName;
      }
      return c.fullName;
    }

    final byObject = groupBy(
      rows,
      (SubcontractorMarginDashboardRow r) => r.objectId,
    );
    final objectIds = byObject.keys.toList()
      ..sort((a, b) => objectName(a).compareTo(objectName(b)));

    final widgets = <Widget>[];
    for (var oi = 0; oi < objectIds.length; oi++) {
      final oid = objectIds[oi];
      final objectRows =
          byObject[oid] ?? const <SubcontractorMarginDashboardRow>[];
      final byContract = groupBy(
        objectRows,
        (SubcontractorMarginDashboardRow r) => r.contractId,
      );
      final cKeys = byContract.keys.toList()
        ..sort((a, b) {
          final la = contractLabel(a);
          final lb = contractLabel(b);
          return la.compareTo(lb);
        });

      final contractChildren = <Widget>[];
      for (final ck in cKeys) {
        final list =
            List<SubcontractorMarginDashboardRow>.of(
              byContract[ck] ?? const <SubcontractorMarginDashboardRow>[],
            )..sort((a, b) {
              final t = a.estimateTitle.compareTo(b.estimateTitle);
              if (t != 0) {
                return t;
              }
              return contractorLabel(
                a.contractorId,
              ).compareTo(contractorLabel(b.contractorId));
            });
        contractChildren.add(
          Padding(
            key: ValueKey('obj-$oid-c-$ck'),
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 10),
            child: _ContractBlock(
              contractId: ck,
              contractTitle: contractLabel(ck),
              rows: list,
              contractorLabel: contractorLabel,
            ),
          ),
        );
      }

      widgets.add(
        Padding(
          key: ValueKey(oid),
          padding: EdgeInsets.only(
            bottom: oi == objectIds.length - 1 ? 16 : 12,
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: Border.all(color: borderColor),
              borderRadius: BorderRadius.circular(12),
            ),
            child: ExpansionTile(
              key: ValueKey('obj-$oid'),
              initiallyExpanded: true,
              title: Text(
                objectName(oid),
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
              ),
              children: contractChildren,
            ),
          ),
        ),
      );
    }
    return widgets;
  }
}

class _ContractBlock extends ConsumerWidget {
  const _ContractBlock({
    required this.contractId,
    required this.contractTitle,
    required this.rows,
    required this.contractorLabel,
  });

  /// Идентификатор договора (ключ группировки); `null` — позиции без договора.
  final String? contractId;
  final String contractTitle;
  final List<SubcontractorMarginDashboardRow> rows;
  final String Function(String? id) contractorLabel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final sub = theme.colorScheme.surfaceContainerHighest.withValues(
      alpha: 0.6,
    );
    final contractState = ref.watch(contractProvider);
    final cid = contractId;
    final contractCard = (cid == null || cid.isEmpty)
        ? null
        : contractState.contracts.firstWhereOrNull((c) => c.id == cid);
    final ourSum = _sumByEstimateGroup(rows, (r) => r.ourAmount);
    final subSum = _sumNum(rows.map((e) => e.subcontractorPlannedAmount));
    final m = ourSum - subSum;
    final factOwn = _sumByEstimateGroup(rows, (r) => r.factOwnAmount);
    final factSubRev = _sumByEstimateGroup(
      rows,
      (r) => r.factSubcontractorRevenueAmount,
    );
    final factSubCost = _sumByEstimateGroup(
      rows,
      (r) => r.factSubcontractorCostAmount,
    );
    final factM = factOwn + factSubRev - factSubCost;
    final anyUnpriced = rows.any((r) => r.unpricedLines > 0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 2),
        Text(
          contractTitle,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        if (contractCard != null) ...[
          const SizedBox(height: 4),
          Text(
            'Сумма договора (карточка): ${formatCurrency(contractCard.amount)}',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
        const SizedBox(height: 8),
        if (rows.isNotEmpty) ...[
          _PlanFactSummaryCard(
            planOur: ourSum,
            planSub: subSum,
            planMargin: m,
            hasPartialSubPricing: anyUnpriced,
            factOwn: factOwn,
            factSubRevenue: factSubRev,
            factSubCost: factSubCost,
            factMargin: factM,
          ),
          const SizedBox(height: 10),
          const _DataHeaderRow(),
        ],
        for (final r in rows)
          _DataRow(row: r, contractorLabel: contractorLabel, colorBg: sub),
      ],
    );
  }
}

/// Карточка: план по сметам и факт по закрытым сменам.
class _PlanFactSummaryCard extends StatelessWidget {
  /// Создаёт карточку сводки по договору.
  const _PlanFactSummaryCard({
    required this.planOur,
    required this.planSub,
    required this.planMargin,
    required this.hasPartialSubPricing,
    required this.factOwn,
    required this.factSubRevenue,
    required this.factSubCost,
    required this.factMargin,
  });

  final double planOur;
  final double planSub;
  final double planMargin;
  final bool hasPartialSubPricing;
  final double factOwn;
  final double factSubRevenue;
  final double factSubCost;
  final double factMargin;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final planPct = planOur == 0 ? null : (planMargin / planOur) * 100;
    final factRev = factOwn + factSubRevenue;
    final factPct = factRev == 0 ? null : (factMargin / factRev) * 100;

    final planBg = scheme.primaryContainer.withValues(
      alpha: theme.brightness == Brightness.dark ? 0.38 : 0.72,
    );
    final factBg = scheme.secondaryContainer.withValues(
      alpha: theme.brightness == Brightness.dark ? 0.32 : 0.55,
    );
    final onPlan = scheme.onPrimaryContainer;
    final onFact = scheme.onSecondaryContainer;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: planBg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: scheme.primary.withValues(alpha: 0.28)),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'План (сметы и расценки суба)',
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: onPlan,
                  ),
                ),
                const SizedBox(height: 6),
                _summaryLine(
                  context,
                  label: 'Выручка по смете',
                  value: formatCurrency(planOur),
                  valueColor: onPlan,
                ),
                _summaryLine(
                  context,
                  label: 'Субподряд (план)',
                  value: hasPartialSubPricing
                      ? '${formatCurrency(planSub)}*'
                      : formatCurrency(planSub),
                  valueColor: onPlan,
                ),
                _summaryLine(
                  context,
                  label: 'Маржа (план)',
                  value:
                      '${formatCurrency(planMargin)}${hasPartialSubPricing ? '*' : ''}',
                  valueColor: onPlan,
                  trailing: planPct == null
                      ? '—'
                      : formatPercentage(planPct, decimalDigits: 1),
                  trailingColor: onPlan,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        DecoratedBox(
          decoration: BoxDecoration(
            color: factBg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: scheme.secondary.withValues(alpha: 0.28)),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Факт (закрытые смены)',
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: onFact,
                  ),
                ),
                Text(
                  'Наши силы / суб: суммы из строк сметы; оплата субу — объём × расценка',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: onFact.withValues(alpha: 0.92),
                  ),
                ),
                const SizedBox(height: 6),
                _summaryLine(
                  context,
                  label: 'Выполнено нашими силами',
                  value: formatCurrency(factOwn),
                  valueColor: onFact,
                ),
                _summaryLine(
                  context,
                  label: 'Выполнено субом (выручка)',
                  value: formatCurrency(factSubRevenue),
                  valueColor: onFact,
                ),
                _summaryLine(
                  context,
                  label: 'Оплата подрядчику (факт)',
                  value: formatCurrency(factSubCost),
                  valueColor: onFact,
                ),
                _summaryLine(
                  context,
                  label: 'Маржа (факт)',
                  value: formatCurrency(factMargin),
                  valueColor: onFact,
                  trailing: factPct == null
                      ? '—'
                      : formatPercentage(factPct, decimalDigits: 1),
                  trailingColor: onFact,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  static Widget _summaryLine(
    BuildContext context, {
    required String label,
    required String value,
    required Color valueColor,
    String? trailing,
    Color? trailingColor,
  }) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Text(
            value,
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: valueColor,
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 8),
            Text(
              trailing,
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: trailingColor ?? valueColor,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DataHeaderRow extends StatelessWidget {
  /// Создаёт строку заголовков.
  const _DataHeaderRow();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 0),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              'Смета (группа)',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const _HeaderCell('План: выручка', flex: 2, align: TextAlign.end),
          const _HeaderCell('План: суб', flex: 2, align: TextAlign.end),
          const _HeaderCell('План: маржа', flex: 2, align: TextAlign.end),
          const _HeaderCell('%', flex: 1, align: TextAlign.end),
        ],
      ),
    );
  }
}

class _HeaderCell extends StatelessWidget {
  const _HeaderCell(this.text, {required this.flex, required this.align});

  final String text;
  final int flex;
  final TextAlign align;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      flex: flex,
      child: Text(
        text,
        textAlign: align,
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _DataRow extends StatelessWidget {
  const _DataRow({
    required this.row,
    required this.contractorLabel,
    required this.colorBg,
  });

  final SubcontractorMarginDashboardRow row;
  final String Function(String? id) contractorLabel;
  final Color colorBg;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final unpriced = row.unpricedLines > 0;
    String pct() {
      final p = row.marginSharePercent;
      if (p == null) {
        return '—';
      }
      return formatPercentage(p, decimalDigits: 1);
    }

    final subStr = unpriced
        ? (row.subcontractorPlannedAmount == 0
              ? '—*'
              : '${formatCurrency(row.subcontractorPlannedAmount)}*')
        : formatCurrency(row.subcontractorPlannedAmount);

    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Material(
        color: colorBg,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          row.estimateTitle,
                          style: theme.textTheme.bodySmall,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Суб (план): ${contractorLabel(row.contractorId)}',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  _NumCell(formatCurrency(row.ourAmount), flex: 2),
                  _NumCell(subStr, flex: 2),
                  _NumCell(
                    '${formatCurrency(row.plannedMargin)}${unpriced ? '*' : ''}',
                    flex: 2,
                  ),
                  Expanded(
                    flex: 1,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (unpriced)
                          Padding(
                            padding: const EdgeInsets.only(right: 2),
                            child: Icon(
                              Icons.warning_amber_outlined,
                              size: 16,
                              color: theme.colorScheme.tertiary,
                            ),
                          ),
                        Text(
                          pct(),
                          textAlign: TextAlign.end,
                          style: theme.textTheme.labelSmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Факт: наши ${formatCurrency(row.factOwnAmount)} · суб ${formatCurrency(row.factSubcontractorRevenueAmount)} · оплата субу ${formatCurrency(row.factSubcontractorCostAmount)} · маржа ${formatCurrency(row.factMargin)}',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NumCell extends StatelessWidget {
  const _NumCell(this.value, {required this.flex});

  final String value;
  final int flex;

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context).textTheme.labelSmall;
    return Expanded(
      flex: flex,
      child: Text(
        value,
        textAlign: TextAlign.end,
        style: base,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

class _TotalsHeader extends ConsumerWidget {
  const _TotalsHeader({required this.rows});

  final List<SubcontractorMarginDashboardRow> rows;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final anyUnpriced = rows.any((r) => r.unpricedLines > 0);
    final our = _sumByEstimateGroup(rows, (r) => r.ourAmount);
    final sub = _sumNum(rows.map((e) => e.subcontractorPlannedAmount));
    final m = our - sub;
    final pct = our == 0 ? null : (m / our) * 100;

    final factOwn = _sumByEstimateGroup(rows, (r) => r.factOwnAmount);
    final factSubRev = _sumByEstimateGroup(
      rows,
      (r) => r.factSubcontractorRevenueAmount,
    );
    final factSubCost = _sumByEstimateGroup(
      rows,
      (r) => r.factSubcontractorCostAmount,
    );
    final factM = factOwn + factSubRev - factSubCost;
    final factRev = factOwn + factSubRev;
    final factPct = factRev == 0 ? null : (factM / factRev) * 100;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Итого по компании',
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'План (сметы)',
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            _totLine(context, 'Выручка по смете', formatCurrency(our)),
            _totLine(context, 'Субподряд (план)', formatCurrency(sub)),
            _totLine(
              context,
              'Маржа (план)',
              '${formatCurrency(m)}${anyUnpriced ? '*' : ''}',
            ),
            if (pct != null)
              _totLine(
                context,
                'Доля маржи (план)',
                formatPercentage(pct, decimalDigits: 1),
              )
            else
              _totLine(context, 'Доля маржи (план)', '—'),
            const SizedBox(height: 8),
            Text(
              'Факт (закрытые смены)',
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            _totLine(context, 'Наши силы', formatCurrency(factOwn)),
            _totLine(context, 'Суб (выручка)', formatCurrency(factSubRev)),
            _totLine(context, 'Оплата субу', formatCurrency(factSubCost)),
            _totLine(context, 'Маржа (факт)', formatCurrency(factM)),
            if (factPct != null)
              _totLine(
                context,
                'Доля маржи (факт)',
                formatPercentage(factPct, decimalDigits: 1),
              )
            else
              _totLine(context, 'Доля маржи (факт)', '—'),
            if (anyUnpriced)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  '* В группе есть позиции без расценки суб; план суба занижен.',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  static Widget _totLine(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}

double _sumNum(Iterable<num> values) {
  return values.fold(0.0, (a, b) => a + b.toDouble());
}

/// Для каждой группы (объект, договор, название сметы) RPC может вернуть несколько строк
/// (разные субы); числовые поля группы совпадают — в итог берём максимум по ключу.
double _sumByEstimateGroup(
  Iterable<SubcontractorMarginDashboardRow> rows,
  double Function(SubcontractorMarginDashboardRow) pick,
) {
  final best = <String, double>{};
  for (final r in rows) {
    final key =
        '${r.objectId}\u0000${r.contractId ?? ''}\u0000${r.estimateTitle}';
    final v = pick(r);
    if (!best.containsKey(key) || v > best[key]!) {
      best[key] = v;
    }
  }
  return best.values.fold(0.0, (a, b) => a + b);
}
