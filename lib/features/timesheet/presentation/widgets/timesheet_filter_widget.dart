import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:projectgt/core/utils/responsive_utils.dart';
import 'package:projectgt/presentation/state/employee_state.dart';
import 'package:projectgt/core/di/providers.dart';
import '../providers/timesheet_provider.dart';
import 'package:projectgt/core/widgets/dropdown_typeahead_field.dart';
import 'package:dropdown_textfield/dropdown_textfield.dart';

/// Виджет фильтрации данных табеля
class TimesheetFilterWidget extends ConsumerStatefulWidget {
  /// Создает виджет фильтров табеля.
  const TimesheetFilterWidget({super.key});

  @override
  ConsumerState<TimesheetFilterWidget> createState() => _TimesheetFilterWidgetState();
}

class _TimesheetFilterWidgetState extends ConsumerState<TimesheetFilterWidget> {
  // Контроллеры для полей фильтров
  final TextEditingController _yearController = TextEditingController();
  final TextEditingController _monthController = TextEditingController();
  final MultiValueDropDownController _employeeController = MultiValueDropDownController();
  final MultiValueDropDownController _objectController = MultiValueDropDownController();
  final MultiValueDropDownController _positionController = MultiValueDropDownController();
  List<String> _selectedPositions = [];
  
  @override
  void initState() {
    super.initState();
    // Инициируем загрузку данных через Future.microtask, чтобы избежать изменения
    // состояния провайдеров во время построения виджет-дерева
    Future.microtask(() {
      // Инициируем загрузку данных сотрудников и объектов
      final employeeState = ref.read(employeeProvider);
      final objectState = ref.read(objectProvider);
      
      // Если список сотрудников пуст, запрашиваем их загрузку
      if (employeeState.employees.isEmpty) {
        ref.read(employeeProvider.notifier).getEmployees();
      }
      
      // Если список объектов пуст, запрашиваем их загрузку
      if (objectState.objects.isEmpty) {
        ref.read(objectProvider.notifier).loadObjects();
      }
    });
  }
  
