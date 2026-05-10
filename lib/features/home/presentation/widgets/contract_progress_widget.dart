import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:projectgt/core/di/providers.dart';
import 'package:projectgt/features/home/presentation/providers/all_contracts_progress_provider.dart';

// Константы для визуализации прогресса
const double _kCircleSize = 180.0;
const double _kStrokeWidth = 18.0;
const double _kProgressHeight = 240.0;
const int _kColorSteps = 9;

// Константы цветовой палитры
const List<Color> _kColorAnchors = [
  Color(0xFFEF4444), // красный (vibrant)
  Color(0xFFF97316), // оранжевый
  Color(0xFFFACC15), // жёлтый
  Color(0xFF10B981), // зелёный (vibrant)
];

// Кэш для NumberFormat и цветовой палитры
final _moneyFormat =
    NumberFormat.currency(locale: 'ru_RU', symbol: '₽', decimalDigits: 0);
final _colorPalette =
    _buildRedToGreenColors(steps: _kColorSteps, anchors: _kColorAnchors);

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

  /// Возвращает заголовок для отображения договора.
  String _getContractTitle(String? contractId, List<dynamic> contracts) {
    if (contractId == null) return 'Договор';
    final int idx = contracts.indexWhere((c) => c.id == contractId);
    return idx >= 0 ? 'Договор ${contracts[idx].number}' : 'Договор';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final contractsState = ref.watch(contractProvider);
    final contracts = contractsState.contracts;
    final allProgressAsync = ref.watch(allContractsProgressProvider);

    // Используем listen для установки начального значения вместо setState в build
    ref.listen<AsyncValue<AllContractsProgress>>(
      allContractsProgressProvider,
      (previous, next) {
        next.whenData((ap) {
          if (_selectedContractId == null && ap.bestContractId != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                setState(() => _selectedContractId = ap.bestContractId);
              }
            });
          }
        });
      },
    );

    // Определяем текущий contractId для отображения
    final String? contractId =
        _selectedContractId ?? allProgressAsync.asData?.value.bestContractId;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(CupertinoIcons.chart_pie,
                size: 18,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _getContractTitle(contractId, contracts),
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
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
              icon: const Icon(CupertinoIcons.chevron_left),
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
              icon: const Icon(CupertinoIcons.chevron_right),
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (contractId == null ||
            allProgressAsync.asData?.value.byContract.isEmpty == true)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Text(
              contractId == null ? 'Загрузка договоров...' : 'Нет договоров',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          )
        else
          Consumer(
            builder: (context, ref, _) {
              // contractId точно не null из-за условия выше, но добавим проверку для линтера
              final String currentContractId = contractId;
              final async = ref.watch(allContractsProgressProvider);
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
                data: (allProgress) {
                  // Извлекаем данные для конкретного договора
                  final data = allProgress.byContract[currentContractId];
                  if (data == null) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Text('Данные не найдены',
                          style: theme.textTheme.bodyMedium),
                    );
                  }
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
                      // Используем кэшированную палитру вместо создания новой в каждом кадре
                      final Color currentColor = _colorAt(ratio, _colorPalette);
                      return Align(
                        alignment: Alignment.center,
                        child: SizedBox(
                          height: _kProgressHeight,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: _kCircleSize,
                                height: _kCircleSize,
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    CustomPaint(
                                      size: const Size(
                                          _kCircleSize, _kCircleSize),
                                      painter: _GradientCircularPainter(
                                        ratio: ratio,
                                        trackColor: theme.colorScheme.onSurface
                                            .withValues(alpha: 0.05),
                                        gradientColors: _colorPalette,
                                        strokeWidth: _kStrokeWidth,
                                        glowColor: currentColor.withValues(alpha: 0.3),
                                      ),
                                    ),
                                    Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          percentStr,
                                          style: theme.textTheme.headlineMedium
                                              ?.copyWith(
                                            fontWeight: FontWeight.w900,
                                            letterSpacing: -1.0,
                                            color: currentColor,
                                          ),
                                        ),
                                        Text(
                                          'ГОТОВО',
                                          style: theme.textTheme.labelSmall?.copyWith(
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: 1.5,
                                            color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.onSurface.withValues(alpha: 0.04),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '${_moneyFormat.format(done)} / ${_moneyFormat.format(total)}',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: theme.colorScheme.onSurface
                                        .withValues(alpha: 0.8),
                                  ),
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
}

/// Создает интерполированную палитру цветов от красного к зелёному.
///
/// [steps] - количество цветов в палитре.
/// [anchors] - якорные цвета для интерполяции.
List<Color> _buildRedToGreenColors({
  required int steps,
  required List<Color> anchors,
}) {
  if (anchors.isEmpty) return const [Colors.red];
  if (steps <= 0) return [anchors.first];
  if (steps == 1) return [anchors.first];

  if (steps <= anchors.length) {
    // Для малого количества шагов - возвращаем подмножество якорей
    final double step = (anchors.length - 1) / (steps - 1);
    return List.generate(steps, (i) => anchors[(i * step).round()]);
  }

  // Интерполяция между якорными цветами
  final List<Color> colors = [];
  final int segments = anchors.length - 1;
  final int colorsPerSegment = (steps / segments).ceil();

  for (int s = 0; s < segments; s++) {
    final Color startColor = anchors[s];
    final Color endColor = anchors[s + 1];

    for (int i = 0; i < colorsPerSegment && colors.length < steps; i++) {
      final double t = colorsPerSegment > 1 ? i / (colorsPerSegment - 1) : 0.0;
      colors.add(Color.lerp(startColor, endColor, t) ?? startColor);
    }
  }

  // Гарантируем правильную длину и корректные крайние цвета
  if (colors.length > steps) {
    colors.removeRange(steps, colors.length);
  }
  colors[0] = anchors.first;
  colors[colors.length - 1] = anchors.last;

  return colors;
}

class _GradientCircularPainter extends CustomPainter {
  final double ratio;
  final Color trackColor;
  final List<Color> gradientColors;
  final double strokeWidth;
  final Color? glowColor;

  const _GradientCircularPainter({
    required this.ratio,
    required this.trackColor,
    required this.gradientColors,
    this.strokeWidth = 12,
    this.glowColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - (strokeWidth / 2) - 4;

    // Фоновый трек (серый круг)
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true;

    canvas.drawCircle(center, radius, trackPaint);

    if (ratio <= 0) return;

    // Свечение (Glow)
    if (glowColor != null) {
      final glowPaint = Paint()
        ..color = glowColor!
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth + 4
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8)
        ..strokeCap = StrokeCap.round
        ..isAntiAlias = true;
      
      const startAngle = -math.pi / 2;
      final sweep = 2 * math.pi * ratio;
      canvas.drawArc(Rect.fromCircle(center: center, radius: radius), startAngle, sweep, false, glowPaint);
    }

    // Старт строго в верхней точке (12 часов)
    const startAngle = -math.pi / 2;
    final sweep = 2 * math.pi * ratio;
    final rect = Rect.fromCircle(center: center, radius: radius);

    // Количество сегментов для плавного градиента
    final int segments = math.max(60, (ratio * 180).toInt());
    final double segmentAngle = sweep / segments;

    // Рисуем каждый сегмент с правильным цветом
    for (int i = 0; i < segments; i++) {
      final double normalizedPosition = i / (segments - 1);
      final double colorProgress = normalizedPosition * ratio;

      final Color segmentColor = _colorAt(colorProgress, gradientColors);

      final Paint paint = Paint()
        ..color = segmentColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = i == 0 || i == segments - 1 ? StrokeCap.round : StrokeCap.butt
        ..isAntiAlias = true;

      final double currentAngle = startAngle + (segmentAngle * i);

      canvas.drawArc(
        rect,
        currentAngle,
        segmentAngle + 0.01, // Небольшой оверлап для плавности
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _GradientCircularPainter oldDelegate) {
    return oldDelegate.ratio != ratio ||
        oldDelegate.trackColor != trackColor ||
        oldDelegate.gradientColors != gradientColors ||
        oldDelegate.glowColor != glowColor;
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
