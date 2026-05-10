import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:projectgt/core/di/providers.dart';
import 'package:projectgt/core/utils/formatters.dart';
import 'package:projectgt/features/home/presentation/providers/all_contracts_progress_provider.dart';
import 'package:projectgt/features/objects/presentation/state/object_state.dart';
import 'package:projectgt/presentation/state/contract_state.dart';

/// Ряд KPI-карточек для десктопной главной (сметы, договоры, объекты, выполнение).
class HomeDesktopKpiSection extends ConsumerWidget {
  /// Создаёт блок KPI для десктопного дашборда.
  const HomeDesktopKpiSection({super.key});

  static const double _cardMinHeight = 104;

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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Сводка по компании',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _KpiCard(
                minHeight: _cardMinHeight,
                label: 'Выполнение',
                accentColor: const Color(0xFF10B981), // Safe Green
                valueWidget: progressAsync.when(
                  data: (p) {
                    final pct = p.companyWeightedExecutionPercent;
                    if (pct == null) {
                      return _KpiValueText('—', theme);
                    }
                    return _KpiValueText(
                      '${pct.toStringAsFixed(1)} %',
                      theme,
                      emphasize: true,
                    );
                  },
                  loading: () => const _KpiSkeleton(),
                  error: (_, __) => _KpiValueText('—', theme, isError: true),
                ),
                icon: CupertinoIcons.chart_pie_fill,
                semanticLabel: 'Взвешенный процент выполнения по сметам компании',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _KpiCard(
                minHeight: _cardMinHeight,
                label: 'Договоры',
                accentColor: const Color(0xFF1E3A8A), // Blueprint Blue
                valueWidget: contractsLoading
                    ? const _KpiSkeleton()
                    : _KpiValueText(
                        formatQuantity(contractsCount),
                        theme,
                      ),
                icon: CupertinoIcons.doc_text_fill,
                semanticLabel: 'Количество договоров',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _KpiCard(
                minHeight: _cardMinHeight,
                label: 'Сметы',
                accentColor: const Color(0xFFF97316), // Warning Orange
                valueWidget: estimatesLoading
                    ? const _KpiSkeleton()
                    : _KpiValueText(
                        formatQuantity(estimatesCount),
                        theme,
                      ),
                icon: CupertinoIcons.list_number,
                semanticLabel: 'Количество смет',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _KpiCard(
                minHeight: _cardMinHeight,
                label: 'Объекты',
                accentColor: const Color(0xFF8B5CF6), // Violet
                valueWidget: objectsLoading
                    ? const _KpiSkeleton()
                    : _KpiValueText(
                        formatQuantity(objectsCount),
                        theme,
                      ),
                icon: CupertinoIcons.building_2_fill,
                semanticLabel: 'Количество объектов',
              ),
            ),
          ],
        ),
      ],
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
    return SizedBox(
      height: 32,
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          width: 96,
          height: 28,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: theme.colorScheme.onSurface.withValues(alpha: 0.08),
          ),
        ),
      ),
    );
  }
}

class _KpiCard extends StatefulWidget {
  final double minHeight;
  final String label;
  final Widget valueWidget;
  final IconData icon;
  final String semanticLabel;
  final Color accentColor;

  const _KpiCard({
    required this.minHeight,
    required this.label,
    required this.valueWidget,
    required this.icon,
    required this.semanticLabel,
    required this.accentColor,
  });

  @override
  State<_KpiCard> createState() => _KpiCardState();
}

class _KpiCardState extends State<_KpiCard> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      container: true,
      label: '${widget.semanticLabel}: ${widget.label}',
      child: MouseRegion(
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          constraints: BoxConstraints(minHeight: widget.minHeight),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _hover
                  ? widget.accentColor.withValues(alpha: 0.4)
                  : theme.colorScheme.outline.withValues(alpha: 0.12),
              width: _hover ? 1.5 : 1.0,
            ),
            boxShadow: _hover
                ? [
                    BoxShadow(
                      color: widget.accentColor.withValues(alpha: 0.1),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: theme.colorScheme.shadow.withValues(alpha: 0.02),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: widget.accentColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      widget.icon,
                      size: 18,
                      color: widget.accentColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.label.toUpperCase(),
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.0,
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              widget.valueWidget,
            ],
          ),
        ),
      ),
    );
  }
}
