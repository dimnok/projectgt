import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/shifts_provider.dart';

const Color _telegramBlue = Color(0xFF229ED9);
const Color _whatsappGreen = Color(0xFF25D366);
const Color _softRed = Color(0xFFE57373);

/// Форматер для денежных сумм (руб., 0 знаков после запятой)
final _moneyFormatter = NumberFormat.currency(
  locale: 'ru_RU',
  symbol: '₽',
  decimalDigits: 0,
);

/// Форматер для дат (ДД.ММ.ГГГГ)
final _dateFormatter = DateFormat('dd.MM.yyyy');

/// Размеры календаря
const double _cellSize = 14.0;
const double _cellSpacing = 4.0;
const double _cellSizeCoefficient = 0.94;
const double _dayFontSize = 9.0;

/// Временные параметры анимации
const Duration _animationDuration = Duration(milliseconds: 400);
const Duration _cellAnimationDuration = Duration(milliseconds: 220);

/// Коэффициенты прозрачности цветов
const double _emptyCellAlpha = 0.18;
const double _emptyCellBorderAlpha = 0.28;
const double _emptyCellTextAlpha = 0.9;
const double _maxCellAlpha = 0.28;
const double _maxCellBorderAlpha = 0.38;
const double _normalCellAlpha = 0.22;
const double _normalCellBorderAlpha = 0.32;

/// Виджет календаря смен - использует отдельный провайдер шифт-данных.
class ShiftsCalendarFlipCard extends ConsumerStatefulWidget {
  /// Создает виджет календаря смен с отдельным провайдером данных.
  const ShiftsCalendarFlipCard({super.key});

  @override
  ConsumerState<ShiftsCalendarFlipCard> createState() =>
      _ShiftsCalendarFlipCardState();
}

