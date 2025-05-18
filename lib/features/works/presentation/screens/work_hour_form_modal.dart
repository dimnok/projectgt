import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/work_hour.dart';
import '../providers/work_hours_provider.dart';
import '../providers/work_provider.dart';
import 'package:projectgt/presentation/state/employee_state.dart' as employee_state;
import 'package:projectgt/domain/entities/employee.dart';
import 'package:uuid/uuid.dart';
import 'dart:developer' as developer;

/// Модальное окно для добавления или редактирования часов сотрудника в смене.
class WorkHourFormModal extends ConsumerStatefulWidget {
  /// Идентификатор смены.
  final String workId;
  /// Начальные данные для редактирования (null для создания новой записи).
  final WorkHour? initial;

  /// Создаёт модальное окно для добавления или редактирования часов сотрудника.
  const WorkHourFormModal({super.key, required this.workId, this.initial});

  @override
  ConsumerState<WorkHourFormModal> createState() => _WorkHourFormModalState();
}

class _WorkHourFormModalState extends ConsumerState<WorkHourFormModal> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedEmployeeId;
  late TextEditingController hoursController;
  late TextEditingController commentController;

  @override
  void initState() {
    super.initState();
    final i = widget.initial;
    _selectedEmployeeId = i?.employeeId;
    hoursController = TextEditingController(text: i?.hours.toString() ?? '');
    commentController = TextEditingController(text: i?.comment ?? '');
    
    // Загружаем список сотрудников, если они еще не загружены
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(employee_state.employeeProvider.notifier).getEmployees();
      
      // Если редактируем существующую запись, предварительно загружаем данные сотрудника
      if (_selectedEmployeeId != null) {
        _loadEmployeeIfNeeded(_selectedEmployeeId!);
      }
    });
  }
  
  /// Загружает сотрудника, если его нет в списке.
  Future<void> _loadEmployeeIfNeeded(String employeeId) async {
    final employees = ref.read(employee_state.employeeProvider).employees;
    final employeeExists = employees.any((e) => e.id == employeeId);
    
    if (!employeeExists) {
      try {
        await ref.read(employee_state.employeeProvider.notifier).getEmployee(employeeId);
      } catch (e) {
        developer.log('Error loading employee $employeeId: $e', name: 'work_hour_form_modal');
      }
    }
  }

  @override
  void dispose() {
    hoursController.dispose();
    commentController.dispose();
    super.dispose();
  }

  /// Сохраняет или обновляет запись о часах сотрудника.
  void _save() async {
    if (!_formKey.currentState!.validate() || _selectedEmployeeId == null) return;
    final hour = WorkHour(
      id: widget.initial?.id ?? const Uuid().v4(),
      workId: widget.workId,
      employeeId: _selectedEmployeeId!,
      hours: num.tryParse(hoursController.text) ?? 0,
      comment: commentController.text.trim().isEmpty ? null : commentController.text.trim(),
      createdAt: widget.initial?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );
    if (widget.initial == null) {
      await ref.read(workHoursProvider(widget.workId).notifier).add(hour);
    } else {
      await ref.read(workHoursProvider(widget.workId).notifier).update(hour);
    }
    if (mounted) Navigator.pop(context);
  }

  /// Форматирует ФИО сотрудника для отображения в выпадающем списке.
  String _formatEmployeeName(Employee employee) {
    return '${employee.lastName} ${employee.firstName}${employee.middleName != null && employee.middleName!.isNotEmpty ? ' ${employee.middleName}' : ''}';
  }

  @override
  Widget build(BuildContext context) {
    // Получаем всех сотрудников
    final employeeState = ref.watch(employee_state.employeeProvider);
    final allEmployees = employeeState.employees;
    final isEmployeesLoading = employeeState.status == employee_state.EmployeeStatus.loading;
    final theme = Theme.of(context);
    
    // Получаем данные о смене, чтобы узнать объект
    final workAsync = ref.watch(workProvider(widget.workId));
    
    // Фильтруем сотрудников по объекту смены и статусу "Работает"
    List<Employee> filteredEmployees = [];
    if (workAsync != null) {
      filteredEmployees = allEmployees
          .where((employee) => employee.objectIds.contains(workAsync.objectId))
          .where((employee) => employee.status == EmployeeStatus.working) // Только работающие сотрудники
          .toList();
    } else {
      filteredEmployees = allEmployees
          .where((employee) => employee.status == EmployeeStatus.working) // Только работающие сотрудники
          .toList();
    }
    
    // Сортируем по фамилии для удобства
    filteredEmployees.sort((a, b) => a.lastName.compareTo(b.lastName));
    
    return StatefulBuilder(
      builder: (context, setState) {
        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Заголовок с кнопкой закрытия
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            widget.initial == null ? 'Добавить сотрудника' : 'Редактировать часы',
                            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          style: IconButton.styleFrom(foregroundColor: Colors.red),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),
                  const Divider(),
                  // Основная карточка
                  Card(
                    margin: EdgeInsets.zero,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: theme.colorScheme.outline.withAlpha(51),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Подзаголовок с пояснением
                            Text(widget.initial == null
                              ? 'Выберите сотрудника и укажите количество часов'
                              : 'Измените количество часов или добавьте комментарий',
                              style: TextStyle(
                                fontSize: 14,
                                color: Theme.of(context).colorScheme.secondary,
                              ),
                            ),
                            const SizedBox(height: 24),
                            
                            // Выпадающий список сотрудников
                            DropdownButtonFormField<String>(
                              decoration: const InputDecoration(
                                labelText: 'Сотрудник',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.person_outline),
                                helperText: 'Отображаются только сотрудники со статусом "Работает"',
                              ),
                              value: _selectedEmployeeId,
                              items: isEmployeesLoading
                                  ? [const DropdownMenuItem(value: '', child: Text('Загрузка сотрудников...'))]
                                  : filteredEmployees.isEmpty
                                      ? [const DropdownMenuItem(value: '', child: Text('Нет сотрудников на объекте'))]
                                      : filteredEmployees.map((employee) {
                                          return DropdownMenuItem(
                                            value: employee.id,
                                            child: Text(
                                              _formatEmployeeName(employee),
                                              style: const TextStyle(fontWeight: FontWeight.w500),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          );
                                        }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  _selectedEmployeeId = value;
                                });
                              },
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Пожалуйста, выберите сотрудника';
                                }
                                return null;
                              },
                              icon: const Icon(Icons.arrow_drop_down_circle_outlined),
                            ),
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
                                helperText: 'Укажите количество отработанных часов',
                              ),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
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
                                hintText: 'Например: Работал в ночную смену',
                                helperText: 'Добавьте комментарий при необходимости',
                              ),
                              maxLines: 3,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Кнопки в стиле окна "Открытие смены"
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size.fromHeight(44),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          child: const Text('Отмена'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _save,
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size.fromHeight(44),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          child: const Text('Сохранить'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
} 