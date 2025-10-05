import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:projectgt/core/widgets/gt_dropdown.dart';
import '../../domain/entities/timesheet_entry.dart';
import '../providers/timesheet_provider.dart';
import '../providers/timesheet_filters_providers.dart';

/// Провайдеры состояния поиска табеля
final timesheetSearchQueryProvider = StateProvider<String>((ref) => '');

/// Видимость поля поиска в AppBar
final timesheetSearchVisibleProvider = StateProvider<bool>((ref) => false);

/// Контроллер поля ввода поиска с авто-диспозом
final _timesheetSearchControllerProvider =
    Provider.autoDispose<TextEditingController>((ref) {
  final initial = ref.read(timesheetSearchQueryProvider);
  final controller = TextEditingController(text: initial);
  ref.onDispose(controller.dispose);

  // Синхронизируемся при внешнем изменении провайдера
  ref.listen<String>(timesheetSearchQueryProvider, (prev, next) {
    if (controller.text != next) {
      controller.text = next;
      controller.selection = TextSelection.fromPosition(
        TextPosition(offset: controller.text.length),
      );
    }
  });

  return controller;
});

/// Виджет действий поиска для AppBar: анимированное поле + кнопка лупы
class TimesheetSearchAction extends ConsumerWidget {
  /// Конструктор виджета действий поиска.
  const TimesheetSearchAction({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final visible = ref.watch(timesheetSearchVisibleProvider);
    final query = ref.watch(timesheetSearchQueryProvider);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeInOut,
          width: visible ? 300 : 0,
          child: visible
              ? Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Container(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.10),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                        BoxShadow(
                          color: Colors.white.withValues(alpha: 0.06),
                          blurRadius: 1,
                          offset: const Offset(-1, -1),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: ref.watch(_timesheetSearchControllerProvider),
                      autofocus: true,
                      onChanged: (value) => ref
                          .read(timesheetSearchQueryProvider.notifier)
                          .state = value,
                      decoration: InputDecoration(
                        hintText: 'Поиск по ФИО...',
                        isDense: true,
                        border: InputBorder.none,
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide(
                            color: theme.colorScheme.outline
                                .withValues(alpha: 0.25),
                            width: 1,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        prefixIcon: const Icon(Icons.person_search, size: 20),
                      ),
                    ),
                  ),
                )
              : const SizedBox.shrink(),
        ),
        IconButton(
          icon: Icon(
            query.trim().isNotEmpty ? Icons.close : Icons.search,
            color: query.trim().isNotEmpty ? Colors.red : null,
          ),
          tooltip: query.trim().isNotEmpty ? 'Очистить поиск' : 'Поиск по ФИО',
          onPressed: () {
            if (query.trim().isNotEmpty) {
              // Очищаем поиск
              ref.read(timesheetSearchQueryProvider.notifier).state = '';
            } else {
              // Переключаем видимость поля поиска
              final newVisible = !ref.read(timesheetSearchVisibleProvider);
              ref.read(timesheetSearchVisibleProvider.notifier).state =
                  newVisible;
            }
          },
        ),
      ],
    );
  }
}

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

/// Кнопка в AppBar для открытия панели фильтров табеля (объекты, должности).
class TimesheetFiltersAction extends ConsumerWidget {
  /// Создаёт кнопку фильтров для раскрытия всплывающей панели с фильтрами табеля.
  const TimesheetFiltersAction({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
            child: _TimesheetFiltersPanel(),
          ),
        ],
      );
    }

    return Container(
      key: iconKey,
      child: IconButton(
        tooltip: 'Фильтры',
        icon: const Icon(Icons.tune),
        onPressed: openPopup,
      ),
    );
  }
}

/// Панель фильтров табеля (объекты и должности)
class _TimesheetFiltersPanel extends ConsumerStatefulWidget {
  const _TimesheetFiltersPanel();

  @override
  ConsumerState<_TimesheetFiltersPanel> createState() =>
      _TimesheetFiltersPanelState();
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

class _TimesheetFiltersPanelState
    extends ConsumerState<_TimesheetFiltersPanel> {
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
    final ts = ref.read(timesheetProvider);
    _selectedObjectIds = ts.selectedObjectIds ?? [];
    _selectedPositions = ts.selectedPositions ?? [];
    _selectedYear = ts.startDate.year;
    _selectedMonth = ts.startDate.month;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final objects = ref.watch(availableObjectsForTimesheetProvider);
    final positionsAsync = ref.watch(availablePositionsForTimesheetProvider);

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
    final selectedPositionOptions =
        _selectedPositions.map<_Option>((p) => _Option(p, p)).toList();

    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 360, maxWidth: 420),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Фильтры',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
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
                  onPressed: () {
                    // Сбрасываем фильтры
                    ref.read(timesheetProvider.notifier).resetFilters();
                    if (!context.mounted) return;
                    Navigator.of(context).pop();
                  },
                  child: const Text('Сброс'),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: () {
                    // Применяем фильтры из локального состояния
                    final startDate =
                        DateTime(_selectedYear, _selectedMonth, 1);
                    final endDate =
                        DateTime(_selectedYear, _selectedMonth + 1, 0);
                    ref
                        .read(timesheetProvider.notifier)
                        .setDateRange(startDate, endDate);
                    ref
                        .read(timesheetProvider.notifier)
                        .setSelectedObjects(_selectedObjectIds);
                    ref
                        .read(timesheetProvider.notifier)
                        .setSelectedPositions(_selectedPositions);
                    if (!context.mounted) return;
                    Navigator.of(context).pop();
                  },
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

/// Утилита фильтрации записей табеля по ФИО сотрудника
List<TimesheetEntry> filterTimesheetByEmployeeName(
  List<TimesheetEntry> entries,
  String query,
) {
  final searchQuery = query.trim().toLowerCase();
  if (searchQuery.isEmpty) return entries;

  return entries.where((entry) {
    final employeeName = (entry.employeeName ?? '').toLowerCase();
    // Поиск по частичному совпадению в ФИО
    return employeeName.contains(searchQuery);
  }).toList();
}

/// Утилита получения отфильтрованного списка сотрудников для выпадающего списка
List<String> getFilteredEmployeeNames(
  List<TimesheetEntry> allEntries,
  String searchQuery,
) {
  final entries = filterTimesheetByEmployeeName(allEntries, searchQuery);
  return entries
      .map((e) => e.employeeName ?? 'Неизвестный сотрудник')
      .toSet()
      .toList()
    ..sort();
}
