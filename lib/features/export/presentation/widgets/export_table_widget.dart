import 'package:flutter/material.dart';
import 'package:pluto_grid/pluto_grid.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/export_report.dart';

/// Виджет таблицы для отображения данных выгрузки.
///
/// Использует PlutoGrid для расширенных возможностей фильтрации и сортировки.
/// Адаптивный дизайн: таблица для десктопа, карточки для мобильных устройств.
class ExportTableWidget extends StatefulWidget {
  /// Список отчетов для отображения.
  final List<ExportReport> reports;

  /// Создаёт виджет таблицы выгрузки.
  const ExportTableWidget({
    super.key,
    required this.reports,
  });

  @override
  State<ExportTableWidget> createState() => _ExportTableWidgetState();
}

class _ExportTableWidgetState extends State<ExportTableWidget> {
  /// Колонки таблицы PlutoGrid.
  late List<PlutoColumn> columns;

  /// Строки таблицы PlutoGrid.
  late List<PlutoRow> rows;

  /// Контроллер состояния таблицы
  PlutoGridStateManager? stateManager;

  /// Контроллер для текста поиска
  final TextEditingController _searchController = TextEditingController();

  /// Критерий сортировки для мобильного вида
  String _sortCriterion = 'objectName';

  /// Порядок сортировки (по возрастанию/убыванию)
  bool _sortAscending = true;

  /// Контроллер прокрутки для списка позиций
  final ScrollController _scrollController = ScrollController();

  /// Флаг видимости верхнего блока
  bool _isHeaderVisible = true;

  /// Предыдущая позиция прокрутки
  double _previousScrollPosition = 0;

