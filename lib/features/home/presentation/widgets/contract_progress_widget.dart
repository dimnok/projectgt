import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:projectgt/core/di/providers.dart';
import 'package:projectgt/features/company/presentation/providers/company_providers.dart';

// Константы для визуализации прогресса
const double _kCircleSize = 180.0;
const double _kStrokeWidth = 18.0;
const double _kProgressHeight = 220.0;
const int _kColorSteps = 9;

// Константы цветовой палитры
const List<Color> _kColorAnchors = [
  Color(0xFFFF3B30), // красный
  Color(0xFFFF9500), // оранжевый
  Color(0xFFFFCC00), // жёлтый
  Color(0xFF34C759), // зелёный
];

// Кэш для NumberFormat и цветовой палитры
final _moneyFormat =
    NumberFormat.currency(locale: 'ru_RU', symbol: '₽', decimalDigits: 0);
final _colorPalette =
    _buildRedToGreenColors(steps: _kColorSteps, anchors: _kColorAnchors);

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
/// Использует Server-Side RPC для масштабируемого решения (работает на любых объёмах данных).
final allContractsProgressProvider = FutureProvider<_AllProgress>((ref) async {
  final client = ref.watch(supabaseClientProvider);
  final activeCompanyId = ref.watch(activeCompanyIdProvider);

  if (activeCompanyId == null) {
    return const _AllProgress(byContract: {}, bestContractId: null);
  }

  // Объявляем переменные вне try, чтобы они были видны после блока
  late final Map<String, double> estimatesTotalByContract;
  late final Map<String, double> executedTotalByContract;

  try {
    // RPC запрос с timeout 30 сек
    final rpcFuture = client.rpc('get_all_contracts_progress', params: {
      'p_company_id': activeCompanyId,
    });
    final List<dynamic> rpcResult = await rpcFuture.timeout(
      const Duration(seconds: 30),
      onTimeout: () => throw Exception(
          'RPC get_all_contracts_progress timeout after 30 seconds'),
    );

    // Инициализируем переменные в try блоке
    estimatesTotalByContract = {};
    executedTotalByContract = {};

    for (final row in rpcResult) {
      final String? contractId = row['contract_id'] as String?;
      if (contractId == null) continue;

      final dynamic estTotal = row['estimate_total'];
      final dynamic execTotal = row['executed_total'];

      final double estimateTotal =
          (estTotal is num) ? estTotal.toDouble() : 0.0;
      final double executedTotal =
          (execTotal is num) ? execTotal.toDouble() : 0.0;

      estimatesTotalByContract[contractId] = estimateTotal;
      executedTotalByContract[contractId] = executedTotal;
    }
  } catch (e) {
    throw Exception('Не удалось получить данные по договорам: $e');
  }

  // Итоговые данные - берём ВСЕ договоры из смет
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
    ref.listen<AsyncValue<_AllProgress>>(
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
                                            .withValues(alpha: 0.08),
                                        gradientColors: _colorPalette,
                                        strokeWidth: _kStrokeWidth,
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
                                '${_moneyFormat.format(done)} / ${_moneyFormat.format(total)}',
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
  const _GradientCircularPainter(
      {required this.ratio,
      required this.trackColor,
      required this.gradientColors,
      this.strokeWidth = 12});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - (strokeWidth / 2) - 2;

    // Фоновый трек (серый круг)
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt
      ..isAntiAlias = true;

    canvas.drawCircle(center, radius, trackPaint);

    if (ratio <= 0) return;

    // Старт строго в верхней точке (12 часов)
    const startAngle = -math.pi / 2;
    final sweep = 2 * math.pi * ratio;
    final rect = Rect.fromCircle(center: center, radius: radius);

    // Количество сегментов для плавного градиента
    // Минимум 60 сегментов для качественного градиента
    final int segments = math.max(60, (ratio * 180).toInt());
    final double segmentAngle = sweep / segments;

    // Рисуем каждый сегмент с правильным цветом
    for (int i = 0; i < segments; i++) {
      // КЛЮЧЕВОЙ МОМЕНТ: мапим сегменты на диапазон [0..ratio]
      // Для 2%: все сегменты будут в диапазоне [0..0.02] - красные
      // Для 50%: сегменты в диапазоне [0..0.5] - от красного до оранжевого
      // Для 100%: сегменты в диапазоне [0..1.0] - от красного до зелёного
      final double normalizedPosition = i / (segments - 1); // от 0 до 1
      final double colorProgress = normalizedPosition * ratio; // от 0 до ratio

      // Получаем цвет для этой позиции в палитре
      final Color segmentColor = _colorAt(colorProgress, gradientColors);

      final Paint paint = Paint()
        ..color = segmentColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.butt
        ..isAntiAlias = true;

      final double currentAngle = startAngle + (segmentAngle * i);

      // Рисуем сегмент без перекрытия (StrokeCap.butt обеспечивает плотное прилегание)
      canvas.drawArc(
        rect,
        currentAngle,
        segmentAngle,
        false,
        paint,
      );
    }
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
