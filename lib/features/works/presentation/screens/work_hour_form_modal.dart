import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/work_hour.dart';
import '../providers/work_hours_provider.dart';
import 'package:projectgt/presentation/state/employee_state.dart'
    as employee_state;
import 'package:projectgt/domain/entities/employee.dart';
import 'package:uuid/uuid.dart';
import 'package:projectgt/core/utils/modal_utils.dart';
import 'package:projectgt/core/widgets/gt_dropdown.dart';
import '../providers/work_provider.dart';

/// Модальное окно для добавления или редактирования часов сотрудника в смене.
class WorkHourFormModal extends ConsumerStatefulWidget {
  /// Идентификатор смены.
  final String workId;

  /// Начальные данные для редактирования (null для создания новой записи).
  final WorkHour? initial;

  /// Контроллер прокрутки для DraggableScrollableSheet.
  final ScrollController? scrollController;

  /// Создаёт модальное окно для добавления или редактирования часов сотрудника.
  const WorkHourFormModal({
    super.key,
    required this.workId,
    this.initial,
    this.scrollController,
  });

  @override
  ConsumerState<WorkHourFormModal> createState() => _WorkHourFormModalState();
}

class _WorkHourFormModalState extends ConsumerState<WorkHourFormModal> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedEmployeeId;
  late TextEditingController hoursController;
  late TextEditingController commentController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final i = widget.initial;
    _selectedEmployeeId = i?.employeeId;
    hoursController = TextEditingController(text: i?.hours.toString() ?? '');
    commentController = TextEditingController(text: i?.comment ?? '');
  }

  @override
  void dispose() {
    hoursController.dispose();
    commentController.dispose();
    super.dispose();
  }

  /// Сохраняет или обновляет запись о часах сотрудника.
  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _selectedEmployeeId == null) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final hour = WorkHour(
        id: widget.initial?.id ?? const Uuid().v4(),
        workId: widget.workId,
        employeeId: _selectedEmployeeId!,
        hours: num.tryParse(hoursController.text) ?? 0,
        comment: commentController.text.trim().isEmpty
            ? null
            : commentController.text.trim(),
        createdAt: widget.initial?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      if (widget.initial == null) {
        await ref.read(workHoursProvider(widget.workId).notifier).add(hour);
      } else {
        await ref.read(workHoursProvider(widget.workId).notifier).update(hour);
      }

      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Форматирует ФИО сотрудника для отображения в выпадающем списке.
  String _formatEmployeeName(Employee employee) {
    return '${employee.lastName} ${employee.firstName}${employee.middleName != null && employee.middleName!.isNotEmpty ? ' ${employee.middleName}' : ''}';
  }

  @override
  Widget build(BuildContext context) {
    final employeeState = ref.watch(employee_state.employeeProvider);
    final allEmployees = employeeState.employees;
    final workHoursAsync = ref.watch(workHoursProvider(widget.workId));
    final workAsync = ref.watch(workProvider(widget.workId));
    final theme = Theme.of(context);

    // Получаем список занятых сотрудников
    final busyEmployeeIds = workHoursAsync.maybeWhen(
      data: (list) => list.map((w) => w.employeeId).toSet(),
      orElse: () => <String>{},
    );

    // Получаем объект смены
    final workObjectId = workAsync?.objectId;

    // Фильтруем сотрудников:
    // - только со статусом "работает"
    // - только относящиеся к объекту смены
    // - если добавление: только свободные
    // - если редактирование: все, но выбранный всегда в списке
    List<Employee> availableEmployees;
    if (workObjectId != null) {
      if (widget.initial == null) {
        availableEmployees = allEmployees
            .where((e) =>
                e.status == EmployeeStatus.working &&
                e.objectIds.contains(workObjectId) &&
                !busyEmployeeIds.contains(e.id))
            .toList();
      } else {
        availableEmployees = allEmployees
            .where((e) =>
                e.status == EmployeeStatus.working &&
                e.objectIds.contains(workObjectId) &&
                (!busyEmployeeIds.contains(e.id) ||
                    e.id == widget.initial!.employeeId))
            .toList();
      }
    } else {
      // Если объект смены не найден, показываем всех работающих
      if (widget.initial == null) {
        availableEmployees = allEmployees
            .where((e) =>
                e.status == EmployeeStatus.working &&
                !busyEmployeeIds.contains(e.id))
            .toList();
      } else {
        availableEmployees = allEmployees
            .where((e) =>
                e.status == EmployeeStatus.working &&
                (!busyEmployeeIds.contains(e.id) ||
                    e.id == widget.initial!.employeeId))
            .toList();
      }
    }

    // Сортируем по алфавиту (ФИО)
    availableEmployees.sort((a, b) {
      final nameA = _formatEmployeeName(a).toLowerCase();
      final nameB = _formatEmployeeName(b).toLowerCase();
      return nameA.compareTo(nameB);
    });

    return Material(
      color: theme.colorScheme.surface,
      child: _isLoading
          ? const Center(child: CupertinoActivityIndicator())
          : Stack(
              children: [
                // Основное содержимое
                Column(
                  children: [
                    // Заголовок (закреплен сверху)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        border: Border(
                          bottom: BorderSide(
                            color: theme.colorScheme.outline
                                .withValues(alpha: 0.2),
                            width: 1,
                          ),
                        ),
                      ),
                      child: ModalUtils.buildModalHeader(
                        title: widget.initial == null
                            ? 'Добавить сотрудника'
                            : 'Редактировать часы',
                        onClose: () => Navigator.pop(context),
                        theme: theme,
                      ),
                    ),

                    // Прокручиваемое содержимое
                    Expanded(
                      child: SingleChildScrollView(
                        controller: widget.scrollController,
                        padding: EdgeInsets.fromLTRB(
                          24.0,
                          24.0,
                          24.0,
                          100.0 + MediaQuery.of(context).viewInsets.bottom,
                        ),
                        child: ModalUtils.buildAdaptiveFormContainer(
                          context: context,
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Подзаголовок с пояснением
                                Text(
                                  widget.initial == null
                                      ? 'Выберите сотрудника и укажите количество часов'
                                      : 'Измените количество часов или добавьте комментарий',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: theme.colorScheme.secondary,
                                  ),
                                ),
                                const SizedBox(height: 24),

                                // Отображение сотрудника (для редактирования) или выпадающий список (для добавления)
                                if (widget.initial == null) ...[
                                  // Выпадающий список сотрудников (только для добавления)
                                  GTDropdown<Employee>(
                                    items: availableEmployees,
                                    itemDisplayBuilder: _formatEmployeeName,
                                    selectedItem: _selectedEmployeeId != null
                                        ? availableEmployees.firstWhere(
                                            (employee) =>
                                                employee.id ==
                                                _selectedEmployeeId,
                                            orElse: () => availableEmployees
                                                    .isNotEmpty
                                                ? availableEmployees.first
                                                : Employee(
                                                    id: '',
                                                    firstName: '',
                                                    lastName: '',
                                                    middleName: null,
                                                    position: '',
                                                    phone: '',
                                                    createdAt: DateTime.now(),
                                                    updatedAt: DateTime.now(),
                                                  ),
                                          )
                                        : null,
                                    onSelectionChanged: (employee) {
                                      setState(() {
                                        _selectedEmployeeId = employee?.id;
                                      });
                                    },
                                    labelText: 'Сотрудник',
                                    hintText: 'Выберите сотрудника',
                                    allowMultipleSelection: false,
                                    allowCustomInput: false,
                                    validator: (value) {
                                      if (_selectedEmployeeId == null ||
                                          _selectedEmployeeId!.isEmpty) {
                                        return 'Пожалуйста, выберите сотрудника';
                                      }
                                      return null;
                                    },
                                  ),
                                ] else ...[
                                  // Отображение ФИО сотрудника (только для редактирования)
                                  Container(
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: theme.colorScheme.outline
                                            .withValues(alpha: 0.3),
                                        width: 1,
                                      ),
                                      borderRadius: const BorderRadius.all(
                                          Radius.circular(4)),
                                      color: theme
                                          .colorScheme.surfaceContainerHighest
                                          .withValues(alpha: 0.3),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 12),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.person_outline,
                                          color: theme.colorScheme.onSurface
                                              .withValues(alpha: 0.6),
                                          size: 20,
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            _selectedEmployeeId != null
                                                ? _formatEmployeeName(
                                                    allEmployees.firstWhere(
                                                      (employee) =>
                                                          employee.id ==
                                                          _selectedEmployeeId,
                                                      orElse: () => Employee(
                                                        id: '',
                                                        firstName: '',
                                                        lastName: '',
                                                        middleName: null,
                                                        position: '',
                                                        phone: '',
                                                        createdAt:
                                                            DateTime.now(),
                                                        updatedAt:
                                                            DateTime.now(),
                                                      ),
                                                    ),
                                                  )
                                                : '',
                                            style: theme.textTheme.bodyLarge
                                                ?.copyWith(
                                              color:
                                                  theme.colorScheme.onSurface,
                                              fontSize: 16,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 16),

                                // Поле ввода часов
                                TextFormField(
                                  controller: hoursController,
                                  decoration: const InputDecoration(
                                    labelText: 'Часы',
                                    border: OutlineInputBorder(),
                                    prefixIcon: Icon(Icons.timer_outlined),
                                    suffixText: 'ч',
                                    hintText: '0',
                                    helperText:
                                        'Укажите количество отработанных часов',
                                  ),
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  keyboardType: TextInputType.text,
                                  textInputAction: TextInputAction.done,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Пожалуйста, введите количество часов';
                                    }
                                    if (num.tryParse(value) == null) {
                                      return 'Пожалуйста, введите корректное число';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),

                                // Поле ввода комментария
                                TextFormField(
                                  controller: commentController,
                                  decoration: const InputDecoration(
                                    labelText: 'Комментарий (необязательно)',
                                    border: OutlineInputBorder(),
                                    prefixIcon: Icon(Icons.comment_outlined),
                                    hintText:
                                        'Например: Работал в ночную смену',
                                    helperText:
                                        'Добавьте комментарий при необходимости',
                                  ),
                                  maxLines: 3,
                                ),

                                const SizedBox(
                                    height: 100), // Место для плавающих кнопок
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                // Плавающие кнопки
                ModalUtils.buildFloatingButtons(
                  onSave: () {
                    if (_selectedEmployeeId != null && !_isLoading) {
                      _save();
                    }
                  },
                  onCancel: () => Navigator.pop(context),
                  isLoading: _isLoading,
                  saveText: 'Сохранить',
                ),
              ],
            ),
    );
  }
}
