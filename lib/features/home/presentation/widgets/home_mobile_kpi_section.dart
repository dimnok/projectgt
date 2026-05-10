import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:projectgt/core/utils/formatters.dart';
import 'package:projectgt/core/widgets/mobile_atmosphere_backdrop.dart';
import 'package:projectgt/core/widgets/mobile_atmosphere_card_style.dart';
import 'package:projectgt/features/home/presentation/providers/all_contracts_progress_provider.dart';
import 'package:projectgt/core/di/providers.dart';

/// Секция KPI для мобильного дашборда с горизонтальным скроллом.
class HomeMobileKpiSection extends ConsumerWidget {
  /// Создаёт мобильную секцию KPI.
  const HomeMobileKpiSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final appearance = MobileAtmosphereAppearance.of(context);
    final style = MobileAtmosphereCardStyle.fromAppearance(appearance);

    final contractsState = ref.watch(contractProvider);
    final estimateState = ref.watch(estimateNotifierProvider);
    final objectState = ref.watch(objectProvider);
    final progressAsync = ref.watch(allContractsProgressProvider);

    final contractsCount = contractsState.contracts.length;
    final estimatesCount = estimateState.estimates.length;
    final objectsCount = objectState.objects.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            'Сводка',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 110,
          child: ListView(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            children: [
              _MobileKpiCard(
                style: style,
                label: 'Выполнение',
                accentColor: const Color(0xFF10B981),
                icon: CupertinoIcons.chart_pie_fill,
                value: progressAsync.when(
                  data: (p) => '${(p.companyWeightedExecutionPercent ?? 0).toStringAsFixed(1)}%',
                  loading: () => '...',
                  error: (_, __) => '—',
                ),
              ),
              const SizedBox(width: 12),
              _MobileKpiCard(
                style: style,
                label: 'Договоры',
                accentColor: const Color(0xFF3B82F6),
                icon: CupertinoIcons.doc_text_fill,
                value: formatQuantity(contractsCount),
              ),
              const SizedBox(width: 12),
              _MobileKpiCard(
                style: style,
                label: 'Сметы',
                accentColor: const Color(0xFFF97316),
                icon: CupertinoIcons.list_number,
                value: formatQuantity(estimatesCount),
              ),
              const SizedBox(width: 12),
              _MobileKpiCard(
                style: style,
                label: 'Объекты',
                accentColor: const Color(0xFF8B5CF6),
                icon: CupertinoIcons.building_2_fill,
                value: formatQuantity(objectsCount),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MobileKpiCard extends StatelessWidget {
  final MobileAtmosphereCardStyle style;
  final String label;
  final String value;
  final IconData icon;
  final Color accentColor;

  const _MobileKpiCard({
    required this.style,
    required this.label,
    required this.value,
    required this.icon,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: 140,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [style.cardTop, style.cardBottom],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: style.cardBorder),
        boxShadow: style.cardShadows,
      ),
      child: Stack(
        children: [
          // Подсветка сверху
          Positioned(
            top: 0,
            left: 20,
            right: 20,
            child: Container(
              height: 1,
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: style.cardHighlight,
                    blurRadius: 1,
                    spreadRadius: 0.5,
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      icon,
                      size: 16,
                      color: accentColor.withValues(alpha: 0.8),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        label.toUpperCase(),
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                Text(
                  value,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
