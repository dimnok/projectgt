import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dropdown_textfield/dropdown_textfield.dart';
import '../providers/payroll_filter_provider.dart';
import 'package:intl/intl.dart';
import 'package:projectgt/core/utils/responsive_utils.dart';
import 'package:projectgt/core/widgets/dropdown_typeahead_field.dart';

/// Виджет фильтрации расчётов ФОТ (аналогично фильтру табеля)
class PayrollFilterWidget extends ConsumerStatefulWidget {
  /// Создаёт виджет фильтров ФОТ.
  const PayrollFilterWidget({super.key});

  @override
  ConsumerState<PayrollFilterWidget> createState() => _PayrollFilterWidgetState();
}

class _PayrollFilterWidgetState extends ConsumerState<PayrollFilterWidget> {
  final MultiValueDropDownController _employeeController = MultiValueDropDownController();
  final MultiValueDropDownController _objectController = MultiValueDropDownController();
  final MultiValueDropDownController _positionController = MultiValueDropDownController();
  final TextEditingController _yearController = TextEditingController();
  final TextEditingController _monthController = TextEditingController();

  @override
  void initState() {
    super.initState();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeControllers();
    });
  }
  
  /// Инициализирует контроллеры текущими значениями фильтров
  void _initializeControllers() {
    final filterState = ref.read(payrollFilterProvider);
    final date = DateTime(filterState.year, filterState.month);
    _yearController.text = filterState.year.toString();
    _monthController.text = DateFormat.MMMM('ru').format(date);
  }

  @override
  void dispose() {
    _employeeController.dispose();
    _objectController.dispose();
    _positionController.dispose();
    _yearController.dispose();
    _monthController.dispose();
    super.dispose();
  }

  /// Создает DropDownValueModel для сотрудника
  DropDownValueModel _createEmployeeDropDownModel(dynamic employee) {
    final fio = [
      employee.lastName, 
      employee.firstName, 
      if (employee.middleName != null && employee.middleName!.isNotEmpty) employee.middleName
    ].join(' ');
    return DropDownValueModel(name: fio, value: employee.id);
  }
  
  /// Создает DropDownValueModel для объекта
  DropDownValueModel _createObjectDropDownModel(dynamic object) {
    return DropDownValueModel(name: object.name, value: object.id);
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filterState = ref.watch(payrollFilterProvider);
    final isDesktop = ResponsiveUtils.isDesktop(context);
    // Получаем только актуальных сотрудников, объекты и должности за период
    final availableEmployees = ref.watch(availableEmployeesForPeriodProvider);
    final availableObjects = ref.watch(availableObjectsForPeriodProvider);
    final availablePositions = ref.watch(availablePositionsForPeriodProvider);
    final positionDropDownList = availablePositions
        .map((p) => DropDownValueModel(name: p, value: p))
        .toList();
    final employeeDropDownList = availableEmployees
        .map((employee) => _createEmployeeDropDownModel(employee))
        .toList();
    final objectDropDownList = availableObjects
        .map((object) => _createObjectDropDownModel(object))
        .toList();

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: theme.colorScheme.outline.withValues(alpha: 51),
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
                TextButton.icon(
                  icon: const Icon(Icons.refresh),
                  label: const Text('Сбросить'),
                  onPressed: () {
                    ref.read(payrollFilterProvider.notifier).resetFilters();
                    _employeeController.setDropDown([]);
                    _objectController.setDropDown([]);
                    _positionController.setDropDown([]);
                    final now = DateTime.now();
                    setState(() {
                      _yearController.text = now.year.toString();
                      _monthController.text = DateFormat.MMMM('ru').format(now);
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (isDesktop)
              Row(
                children: [
                  // Фильтр по периоду (год и месяц)
                  Expanded(
                    child: _buildPeriodFilter(theme, filterState),
                  ),
                  const SizedBox(width: 16),
                  // Фильтр по сотруднику
                  Expanded(
                    child: _buildMultiDropDown(
                      label: 'Сотрудник',
                      hint: 'Выберите одного или несколько',
                      controller: _employeeController,
                      items: employeeDropDownList,
                      onSelectionChanged: (ids) => 
                          ref.read(payrollFilterProvider.notifier).setEmployeeFilter(ids),
                    ),
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
                          ref.read(payrollFilterProvider.notifier).setObjectFilter(ids),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Фильтр по должности
                  Expanded(
                    child: _buildMultiDropDown(
                      label: 'Должность',
                      hint: 'Выберите одну или несколько',
                      controller: _positionController,
                      items: positionDropDownList,
                      onSelectionChanged: (positions) => 
                          ref.read(payrollFilterProvider.notifier).setPositionFilter(positions),
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
                    label: 'Сотрудник',
                    hint: 'Выберите одного или несколько',
                    controller: _employeeController,
                    items: employeeDropDownList,
                    onSelectionChanged: (ids) => 
                        ref.read(payrollFilterProvider.notifier).setEmployeeFilter(ids),
                  ),
                  const SizedBox(height: 16),
                  _buildMultiDropDown(
                    label: 'Объект',
                    hint: 'Выберите один или несколько',
                    controller: _objectController,
                    items: objectDropDownList,
                    onSelectionChanged: (ids) => 
                        ref.read(payrollFilterProvider.notifier).setObjectFilter(ids),
                  ),
                  const SizedBox(height: 16),
                  _buildMultiDropDown(
                    label: 'Должность',
                    hint: 'Выберите одну или несколько',
                    controller: _positionController,
                    items: positionDropDownList,
                    onSelectionChanged: (positions) => 
                        ref.read(payrollFilterProvider.notifier).setPositionFilter(positions),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  /// Создает фильтр по периоду (год и месяц)
  Widget _buildPeriodFilter(ThemeData theme, PayrollFilterState filterState) {
    final now = DateTime.now();
    // Список годов: 3 года назад, текущий, 2 года вперёд
    final years = List.generate(6, (i) => (now.year - 3 + i).toString());
    // Список месяцев
    final months = List.generate(12, (i) => DateTime(2000, i + 1));
    
    return Row(
      children: [
        // Год
        Expanded(
          child: StringDropdownTypeAheadField(
            controller: _yearController,
            labelText: 'Год',
            hintText: 'Выберите год',
            values: years,
            allowCustomValues: false,
            onSelected: (year) {
              final selectedYear = int.tryParse(year);
              if (selectedYear != null) {
                ref.read(payrollFilterProvider.notifier).setYear(selectedYear);
              }
            },
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Выберите год';
              }
              return null;
            },
          ),
        ),
        const SizedBox(width: 12),
        // Месяц
        Expanded(
          child: DropdownTypeAheadField<DateTime>(
            controller: _monthController,
            labelText: 'Месяц',
            hintText: 'Выберите месяц',
            items: months,
            displayStringForOption: (date) => DateFormat.MMMM('ru').format(date),
            onSelected: (date) {
              ref.read(payrollFilterProvider.notifier).setMonth(date.month);
            },
            allowCustomValues: false,
            suffixIcon: Icons.keyboard_arrow_down,
            decoration: InputDecoration(
              labelText: 'Месяц',
              hintText: 'Выберите месяц',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              prefixIcon: const Icon(Icons.date_range),
            ),
          ),
        ),
      ],
    );
  }
} 