  /// Минимальное смещение для срабатывания скрытия/показа
  final double _scrollThreshold = 20.0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// Обработчик прокрутки для скрытия/показа заголовка
  void _onScroll() {
    final currentScrollPosition = _scrollController.position.pixels;
    final scrollDelta = currentScrollPosition - _previousScrollPosition;

    if (scrollDelta.abs() > _scrollThreshold) {
      final shouldShowHeader = scrollDelta < 0 || currentScrollPosition <= 0;

      if (shouldShowHeader != _isHeaderVisible) {
        setState(() {
          _isHeaderVisible = shouldShowHeader;
        });
      }

      _previousScrollPosition = currentScrollPosition;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isLargeScreen = MediaQuery.of(context).size.width > 900;
    final containerWidth =
        MediaQuery.of(context).size.width - 32; // 32 — padding

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

    // Строим таблицу только если экран достаточно широкий
    if (isLargeScreen) {
      _buildTable(widget.reports, containerWidth);
    }

    // Фильтруем и сортируем элементы для мобильного представления
    final filteredReports =
        isLargeScreen ? widget.reports : _filterAndSortReports(widget.reports);

    final cellStyle = theme.textTheme.bodyMedium ?? const TextStyle();
    final columnStyle =
        theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold) ??
            const TextStyle(fontWeight: FontWeight.bold);
    final moneyFormat = NumberFormat('###,##0.00', 'ru_RU');

    return widget.reports.isEmpty
        ? const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.search,
                  size: 64,
                  color: Colors.grey,
                ),
                SizedBox(height: 16),
                Text(
                  'Нет данных для отображения',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          )
        : Padding(
            padding: EdgeInsets.zero,
            child: isLargeScreen
                ? PlutoGrid(
                    columns: columns,
                    rows: rows,
                    mode: PlutoGridMode.normal,
                    onLoaded: (PlutoGridOnLoadedEvent event) {
                      stateManager = event.stateManager;
                      event.stateManager.setShowColumnFilter(true);
                    },
                    configuration: isDark
                        ? PlutoGridConfiguration.dark(
                            localeText: ruLocale,
                            style: PlutoGridStyleConfig.dark(
                              columnFilterHeight: 36,
                              cellTextStyle: cellStyle,
                              columnTextStyle: columnStyle,
                            ),
                          )
                        : PlutoGridConfiguration(
                            localeText: ruLocale,
                            style: PlutoGridStyleConfig(
                              gridBorderColor: theme.dividerColor,
                              activatedBorderColor: theme.colorScheme.primary,
                              rowColor: theme.colorScheme.surface,
                              activatedColor: theme.colorScheme.primary
                                  .withValues(alpha: 0.08),
                              cellTextStyle: cellStyle,
                              columnTextStyle: columnStyle,
                              enableColumnBorderVertical: true,
                              enableColumnBorderHorizontal: true,
                              enableGridBorderShadow: false,
                              columnFilterHeight: 36,
                            ),
                          ),
                  )
                : Column(
                    children: [
                      // Поиск и сортировка для мобильного вида
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        height: _isHeaderVisible ? null : 0,
                        child: AnimatedOpacity(
                          duration: const Duration(milliseconds: 300),
                          opacity: _isHeaderVisible ? 1.0 : 0.0,
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surface,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                // Поиск
                                TextField(
                                  controller: _searchController,
                                  decoration: InputDecoration(
                                    hintText: 'Поиск по данным...',
                                    prefixIcon: const Icon(Icons.search),
                                    suffixIcon:
                                        _searchController.text.isNotEmpty
                                            ? IconButton(
                                                icon: const Icon(Icons.clear),
                                                onPressed: () {
                                                  _searchController.clear();
                                                  setState(() {});
                                                },
                                              )
                                            : null,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  onChanged: (value) => setState(() {}),
                                ),
                                const SizedBox(height: 12),

                                // Сортировка
                                Row(
                                  children: [
                                    Expanded(
                                      child: DropdownButtonFormField<String>(
                                        value: _sortCriterion,
                                        decoration: InputDecoration(
                                          labelText: 'Сортировка',
                                          border: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                        ),
                                        items: const [
                                          DropdownMenuItem(
                                              value: 'objectName',
                                              child: Text('По объекту')),
                                          DropdownMenuItem(
                                              value: 'contractName',
                                              child: Text('По договору')),
                                          DropdownMenuItem(
                                              value: 'system',
                                              child: Text('По системе')),
                                          DropdownMenuItem(
                                              value: 'workName',
                                              child: Text('По работе')),
                                          DropdownMenuItem(
                                              value: 'total',
                                              child: Text('По сумме')),
                                        ],
                                        onChanged: (value) {
                                          if (value != null) {
                                            setState(() {
                                              _sortCriterion = value;
                                            });
                                          }
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    IconButton(
                                      onPressed: () {
                                        setState(() {
                                          _sortAscending = !_sortAscending;
                                        });
                                      },
                                      icon: Icon(
                                        _sortAscending
                                            ? Icons.arrow_upward
                                            : Icons.arrow_downward,
                                      ),
                                      tooltip: _sortAscending
                                          ? 'По возрастанию'
                                          : 'По убыванию',
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Статистика
                      if (_isHeaderVisible) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Статистика по отчету',
                                style: theme.textTheme.titleSmall
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Записей:',
                                          style: theme.textTheme.bodySmall
                                              ?.copyWith(
                                            color: theme.colorScheme.onSurface
                                                .withValues(alpha: 0.7),
                                          ),
                                        ),
                                        Text(
                                          '${filteredReports.length}',
                                          style: theme.textTheme.titleMedium
                                              ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Итого:',
                                          style: theme.textTheme.bodySmall
                                              ?.copyWith(
                                            color: theme.colorScheme.onSurface
                                                .withValues(alpha: 0.7),
                                          ),
                                        ),
                                        Text(
                                          '${moneyFormat.format(filteredReports.fold(0.0, (sum, item) => sum + (item.total ?? 0)))} ₽',
                                          style: theme.textTheme.titleMedium
                                              ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: theme.colorScheme.primary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Список карточек для мобильного вида
                      Expanded(
                        child: ListView.builder(
                          controller: _scrollController,
                          itemCount: filteredReports.length,
                          itemBuilder: (context, index) {
                            final report = filteredReports[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Заголовок карточки
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            report.workName,
                                            style: theme.textTheme.titleMedium
                                                ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        if (report.total != null)
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: theme.colorScheme.primary
                                                  .withValues(alpha: 0.1),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              '${moneyFormat.format(report.total!)} ₽',
                                              style: theme.textTheme.labelMedium
                                                  ?.copyWith(
                                                color:
                                                    theme.colorScheme.primary,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),

                                    // Основная информация
                                    _buildInfoRow(
                                        'Объект', report.objectName, theme),
                                    _buildInfoRow(
                                        'Договор', report.contractName, theme),
                                    _buildInfoRow(
                                        'Система', report.system, theme),
                                    _buildInfoRow(
                                        'Подсистема', report.subsystem, theme),
                                    _buildInfoRow('№ позиции',
                                        report.positionNumber, theme),

                                    if (report.section.isNotEmpty ||
                                        report.floor.isNotEmpty) ...[
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          if (report.section.isNotEmpty)
                                            Expanded(
                                                child: _buildInfoRow('Секция',
                                                    report.section, theme)),
                                          if (report.floor.isNotEmpty)
                                            Expanded(
                                                child: _buildInfoRow('Этаж',
                                                    report.floor, theme)),
                                        ],
                                      ),
                                    ],

                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Expanded(
                                            child: _buildInfoRow(
                                                'Количество',
                                                '${report.quantity} ${report.unit}',
                                                theme)),
                                        if (report.price != null)
                                          Expanded(
                                              child: _buildInfoRow(
                                                  'Цена',
                                                  '${moneyFormat.format(report.price!)} ₽',
                                                  theme)),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
          );
  }

  /// Строит таблицу для десктопного вида
  void _buildTable(List<ExportReport> reports, double containerWidth) {
    // Специальные колонки по 4%: №, Секция, Этаж, Ед. изм., Количество
    final smallColumnWidth = containerWidth * 0.04; // 4% для узких колонок
    final standardColumnWidth =
        containerWidth * 0.07; // 7% для стандартных колонок
    final workNameColumnWidth = containerWidth *
        0.31; // 31% для наименования работы (100% - 7*7% - 5*4% = 31%)

    final moneyFormat = NumberFormat('###,##0.00', 'ru_RU');

    columns = [
      PlutoColumn(
        title: 'Объект',
        field: 'objectName',
        type: PlutoColumnType.text(),
        width: standardColumnWidth,
        titleTextAlign: PlutoColumnTextAlign.center,
        renderer: (rendererContext) {
          final isTotal =
              rendererContext.row.cells['objectName']?.value == 'ИТОГО';
          return Text(
            rendererContext.cell.value?.toString() ?? '',
            textAlign: TextAlign.center,
            style:
                Theme.of(rendererContext.stateManager.gridKey.currentContext!)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(
                      fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
                      color: isTotal ? Colors.blue : null,
                    ),
          );
        },
      ),
      PlutoColumn(
        title: 'Договор',
        field: 'contractName',
        type: PlutoColumnType.text(),
        width: standardColumnWidth,
        titleTextAlign: PlutoColumnTextAlign.center,
        renderer: (rendererContext) {
          final isTotal =
              rendererContext.row.cells['objectName']?.value == 'ИТОГО';
          return Text(
            rendererContext.cell.value?.toString() ?? '',
            textAlign: TextAlign.center,
            style:
                Theme.of(rendererContext.stateManager.gridKey.currentContext!)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(
                      fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
                      color: isTotal ? Colors.blue : null,
                    ),
          );
        },
      ),
      PlutoColumn(
        title: 'Система',
        field: 'system',
        type: PlutoColumnType.text(),
        width: standardColumnWidth,
        titleTextAlign: PlutoColumnTextAlign.center,
        renderer: (rendererContext) {
          final isTotal =
              rendererContext.row.cells['objectName']?.value == 'ИТОГО';
          return Text(
            rendererContext.cell.value?.toString() ?? '',
            textAlign: TextAlign.center,
            style:
                Theme.of(rendererContext.stateManager.gridKey.currentContext!)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(
                      fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
                      color: isTotal ? Colors.blue : null,
                    ),
          );
        },
      ),
      PlutoColumn(
        title: 'Подсистема',
        field: 'subsystem',
        type: PlutoColumnType.text(),
        width: standardColumnWidth,
        titleTextAlign: PlutoColumnTextAlign.center,
        renderer: (rendererContext) {
          final isTotal =
              rendererContext.row.cells['objectName']?.value == 'ИТОГО';
          return Text(
            rendererContext.cell.value?.toString() ?? '',
            textAlign: TextAlign.center,
            style:
                Theme.of(rendererContext.stateManager.gridKey.currentContext!)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(
                      fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
                      color: isTotal ? Colors.blue : null,
                    ),
          );
        },
      ),
      PlutoColumn(
        title: '№',
        field: 'positionNumber',
        type: PlutoColumnType.text(),
        width: smallColumnWidth,
        titleTextAlign: PlutoColumnTextAlign.center,
        renderer: (rendererContext) {
          final isTotal =
              rendererContext.row.cells['objectName']?.value == 'ИТОГО';
          return Text(
            rendererContext.cell.value?.toString() ?? '',
            textAlign: TextAlign.center,
            style:
                Theme.of(rendererContext.stateManager.gridKey.currentContext!)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(
                      fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
                      color: isTotal ? Colors.blue : null,
                    ),
          );
        },
      ),
      PlutoColumn(
        title: 'Наименование работы',
        field: 'workName',
        type: PlutoColumnType.text(),
        width: workNameColumnWidth,
        titleTextAlign: PlutoColumnTextAlign.center,
        renderer: (rendererContext) {
          final isTotal =
              rendererContext.row.cells['objectName']?.value == 'ИТОГО';
          return Text(
            rendererContext.cell.value?.toString() ?? '',
            softWrap: true,
            overflow: TextOverflow.visible,
            maxLines: null,
            style:
                Theme.of(rendererContext.stateManager.gridKey.currentContext!)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(
                      fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
                      color: isTotal ? Colors.blue : null,
                    ),
          );
        },
      ),
      PlutoColumn(
        title: 'Секция',
        field: 'section',
        type: PlutoColumnType.text(),
        width: smallColumnWidth,
        titleTextAlign: PlutoColumnTextAlign.center,
        renderer: (rendererContext) {
          final isTotal =
              rendererContext.row.cells['objectName']?.value == 'ИТОГО';
          return Text(
            rendererContext.cell.value?.toString() ?? '',
            textAlign: TextAlign.center,
            style:
                Theme.of(rendererContext.stateManager.gridKey.currentContext!)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(
                      fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
                      color: isTotal ? Colors.blue : null,
                    ),
          );
        },
      ),
      PlutoColumn(
        title: 'Этаж',
        field: 'floor',
        type: PlutoColumnType.text(),
        width: smallColumnWidth,
        titleTextAlign: PlutoColumnTextAlign.center,
        renderer: (rendererContext) {
          final isTotal =
              rendererContext.row.cells['objectName']?.value == 'ИТОГО';
          return Text(
            rendererContext.cell.value?.toString() ?? '',
            textAlign: TextAlign.center,
            style:
                Theme.of(rendererContext.stateManager.gridKey.currentContext!)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(
                      fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
                      color: isTotal ? Colors.blue : null,
                    ),
          );
        },
      ),
      PlutoColumn(
        title: 'Ед. изм.',
        field: 'unit',
        type: PlutoColumnType.text(),
        width: smallColumnWidth,
        titleTextAlign: PlutoColumnTextAlign.center,
        renderer: (rendererContext) {
          final isTotal =
              rendererContext.row.cells['objectName']?.value == 'ИТОГО';
          return Text(
            rendererContext.cell.value?.toString() ?? '',
            textAlign: TextAlign.center,
            style:
                Theme.of(rendererContext.stateManager.gridKey.currentContext!)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(
                      fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
                      color: isTotal ? Colors.blue : null,
                    ),
          );
        },
      ),
      PlutoColumn(
        title: 'Количество',
        field: 'quantity',
        type: PlutoColumnType.number(),
        width: smallColumnWidth,
        titleTextAlign: PlutoColumnTextAlign.center,
        renderer: (rendererContext) {
          final isTotal =
              rendererContext.row.cells['objectName']?.value == 'ИТОГО';
          return Text(
            rendererContext.cell.value?.toString() ?? '',
            textAlign: TextAlign.center,
            style:
                Theme.of(rendererContext.stateManager.gridKey.currentContext!)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(
                      fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
                      color: isTotal ? Colors.blue : null,
                    ),
          );
        },
      ),
      PlutoColumn(
        title: 'Цена',
        field: 'price',
        type: PlutoColumnType.number(),
        width: standardColumnWidth,
        titleTextAlign: PlutoColumnTextAlign.center,
        renderer: (rendererContext) {
          final isTotal =
              rendererContext.row.cells['objectName']?.value == 'ИТОГО';
          final value = rendererContext.cell.value;
          final formatted = value is num
              ? moneyFormat.format(value)
              : (value?.toString() ?? '');
          return Text(
            formatted,
            textAlign: TextAlign.right,
            style:
                Theme.of(rendererContext.stateManager.gridKey.currentContext!)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(
                      color: isTotal ? Colors.blue : Colors.green,
                      fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
                    ),
          );
        },
      ),
      PlutoColumn(
        title: 'Сумма',
        field: 'total',
        type: PlutoColumnType.number(),
        width: standardColumnWidth,
        titleTextAlign: PlutoColumnTextAlign.center,
        renderer: (rendererContext) {
          final isTotal =
              rendererContext.row.cells['objectName']?.value == 'ИТОГО';
          final value = rendererContext.cell.value;
          final formatted = value is num
              ? moneyFormat.format(value)
              : (value?.toString() ?? '');
          return Text(
            formatted,
            textAlign: TextAlign.right,
            style:
                Theme.of(rendererContext.stateManager.gridKey.currentContext!)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isTotal ? Colors.blue : Colors.green,
                      fontSize: isTotal ? 16 : null,
                    ),
          );
        },
      ),
    ];

    // Создаем строки данных
    rows = reports
        .map((report) => PlutoRow(cells: {
              'objectName': PlutoCell(value: report.objectName),
              'contractName': PlutoCell(value: report.contractName),
              'system': PlutoCell(value: report.system),
              'subsystem': PlutoCell(value: report.subsystem),
              'positionNumber': PlutoCell(value: report.positionNumber),
              'workName': PlutoCell(value: report.workName),
              'section': PlutoCell(value: report.section),
              'floor': PlutoCell(value: report.floor),
              'unit': PlutoCell(value: report.unit),
              'quantity': PlutoCell(value: report.quantity),
              'price': PlutoCell(value: report.price),
              'total': PlutoCell(value: report.total),
            }))
        .toList();

    // Подсчитываем общую сумму
    final totalSum =
        reports.fold<double>(0.0, (sum, report) => sum + (report.total ?? 0.0));

    // Добавляем итоговую строку
    if (reports.isNotEmpty) {
      rows.add(PlutoRow(cells: {
        'objectName': PlutoCell(value: 'ИТОГО'),
        'contractName': PlutoCell(value: ''),
        'system': PlutoCell(value: ''),
        'subsystem': PlutoCell(value: ''),
        'positionNumber': PlutoCell(value: ''),
        'workName': PlutoCell(value: ''),
        'section': PlutoCell(value: ''),
        'floor': PlutoCell(value: ''),
        'unit': PlutoCell(value: ''),
        'quantity': PlutoCell(value: ''),
        'price': PlutoCell(value: ''),
        'total': PlutoCell(value: totalSum),
      }));
    }
  }

  /// Фильтрует и сортирует отчеты для мобильного вида
  List<ExportReport> _filterAndSortReports(List<ExportReport> reports) {
    var filtered = reports.where((report) {
      if (_searchController.text.isEmpty) return true;

      final searchText = _searchController.text.toLowerCase();
      return report.workName.toLowerCase().contains(searchText) ||
          report.objectName.toLowerCase().contains(searchText) ||
          report.contractName.toLowerCase().contains(searchText) ||
          report.system.toLowerCase().contains(searchText) ||
          report.subsystem.toLowerCase().contains(searchText);
    }).toList();

    filtered.sort((a, b) {
      dynamic aValue, bValue;

      switch (_sortCriterion) {
        case 'objectName':
          aValue = a.objectName;
          bValue = b.objectName;
          break;
        case 'contractName':
          aValue = a.contractName;
          bValue = b.contractName;
          break;
        case 'system':
          aValue = a.system;
          bValue = b.system;
          break;
        case 'workName':
          aValue = a.workName;
          bValue = b.workName;
          break;
        case 'total':
          aValue = a.total ?? 0;
          bValue = b.total ?? 0;
          break;
        default:
          aValue = a.objectName;
          bValue = b.objectName;
      }

      final comparison = Comparable.compare(aValue, bValue);
      return _sortAscending ? comparison : -comparison;
    });

    return filtered;
  }

  /// Строит строку информации для карточки
  Widget _buildInfoRow(String label, String value, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}
