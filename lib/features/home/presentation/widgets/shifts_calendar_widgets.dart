import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';

const Color _telegramBlue = Color(0xFF229ED9);
const Color _whatsappGreen = Color(0xFF25D366);
const Color _softRed = Color(0xFFE57373);

/// Виджет календаря смен с эффектом переворота карты.
///
/// Отображает календарь смен с возможностью переворота для просмотра
/// детальной информации по выбранной дате.
class ShiftsCalendarFlipCard extends StatefulWidget {
  /// Список отчетов о сменах для отображения.
  final List<dynamic> reports; // ExportReport

  /// Флаг загрузки данных.
  final bool isLoading;

  /// Создает виджет календаря смен с переворотом.
  ///
  /// [reports] - список отчетов о сменах.
  /// [isLoading] - флаг загрузки данных.
  const ShiftsCalendarFlipCard(
      {super.key, required this.reports, required this.isLoading});

  @override
  State<ShiftsCalendarFlipCard> createState() => _ShiftsCalendarFlipCardState();
}

class _ShiftsCalendarFlipCardState extends State<ShiftsCalendarFlipCard> {
  bool _flipped = false;
  DateTime? _selectedDate;
  double _selectedAmount = 0;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 500),
      transitionBuilder: (child, anim) {
        final rotate = Tween(begin: math.pi, end: 0.0).animate(anim);
        return AnimatedBuilder(
          animation: rotate,
          child: child,
          builder: (context, child) {
            final isUnder = (ValueKey(_flipped) != child!.key);
            final tilt = (anim.value - 0.5).abs() - 0.5;
            final angle = isUnder ? -rotate.value : rotate.value;
            return Transform(
              transform: Matrix4.rotationY(angle)..setEntry(3, 0, 0.001 * tilt),
              alignment: Alignment.center,
              child: child,
            );
          },
        );
      },
      child: _flipped
          ? Builder(builder: (context) {
              final DateTime? d = _selectedDate;
              final Map<String, double> objectTotals = {};
              final Map<String, Map<String, double>> systemsByObject = {};
              if (d != null) {
                final DateTime selected = DateTime(d.year, d.month, d.day);
                for (final r in widget.reports) {
                  final DateTime rw = DateTime(
                      r.workDate.year, r.workDate.month, r.workDate.day);
                  if (rw == selected) {
                    final double total = (r.total ?? 0).toDouble();
                    final String obj = (r.objectName ?? '—').toString();
                    final String sys = (r.system ?? '—').toString();
                    objectTotals[obj] = (objectTotals[obj] ?? 0) + total;
                    final m = systemsByObject.putIfAbsent(
                        obj, () => <String, double>{});
                    m[sys] = (m[sys] ?? 0) + total;
                  }
                }
              }
              return _CalendarBackSide(
                key: const ValueKey(true),
                date: _selectedDate,
                amount: _selectedAmount,
                objectTotals: objectTotals,
                systemsByObject: systemsByObject,
                onClose: () => setState(() => _flipped = false),
              );
            })
          : SingleChildScrollView(
              key: const ValueKey(false),
              physics: const NeverScrollableScrollPhysics(),
              child: ShiftsHeatmap(
                reports: widget.reports,
                isLoading: widget.isLoading,
                onDateTap: (d, v) => setState(() {
                  _selectedDate = d;
                  _selectedAmount = v;
                  _flipped = true;
                }),
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
  /// Список отчетов о сменах для отображения.
  final List<dynamic> reports; // ExportReport

  /// Флаг загрузки данных.
  final bool isLoading;

  /// Callback при нажатии на дату.
  ///
  /// [date] - выбранная дата.
  /// [value] - сумма работ за эту дату.
  final void Function(DateTime date, double value)? onDateTap;

  /// Создает виджет тепловой карты смен.
  ///
  /// [reports] - список отчетов о сменах.
  /// [isLoading] - флаг загрузки данных.
  /// [onDateTap] - callback при выборе даты.
  const ShiftsHeatmap(
      {super.key,
      required this.reports,
      required this.isLoading,
      this.onDateTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    final monthEnd = DateTime(now.year, now.month + 1, 0);

    final Map<DateTime, double> sumByDate = {};
    double maxValue = 0;
    for (final r in reports) {
      if (r.workDate.year == now.year && r.workDate.month == now.month) {
        final d = DateTime(r.workDate.year, r.workDate.month, r.workDate.day);
        final total = (r.total ?? 0).toDouble();
        sumByDate[d] = (sumByDate[d] ?? 0) + total;
        if (sumByDate[d]! > maxValue) maxValue = sumByDate[d]!;
      }
    }

    final int prefix = monthStart.weekday - 1;
    final int daysInMonth = monthEnd.day;
    final int totalCells = ((prefix + daysInMonth + 6) ~/ 7) * 7;

    List<DateTime?> cells = List<DateTime?>.filled(totalCells, null);
    for (int i = 0; i < daysInMonth; i++) {
      cells[prefix + i] = DateTime(now.year, now.month, i + 1);
    }

    Widget cell(DateTime? d) {
      if (d == null) return const SizedBox(width: 14, height: 14);
      final v = sumByDate[d] ?? 0.0;
      final bool isMax = maxValue > 0 && (v == maxValue);
      final bool isZero = v == 0.0;

      Color fill;
      Color border;
      Color textColor;
      if (isZero) {
        fill = _softRed.withValues(alpha: 0.18);
        border = _softRed.withValues(alpha: 0.28);
        textColor = _softRed.withValues(alpha: 0.9);
      } else if (isMax) {
        fill = _whatsappGreen.withValues(alpha: 0.28);
        border = _whatsappGreen.withValues(alpha: 0.38);
        textColor = _whatsappGreen;
      } else {
        fill = _telegramBlue.withValues(alpha: 0.22);
        border = _telegramBlue.withValues(alpha: 0.32);
        textColor = _telegramBlue;
      }

      final box = Tooltip(
        message:
            '${DateFormat('dd.MM.yyyy').format(d)} — ${NumberFormat.currency(locale: 'ru_RU', symbol: '₽', decimalDigits: 0).format(v)}',
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          margin: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: fill,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: border),
          ),
          width: 14,
          height: 14,
          child: Center(
            child: Text(
              '${d.day}',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontSize: 9,
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
            const double spacing = 4.0;
            final double baseSize =
                (constraints.maxWidth - (columns * spacing)) / columns;
            final double size = baseSize * 0.94;

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
  final Map<String, double> objectTotals;
  final Map<String, Map<String, double>> systemsByObject;
  final VoidCallback onClose;
  const _CalendarBackSide(
      {super.key,
      required this.date,
      required this.amount,
      required this.objectTotals,
      required this.systemsByObject,
      required this.onClose});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateStr = date != null ? DateFormat('dd.MM.yyyy').format(date!) : '—';
    // Строки систем вместо чипов
    List<Widget> buildSystemRows(Map<String, double> map) {
      final moneyFmt =
          NumberFormat.currency(locale: 'ru_RU', symbol: '₽', decimalDigits: 0);
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
                      moneyFmt.format(e.value),
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
              // Верхняя панель: дата слева, кнопка назад справа
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
                    icon: const Icon(Icons.swap_horiz),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
              const SizedBox(height: 8),

              const SizedBox(height: 6),
              Builder(builder: (context) {
                final moneyFmt = NumberFormat.currency(
                    locale: 'ru_RU', symbol: '₽', decimalDigits: 0);
                final sortedObjects = objectTotals.entries.toList()
                  ..sort((a, b) => b.value.compareTo(a.value));
                return Column(
                  children: sortedObjects.map((obj) {
                    final String objName = obj.key;
                    final double objSum = obj.value;
                    final systems =
                        systemsByObject[objName] ?? const <String, double>{};
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
                                moneyFmt.format(objSum),
                                style: theme.textTheme.labelLarge?.copyWith(
                                  color: theme.colorScheme.primary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          if (systemRows.isEmpty)
                            Text('Нет систем',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurface
                                      .withValues(alpha: 0.6),
                                ))
                          else
                            Column(
                              children: systemRows,
                            ),
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