  @override
  void dispose() {
    _employeeController.dispose();
    _objectController.dispose();
    _yearController.dispose();
    _monthController.dispose();
    _positionController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = ref.watch(timesheetProvider);
    final isDesktop = ResponsiveUtils.isDesktop(context);
    
    // Загружаем данные для выпадающих списков и делаем проверку на существование
    final employeeState = ref.watch(employeeProvider);
    final objectState = ref.watch(objectProvider);
    
    // Получаем сотрудников только с часами (есть записи в timesheetState.entries)
    final employeesWithHours = employeeState.employees.where((employee) =>
      state.entries.any((entry) => entry.employeeId == employee.id)
    ).toList();
    
    // Получаем id объектов, которые есть в табеле
    final objectIdsWithEntries = state.entries.map((e) => e.objectId).toSet();
    // Оставляем только объекты, которые есть в табеле
    final filteredObjects = objectState.objects.where((o) => objectIdsWithEntries.contains(o.id)).toList();
    
    // Получаем только те должности, которые есть в табеле
    final positionsInTimesheet = state.entries
        .map((e) => e.employeePosition)
        .where((p) => p != null && p.isNotEmpty)
        .map((p) => p!)
        .toSet()
        .toList()
      ..sort();
    final positionDropDownList = positionsInTimesheet
        .map((p) => DropDownValueModel(name: p, value: p))
        .toList();
    
    // Цвета для чекбокса, галочки, текста и кнопки 'Ок' — всегда как в светлой теме
    const textColor = Colors.black;
    const checkboxColor = Colors.green;
    const checkMarkColor = Colors.red;
    const okButtonColor = Colors.green;
    
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: theme.colorScheme.outline.withAlpha(51),
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
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton.icon(
                  icon: const Icon(Icons.refresh),
                  label: const Text('Сбросить'),
                  onPressed: () {
                    ref.read(timesheetProvider.notifier).resetFilters();
                    _employeeController.setDropDown([]);
                    _objectController.setDropDown([]);
                    _positionController.setDropDown([]);
                    _yearController.text = DateTime.now().year.toString();
                    _monthController.text = DateFormat.MMMM('ru').format(DateTime.now());
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (isDesktop) ...[
              // Десктопный вид (в одну строку)
              Row(
                children: [
                  // Фильтр по периоду (год и месяц)
                  Expanded(
                    child: _buildPeriodFilter(theme, state),
                  ),
                  const SizedBox(width: 16),
                  // Фильтр по сотруднику
                  Expanded(
                    child: DropDownTextField.multiSelection(
                      controller: _employeeController,
                      dropDownList: [
                        ...employeesWithHours.map((employee) {
                          final fio = [employee.lastName, employee.firstName, if (employee.middleName != null && employee.middleName!.isNotEmpty) employee.middleName]
                              .join(' ');
                          return DropDownValueModel(
                            name: fio,
                            value: employee.id,
                          );
                        }),
                      ],
                      submitButtonText: 'Ок',
                      submitButtonColor: okButtonColor,
                      checkBoxProperty: CheckBoxProperty(
                        fillColor: WidgetStateProperty.all<Color>(checkboxColor),
                        checkColor: checkMarkColor,
                      ),
                      displayCompleteItem: true,
                      textFieldDecoration: InputDecoration(
                        labelText: 'Сотрудник',
                        hintText: 'Выберите одного или несколько',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      listTextStyle: theme.textTheme.bodyMedium?.copyWith(color: textColor),
                      onChanged: (val) {
                        final list = val is List<DropDownValueModel>
                            ? val
                            : List<DropDownValueModel>.from(val);
                        final selectedIds = list
                            .map((e) => e.value as String?)
                            .where((id) => id != null)
                            .cast<String>()
                            .toList();
                        ref.read(timesheetProvider.notifier).setSelectedEmployees(selectedIds);
                        setState(() {
                          _employeeController.setDropDown(list);
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Фильтр по объекту
                  Expanded(
                    child: DropDownTextField.multiSelection(
                      controller: _objectController,
                      dropDownList: [
                        ...filteredObjects.map((object) => DropDownValueModel(
                          name: object.name,
                          value: object.id,
                        )),
                      ],
                      submitButtonText: 'Ок',
                      submitButtonColor: okButtonColor,
                      checkBoxProperty: CheckBoxProperty(
                        fillColor: WidgetStateProperty.all<Color>(checkboxColor),
                        checkColor: checkMarkColor,
                      ),
                      displayCompleteItem: true,
                      textFieldDecoration: InputDecoration(
                        labelText: 'Объект',
                        hintText: 'Выберите один или несколько',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      listTextStyle: theme.textTheme.bodyMedium?.copyWith(color: textColor),
                      onChanged: (val) {
                        final list = val is List<DropDownValueModel>
                            ? val
                            : List<DropDownValueModel>.from(val);
                        final selectedIds = list.map((e) => e.value as String?).where((id) => id != null).toList();
                        ref.read(timesheetProvider.notifier).setSelectedObject(selectedIds.isEmpty ? null : selectedIds.first);
                        setState(() {
                          _objectController.setDropDown(list);
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Новый фильтр по должности (мультивыбор)
                  Expanded(
                    child: DropDownTextField.multiSelection(
                      controller: _positionController,
                      dropDownList: positionDropDownList,
                      submitButtonText: 'Ок',
                      submitButtonColor: okButtonColor,
                      checkBoxProperty: CheckBoxProperty(
                        fillColor: WidgetStateProperty.all<Color>(checkboxColor),
                        checkColor: checkMarkColor,
                      ),
                      displayCompleteItem: true,
                      textFieldDecoration: InputDecoration(
                        labelText: 'Должность',
                        hintText: 'Выберите одну или несколько',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      listTextStyle: theme.textTheme.bodyMedium?.copyWith(color: textColor),
                      onChanged: (val) {
                        final list = val is List<DropDownValueModel>
                            ? val
                            : List<DropDownValueModel>.from(val);
                        setState(() {
                          _selectedPositions = list.map((e) => e.value.toString()).toList();
                        });
                        ref.read(timesheetProvider.notifier).setSelectedPositions(_selectedPositions);
                      },
                    ),
                  ),
                ],
              ),
            ] else ...[
              // Мобильный вид (в столбец)
              _buildPeriodFilter(theme, state),
              const SizedBox(height: 16),
              DropDownTextField.multiSelection(
                controller: _employeeController,
                dropDownList: [
                  ...employeesWithHours.map((employee) {
                    final fio = [employee.lastName, employee.firstName, if (employee.middleName != null && employee.middleName!.isNotEmpty) employee.middleName]
                        .join(' ');
                    return DropDownValueModel(
                      name: fio,
                      value: employee.id,
                    );
                  }),
                ],
                submitButtonText: 'Ок',
                submitButtonColor: okButtonColor,
                checkBoxProperty: CheckBoxProperty(
                  fillColor: WidgetStateProperty.all<Color>(checkboxColor),
                  checkColor: checkMarkColor,
                ),
                displayCompleteItem: true,
                textFieldDecoration: InputDecoration(
                  labelText: 'Сотрудник',
                  hintText: 'Выберите одного или несколько',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                listTextStyle: theme.textTheme.bodyMedium?.copyWith(color: textColor),
                onChanged: (val) {
                  final list = val is List<DropDownValueModel>
                      ? val
                      : List<DropDownValueModel>.from(val);
                  final selectedIds = list
                      .map((e) => e.value as String?)
                      .where((id) => id != null)
                      .cast<String>()
                      .toList();
                  ref.read(timesheetProvider.notifier).setSelectedEmployees(selectedIds);
                  setState(() {
                    _employeeController.setDropDown(list);
                  });
                },
              ),
              const SizedBox(height: 16),
              DropDownTextField.multiSelection(
                controller: _objectController,
                dropDownList: [
                  ...filteredObjects.map((object) => DropDownValueModel(
                    name: object.name,
                    value: object.id,
                  )),
                ],
                submitButtonText: 'Ок',
                submitButtonColor: okButtonColor,
                checkBoxProperty: CheckBoxProperty(
                  fillColor: WidgetStateProperty.all<Color>(checkboxColor),
                  checkColor: checkMarkColor,
                ),
                displayCompleteItem: true,
                textFieldDecoration: InputDecoration(
                  labelText: 'Объект',
                  hintText: 'Выберите один или несколько',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                listTextStyle: theme.textTheme.bodyMedium?.copyWith(color: textColor),
                onChanged: (val) {
                  final list = val is List<DropDownValueModel>
                      ? val
                      : List<DropDownValueModel>.from(val);
                  final selectedIds = list.map((e) => e.value as String?).where((id) => id != null).toList();
                  ref.read(timesheetProvider.notifier).setSelectedObject(selectedIds.isEmpty ? null : selectedIds.first);
                  setState(() {
                    _objectController.setDropDown(list);
                  });
                },
              ),
              const SizedBox(height: 16),
              // Новый фильтр по должности (мультивыбор)
              DropDownTextField.multiSelection(
                controller: _positionController,
                dropDownList: positionDropDownList,
                submitButtonText: 'Ок',
                submitButtonColor: okButtonColor,
                checkBoxProperty: CheckBoxProperty(
                  fillColor: WidgetStateProperty.all<Color>(checkboxColor),
                  checkColor: checkMarkColor,
                ),
                displayCompleteItem: true,
                textFieldDecoration: InputDecoration(
                  labelText: 'Должность',
                  hintText: 'Выберите одну или несколько',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                listTextStyle: theme.textTheme.bodyMedium?.copyWith(color: textColor),
                onChanged: (val) {
                  final list = val is List<DropDownValueModel>
                      ? val
                      : List<DropDownValueModel>.from(val);
                  setState(() {
                    _selectedPositions = list.map((e) => e.value.toString()).toList();
                  });
                  ref.read(timesheetProvider.notifier).setSelectedPositions(_selectedPositions);
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  /// Создает фильтр по периоду (год и месяц)
  Widget _buildPeriodFilter(ThemeData theme, TimesheetState state) {
    final now = DateTime.now();
    final years = List.generate(6, (i) => (now.year - 3 + i).toString()); // 3 года назад, текущий, 2 вперёд
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
                final newStart = DateTime(selectedYear, state.startDate.month, 1);
                final newEnd = DateTime(selectedYear, state.startDate.month + 1, 0);
                ref.read(timesheetProvider.notifier).setDateRange(newStart, newEnd);
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
              final newStart = DateTime(state.startDate.year, date.month, 1);
              final newEnd = DateTime(state.startDate.year, date.month + 1, 0);
              ref.read(timesheetProvider.notifier).setDateRange(newStart, newEnd);
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