import 'package:flutter/material.dart';
import 'package:projectgt/core/utils/formatters.dart';

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
        padding: const EdgeInsets.all(20),
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
                  height: 40,
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
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Divider(height: 1),
            ),
            _buildStatRow(
              context,
              'Общая сумма',
              formatCurrency(totalAmount),
              isMain: true,
            ),
            const SizedBox(height: 12),
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
            color: theme.colorScheme.surfaceContainerHighest
                .withValues(alpha: 0.3),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: theme.colorScheme.onSurfaceVariant, size: 20),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 4),
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
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        Text(
          value,
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
