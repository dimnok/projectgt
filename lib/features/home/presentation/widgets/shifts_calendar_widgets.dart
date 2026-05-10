import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/shifts_provider.dart';

const Color _telegramBlue = Color(0xFF3B82F6); // Vibrant Blue
const Color _whatsappGreen = Color(0xFF10B981); // Vibrant Green
const Color _softRed = Color(0xFFEF4444); // Vibrant Red
const Color _warningAmber = Color(0xFFF59E0B); // Amber for medium values

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

/// Виджет календаря смен - использует отдельный провайдер шифт-данных.
class ShiftsCalendarFlipCard extends ConsumerStatefulWidget {
  /// Если `true`, заголовок не отображается.
  final bool hideHeader;

  /// Создает виджет календаря смен с отдельным провайдером данных.
  const ShiftsCalendarFlipCard({
    super.key,
    this.hideHeader = false,
  });

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
    final monthStr =
        '${_currentMonth.year}-${_currentMonth.month.toString().padLeft(2, '0')}';
    final shiftsAsync = ref.watch(shiftsForMonthProvider(monthStr));

    if (_selectedDate != null) {
      final dateStr =
          '${_selectedDate!.year}-${_selectedDate!.month.toString().padLeft(2, '0')}-${_selectedDate!.day.toString().padLeft(2, '0')}';
      final dateDetailsAsync = ref.watch(shiftsForDateProvider(dateStr));

      return AnimatedBuilder(
        animation: _animController,
        builder: (context, child) {
          return Stack(
            children: [
              /// Календарь видимый в фоне (скрывается с анимацией)
              Opacity(
                opacity: 1 - _fadeAnimation.value,
                child: shiftsAsync.when(
                  loading: () => ShiftsHeatmap(
                    shifts: [],
                    isLoading: true,
                    onDateTap: null,
                    hideHeader: widget.hideHeader,
                  ),
                  error: (err, stack) => Center(
                    child: SelectableText('Ошибка загрузки: $err'),
                  ),
                  data: (shifts) => IgnorePointer(
                    child: ShiftsHeatmap(
                      shifts: shifts,
                      isLoading: false,
                      onDateTap: null,
                      hideHeader: widget.hideHeader,
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
      loading: () => ShiftsHeatmap(
        shifts: [],
        isLoading: true,
        onDateTap: null,
        hideHeader: widget.hideHeader,
      ),
      error: (err, stack) => Center(
        child: SelectableText('Ошибка загрузки: $err'),
      ),
      data: (shifts) => ShiftsHeatmap(
        shifts: shifts,
        isLoading: false,
        hideHeader: widget.hideHeader,
        onDateTap: (d, v) {
          _animController.reset();
          setState(() {
            _selectedDate = d;
            _selectedAmount = v;
          });
          _animController.forward();
        },
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

  /// Если `true`, заголовок не отображается.
  final bool hideHeader;

  /// Создает виджет тепловой карты смен.
  const ShiftsHeatmap({
    super.key,
    required this.shifts,
    required this.isLoading,
    this.onDateTap,
    this.hideHeader = false,
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
        fill = _softRed.withValues(alpha: 0.08);
        border = _softRed.withValues(alpha: 0.15);
        textColor = _softRed;
      } else if (isMax) {
        fill = _whatsappGreen.withValues(alpha: 0.15);
        border = _whatsappGreen.withValues(alpha: 0.25);
        textColor = _whatsappGreen;
      } else {
        // Добавляем промежуточный цвет для средних значений
        final bool isHigh = maxValue > 0 && (v > maxValue * 0.6);
        final Color base = isHigh ? _warningAmber : _telegramBlue;
        fill = base.withValues(alpha: 0.12);
        border = base.withValues(alpha: 0.2);
        textColor = base;
      }

      final box = Tooltip(
        message: '${_dateFormatter.format(d)} — ${_moneyFormatter.format(v)}',
        child: AnimatedContainer(
          duration: _cellAnimationDuration,
          curve: Curves.easeOut,
          margin: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: fill,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: border, width: 1.2),
            boxShadow: !isZero ? [
              BoxShadow(
                color: textColor.withValues(alpha: 0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              )
            ] : null,
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
                    fontWeight: FontWeight.w800,
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
        if (!hideHeader) ...[
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
        ],
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
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
    );
  }
}
