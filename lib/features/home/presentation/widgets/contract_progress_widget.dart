import 'package:flutter/material.dart';
// import removed: math no longer used
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:projectgt/core/di/providers.dart';

class _ContractProgress {
  final double estimatesTotal;
  final double executedTotal;
  const _ContractProgress(
      {required this.estimatesTotal, required this.executedTotal});
}

class _AllProgress {
  final Map<String, _ContractProgress> byContract;
  final String? bestContractId;
  const _AllProgress({required this.byContract, required this.bestContractId});
}

/// Провайдер прогресса выполнения по всем договорам.
///
/// Вычисляет общую сумму смет и выполненных работ для каждого договора,
/// определяет договор с наибольшим прогрессом выполнения.
final allContractsProgressProvider = FutureProvider<_AllProgress>((ref) async {
  final client = ref.watch(supabaseClientProvider);

  // Суммы смет по договору
  final estimatesResp = await client
      .from('estimates')
      .select('contract_id, total, quantity, price');

  final Map<String, double> estimatesTotalByContract = {};
  for (final row in (estimatesResp as List)) {
    final String? contractId = row['contract_id'] as String?;
    if (contractId == null) continue;
    final double quantity = (row['quantity'] as num?)?.toDouble() ?? 0;
    final double price = (row['price'] as num?)?.toDouble() ?? 0;
    final double rowTotal =
        (row['total'] as num?)?.toDouble() ?? (quantity * price);
    estimatesTotalByContract[contractId] =
        (estimatesTotalByContract[contractId] ?? 0) + rowTotal;
  }

  // Выполнение по договору (сумма по work_items, join на estimates.contract_id)
  final workItemsResp = await client
      .from('work_items')
      .select('total, quantity, price, estimates!inner(contract_id)');

  final Map<String, double> executedTotalByContract = {};
  for (final row in (workItemsResp as List)) {
    final Map<String, dynamic>? estimates =
        row['estimates'] as Map<String, dynamic>?;
    if (estimates == null) continue;
    final String? contractId = estimates['contract_id'] as String?;
    if (contractId == null) continue;
    final double quantity = (row['quantity'] as num?)?.toDouble() ?? 0;
    final double price = (row['price'] as num?)?.toDouble() ?? 0;
    final double rowTotal =
        (row['total'] as num?)?.toDouble() ?? (quantity * price);
    executedTotalByContract[contractId] =
        (executedTotalByContract[contractId] ?? 0) + rowTotal;
  }

  final Map<String, _ContractProgress> byContract = {};
  for (final entry in estimatesTotalByContract.entries) {
    final String contractId = entry.key;
    final double est = entry.value;
    final double done = executedTotalByContract[contractId] ?? 0;
    byContract[contractId] =
        _ContractProgress(estimatesTotal: est, executedTotal: done);
  }

  String? best;
  double bestRatio = -1;
  byContract.forEach((cid, prog) {
    final double ratio = prog.estimatesTotal > 0
        ? (prog.executedTotal / prog.estimatesTotal)
        : 0;
    if (ratio > bestRatio) {
      bestRatio = ratio;
      best = cid;
    }
  });

  return _AllProgress(byContract: byContract, bestContractId: best);
});

/// Провайдер прогресса выполнения для конкретного договора.
///
/// Вычисляет сумму смет и выполненных работ для указанного договора.
///
/// [contractId] - идентификатор договора.
final contractProgressProvider =
    FutureProvider.family<_ContractProgress, String>((ref, contractId) async {
  final client = ref.watch(supabaseClientProvider);

  // Сумма смет по договору
  final estimatesResp = await client
      .from('estimates')
      .select('total, quantity, price')
      .eq('contract_id', contractId);

  double estimatesTotal = 0;
  for (final row in (estimatesResp as List)) {
    final double quantity = (row['quantity'] as num?)?.toDouble() ?? 0;
    final double price = (row['price'] as num?)?.toDouble() ?? 0;
    final double rowTotal =
        (row['total'] as num?)?.toDouble() ?? (quantity * price);
    estimatesTotal += rowTotal;
  }

  // Сумма выполнения по договору из смен: work_items с join на estimates(contract_id)
  final workItemsResp = await client
      .from('work_items')
      .select('total, quantity, price, estimates!inner(contract_id)')
      .eq('estimates.contract_id', contractId);

  double executedTotal = 0;
  for (final row in (workItemsResp as List)) {
    final double quantity = (row['quantity'] as num?)?.toDouble() ?? 0;
    final double price = (row['price'] as num?)?.toDouble() ?? 0;
    final double rowTotal =
        (row['total'] as num?)?.toDouble() ?? (quantity * price);
    executedTotal += rowTotal;
  }

  return _ContractProgress(
      estimatesTotal: estimatesTotal, executedTotal: executedTotal);
});