class _ShiftsCalendarFlipCardState extends ConsumerState<ShiftsCalendarFlipCard>
    with SingleTickerProviderStateMixin {
  DateTime? _selectedDate;
  double _selectedAmount = 0;
  late final DateTime _currentMonth;
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _currentMonth = DateTime.now();
    _animController = AnimationController(
      duration: _animationDuration,
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut),
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final shiftsAsync = ref.watch(shiftsForMonthProvider(_currentMonth));

    if (_selectedDate != null) {
      final dateDetailsAsync = ref.watch(shiftsForDateProvider(_selectedDate!));

      return AnimatedBuilder(
        animation: _animController,
        builder: (context, child) {
          return Stack(
            children: [
              /// Календарь видимый в фоне (скрывается с анимацией)
              Opacity(
                opacity: 1 - _fadeAnimation.value,
                child: SingleChildScrollView(
                  physics: const NeverScrollableScrollPhysics(),
                  child: shiftsAsync.when(
                    loading: () => const ShiftsHeatmap(
                      shifts: [],
                      isLoading: true,
                      onDateTap: null,
                    ),
                    error: (err, stack) => Center(
                      child: SelectableText('Ошибка загрузки: $err'),
                    ),
                    data: (shifts) => IgnorePointer(
                      child: ShiftsHeatmap(
                        shifts: shifts,
                        isLoading: false,
                        onDateTap: null,
                      ),
                    ),
                  ),
                ),
              ),

              /// Модальное окно с деталями дня
              Positioned.fill(
                child: dateDetailsAsync.when(
                  loading: () => const Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  error: (err, stack) => Center(
                    child: SelectableText('Ошибка: $err'),
                  ),
                  data: (details) {
                    final objectTotals =
                        details['objectTotals'] as Map<String, dynamic>? ?? {};
                    final systemsByObject = details['systemsByObject']
                            as Map<String, Map<String, double>>? ??
                        {};

                    return Transform.scale(
                      scale: _scaleAnimation.value,
                      child: Opacity(
                        opacity: _fadeAnimation.value,
                        child: _CalendarBackSide(
                          date: _selectedDate,
                          amount: _selectedAmount,
                          objectTotals: objectTotals,
                          systemsByObject: systemsByObject,
                          onClose: () {
                            _animController.reverse().then((_) {
                              setState(() {
                                _selectedDate = null;
                                _selectedAmount = 0;
                              });
                            });
                          },
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      );
    }

    /// Календарь смен - основной вид
    return shiftsAsync.when(
      loading: () => const SingleChildScrollView(
        physics: NeverScrollableScrollPhysics(),
        child: ShiftsHeatmap(
          shifts: [],
          isLoading: true,
          onDateTap: null,
        ),
      ),
      error: (err, stack) => SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        child: Center(
          child: SelectableText('Ошибка загрузки: $err'),
        ),
      ),
      data: (shifts) => SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        child: ShiftsHeatmap(
          shifts: shifts,
          isLoading: false,
          onDateTap: (d, v) {
            _animController.reset();
            setState(() {
              _selectedDate = d;
              _selectedAmount = v;
            });
            _animController.forward();
          },
        ),
      ),
    );
  }
}

/// Виджет тепловой карты смен.
///
/// Отображает календарь текущего месяца с цветовой индикацией
/// интенсивности работ по дням. Более насыщенный цвет означает
/// большую сумму выполненных работ в этот день.
class ShiftsHeatmap extends StatelessWidget {
  /// Список смен, агрегированный по датам.
  final List<Map<String, dynamic>> shifts;

  /// Флаг загрузки данных.
  final bool isLoading;

  /// Callback при нажатии на дату.
  final void Function(DateTime date, double value)? onDateTap;

  /// Создает виджет тепловой карты смен.
  const ShiftsHeatmap({
    super.key,
    required this.shifts,
    required this.isLoading,
    this.onDateTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    final monthEnd = DateTime(now.year, now.month + 1, 0);

    final Map<DateTime, double> sumByDate = {};
    double maxValue = 0;

    for (final shift in shifts) {
      final date = shift['date'] as DateTime?;
      final total = (shift['total'] as num?)?.toDouble() ?? 0.0;

      if (date != null) {
        final d = DateTime(date.year, date.month, date.day);
        sumByDate[d] = (sumByDate[d] ?? 0) + total;
        if (sumByDate[d]! > maxValue) maxValue = sumByDate[d]!;
      }
    }

    final int prefix = monthStart.weekday - 1;
    final int daysInMonth = monthEnd.day;
    final int totalCells = ((prefix + daysInMonth + 6) ~/ 7) * 7;

    final List<DateTime?> cells = List<DateTime?>.filled(totalCells, null);
    for (int i = 0; i < daysInMonth; i++) {
      cells[prefix + i] = DateTime(now.year, now.month, i + 1);
    }

    Widget cell(DateTime? d) {
      if (d == null) return const SizedBox(width: _cellSize, height: _cellSize);

      final v = sumByDate[d] ?? 0.0;
      final bool isMax = maxValue > 0 && (v == maxValue);
      final bool isZero = v == 0.0;

      Color fill;
      Color border;
      Color textColor;

      if (isZero) {
        fill = _softRed.withValues(alpha: _emptyCellAlpha);
        border = _softRed.withValues(alpha: _emptyCellBorderAlpha);
        textColor = _softRed.withValues(alpha: _emptyCellTextAlpha);
      } else if (isMax) {
        fill = _whatsappGreen.withValues(alpha: _maxCellAlpha);
        border = _whatsappGreen.withValues(alpha: _maxCellBorderAlpha);
        textColor = _whatsappGreen;
      } else {
        fill = _telegramBlue.withValues(alpha: _normalCellAlpha);
        border = _telegramBlue.withValues(alpha: _normalCellBorderAlpha);
        textColor = _telegramBlue;
      }

      final box = Tooltip(
        message: '${_dateFormatter.format(d)} — ${_moneyFormatter.format(v)}',
        child: AnimatedContainer(
          duration: _cellAnimationDuration,
          curve: Curves.easeOut,
          margin: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: fill,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: border),
          ),
          width: _cellSize,
          height: _cellSize,
          child: Center(
            child: Text(
              '${d.day}',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontSize: _dayFontSize,
                    height: 1.0,
                    color: textColor.withValues(alpha: 0.9),
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        ),
      );

      if (onDateTap == null || isZero) return box;
      return GestureDetector(onTap: () => onDateTap!(d, v), child: box);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(CupertinoIcons.calendar,
                size: 18,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7)),
            const SizedBox(width: 8),
            Text(
              'Календарь смен',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(width: 8),
            if (isLoading)
              const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
          ],
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            const columns = 7;
            final rows = (cells.length / columns).ceil();
            const double spacing = _cellSpacing;
            final double baseSize =
                (constraints.maxWidth - (columns * spacing)) / columns;
            final double size = baseSize * _cellSizeCoefficient;

            List<Widget> weekRows = [];
            for (int r = 0; r < rows; r++) {
              final startIndex = r * columns;
              final endIndex = startIndex + columns;
              final weekDays = cells.sublist(startIndex, endIndex);
              weekRows.add(Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: weekDays
                      .map((d) =>
                          SizedBox(width: size, height: size, child: cell(d)))
                      .toList(),
                ),
              ));
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: weekRows,
            );
          },
        ),
      ],
    );
  }
}

class _CalendarBackSide extends StatelessWidget {
  final DateTime? date;
  final double amount;
  final Map<String, dynamic> objectTotals;
  final Map<String, Map<String, double>> systemsByObject;
  final VoidCallback onClose;

  const _CalendarBackSide({
    required this.date,
    required this.amount,
    required this.objectTotals,
    required this.systemsByObject,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateStr = date != null ? _dateFormatter.format(date!) : '—';

    /// Строит список систем для объекта.
    List<Widget> buildSystemRows(Map<String, double> map) {
      final entries = map.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      return entries
          .map((e) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      margin: const EdgeInsets.only(right: 8, left: 2),
                      decoration: BoxDecoration(
                        color: _whatsappGreen.withValues(alpha: 0.9),
                        shape: BoxShape.circle,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        e.key,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Text(
                      _moneyFormatter.format(e.value),
                      style: theme.textTheme.labelMedium?.copyWith(
                        color:
                            theme.colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ))
          .toList();
    }

    return Align(
      alignment: Alignment.topLeft,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              /// Верхняя панель: дата слева, кнопка назад справа.
              Row(
                children: [
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        dateStr,
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w800),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Назад к календарю',
                    onPressed: onClose,
                    icon: const Icon(CupertinoIcons.arrow_right_arrow_left),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const SizedBox(height: 6),
              Builder(builder: (context) {
                final sortedObjects = objectTotals.entries
                    .map((e) => MapEntry(e.key, (e.value as num).toDouble()))
                    .toList()
                  ..sort((a, b) => b.value.compareTo(a.value));

                /// Проверка на пустые данные
                if (sortedObjects.isEmpty) {
                  return Center(
                    child: Text(
                      'Нет данных за выбранный день',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color:
                            theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  );
                }

                return Column(
                  children: sortedObjects.map((obj) {
                    final String objName = obj.key;
                    final double objSum = obj.value;
                    final systems =
                        systemsByObject[objName] ?? <String, double>{};
                    final systemRows = buildSystemRows(systems);

                    return Container(
                      width: double.infinity,
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color:
                              theme.colorScheme.outline.withValues(alpha: 0.18),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  objName,
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Text(
                                _moneyFormatter.format(objSum),
                                style: theme.textTheme.labelLarge?.copyWith(
                                  color: theme.colorScheme.primary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          if (systemRows.isEmpty)
                            Text(
                              'Нет систем',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurface
                                    .withValues(alpha: 0.6),
                              ),
                            )
                          else
                            Column(children: systemRows),
                        ],
                      ),
                    );
                  }).toList(),
                );
              }),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
