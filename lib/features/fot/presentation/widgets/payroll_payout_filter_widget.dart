import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dropdown_textfield/dropdown_textfield.dart';
import '../providers/payroll_payout_filter_provider.dart';
import 'package:intl/intl.dart';
import 'package:projectgt/core/utils/responsive_utils.dart';

/// Виджет фильтрации выплат по ФОТ.
///
/// Предоставляет фильтры специфичные для выплат: диапазон дат, способ выплаты, сотрудники.
class PayrollPayoutFilterWidget extends ConsumerStatefulWidget {
  /// Создаёт виджет фильтров выплат.
  const PayrollPayoutFilterWidget({super.key});

  @override
  ConsumerState<PayrollPayoutFilterWidget> createState() =>
      _PayrollPayoutFilterWidgetState();
}

class _PayrollPayoutFilterWidgetState
    extends ConsumerState<PayrollPayoutFilterWidget> {
  final MultiValueDropDownController _employeeController =
      MultiValueDropDownController();
  final MultiValueDropDownController _methodController =
      MultiValueDropDownController();
  final TextEditingController _startDateController = TextEditingController();
  final TextEditingController _endDateController = TextEditingController();

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeControllers();
    });
  }

  /// Инициализирует контроллеры текущими значениями фильтров
  void _initializeControllers() {
    final filterState = ref.read(payrollPayoutFilterProvider);
    _startDateController.text =
        DateFormat('dd.MM.yyyy').format(filterState.startDate);
    _endDateController.text =
        DateFormat('dd.MM.yyyy').format(filterState.endDate);
  }

  @override
  void dispose() {
    _employeeController.dispose();
    _methodController.dispose();
    _startDateController.dispose();
    _endDateController.dispose();
    super.dispose();
  }

  /// Создает DropDownValueModel для сотрудника
  DropDownValueModel _createEmployeeDropDownModel(dynamic employee) {
    final fio = [
      employee.lastName,
      employee.firstName,
      if (employee.middleName != null && employee.middleName!.isNotEmpty)
        employee.middleName
    ].join(' ');
    return DropDownValueModel(name: fio, value: employee.id);
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
      onChanged: isEmpty
          ? null
          : (val) {
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

  /// Создает поле выбора даты
  Widget _buildDateField({
    required String label,
    required TextEditingController controller,
    required VoidCallback onTap,
    required IconData icon,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AbsorbPointer(
        child: TextFormField(
          controller: controller,
          decoration: InputDecoration(
            labelText: label,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            prefixIcon: Icon(icon),
          ),
        ),
      ),
    );
  }

  /// Показывает диалог выбора даты
  Future<void> _pickDate({
    required TextEditingController controller,
    required bool isStartDate,
  }) async {
    final filterState = ref.read(payrollPayoutFilterProvider);
    final initialDate =
        isStartDate ? filterState.startDate : filterState.endDate;

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      locale: const Locale('ru'),
    );

    if (picked != null) {
      controller.text = DateFormat('dd.MM.yyyy').format(picked);

      if (isStartDate) {
        ref.read(payrollPayoutFilterProvider.notifier).setStartDate(picked);
      } else {
        ref.read(payrollPayoutFilterProvider.notifier).setEndDate(picked);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filterState = ref.watch(payrollPayoutFilterProvider);
    final isDesktop = ResponsiveUtils.isDesktop(context);

    final employees = filterState.employees;
    final employeeDropDownList = employees
        .map((employee) => _createEmployeeDropDownModel(employee))
        .toList();

    final methodDropDownList = availablePayoutMethods
        .map((method) =>
            DropDownValueModel(name: method['name']!, value: method['value']!))
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Фильтры выплат',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                TextButton.icon(
                  icon: const Icon(Icons.refresh),
                  label: const Text('Сбросить'),
                  onPressed: () {
                    ref
                        .read(payrollPayoutFilterProvider.notifier)
                        .resetFilters();
                    _employeeController.setDropDown([]);
                    _methodController.setDropDown([]);
                    final now = DateTime.now();
                    final thirtyDaysAgo =
                        now.subtract(const Duration(days: 30));
                    setState(() {
                      _startDateController.text =
                          DateFormat('dd.MM.yyyy').format(thirtyDaysAgo);
                      _endDateController.text =
                          DateFormat('dd.MM.yyyy').format(now);
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (isDesktop)
              Row(
                children: [
                  // Диапазон дат
                  _buildDateRangeFilter(),
                  const SizedBox(width: 16),
                  // Фильтр по сотруднику
                  Expanded(
                    child: _buildMultiDropDown(
                      label: 'Сотрудники',
                      hint: 'Выберите одного или несколько',
                      controller: _employeeController,
                      items: employeeDropDownList,
                      onSelectionChanged: (ids) => ref
                          .read(payrollPayoutFilterProvider.notifier)
                          .setEmployeeFilter(ids),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Фильтр по способу выплаты
                  Expanded(
                    child: _buildMultiDropDown(
                      label: 'Способ выплаты',
                      hint: 'Выберите один или несколько',
                      controller: _methodController,
                      items: methodDropDownList,
                      onSelectionChanged: (methods) => ref
                          .read(payrollPayoutFilterProvider.notifier)
                          .setPayoutMethodFilter(methods),
                    ),
                  ),
                ],
              )
            else
              Column(
                children: [
                  _buildDateRangeFilter(),
                  const SizedBox(height: 16),
                  _buildMultiDropDown(
                    label: 'Сотрудники',
                    hint: 'Выберите одного или несколько',
                    controller: _employeeController,
                    items: employeeDropDownList,
                    onSelectionChanged: (ids) => ref
                        .read(payrollPayoutFilterProvider.notifier)
                        .setEmployeeFilter(ids),
                  ),
                  const SizedBox(height: 16),
                  _buildMultiDropDown(
                    label: 'Способ выплаты',
                    hint: 'Выберите один или несколько',
                    controller: _methodController,
                    items: methodDropDownList,
                    onSelectionChanged: (methods) => ref
                        .read(payrollPayoutFilterProvider.notifier)
                        .setPayoutMethodFilter(methods),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  /// Создает фильтр диапазона дат
  Widget _buildDateRangeFilter() {
    return Expanded(
      child: Row(
        children: [
          // Дата "от"
          Expanded(
            child: _buildDateField(
              label: 'Дата от',
              controller: _startDateController,
              icon: Icons.date_range,
              onTap: () => _pickDate(
                controller: _startDateController,
                isStartDate: true,
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Дата "до"
          Expanded(
            child: _buildDateField(
              label: 'Дата до',
              controller: _endDateController,
              icon: Icons.date_range,
              onTap: () => _pickDate(
                controller: _endDateController,
                isStartDate: false,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
