import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:projectgt/core/di/providers.dart';
import 'package:projectgt/core/utils/formatters.dart';
import 'package:projectgt/features/home/presentation/providers/all_contracts_progress_provider.dart';
import 'package:projectgt/features/objects/presentation/state/object_state.dart';
import 'package:projectgt/presentation/state/contract_state.dart';

/// Единая панель (Ribbon) KPI для десктопной главной.
class HomeDesktopKpiSection extends ConsumerWidget {
  /// Создаёт блок KPI в виде единой ленты.
  const HomeDesktopKpiSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final contractsState = ref.watch(contractProvider);
    final estimateState = ref.watch(estimateNotifierProvider);
    final objectState = ref.watch(objectProvider);
    final progressAsync = ref.watch(allContractsProgressProvider);

    final contractsLoading = contractsState.status == ContractStatusState.loading;
    final estimatesLoading = estimateState.isLoading;
    final objectsLoading = objectState.status == ObjectStatus.loading;

    final contractsCount = contractsState.contracts.length;
    final estimatesCount = estimateState.estimates.length;
    final objectsCount = objectState.objects.length;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.1),
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            Expanded(
              child: _KpiRibbonItem(
                label: 'Выполнение',
                subtitle: 'Средний показатель',
                accentColor: const Color(0xFF10B981),
                valueWidget: progressAsync.when(
                  data: (p) {
                    final pct = p.companyWeightedExecutionPercent;
                    if (pct == null) return _KpiValueText('—', theme);
                    return _KpiValueText('${pct.toStringAsFixed(1)} %', theme, emphasize: true);
                  },
                  loading: () => const _KpiSkeleton(),
                  error: (_, __) => _KpiValueText('—', theme, isError: true),
                ),
                icon: CupertinoIcons.chart_pie_fill,
              ),
            ),
            _buildDivider(theme),
            Expanded(
              child: _KpiRibbonItem(
                label: 'Договоры',
                subtitle: 'Всего в базе',
                accentColor: const Color(0xFF1E3A8A),
                valueWidget: contractsLoading
                    ? const _KpiSkeleton()
                    : _KpiValueText(formatQuantity(contractsCount), theme),
                icon: CupertinoIcons.doc_text_fill,
              ),
            ),
            _buildDivider(theme),
            Expanded(
              child: _KpiRibbonItem(
                label: 'Сметы',
                subtitle: 'Загружено',
                accentColor: const Color(0xFFF97316),
                valueWidget: estimatesLoading
                    ? const _KpiSkeleton()
                    : _KpiValueText(formatQuantity(estimatesCount), theme),
                icon: CupertinoIcons.list_number,
              ),
            ),
            _buildDivider(theme),
            Expanded(
              child: _KpiRibbonItem(
                label: 'Объекты',
                subtitle: 'Активные площадки',
                accentColor: const Color(0xFF8B5CF6),
                valueWidget: objectsLoading
                    ? const _KpiSkeleton()
                    : _KpiValueText(formatQuantity(objectsCount), theme),
                icon: CupertinoIcons.building_2_fill,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: VerticalDivider(
        width: 1,
        thickness: 1,
        color: theme.colorScheme.outline.withValues(alpha: 0.1),
      ),
    );
  }
}

class _KpiRibbonItem extends StatelessWidget {
  final String label;
  final String subtitle;
  final Widget valueWidget;
  final IconData icon;
  final Color accentColor;

  const _KpiRibbonItem({
    required this.label,
    required this.subtitle,
    required this.valueWidget,
    required this.icon,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 16, color: accentColor),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label.toUpperCase(),
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          valueWidget,
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _KpiValueText extends StatelessWidget {
  final String text;
  final ThemeData theme;
  final bool emphasize;
  final bool isError;

  const _KpiValueText(
    this.text,
    this.theme, {
    this.emphasize = false,
    this.isError = false,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: theme.textTheme.headlineSmall?.copyWith(
        fontWeight: FontWeight.w800,
        letterSpacing: -0.5,
        color: isError ? theme.colorScheme.error : null,
        fontSize: emphasize ? 28 : 24,
      ),
    );
  }
}

class _KpiSkeleton extends StatelessWidget {
  const _KpiSkeleton();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: 64,
      height: 28,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        color: theme.colorScheme.onSurface.withValues(alpha: 0.08),
      ),
    );
  }
}
