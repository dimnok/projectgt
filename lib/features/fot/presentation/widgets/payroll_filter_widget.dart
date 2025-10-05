import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/widgets/gt_dropdown.dart';
import '../providers/payroll_filter_providers.dart';

/// Опция для dropdown списков в фильтре
class _Option {
  final String value;
  final String label;
  const _Option(this.value, this.label);

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is _Option && other.value == value);

  @override
  int get hashCode => value.hashCode;
}

/// Кнопка в AppBar для открытия панели фильтров ФОТ (объекты, должности).
///
/// Отображает иконку tune, при нажатии на которую открывается всплывающая
/// панель с фильтрами по объектам и должностям сотрудников.
class PayrollFiltersAction extends ConsumerWidget {
  /// Создаёт кнопку фильтров для раскрытия всплывающей панели с фильтрами ФОТ.
  const PayrollFiltersAction({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final iconKey = GlobalKey();
    final filterState = ref.watch(payrollFilterProvider);

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
        color: Theme.of(context).colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
          ),
        ),
        items: const [
          PopupMenuItem(
            enabled: false,
            padding: EdgeInsets.zero,
            child: _PayrollFiltersPanel(),
          ),
        ],
      );
    }

    return Container(
      key: iconKey,
      child: Stack(
        children: [
          IconButton(
            tooltip: 'Фильтры',
            icon: const Icon(Icons.tune),
            onPressed: openPopup,
          ),
          // Индикатор активных фильтров
          if (filterState.hasActiveFilters)
            Positioned(
              right: 8,
              top: 8,
              child: Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Константные списки месяцев
const _kMonthOptions = [
  _Option('1', 'Январь'),
  _Option('2', 'Февраль'),
  _Option('3', 'Март'),
  _Option('4', 'Апрель'),
  _Option('5', 'Май'),
  _Option('6', 'Июнь'),
  _Option('7', 'Июль'),
  _Option('8', 'Август'),
  _Option('9', 'Сентябрь'),
  _Option('10', 'Октябрь'),
  _Option('11', 'Ноябрь'),
  _Option('12', 'Декабрь'),
];

/// Панель фильтров ФОТ (год, месяц, объекты и должности)
class _PayrollFiltersPanel extends ConsumerStatefulWidget {
  const _PayrollFiltersPanel();

  @override
  ConsumerState<_PayrollFiltersPanel> createState() =>
      _PayrollFiltersPanelState();
}

class _PayrollFiltersPanelState extends ConsumerState<_PayrollFiltersPanel> {
  // Локальное состояние для редактирования фильтров без немедленного применения
  List<String> _selectedObjectIds = [];
  List<String> _selectedPositions = [];
  int _selectedYear = DateTime.now().year;
  int _selectedMonth = DateTime.now().month;

  // Генерируем список годов один раз
  late final List<_Option> _yearOptions = List.generate(
    10,
    (i) {
      final year = DateTime.now().year - 5 + i;
      return _Option(year.toString(), year.toString());
    },
  );

  @override
  void initState() {
    super.initState();
    // Инициализируем локальное состояние текущими значениями из провайдера
    final filterState = ref.read(payrollFilterProvider);
    _selectedObjectIds = List.from(filterState.selectedObjectIds);
    _selectedPositions = List.from(filterState.selectedPositions);
    _selectedYear = filterState.selectedYear;
    _selectedMonth = filterState.selectedMonth;
  }

  void _applyFilters() {
    ref
        .read(payrollFilterProvider.notifier)
        .setSelectedObjects(_selectedObjectIds);
    ref
        .read(payrollFilterProvider.notifier)
        .setSelectedPositions(_selectedPositions);
    ref
        .read(payrollFilterProvider.notifier)
        .setYearAndMonth(_selectedYear, _selectedMonth);
    if (!context.mounted) return;
    Navigator.of(context).pop();
  }

  void _resetFilters() {
    ref.read(payrollFilterProvider.notifier).resetFilters();
    if (!context.mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final objects = ref.watch(availableObjectsForPayrollProvider);
    final positionsAsync = ref.watch(availablePositionsForPayrollProvider);

    final objectOptions = objects
        .map<_Option>((o) => _Option(o.id as String, o.name as String))
        .toList();

    // Обрабатываем AsyncValue для должностей
    final positionOptions = positionsAsync.when(
      data: (positions) =>
          positions.map<_Option>((p) => _Option(p, p)).toList(),
      loading: () => <_Option>[],
      error: (_, __) => <_Option>[],
    );

    // Находим выбранные элементы из существующих списков
    final selectedYearOption = _yearOptions.firstWhere(
      (o) => o.value == _selectedYear.toString(),
      orElse: () => _yearOptions.first,
    );
    final selectedMonthOption = _kMonthOptions.firstWhere(
      (o) => o.value == _selectedMonth.toString(),
      orElse: () => _kMonthOptions.first,
    );
    final selectedObjectOptions = _selectedObjectIds
        .map<_Option>((id) => objectOptions.firstWhere((o) => o.value == id,
            orElse: () => _Option(id, id)))
        .toList();
    final selectedPositionOptions = _selectedPositions
        .map<_Option>((pos) => positionOptions.firstWhere((o) => o.value == pos,
            orElse: () => _Option(pos, pos)))
        .toList();

    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 360, maxWidth: 420),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Заголовок
            Text(
              'Фильтры',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            // Год
            GTDropdown<_Option>(
              items: _yearOptions,
              itemDisplayBuilder: (o) => o.label,
              selectedItem: selectedYearOption,
              onSelectionChanged: (opt) {
                if (opt != null) {
                  setState(() {
                    _selectedYear = int.parse(opt.value);
                  });
                }
              },
              labelText: 'Год',
              hintText: 'Выберите...',
              allowMultipleSelection: false,
            ),
            const SizedBox(height: 12),

            // Месяц
            GTDropdown<_Option>(
              items: _kMonthOptions,
              itemDisplayBuilder: (o) => o.label,
              selectedItem: selectedMonthOption,
              onSelectionChanged: (opt) {
                if (opt != null) {
                  setState(() {
                    _selectedMonth = int.parse(opt.value);
                  });
                }
              },
              labelText: 'Месяц',
              hintText: 'Выберите...',
              allowMultipleSelection: false,
            ),
            const SizedBox(height: 12),

            // Объекты (мультивыбор)
            GTDropdown<_Option>(
              items: objectOptions,
              itemDisplayBuilder: (o) => o.label,
              selectedItems: selectedObjectOptions,
              onMultiSelectionChanged: (opts) {
                setState(() {
                  _selectedObjectIds = opts.map((e) => e.value).toList();
                });
              },
              labelText: 'Объекты',
              hintText: 'Выберите...',
              allowMultipleSelection: true,
            ),
            const SizedBox(height: 12),

            // Должности (мультивыбор)
            GTDropdown<_Option>(
              items: positionOptions,
              itemDisplayBuilder: (o) => o.label,
              selectedItems: selectedPositionOptions,
              onMultiSelectionChanged: (opts) {
                setState(() {
                  _selectedPositions = opts.map((e) => e.value).toList();
                });
              },
              labelText: 'Должности',
              hintText: 'Выберите...',
              allowMultipleSelection: true,
            ),

            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _resetFilters,
                  child: const Text('Сброс'),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: _applyFilters,
                  child: const Text('Применить'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
