import 'package:flutter/material.dart';
import 'package:projectgt/core/utils/formatters.dart';
import 'package:projectgt/core/utils/responsive_utils.dart';
import 'package:projectgt/features/works/presentation/widgets/work_detail_data_spacing.dart';

/// Виджет карточки статистики смены.
class WorkStatsCard extends StatelessWidget {
  /// Количество работ.
  final int worksCount;

  /// Количество уникальных сотрудников.
  final int uniqueEmployees;

  /// Общая сумма работ.
  final double totalAmount;

  /// Выработка на одного сотрудника.
  final double productivityPerEmployee;

  /// Конструктор карточки статистики.
  const WorkStatsCard({
    super.key,
    required this.worksCount,
    required this.uniqueEmployees,
    required this.totalAmount,
    required this.productivityPerEmployee,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: theme.colorScheme.outline.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      color: theme.cardColor,
      child: Padding(
        padding: WorkDetailDataSpacing.cardPaddingOf(context),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    context,
                    'Сотрудников',
                    uniqueEmployees.toString(),
                    Icons.people_outline,
                  ),
                ),
                Container(
                  width: 1,
                  height: ResponsiveUtils.isMobile(context) ? 48 : 44,
                  color: theme.colorScheme.outline.withValues(alpha: 0.1),
                ),
                Expanded(
                  child: _buildStatItem(
                    context,
                    'Работ',
                    worksCount.toString(),
                    Icons.handyman_outlined,
                  ),
                ),
              ],
            ),
            Padding(
              padding: EdgeInsets.symmetric(
                vertical: WorkDetailDataSpacing.dividerVerticalPaddingOf(
                  context,
                ),
              ),
              child: Divider(
                height: 1,
                thickness: 1,
                color: theme.colorScheme.outline.withValues(alpha: 0.12),
              ),
            ),
            _buildStatRow(
              context,
              'Общая сумма',
              formatCurrency(totalAmount),
              isMain: true,
            ),
            SizedBox(height: WorkDetailDataSpacing.listRowGapOf(context)),
            _buildStatRow(
              context,
              'Выработка на чел.',
              formatCurrency(productivityPerEmployee),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withValues(
              alpha: 0.3,
            ),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: theme.colorScheme.onSurfaceVariant,
            size: 22,
          ),
        ),
        SizedBox(height: WorkDetailDataSpacing.statIconToValueGapOf(context)),
        Text(
          value,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
        SizedBox(height: WorkDetailDataSpacing.statValueToLabelGapOf(context)),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildStatRow(
    BuildContext context,
    String label,
    String value, {
    bool isMain = false,
  }) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Expanded(
          child: Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Text(
          value,
          textAlign: TextAlign.end,
          style: isMain
              ? theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                )
              : theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
        ),
      ],
    );
  }
}
