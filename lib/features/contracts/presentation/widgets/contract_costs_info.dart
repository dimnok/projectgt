import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:projectgt/core/utils/formatters.dart';
import 'package:projectgt/features/contracts/presentation/providers/contract_costs_providers.dart';

/// Виджет для отображения информации о выработке и прибыли по договору
class ContractCostsInfo extends ConsumerWidget {
  /// ID договора для расчета затрат
  final String contractId;

  /// ID объекта для фильтрации затрат
  final String objectId;

  /// Сумма договора для расчета прибыли
  final double contractAmount;

  /// Создает виджет для отображения информации о затратах
  const ContractCostsInfo({
    super.key,
    required this.contractId,
    required this.objectId,
    required this.contractAmount,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    // Получаем данные по выработке, передавая contractId|objectId
    final params = '$contractId|$objectId';
    final worksSummaryAsync = ref.watch(contractWorksSummaryProvider(params));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Финансовые показатели',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        worksSummaryAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(),
          ),
          error: (error, stack) => Center(
            child: Text(
              'Ошибка загрузки: $error',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          ),
          data: (worksSummary) {
            final totalWorksAmount = worksSummary['totalAmount'] as double;

            // Расчет прибыли (без учета ФОТ)
            final profit = contractAmount - totalWorksAmount;
            final profitPercent =
                contractAmount > 0 ? (profit / contractAmount * 100) : 0;

            return Row(
              children: [
                Expanded(
                  child: _InfoCard(
                    icon: Icons.engineering_outlined,
                    title: 'Выработка',
                    subtitle: 'По договору',
                    amount: totalWorksAmount > 0
                        ? formatCurrency(totalWorksAmount)
                        : '—',
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _InfoCard(
                    icon: profit >= 0
                        ? Icons.trending_up_outlined
                        : Icons.trending_down_outlined,
                    title: 'Прибыль',
                    subtitle:
                        '${profitPercent.toStringAsFixed(1)}% от договора',
                    amount: formatCurrency(profit.abs()),
                    color: profit >= 0 ? Colors.green : theme.colorScheme.error,
                    showSign: profit < 0,
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}

/// Карточка информации
class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String amount;
  final Color color;
  final bool showSign;

  const _InfoCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.color,
    this.showSign = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: color),
              const SizedBox(width: 8),
              Text(
                title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            showSign ? '-$amount' : amount,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