/// Виджет отображения прогресса выполнения договоров.
///
/// Показывает список договоров с информацией о сумме смет,
/// выполненных работах и проценте выполнения. Позволяет выбрать
/// конкретный договор для детального просмотра прогресса.
class ContractProgressWidget extends ConsumerStatefulWidget {
  /// Создает виджет прогресса выполнения договоров.
  const ContractProgressWidget({super.key});

  @override
  ConsumerState<ContractProgressWidget> createState() =>
      _ContractProgressWidgetState();
}

class _ContractProgressWidgetState
    extends ConsumerState<ContractProgressWidget> {
  String? _selectedContractId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Выбор по умолчанию делаем по наибольшему прогрессу через провайдер allContractsProgressProvider
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final contractsState = ref.watch(contractProvider);
    final money =
        NumberFormat.currency(locale: 'ru_RU', symbol: '₽', decimalDigits: 0);

    final contracts = contractsState.contracts;
    final allProgressAsync = ref.watch(allContractsProgressProvider);
    String? contractId = _selectedContractId;
    allProgressAsync.whenData((ap) {
      if (contractId == null && ap.bestContractId != null) {
        contractId = ap.bestContractId;
        if (mounted) setState(() => _selectedContractId = ap.bestContractId);
      }
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.pie_chart_outline,
                size: 18,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7)),
            const SizedBox(width: 8),
            Expanded(
              child: Builder(builder: (context) {
                String title = 'Договор';
                if (contractId != null) {
                  final int idx =
                      contracts.indexWhere((c) => c.id == contractId);
                  if (idx >= 0) {
                    title = 'Договор ${contracts[idx].number}';
                  }
                }
                return Text(
                  title,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                );
              }),
            ),
            IconButton(
              tooltip: 'Предыдущий',
              onPressed: (contracts.isEmpty || contractId == null)
                  ? null
                  : () {
                      final int idx =
                          contracts.indexWhere((c) => c.id == contractId);
                      if (idx > 0) {
                        final nextId = contracts[idx - 1].id;
                        setState(() => _selectedContractId = nextId);
                      }
                    },
              icon: const Icon(Icons.chevron_left),
              visualDensity: VisualDensity.compact,
            ),
            IconButton(
              tooltip: 'Следующий',
              onPressed: (contracts.isEmpty || contractId == null)
                  ? null
                  : () {
                      final int idx =
                          contracts.indexWhere((c) => c.id == contractId);
                      if (idx >= 0 && idx < contracts.length - 1) {
                        final nextId = contracts[idx + 1].id;
                        setState(() => _selectedContractId = nextId);
                      }
                    },
              icon: const Icon(Icons.chevron_right),
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
        const SizedBox(height: 8),
        const SizedBox(height: 12),
        if (contractId == null || contracts.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Text(
              contracts.isEmpty ? 'Нет договоров' : 'Выберите договор',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          )
        else
          Consumer(
            builder: (context, ref, _) {
              final async = ref.watch(contractProgressProvider(contractId!));
              return async.when(
                loading: () => const SizedBox(
                  height: 160,
                  child:
                      Center(child: CircularProgressIndicator(strokeWidth: 2)),
                ),
                error: (e, st) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Text('Ошибка: $e',
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(color: theme.colorScheme.error)),
                ),
                data: (data) {
                  final double total = data.estimatesTotal;
                  final double done = data.executedTotal;
                  final double targetRatio =
                      total > 0 ? (done / total).clamp(0.0, 1.0) : 0.0;

                  return TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: targetRatio),
                    duration: const Duration(milliseconds: 700),
                    curve: Curves.easeOutCubic,
                    builder: (context, ratio, _) {
                      final String percentStr =
                          '${(ratio * 100).toStringAsFixed(0)}%';
                      final List<Color> palette =
                          _buildRedToGreenColors(steps: 9);
                      final Color currentColor = _colorAt(ratio, palette);
                      return Align(
                        alignment: Alignment.center,
                        child: SizedBox(
                          height: 220,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: 180,
                                height: 180,
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    CustomPaint(
                                      size: const Size(180, 180),
                                      painter: _GradientCircularPainter(
                                        ratio: ratio,
                                        trackColor: theme.colorScheme.onSurface
                                            .withValues(alpha: 0.08),
                                        gradientColors: palette,
                                        strokeWidth: 18,
                                      ),
                                    ),
                                    Text(
                                      percentStr,
                                      style: theme.textTheme.headlineSmall
                                          ?.copyWith(
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.2,
                                        color: currentColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                '${money.format(total)} / ${money.format(done)}',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurface
                                      .withValues(alpha: 0.7),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              );
            },
          ),
      ],
    );
  }

  // Прокрутка чипов удалена
}

List<Color> _buildRedToGreenColors({int steps = 7}) {
  // Профессиональная палитра от красного к зелёному:
  // старт — фирменный iOS-красный, финиш — iOS-зелёный, с мягкими переходами
  const List<Color> anchors = [
    Color(0xFFFF3B30), // красный
    Color(0xFFFF9500), // оранжевый
    Color(0xFFFFCC00), // жёлтый
    Color(0xFF34C759), // зелёный
  ];
  if (steps <= anchors.length) {
    // если шагов мало — используем подмножество
    final double step = (anchors.length - 1) / (steps - 1);
    return [for (int i = 0; i < steps; i++) anchors[(i * step).round()]];
  }
  // Иначе — интерполируем между якорями
  final List<Color> colors = <Color>[];
  final int segments = anchors.length - 1;
  final int perSeg = (steps / segments).ceil();
  for (int s = 0; s < segments; s++) {
    final Color a = anchors[s];
    final Color b = anchors[s + 1];
    for (int i = 0; i < perSeg; i++) {
      if (s * perSeg + i >= steps) break;
      final double t = i / (perSeg - 1).clamp(1, double.maxFinite);
      colors.add(Color.lerp(a, b, t) ?? a);
    }
  }
  // Гарантируем длину и конечные цвета
  if (colors.isEmpty) return anchors;
  colors[0] = anchors.first;
  colors[colors.length - 1] = anchors.last;
  if (colors.length > steps) {
    colors.removeRange(steps, colors.length);
  }
  return colors;
}

class _GradientCircularPainter extends CustomPainter {
  final double ratio;
  final Color trackColor;
  final List<Color> gradientColors;
  final double strokeWidth;
  const _GradientCircularPainter(
      {required this.ratio,
      required this.trackColor,
      required this.gradientColors,
      this.strokeWidth = 12});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - (strokeWidth / 2) - 2;

    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..isAntiAlias = true;

    canvas.drawCircle(center, radius, trackPaint);

    if (ratio <= 0) return;

    // Старт в верхней точке и слегка смещаем назад на половину толщины,
    // чтобы в начале всегда был красный сектор и не проскакивал зелёный
    final startAngle = -3.141592653589793 / 2 - (strokeWidth / radius) * 0.02;
    final sweep = 2 * 3.141592653589793 * ratio;
    final rect = Rect.fromCircle(center: center, radius: radius);

    // (stops не требуется при кусочной отрисовке)
    // Рисуем прогресс кусочно (штрихами) чтобы гарантировать начало с красного
    final int segments = (90 + 180 * ratio).toInt().clamp(1, 270);
    final double segSweep = sweep / segments;
    for (int i = 0; i < segments; i++) {
      // Цвет дуги должен соответствовать реальному прогрессу.
      // Используем глобальную позицию относительно полного диапазона [0..1],
      // умноженную на ratio, чтобы при малых значениях кончик не становился зелёным.
      final double tm = ((i + 0.5) / segments) * ratio;
      final Color c = _colorAt(tm, gradientColors);
      final Paint p = Paint()
        ..color = c
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round
        ..isAntiAlias = true;
      final double a0 = startAngle + segSweep * i;
      canvas.drawArc(rect, a0, segSweep, false, p);
    }

    // Объёмный эффект: мягкая внешняя тень и внутренняя подсветка вдоль дуги
    final Paint outerShadow = Paint()
      ..color = const Color(0xFF000000).withValues(alpha: 0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth + 3
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2)
      ..isAntiAlias = true;
    canvas.drawArc(rect, startAngle, sweep, false, outerShadow);

    final Paint innerHighlight = Paint()
      ..color = const Color(0xFFFFFFFF).withValues(alpha: 0.10)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth - 3
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5)
      ..isAntiAlias = true;
    canvas.drawArc(rect, startAngle, sweep, false, innerHighlight);
  }

  @override
  bool shouldRepaint(covariant _GradientCircularPainter oldDelegate) {
    return oldDelegate.ratio != ratio ||
        oldDelegate.trackColor != trackColor ||
        oldDelegate.gradientColors != gradientColors;
  }
}

// Вспомогательная функция для цветовой интерполяции вдоль прогресса
Color _colorAt(double t, List<Color> colors) {
  if (colors.isEmpty) return Colors.red;
  if (colors.length == 1) return colors.first;
  final int segments = colors.length - 1;
  final double scaled = (t.clamp(0.0, 1.0)) * segments;
  final int idx = scaled.floor().clamp(0, segments - 1);
  final double localT = scaled - idx;
  final Color a = colors[idx];
  final Color b = colors[idx + 1];
  return Color.lerp(a, b, localT) ?? a;
}

// legend dot widget удалён за неиспользованием
