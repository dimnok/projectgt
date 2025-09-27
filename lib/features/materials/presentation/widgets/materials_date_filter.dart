import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:projectgt/core/utils/formatters.dart';

/// Выбранный период дат для фильтра материалов
final materialsDateRangeProvider = StateProvider<DateTimeRange?>((ref) => null);

/// Действие в AppBar: кнопка с календарём, открывающая компактный выбор диапазона дат
class MaterialsDateRangeAction extends ConsumerWidget {
  /// Конструктор действия выбора периода дат.
  const MaterialsDateRangeAction({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final range = ref.watch(materialsDateRangeProvider);
    final theme = Theme.of(context);
    final iconKey = GlobalKey();

    Future<void> openPopup() async {
      final box = iconKey.currentContext!.findRenderObject() as RenderBox;
      final overlay =
          Overlay.of(context).context.findRenderObject() as RenderBox;
      final offset = box.localToGlobal(Offset.zero, ancestor: overlay);
      final position = RelativeRect.fromLTRB(
        offset.dx,
        offset.dy + box.size.height,
        offset.dx + box.size.width,
        offset.dy,
      );

      await showMenu(
        context: context,
        position: position,
        elevation: 0,
        color: theme.colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(32),
          side: BorderSide(
            color: theme.colorScheme.outline.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        items: [
          const PopupMenuItem(
            enabled: false,
            padding: EdgeInsets.zero,
            child: _CompactDateRangePicker(),
          ),
        ],
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (range != null)
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: _RangeChip(range: range),
          ),
        Container(
          key: iconKey,
          child: IconButton(
            icon: const Icon(Icons.calendar_month),
            tooltip: 'Выбрать период',
            onPressed: openPopup,
          ),
        ),
      ],
    );
  }
}

class _RangeChip extends StatelessWidget {
  final DateTimeRange range;
  const _RangeChip({required this.range});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final text = '${formatRuDate(range.start)} — ${formatRuDate(range.end)}';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        text,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurface,
        ),
      ),
    );
  }
}

/// Компактный выбор периода через всплывающее окно
class _CompactDateRangePicker extends ConsumerStatefulWidget {
  const _CompactDateRangePicker();
  @override
  ConsumerState<_CompactDateRangePicker> createState() =>
      _CompactDateRangePickerState();
}

