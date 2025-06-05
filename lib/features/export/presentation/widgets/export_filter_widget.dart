import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dropdown_textfield/dropdown_textfield.dart';
import 'package:projectgt/core/utils/responsive_utils.dart';
import '../providers/export_filter_provider.dart';
import '../../domain/entities/export_filter.dart';
import '../providers/export_provider.dart';

/// Виджет фильтров для модуля выгрузки данных.
///
/// Предоставляет интерфейс для настройки параметров выгрузки:
/// - Выбор периода (дата начала и окончания)
/// - Фильтрация по объектам (множественный выбор)
/// - Фильтрация по договорам (множественный выбор)
/// - Фильтрация по системам (множественный выбор)
/// - Фильтрация по подсистемам (множественный выбор)
///
/// Адаптируется под размер экрана:
/// - Десктоп: фильтры в 2 колонки
/// - Мобильный: фильтры в 1 колонку
class ExportFilterWidget extends ConsumerStatefulWidget {
  /// Создаёт виджет фильтров выгрузки.
  const ExportFilterWidget({super.key});

  @override
  ConsumerState<ExportFilterWidget> createState() => _ExportFilterWidgetState();
}

class _ExportFilterWidgetState extends ConsumerState<ExportFilterWidget> {
  final MultiValueDropDownController _objectController = MultiValueDropDownController();
  final MultiValueDropDownController _contractController = MultiValueDropDownController();
  final MultiValueDropDownController _systemController = MultiValueDropDownController();
  final MultiValueDropDownController _subsystemController = MultiValueDropDownController();
  final TextEditingController _dateFromController = TextEditingController();
  final TextEditingController _dateToController = TextEditingController();
  final TextEditingController _fileNameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeControllers();
    });
  }
  
  /// Инициализирует контроллеры текущими значениями фильтров
  void _initializeControllers() {
    final filterState = ref.read(exportFilterProvider);
    _dateFromController.text = _formatDate(filterState.dateFrom);
    _dateToController.text = _formatDate(filterState.dateTo);
  }

  @override
  void dispose() {
    _objectController.dispose();
    _contractController.dispose();
    _systemController.dispose();
    _subsystemController.dispose();
    _dateFromController.dispose();
    _dateToController.dispose();
    _fileNameController.dispose();
    super.dispose();
  }

  /// Форматирует дату для отображения
  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }

  /// Создает DropDownValueModel для объекта
  DropDownValueModel _createObjectDropDownModel(dynamic object) {
    return DropDownValueModel(name: object.name, value: object.id);
  }

  /// Создает DropDownValueModel для договора
  DropDownValueModel _createContractDropDownModel(dynamic contract) {
    final displayName = '${contract.number} (${contract.contractorName ?? 'Без контрагента'})';
    return DropDownValueModel(name: displayName, value: contract.id);
  }

  /// Создает общий выпадающий список с множественным выбором
  Widget _buildMultiDropDown({
    required String label,
    required String hint,
    required MultiValueDropDownController controller,
    required List<DropDownValueModel> items,
    required Function(List<String>) onSelectionChanged,
  }) {
    final theme = Theme.of(context);
    final isEmpty = items.isEmpty;
    return DropDownTextField.multiSelection(
      controller: controller,
      dropDownList: items,
      submitButtonText: 'Ок',
      submitButtonColor: Colors.green,
      checkBoxProperty: CheckBoxProperty(
        fillColor: WidgetStateProperty.all<Color>(Colors.green),
        checkColor: Colors.white,
      ),
      displayCompleteItem: true,
      textFieldDecoration: InputDecoration(
        labelText: label,
        hintText: isEmpty ? 'Нет доступных значений' : hint,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      listTextStyle: theme.textTheme.bodyMedium?.copyWith(color: Colors.black),
      onChanged: isEmpty ? null : (val) {
        if (val == null) return;
        final list = val is List<DropDownValueModel> 
            ? val 
            : List<DropDownValueModel>.from(val);
        final selectedValues = list
            .map((e) => e.value as String?)
            .where((value) => value != null)
            .cast<String>()
            .toList();
        onSelectionChanged(selectedValues);
      },
    );
  }

  /// Показывает календарь для выбора даты
  Future<void> _selectDate(TextEditingController controller, bool isStartDate) async {
    final filterState = ref.read(exportFilterProvider);
    final initialDate = isStartDate ? filterState.dateFrom : filterState.dateTo;
    
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      locale: const Locale('ru'),
    );
    
    if (picked != null) {
      controller.text = _formatDate(picked);
      
      if (isStartDate) {
        ref.read(exportFilterProvider.notifier).setDateFrom(picked);
      } else {
        ref.read(exportFilterProvider.notifier).setDateTo(picked);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filterState = ref.watch(exportFilterProvider);
    final isDesktop = ResponsiveUtils.isDesktop(context);
    
    // Получаем доступные значения для фильтров
    final availableObjects = ref.watch(availableObjectsForExportProvider);
    final availableContracts = ref.watch(availableContractsForExportProvider);
    final availableSystems = ref.watch(availableSystemsForExportProvider);
    final availableSubsystems = ref.watch(availableSubsystemsForExportProvider);
    
    final objectDropDownList = availableObjects
        .map((object) => _createObjectDropDownModel(object))
        .toList();
    final contractDropDownList = availableContracts
        .map((contract) => _createContractDropDownModel(contract))
        .toList();
    final systemDropDownList = availableSystems
        .map((system) => DropDownValueModel(name: system, value: system))
        .toList();
    final subsystemDropDownList = availableSubsystems
        .map((subsystem) => DropDownValueModel(name: subsystem, value: subsystem))
        .toList();

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
              ? theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.92)
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Фильтры',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                Row(
                  children: [
                    // Кнопка "Сформировать отчет" - красная
                    ElevatedButton.icon(
                      onPressed: () {
                        // Преобразуем состояние фильтров в ExportFilter
                        final filter = ExportFilter(
                          objectId: filterState.objectIds.isNotEmpty ? filterState.objectIds.first : null,
                          contractId: filterState.contractIds.isNotEmpty ? filterState.contractIds.first : null,
                          system: filterState.systems.isNotEmpty ? filterState.systems.first : null,
                          subsystem: filterState.subsystems.isNotEmpty ? filterState.subsystems.first : null,
                          dateFrom: filterState.dateFrom,
                          dateTo: filterState.dateTo,
                        );
                        
                        // Запускаем загрузку данных отчета
                        ref.read(exportProvider.notifier).loadReportData(filter);
                      },
                      icon: const Icon(Icons.download, color: Colors.white),
                      label: const Text('Сформировать отчет', style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Кнопка "Выгрузить отчет" - зелёная
                    Consumer(
                      builder: (context, ref, child) {
                        final exportState = ref.watch(exportProvider);
                        final hasData = exportState.reports.isNotEmpty;
                        final isExporting = exportState.isExporting;
                        
                        return ElevatedButton.icon(
                          onPressed: hasData && !isExporting ? () => _showExportDialog(context, ref) : null,
                          icon: isExporting 
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : const Icon(Icons.upload, color: Colors.white),
                          label: const Text('Выгрузить отчет', style: TextStyle(color: Colors.white)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: hasData ? Colors.green : Colors.grey,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 8),
                    // Кнопка "Сбросить"
                    TextButton.icon(
                      icon: const Icon(Icons.refresh),
                      label: const Text('Сбросить'),
                      onPressed: () {
                        // Сбрасываем фильтры
                        ref.read(exportFilterProvider.notifier).resetFilters();
                        _objectController.setDropDown([]);
                        _contractController.setDropDown([]);
                        _systemController.setDropDown([]);
                        _subsystemController.setDropDown([]);
                        final now = DateTime.now();
                        final thirtyDaysAgo = now.subtract(const Duration(days: 30));
                        setState(() {
                          _dateFromController.text = _formatDate(thirtyDaysAgo);
                          _dateToController.text = _formatDate(now);
                        });
                        
                        // Очищаем данные отчета
                        ref.read(exportProvider.notifier).clearData();
                      },
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (isDesktop)
              Row(
                children: [
                  // Фильтр по периоду
                  Expanded(
                    child: _buildPeriodFilter(theme, filterState),
                  ),
                  const SizedBox(width: 16),
                  // Фильтр по объекту
                  Expanded(
                    child: _buildMultiDropDown(
                      label: 'Объект',
                      hint: 'Выберите один или несколько',
                      controller: _objectController,
                      items: objectDropDownList,
                      onSelectionChanged: (ids) => 
                          ref.read(exportFilterProvider.notifier).setObjectFilter(ids),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Фильтр по договору
                  Expanded(
                    child: _buildMultiDropDown(
                      label: 'Договор',
                      hint: 'Выберите один или несколько',
                      controller: _contractController,
                      items: contractDropDownList,
                      onSelectionChanged: (ids) => 
                          ref.read(exportFilterProvider.notifier).setContractFilter(ids),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Фильтр по системе
                  Expanded(
                    child: _buildMultiDropDown(
                      label: 'Система',
                      hint: 'Выберите одну или несколько',
                      controller: _systemController,
                      items: systemDropDownList,
                      onSelectionChanged: (systems) => 
                          ref.read(exportFilterProvider.notifier).setSystemFilter(systems),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Фильтр по подсистеме
                  Expanded(
                    child: _buildMultiDropDown(
                      label: 'Подсистема',
                      hint: 'Выберите одну или несколько',
                      controller: _subsystemController,
                      items: subsystemDropDownList,
                      onSelectionChanged: (subsystems) => 
                          ref.read(exportFilterProvider.notifier).setSubsystemFilter(subsystems),
                    ),
                  ),
                ],
              )
            else 
              Column(
                children: [
                  _buildPeriodFilter(theme, filterState),
                  const SizedBox(height: 16),
                  _buildMultiDropDown(
                    label: 'Объект',
                    hint: 'Выберите один или несколько',
                    controller: _objectController,
                    items: objectDropDownList,
                    onSelectionChanged: (ids) => 
                        ref.read(exportFilterProvider.notifier).setObjectFilter(ids),
                  ),
                  const SizedBox(height: 16),
                  _buildMultiDropDown(
                    label: 'Договор',
                    hint: 'Выберите один или несколько',
                    controller: _contractController,
                    items: contractDropDownList,
                    onSelectionChanged: (ids) => 
                        ref.read(exportFilterProvider.notifier).setContractFilter(ids),
                  ),
                  const SizedBox(height: 16),
                  _buildMultiDropDown(
                    label: 'Система',
                    hint: 'Выберите одну или несколько',
                    controller: _systemController,
                    items: systemDropDownList,
                    onSelectionChanged: (systems) => 
                        ref.read(exportFilterProvider.notifier).setSystemFilter(systems),
                  ),
                  const SizedBox(height: 16),
                  _buildMultiDropDown(
                    label: 'Подсистема',
                    hint: 'Выберите одну или несколько',
                    controller: _subsystemController,
                    items: subsystemDropDownList,
                    onSelectionChanged: (subsystems) => 
                        ref.read(exportFilterProvider.notifier).setSubsystemFilter(subsystems),
                  ),
                ],
              ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  /// Создает фильтр по периоду (дата начала и окончания)
  Widget _buildPeriodFilter(ThemeData theme, ExportFilterState filterState) {
    return Row(
      children: [
        // Дата начала
        Expanded(
          child: TextFormField(
            controller: _dateFromController,
            readOnly: true,
            decoration: InputDecoration(
              labelText: 'Дата начала',
              hintText: 'Выберите дату',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              prefixIcon: const Icon(Icons.date_range),
              suffixIcon: const Icon(Icons.keyboard_arrow_down),
            ),
            onTap: () => _selectDate(_dateFromController, true),
          ),
        ),
        const SizedBox(width: 12),
        // Дата окончания
        Expanded(
          child: TextFormField(
            controller: _dateToController,
            readOnly: true,
            decoration: InputDecoration(
              labelText: 'Дата окончания',
              hintText: 'Выберите дату',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              prefixIcon: const Icon(Icons.date_range),
              suffixIcon: const Icon(Icons.keyboard_arrow_down),
            ),
            onTap: () => _selectDate(_dateToController, false),
          ),
        ),
      ],
    );
  }

  /// Показывает диалог экспорта.
  void _showExportDialog(BuildContext context, WidgetRef ref) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Экспорт в Excel'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Введите имя файла:'),
            const SizedBox(height: 8),
            TextField(
              controller: _fileNameController,
              decoration: const InputDecoration(
                hintText: 'Имя файла',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () => _exportToExcel(context, ref),
            child: const Text('Экспорт'),
          ),
        ],
      ),
    );
  }

  /// Выполняет экспорт в Excel.
  void _exportToExcel(BuildContext context, WidgetRef ref) async {
    Navigator.of(context).pop(); // Закрываем диалог
    
    final fileName = _fileNameController.text.trim();
    if (fileName.isEmpty) {
      if (mounted) {
        _showSnackBar(context, 'Введите имя файла', isError: true);
      }
      return;
    }

    final filePath = await ref.read(exportProvider.notifier).exportToExcel(fileName);
    
    if (!mounted) return; // Проверяем mounted после async операции
    
    if (filePath != null) {
      _showSnackBar(context, 'Файл успешно сохранен: $filePath');
    } else {
      final error = ref.read(exportProvider).error;
      if (error != null) {
        _showSnackBar(context, error, isError: true);
      }
    }
  }

  /// Показывает SnackBar с сообщением.
  void _showSnackBar(BuildContext context, String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError 
            ? Theme.of(context).colorScheme.error 
            : Theme.of(context).colorScheme.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
} 