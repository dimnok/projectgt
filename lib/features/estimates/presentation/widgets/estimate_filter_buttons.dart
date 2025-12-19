import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

enum EstimateStatusFilter {
  none,
  overExecution,
  completed,
  zeroExecution,
}

class EstimateFilterButtons extends StatelessWidget {
  const EstimateFilterButtons({
    super.key,
    required this.selectedFilter,
    required this.onChanged,
  });

  final EstimateStatusFilter selectedFilter;
  final ValueChanged<EstimateStatusFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _FilterButton(
          isActive: selectedFilter == EstimateStatusFilter.overExecution,
          icon: CupertinoIcons.exclamationmark_circle_fill,
          color: CupertinoColors.systemRed,
          tooltip: 'Перевыполнение (>100%)',
          onTap: () => onChanged(
            selectedFilter == EstimateStatusFilter.overExecution
                ? EstimateStatusFilter.none
                : EstimateStatusFilter.overExecution,
          ),
        ),
        const SizedBox(width: 8),
        _FilterButton(
          isActive: selectedFilter == EstimateStatusFilter.completed,
          icon: CupertinoIcons.checkmark_circle_fill,
          color: CupertinoColors.systemGreen,
          tooltip: 'Выполнено (100%)',
          onTap: () => onChanged(
            selectedFilter == EstimateStatusFilter.completed
                ? EstimateStatusFilter.none
                : EstimateStatusFilter.completed,
          ),
        ),
        const SizedBox(width: 8),
        _FilterButton(
          isActive: selectedFilter == EstimateStatusFilter.zeroExecution,
          icon: CupertinoIcons.circle_fill,
          color: Colors.amber, // Используем Amber для лучшей видимости на белом
          tooltip: 'Не приступали (0%)',
          onTap: () => onChanged(
            selectedFilter == EstimateStatusFilter.zeroExecution
                ? EstimateStatusFilter.none
                : EstimateStatusFilter.zeroExecution,
          ),
        ),
      ],
    );
  }
}

class _FilterButton extends StatelessWidget {
  const _FilterButton({
    required this.isActive,
    required this.icon,
    required this.color,
    required this.onTap,
    this.tooltip,
  });

  final bool isActive;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Tooltip(
      message: tooltip ?? '',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: isActive
                  ? color.withValues(alpha: 0.15)
                  : Colors.transparent,
              shape: BoxShape.circle,
              border: isActive
                  ? Border.all(color: color, width: 1.5)
                  : Border.all(
                      color: theme.colorScheme.outline.withValues(alpha: 0.2),
                      width: 1,
                    ),
            ),
            child: Icon(
              icon,
              size: 20,
              color: isActive
                  ? color
                  : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
          ),
        ),
      ),
    );
  }
}

