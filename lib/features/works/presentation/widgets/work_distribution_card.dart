import 'package:flutter/material.dart';
import 'package:projectgt/core/utils/responsive_utils.dart';
import 'package:projectgt/features/works/domain/entities/work_item.dart';
import 'package:projectgt/core/utils/formatters.dart';
import 'package:projectgt/features/works/presentation/widgets/work_detail_data_spacing.dart';

/// Карточка «Распределение работ по системам».
///
/// Показывает распределение только по сумме (₽). Проценты считаются по сумме.
class WorkDistributionCard extends StatelessWidget {
  /// Список работ смены.
  final List<WorkItem> items;

  /// Создаёт карточку распределения работ по системам.
  ///
  /// [items] — список работ смены для агрегирования сумм по системам.
  const WorkDistributionCard({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Агрегируем суммы по системам
    final Map<String, double> systemSums = <String, double>{};
    for (final item in items) {
      systemSums[item.system] =
          (systemSums[item.system] ?? 0) + (item.total ?? 0);
    }

    final sortedSystems = systemSums.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final double maxSum = sortedSystems.isNotEmpty
        ? sortedSystems.first.value
        : 1.0;
    final double totalSum = systemSums.values.fold<double>(
      0,
      (sum, v) => sum + v,
    );

    final List<Color> colors = <Color>[
      const Color(0xFF2196F3),
      const Color(0xFF4CAF50),
      const Color(0xFFFF9800),
      const Color(0xFF9C27B0),
      const Color(0xFFF44336),
    ];

    final topSystems = sortedSystems.take(5).toList();

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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Распределение работ по системам',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: 0.2,
                color: theme.colorScheme.onSurface,
              ),
            ),
            SizedBox(height: WorkDetailDataSpacing.titleToContentOf(context)),
            ...topSystems.asMap().entries.map((entry) {
              final int index = entry.key;
              final mapEntry = entry.value;
              final systemName = mapEntry.key;
              final double systemSum = mapEntry.value;
              final double progress = maxSum > 0 ? systemSum / maxSum : 0.0;
              final double sumPercent = totalSum > 0
                  ? systemSum / totalSum
                  : 0.0;
              final Color color = colors[index % colors.length];
              final isLast = index == topSystems.length - 1;

              return Padding(
                padding: EdgeInsets.only(
                  bottom: isLast
                      ? 0
                      : WorkDetailDataSpacing.listRowGapOf(context) +
                            (ResponsiveUtils.isMobile(context) ? 4 : 0),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildPercentageCircle(
                      context,
                      sumPercent,
                      color,
                      '${(sumPercent * 100).round()}%',
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  systemName,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  '${formatCurrency(systemSum)} (${(sumPercent * 100).round()}%)',
                                  textAlign: TextAlign.end,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: color,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(
                            height: ResponsiveUtils.isMobile(context) ? 10 : 8,
                          ),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: LinearProgressIndicator(
                              value: progress,
                              minHeight: ResponsiveUtils.isMobile(context)
                                  ? 9
                                  : 8,
                              backgroundColor: theme.colorScheme.primary
                                  .withValues(alpha: 0.1),
                              valueColor: AlwaysStoppedAnimation<Color>(color),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
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
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(
                  Icons.pie_chart_outline_rounded,
                  color: theme.colorScheme.primary,
                  size: 22,
                ),
                SizedBox(
                  width: WorkDetailDataSpacing.titleToContentOf(context),
                ),
                Expanded(
                  child: Text(
                    'Общая сумма:',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ),
                Text(
                  formatCurrency(totalSum),
                  textAlign: TextAlign.end,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPercentageCircle(
    BuildContext context,
    double percentage,
    Color color,
    String label,
  ) {
    return Container(
      width: 40,
      height: 40,
      margin: const EdgeInsets.only(right: 12),
      child: Stack(
        children: [
          CustomPaint(
            size: const Size(40, 40),
            painter: CirclePercentPainter(
              percentage: percentage,
              color: color,
              backgroundColor: Theme.of(
                context,
              ).colorScheme.outline.withValues(alpha: 0.2),
              fillColor: Theme.of(context).colorScheme.surface,
              strokeWidth: 4,
            ),
          ),
          Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Отрисовщик кругового индикатора процента.
class CirclePercentPainter extends CustomPainter {
  /// Значение прогресса в диапазоне 0..1.
  final double percentage;

  /// Цвет дуги прогресса.
  final Color color;

  /// Толщина линий индикатора.
  final double strokeWidth;

  /// Цвет фона (окружности) индикатора.
  final Color backgroundColor;

  /// Цвет заливки внутри индикатора.
  final Color fillColor;

  /// Создаёт отрисовщик кругового индикатора.
  CirclePercentPainter({
    required this.percentage,
    required this.color,
    required this.backgroundColor,
    required this.fillColor,
    this.strokeWidth = 4.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius =
        (size.width < size.height ? size.width : size.height) / 2 -
        strokeWidth / 2;

    final backgroundPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawCircle(center, radius, backgroundPaint);

    final fillPaint = Paint()
      ..color = fillColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius, fillPaint);

    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = strokeWidth;

    const startAngle = -90 * 3.1415926535897932 / 180;
    final sweepAngle = 2 * 3.1415926535897932 * percentage;
    final rect = Rect.fromCircle(center: center, radius: radius);
    canvas.drawArc(rect, startAngle, sweepAngle, false, progressPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
