import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:projectgt/core/di/providers.dart';

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

/// Вычисляет общую сумму из строки данных.
///
/// Использует значение `total`, если оно указано, иначе вычисляет как `quantity * price`.
double _calculateRowTotal(Map<String, dynamic> row) {
  final double quantity = (row['quantity'] as num?)?.toDouble() ?? 0;
  final double price = (row['price'] as num?)?.toDouble() ?? 0;
  return (row['total'] as num?)?.toDouble() ?? (quantity * price);
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
    final double rowTotal = _calculateRowTotal(row);
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
    final double rowTotal = _calculateRowTotal(row);
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
/// Использует данные из [allContractsProgressProvider] для избежания дублирования запросов к БД.
/// Если данных нет в общем провайдере, делает отдельные запросы.
///
/// [contractId] - идентификатор договора.
final contractProgressProvider =
    FutureProvider.family<_ContractProgress, String>((ref, contractId) async {
  // Пытаемся получить данные из общего провайдера (оптимизация)
  final allProgressAsync = ref.watch(allContractsProgressProvider);

  return allProgressAsync.when(
    data: (allProgress) {
      // Если данные есть в кэше - используем их
      if (allProgress.byContract.containsKey(contractId)) {
        return allProgress.byContract[contractId]!;
      }
      // Если данных нет - делаем отдельный запрос (fallback)
      return _fetchContractProgress(ref, contractId);
    },
    loading: () => _fetchContractProgress(ref, contractId),
    error: (_, __) => _fetchContractProgress(ref, contractId),
  );
});

/// Выполняет прямые запросы к БД для получения прогресса конкретного договора.
///
/// Используется как fallback, когда данные недоступны в [allContractsProgressProvider].
Future<_ContractProgress> _fetchContractProgress(
  Ref ref,
  String contractId,
) async {
  final client = ref.watch(supabaseClientProvider);

  // Сумма смет по договору
  final estimatesResp = await client
      .from('estimates')
      .select('total, quantity, price')
      .eq('contract_id', contractId);

  double estimatesTotal = 0;
  for (final row in (estimatesResp as List)) {
    estimatesTotal += _calculateRowTotal(row);
  }

  // Сумма выполнения по договору из смен
  final workItemsResp = await client
      .from('work_items')
      .select('total, quantity, price, estimates!inner(contract_id)')
      .eq('estimates.contract_id', contractId);

  double executedTotal = 0;
  for (final row in (workItemsResp as List)) {
    executedTotal += _calculateRowTotal(row);
  }

  return _ContractProgress(
    estimatesTotal: estimatesTotal,
    executedTotal: executedTotal,
  );
}

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
            Icon(Icons.pie_chart_outline,
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
        const SizedBox(height: 16),
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
              // contractId точно не null из-за условия выше, но добавим проверку для линтера
              final String currentContractId = contractId;
              final async =
                  ref.watch(contractProgressProvider(currentContractId));
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

  // Прокрутка чипов удалена
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

// legend dot widget удалён за неиспользованием
