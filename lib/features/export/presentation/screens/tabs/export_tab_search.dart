import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:pluto_grid/pluto_grid.dart';
import 'dart:async';
import 'package:projectgt/core/utils/responsive_utils.dart';
import '../../providers/work_search_provider.dart';
import '../../providers/export_provider.dart';

/// Таб "Поиск" для расширенного поиска и фильтрации данных.
/// Включает в себя собственные табы под блоком фильтров.
class ExportTabSearch extends ConsumerStatefulWidget {
  /// Callback для переключения на таб "Выгрузка".
  final VoidCallback? onSwitchToReports;

  /// Создаёт таб поиска.
  const ExportTabSearch({
    super.key,
    this.onSwitchToReports,
  });

  @override
  ConsumerState<ExportTabSearch> createState() => _ExportTabSearchState();
}

class _ExportTabSearchState extends ConsumerState<ExportTabSearch> {
  /// Контроллер для поля поиска.
  final TextEditingController _searchController = TextEditingController();

  /// Контроллер для даты начала.
  final TextEditingController _startDateController = TextEditingController();

  /// Контроллер для даты окончания.
  final TextEditingController _endDateController = TextEditingController();

  /// Выбранная дата начала.
  DateTime? _startDate;

  /// Выбранная дата окончания.
  DateTime? _endDate;

  /// Выбранный объект.
  String? _selectedObjectId;

  /// Таймер для debounce поиска.
  Timer? _debounceTimer;

  /// Задержка для debounce в миллисекундах.
  static const int _debounceDelayMs = 500;

  /// Индекс выбранного таба внутри поиска.
  int _selectedTabIndex = 1; // По умолчанию таб "Поиск"

  /// Список табов.
  final List<Tab> _tabs = const [
    Tab(text: 'Выгрузка'),
    Tab(text: 'Поиск'),
  ];

  @override
  void initState() {
    super.initState();
    // Добавляем слушатель изменений в поле поиска
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _startDateController.dispose();
    _endDateController.dispose();
    super.dispose();
  }

  /// Обработчик изменений в поле поиска.
  void _onSearchChanged() {
    // Отменяем предыдущий таймер
    _debounceTimer?.cancel();

    // Запускаем новый таймер
    _debounceTimer = Timer(const Duration(milliseconds: _debounceDelayMs), () {
      _performSearch();
    });
  }

  /// Обработчик переключения табов.
  void _onTabChanged(int index) {
    if (index == 0) {
      // Переключение на таб "Выгрузка" - вызываем callback
      widget.onSwitchToReports?.call();
    } else {
      // Остаемся в табе "Поиск"
      setState(() {
        _selectedTabIndex = index;
      });
    }
  }

