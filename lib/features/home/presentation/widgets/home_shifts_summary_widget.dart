import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/shifts_provider.dart';

/// Виджет сводки по открытым сменам на сегодня.
///
/// Отображает количество объектов в работе и разбивку по ИТР/монтажникам.
class HomeShiftsSummaryWidget extends ConsumerWidget {
  /// Если `true`, заголовок «Сводка на сегодня» не отображается.
  final bool hideHeader;

  /// Создаёт виджет сводки.
  const HomeShiftsSummaryWidget({
    super.key,
    this.hideHeader = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final now = DateTime.now();
    final dateStr =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final summaryAsync = ref.watch(shiftsSummaryForDateProvider(dateStr));

    return summaryAsync.when(
      data: (summary) => _buildContent(context, theme, summary),
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
      error: (err, stack) => Center(
        child: Text(
          'Ошибка загрузки сводки',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.error,
          ),
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    ThemeData theme,
    Map<String, dynamic> summary,
  ) {
    final int totalObjects = summary['totalObjects'] ?? 0;
    final int totalItr = summary['totalItr'] ?? 0;
    final int totalInstallers = summary['totalInstallers'] ?? 0;
    final List<dynamic> objects = summary['objects'] ?? [];

    if (totalObjects == 0) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                CupertinoIcons.info,
                size: 32,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
              ),
              const SizedBox(height: 12),
              Text(
                'Нет открытых смен на сегодня',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Заголовок сводки
        if (!hideHeader) ...[
          Row(
            children: [
              Icon(
                CupertinoIcons.briefcase,
                size: 18,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Сводка на сегодня',
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],

        // Общая статистика
        Row(
          children: [
            _StatChip(
              label: 'Объектов',
              value: totalObjects.toString(),
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: 8),
            _StatChip(
              label: 'ИТР',
              value: totalItr.toString(),
              color: const Color(0xFF8B5CF6), // Violet
            ),
            const SizedBox(width: 8),
            _StatChip(
              label: 'Монтажников',
              value: totalInstallers.toString(),
              color: const Color(0xFF10B981), // Emerald
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Список объектов
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          itemCount: objects.length,
          separatorBuilder: (context, index) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final obj = objects[index];
            return _ObjectRow(
              name: obj['name'] ?? 'Объект',
              itr: obj['itr'] ?? 0,
              installers: obj['installers'] ?? 0,
            );
          },
        ),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatChip({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withValues(alpha: 0.15),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w900,
                color: color,
                height: 1.1,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                fontSize: 9,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                fontWeight: FontWeight.w700,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _ObjectRow extends StatelessWidget {
  final String name;
  final int itr;
  final int installers;

  const _ObjectRow({
    required this.name,
    required this.itr,
    required this.installers,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.08),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              name,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 12),
          _MiniCount(
            label: 'ИТР',
            count: itr,
            color: const Color(0xFF8B5CF6),
          ),
          const SizedBox(width: 8),
          _MiniCount(
            label: 'Монт.',
            count: installers,
            color: const Color(0xFF10B981),
          ),
        ],
      ),
    );
  }
}

class _MiniCount extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _MiniCount({
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              fontSize: 9,
              color: color.withValues(alpha: 0.7),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            count.toString(),
            style: theme.textTheme.labelSmall?.copyWith(
              fontSize: 10,
              color: color,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}
