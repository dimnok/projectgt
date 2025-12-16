import 'package:flutter/material.dart';
import 'package:projectgt/features/works/domain/entities/work_item.dart';
import 'package:projectgt/core/utils/formatters.dart';

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
    final double maxSum =
        sortedSystems.isNotEmpty ? sortedSystems.first.value : 1.0;
    final double totalSum =
        systemSums.values.fold<double>(0, (sum, v) => sum + v);

    final List<Color> colors = <Color>[
      const Color(0xFF2196F3),
      const Color(0xFF4CAF50),
      const Color(0xFFFF9800),
      const Color(0xFF9C27B0),
      const Color(0xFFF44336),
    ];

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Распределение работ по системам',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 24),
            ...sortedSystems.take(5).toList().asMap().entries.map((entry) {
              final int index = entry.key;
              final systemName = entry.value.key;
              final double systemSum = entry.value.value;
              final double progress = maxSum > 0 ? systemSum / maxSum : 0.0;
              final double sumPercent =
                  totalSum > 0 ? systemSum / totalSum : 0.0;
              final Color color = colors[index % colors.length];

              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Row(
                  children: [
                    _buildPercentageCircle(context, sumPercent, color,
                        '${(sumPercent * 100).round()}%'),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                              Text(
                                '${formatCurrency(systemSum)} (${(sumPercent * 100).round()}%)',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: color,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: LinearProgressIndicator(
                              value: progress,
                              minHeight: 8,
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
            const Divider(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      margin: const EdgeInsets.only(right: 12),
                      child: Icon(
                        Icons.data_usage_rounded,
                        color: theme.colorScheme.primary,
                        size: 24,
                      ),
                    ),
                    Text(
                      'Общая сумма:',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Text(
                  formatCurrency(totalSum),
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
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
      BuildContext context, double percentage, Color color, String label) {
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
              backgroundColor:
                  Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
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
    final radius = (size.width < size.height ? size.width : size.height) / 2 -
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