  /// Форматирует дату для отображения в стиле основного экспорта.
  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final searchState = ref.watch(workSearchProvider);
    final objectsAsync = ref.watch(availableObjectsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Блок фильтров для поиска
        _buildAdvancedFilters(context, theme, objectsAsync),

        // Табы под блоком фильтров
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 4.0),
          child: DefaultTabController(
            length: _tabs.length,
            initialIndex: _selectedTabIndex,
            child: Builder(
              builder: (context) {
                final TabController tabController =
                    DefaultTabController.of(context);
                tabController.addListener(() {
                  if (tabController.indexIsChanging) {
                    _onTabChanged(tabController.index);
                  }
                });
                return TabBar(
                  tabs: _tabs,
                  controller: tabController,
                  labelColor: theme.colorScheme.primary,
                  unselectedLabelColor: theme.colorScheme.outline,
                  indicatorColor: theme.colorScheme.primary,
                );
              },
            ),
          ),
        ),

        // Контент табов
        Expanded(
          child: IndexedStack(
            index: _selectedTabIndex,
            children: [
              // Таб "Выгрузка" - не должен отображаться, так как переключаемся на основной экран
              Container(),
              // Таб "Поиск" - результаты поиска
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: _buildSearchResults(context, theme, searchState),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Строит продвинутый блок фильтров в стиле основного экспорта.
  Widget _buildAdvancedFilters(BuildContext context, ThemeData theme,
      AsyncValue<List<Map<String, dynamic>>> objectsAsync) {
    final isDesktop = ResponsiveUtils.isDesktop(context);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Container(
        decoration: BoxDecoration(
          color: theme.brightness == Brightness.dark
              ? theme.colorScheme.surfaceContainerHighest
                  .withValues(alpha: 0.92)
              : theme.colorScheme.surface.withValues(alpha: 0.98),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: theme.brightness == Brightness.dark
                  ? Colors.black.withValues(alpha: 0.28)
                  : Colors.black.withValues(alpha: 0.16),
              blurRadius: 48,
              spreadRadius: 0,
              offset: const Offset(0, 16),
            ),
            BoxShadow(
              color: theme.brightness == Brightness.dark
                  ? Colors.black.withValues(alpha: 0.10)
                  : Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              spreadRadius: 0,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Заголовок и кнопки
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Поиск работ',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                Row(
                  children: [
                    // Кнопка "Очистить все фильтры"
                    TextButton.icon(
                      icon: const Icon(Icons.refresh),
                      label: const Text('Очистить все'),
                      onPressed: _clearSearch,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Фильтры
            if (isDesktop)
              Row(
                children: [
                  // Период
                  Expanded(
                    flex: 2,
                    child: _buildPeriodFilter(theme),
                  ),
                  const SizedBox(width: 16),
                  // Объект
                  Expanded(
                    child: _buildObjectFilter(theme, objectsAsync),
                  ),
                  const SizedBox(width: 16),
                  // Поиск
                  Expanded(
                    flex: 2,
                    child: _buildSearchField(theme),
                  ),
                ],
              )
            else
              Column(
                children: [
                  _buildPeriodFilter(theme),
                  const SizedBox(height: 16),
                  _buildObjectFilter(theme, objectsAsync),
                  const SizedBox(height: 16),
                  _buildSearchField(theme),
                ],
              ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  /// Создает фильтр по периоду.
  Widget _buildPeriodFilter(ThemeData theme) {
    return Row(
      children: [
        // Дата начала
        Expanded(
          child: TextFormField(
            controller: _startDateController,
            readOnly: true,
            decoration: InputDecoration(
              labelText: 'Дата начала',
              hintText: 'Выберите дату',
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              prefixIcon: const Icon(Icons.date_range),
              suffixIcon: const Icon(Icons.keyboard_arrow_down),
            ),
            onTap: () => _selectStartDate(context),
          ),
        ),
        const SizedBox(width: 12),
        // Дата окончания
        Expanded(
          child: TextFormField(
            controller: _endDateController,
            readOnly: true,
            decoration: InputDecoration(
              labelText: 'Дата окончания',
              hintText: 'Выберите дату',
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              prefixIcon: const Icon(Icons.date_range),
              suffixIcon: const Icon(Icons.keyboard_arrow_down),
            ),
            onTap: () => _selectEndDate(context),
          ),
        ),
      ],
    );
  }

  /// Создает фильтр по объекту.
  Widget _buildObjectFilter(
      ThemeData theme, AsyncValue<List<Map<String, dynamic>>> objectsAsync) {
    return objectsAsync.when(
      data: (objects) => DropdownButtonFormField<String>(
        value: _selectedObjectId,
        decoration: InputDecoration(
          labelText: 'Объект',
          hintText: 'Выберите объект',
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        ),
        items: [
          const DropdownMenuItem<String>(
            value: null,
            child: Text('Все объекты'),
          ),
          ...objects.map((object) {
            return DropdownMenuItem<String>(
              value: object['id']?.toString(),
              child: Text(object['name']?.toString() ?? ''),
            );
          }),
        ],
        onChanged: (value) {
          setState(() {
            _selectedObjectId = value;
          });
          // Автоматически запускаем поиск при изменении объекта
          _performSearch();
        },
      ),
      loading: () => DropdownButtonFormField<String>(
        value: null,
        decoration: InputDecoration(
          labelText: 'Объект',
          hintText: 'Загрузка...',
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        ),
        items: const [],
        onChanged: null,
      ),
      error: (error, stack) => DropdownButtonFormField<String>(
        value: null,
        decoration: InputDecoration(
          labelText: 'Объект',
          hintText: 'Ошибка загрузки',
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        ),
        items: const [],
        onChanged: null,
      ),
    );
  }

  /// Создает поле поиска.
  Widget _buildSearchField(ThemeData theme) {
    return StatefulBuilder(
      builder: (context, setState) {
        return TextFormField(
          controller: _searchController,
          decoration: InputDecoration(
            labelText: 'Поиск по наименованию работ',
            hintText: 'Поиск в реальном времени...',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            prefixIcon: const Icon(Icons.search),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _searchController.clear();
                      setState(() {}); // Обновляем локальное состояние
                    },
                    tooltip: 'Очистить поиск',
                  )
                : null,
          ),
          onChanged: (value) {
            setState(() {}); // Обновляем suffixIcon при изменении текста
          },
          onFieldSubmitted: (_) => _performSearch(),
        );
      },
    );
  }

  /// Строит результаты поиска.
  Widget _buildSearchResults(
      BuildContext context, ThemeData theme, WorkSearchState searchState) {
    if (searchState.isLoading) {
      return Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: theme.colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
        child: const Center(
          child: Padding(
            padding: EdgeInsets.all(32.0),
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    if (searchState.error != null) {
      return Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: theme.colorScheme.error.withValues(alpha: 0.2),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 48,
                color: theme.colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                searchState.error!,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.error,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    if (searchState.results.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: theme.colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              'Введите запрос для поиска',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Начните вводить название работы для автоматического поиска',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.outline,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return _buildResultsTable(context, theme, searchState.results);
  }

  /// Строит таблицу результатов.
  Widget _buildResultsTable(
      BuildContext context, ThemeData theme, List results) {
    // Русская локализация для PlutoGrid
    const ruLocale = PlutoGridLocaleText(
      unfreezeColumn: 'Открепить',
      freezeColumnToStart: 'Закрепить в начале',
      freezeColumnToEnd: 'Закрепить в конце',
      autoFitColumn: 'Автоматический размер',
      hideColumn: 'Скрыть колонку',
      setColumns: 'Выбрать колонки',
      setFilter: 'Установить фильтр',
      resetFilter: 'Сбросить фильтр',
      setColumnsTitle: 'Настройка колонок',
      filterColumn: 'Колонка',
      filterType: 'Тип',
      filterValue: 'Значение',
      filterAllColumns: 'Все колонки',
      filterContains: 'Содержит',
      filterEquals: 'Равно',
      filterStartsWith: 'Начинается с',
      filterEndsWith: 'Заканчивается на',
      filterGreaterThan: 'Больше чем',
      filterGreaterThanOrEqualTo: 'Больше или равно',
      filterLessThan: 'Меньше чем',
      filterLessThanOrEqualTo: 'Меньше или равно',
      sunday: 'Вск',
      monday: 'Пн',
      tuesday: 'Вт',
      wednesday: 'Ср',
      thursday: 'Чт',
      friday: 'Пт',
      saturday: 'Сб',
      hour: 'Часы',
      minute: 'Минуты',
      loadingText: 'Загрузка',
    );

    // Подсчет общего количества
    final totalQuantity =
        results.fold<num>(0, (sum, result) => sum + result.quantity);

    // Создание строк для таблицы
    final rows = results.map((result) {
      return PlutoRow(
        cells: {
          'date': PlutoCell(
              value: DateFormat('dd.MM.yyyy').format(result.workDate)),
          'object': PlutoCell(value: result.objectName),
          'system': PlutoCell(value: result.system),
          'subsystem': PlutoCell(value: result.subsystem),
          'section': PlutoCell(value: result.section),
          'floor': PlutoCell(value: result.floor),
          'materialName': PlutoCell(value: result.materialName),
          'unit': PlutoCell(value: result.unit),
          'quantity': PlutoCell(value: result.quantity),
        },
      );
    }).toList();

    // Добавление итоговой строки
    rows.add(
      PlutoRow(
        cells: {
          'date': PlutoCell(value: 'ИТОГО'),
          'object': PlutoCell(value: ''),
          'system': PlutoCell(value: ''),
          'subsystem': PlutoCell(value: ''),
          'section': PlutoCell(value: ''),
          'floor': PlutoCell(value: ''),
          'materialName': PlutoCell(value: ''),
          'unit': PlutoCell(value: ''),
          'quantity': PlutoCell(value: totalQuantity),
        },
      ),
    );

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: PlutoGrid(
          columns: _buildColumns(theme),
          rows: rows,
          configuration: theme.brightness == Brightness.dark
              ? PlutoGridConfiguration.dark(
                  localeText: ruLocale,
                  style: PlutoGridStyleConfig.dark(
                    gridBackgroundColor: theme.colorScheme.surface,
                    rowColor: theme.colorScheme.surface,
                    evenRowColor: theme.colorScheme.surfaceContainerHighest
                        .withValues(alpha: 0.3),
                    borderColor:
                        theme.colorScheme.outline.withValues(alpha: 0.2),
                    activatedBorderColor: theme.colorScheme.primary,
                    gridBorderRadius: BorderRadius.circular(12),
                  ),
                  columnSize: const PlutoGridColumnSizeConfig(
                    autoSizeMode: PlutoAutoSizeMode.scale,
                  ),
                )
              : PlutoGridConfiguration(
                  localeText: ruLocale,
                  style: PlutoGridStyleConfig(
                    gridBackgroundColor: theme.colorScheme.surface,
                    rowColor: theme.colorScheme.surface,
                    evenRowColor: theme.colorScheme.surfaceContainerHighest
                        .withValues(alpha: 0.3),
                    borderColor:
                        theme.colorScheme.outline.withValues(alpha: 0.2),
                    activatedBorderColor: theme.colorScheme.primary,
                    gridBorderRadius: BorderRadius.circular(12),
                  ),
                  columnSize: const PlutoGridColumnSizeConfig(
                    autoSizeMode: PlutoAutoSizeMode.scale,
                  ),
                ),
          rowColorCallback: (PlutoRowColorContext rowColorContext) {
            // Убираем выделение итоговой строки фоном
            return Colors.transparent;
          },
        ),
      ),
    );
  }

  /// Создает колонки для таблицы.
  List<PlutoColumn> _buildColumns(ThemeData theme) {
    return [
      PlutoColumn(
        title: 'Дата смены',
        field: 'date',
        type: PlutoColumnType.text(),
        width: 120,
        renderer: (rendererContext) {
          final isTotal = rendererContext.row.cells['date']?.value == 'ИТОГО';
          return Container(
            padding: const EdgeInsets.all(8),
            alignment: Alignment.center,
            child: Text(
              rendererContext.cell.value.toString(),
              style: TextStyle(
                fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
                color: isTotal ? Colors.blue : null,
              ),
            ),
          );
        },
      ),
      PlutoColumn(
        title: 'Объект',
        field: 'object',
        type: PlutoColumnType.text(),
        width: 150,
      ),
      PlutoColumn(
        title: 'Система',
        field: 'system',
        type: PlutoColumnType.text(),
        width: 150,
      ),
      PlutoColumn(
        title: 'Подсистема',
        field: 'subsystem',
        type: PlutoColumnType.text(),
        width: 150,
      ),
      PlutoColumn(
        title: 'Секция',
        field: 'section',
        type: PlutoColumnType.text(),
        width: 120,
      ),
      PlutoColumn(
        title: 'Этаж',
        field: 'floor',
        type: PlutoColumnType.text(),
        width: 100,
      ),
      PlutoColumn(
        title: 'Наименование материала',
        field: 'materialName',
        type: PlutoColumnType.text(),
        width: 200,
      ),
      PlutoColumn(
        title: 'Ед. изм.',
        field: 'unit',
        type: PlutoColumnType.text(),
        width: 80,
      ),
      PlutoColumn(
        title: 'Кол-во',
        field: 'quantity',
        type: PlutoColumnType.number(),
        width: 100,
        renderer: (rendererContext) {
          final isTotal = rendererContext.row.cells['date']?.value == 'ИТОГО';
          return Container(
            padding: const EdgeInsets.all(8),
            alignment: Alignment.centerRight,
            child: Text(
              rendererContext.cell.value.toString(),
              style: TextStyle(
                fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
                color: isTotal ? Colors.blue : null,
                fontSize: isTotal ? 16 : 14,
              ),
            ),
          );
        },
      ),
    ];
  }

  /// Выбор даты начала.
  Future<void> _selectStartDate(BuildContext context) async {
    final date = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      locale: const Locale('ru'),
    );

    if (date != null) {
      setState(() {
        _startDate = date;
        _startDateController.text = _formatDate(date);
      });
      // Автоматически запускаем поиск при изменении даты
      _performSearch();
    }
  }

  /// Выбор даты окончания.
  Future<void> _selectEndDate(BuildContext context) async {
    final date = await showDatePicker(
      context: context,
      initialDate: _endDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      locale: const Locale('ru'),
    );

    if (date != null) {
      setState(() {
        _endDate = date;
        _endDateController.text = _formatDate(date);
      });
      // Автоматически запускаем поиск при изменении даты
      _performSearch();
    }
  }

  /// Выполняет поиск.
  void _performSearch() {
    final query = _searchController.text.trim();

    // Если запрос пустой, очищаем результаты
    if (query.isEmpty) {
      ref.read(workSearchProvider.notifier).clearResults();
      return;
    }

    // Выполняем поиск только если есть текст для поиска
    ref.read(workSearchProvider.notifier).searchMaterials(
          startDate: _startDate,
          endDate: _endDate,
          objectId: _selectedObjectId,
          searchQuery: query,
        );
  }

  /// Очищает поиск.
  void _clearSearch() {
    // Отменяем таймер debounce
    _debounceTimer?.cancel();

    _searchController.clear();
    setState(() {
      _startDate = null;
      _endDate = null;
      _selectedObjectId = null;
      _startDateController.clear();
      _endDateController.clear();
    });
    ref.read(workSearchProvider.notifier).clearResults();
  }
}