class _CompactDateRangePickerState
    extends ConsumerState<_CompactDateRangePicker> {
  late DateTime _today;
  DateTime? _start;
  DateTime? _end;
  bool _selectingStart = true;

  @override
  void initState() {
    super.initState();
    _today = DateTime.now();
    final current = ref.read(materialsDateRangeProvider);
    _start = current?.start;
    _end = current?.end;
    _selectingStart = _start == null || (_start != null && _end != null);
  }

  void _onDateChanged(DateTime date) {
    setState(() {
      if (_selectingStart) {
        _start = DateTime(date.year, date.month, date.day);
        if (_end != null && _end!.isBefore(_start!)) {
          _end = _start;
        }
        _selectingStart = false;
      } else {
        _end = DateTime(date.year, date.month, date.day);
        if (_start != null && _end!.isBefore(_start!)) {
          final tmp = _start;
          _start = _end;
          _end = tmp;
        }
        _selectingStart = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      builder: (context, t, child) {
        final scale = 0.98 + 0.02 * t; // 98% -> 100%
        return Opacity(
          opacity: t,
          child: Transform.scale(
            scale: scale,
            child: child,
          ),
        );
      },
      child: SizedBox(
        width: 360,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Верхняя панель: только кнопка "Сброс" справа
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _start = null;
                        _end = null;
                        _selectingStart = true;
                      });
                      // Сбросим общий провайдер, чтобы сразу убрать чип
                      ref.read(materialsDateRangeProvider.notifier).state =
                          null;
                    },
                    child: const Text('Сброс'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _CompactMonthGrid(
                today: _today,
                start: _start,
                end: _end,
                onPick: _onDateChanged,
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Отмена'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: () {
                      if (_start != null && _end != null) {
                        ref.read(materialsDateRangeProvider.notifier).state =
                            DateTimeRange(start: _start!, end: _end!);
                      }
                      Navigator.of(context).pop();
                    },
                    child: const Text('Готово'),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}

/// Мини-календарь месяца с выбором начала/конца и подсветкой диапазона
class _CompactMonthGrid extends StatefulWidget {
  final DateTime today;
  final DateTime? start;
  final DateTime? end;
  final ValueChanged<DateTime> onPick;
  const _CompactMonthGrid(
      {required this.today,
      required this.start,
      required this.end,
      required this.onPick});

  @override
  State<_CompactMonthGrid> createState() => _CompactMonthGridState();
}

class _CompactMonthGridState extends State<_CompactMonthGrid> {
  late DateTime _month; // первый день месяца

  @override
  void initState() {
    super.initState();
    final anchor = widget.start ?? widget.end ?? widget.today;
    _month = DateTime(anchor.year, anchor.month, 1);
  }

  void _shiftMonth(int delta) {
    setState(() {
      _month = DateTime(_month.year, _month.month + delta, 1);
    });
  }

  static const _monthsRu = [
    'Январь',
    'Февраль',
    'Март',
    'Апрель',
    'Май',
    'Июнь',
    'Июль',
    'Август',
    'Сентябрь',
    'Октябрь',
    'Ноябрь',
    'Декабрь'
  ];

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  bool _inRange(DateTime d) {
    final s = widget.start;
    final e = widget.end;
    if (s == null) return false;
    if (e == null) return _isSameDay(d, s); // только старт выбран
    final dd = DateTime(d.year, d.month, d.day);
    final ss = DateTime(s.year, s.month, s.day);
    final ee = DateTime(e.year, e.month, e.day);
    return dd.isAtSameMomentAs(ss) ||
        dd.isAtSameMomentAs(ee) ||
        (dd.isAfter(ss) && dd.isBefore(ee));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final firstWeekday =
        DateTime(_month.year, _month.month, 1).weekday; // 1..7 (Mon..Sun)
    final daysInMonth = DateTime(_month.year, _month.month + 1, 0).day;
    final leading = (firstWeekday + 6) % 7; // сдвиг так, чтобы понедельник = 0
    final totalCells = leading + daysInMonth;
    final rows = ((totalCells + 6) ~/ 7);

    Widget dayCell(DateTime? date) {
      final isValid = date != null;
      final inRange = isValid && _inRange(date);
      final textStyle = theme.textTheme.bodyMedium!.copyWith(
        color: inRange ? Colors.white : theme.colorScheme.onSurface,
        fontWeight: inRange ? FontWeight.w600 : FontWeight.w400,
      );
      final child = Center(
        child: Container(
          width: 32,
          height: 32,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: inRange ? Colors.blue : Colors.transparent,
            shape: BoxShape.circle,
          ),
          child: Text(isValid ? '${date.day}' : '', style: textStyle),
        ),
      );
      if (!isValid) return child;
      return GestureDetector(onTap: () => widget.onPick(date), child: child);
    }

    List<Widget> buildGrid() {
      final cells = <Widget>[];
      // Шапка дней недели (Пн-Вс)
      const weekdays = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];
      cells.add(Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: weekdays
            .map((w) => Expanded(
                child:
                    Center(child: Text(w, style: theme.textTheme.bodySmall))))
            .toList(),
      ));
      cells.add(const SizedBox(height: 6));

      int day = 1;
      for (int r = 0; r < rows; r++) {
        final rowChildren = <Widget>[];
        for (int c = 0; c < 7; c++) {
          final idx = r * 7 + c;
          DateTime? date;
          if (idx >= leading && day <= daysInMonth) {
            date = DateTime(_month.year, _month.month, day++);
          }
          rowChildren.add(Expanded(child: dayCell(date)));
        }
        cells.add(Row(children: rowChildren));
      }
      return cells;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left),
              onPressed: () => _shiftMonth(-1),
            ),
            Expanded(
              child: Center(
                child: Text('${_monthsRu[_month.month - 1]} ${_month.year}',
                    style: theme.textTheme.titleSmall),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right),
              onPressed: () => _shiftMonth(1),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ...buildGrid(),
      ],
    );
  }
}
