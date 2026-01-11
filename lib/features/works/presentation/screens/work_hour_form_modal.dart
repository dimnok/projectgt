import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/work_hour.dart';
import '../providers/work_hours_provider.dart';
import 'package:projectgt/presentation/state/employee_state.dart'
    as employee_state;
import 'package:projectgt/domain/entities/employee.dart';
import 'package:uuid/uuid.dart';
import 'package:projectgt/core/widgets/gt_dropdown.dart';
import 'package:projectgt/core/widgets/gt_text_field.dart';
import 'package:projectgt/core/widgets/gt_buttons.dart';
import 'package:projectgt/core/widgets/mobile_bottom_sheet_content.dart';
import 'package:projectgt/core/widgets/desktop_dialog_content.dart';
import '../providers/work_provider.dart';
import 'package:projectgt/features/company/presentation/providers/company_providers.dart';
import 'package:projectgt/core/utils/responsive_utils.dart';
import 'package:projectgt/core/utils/formatters.dart';

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
      final activeCompanyId = ref.read(activeCompanyIdProvider);
      if (activeCompanyId == null) {
        throw Exception('Компания не выбрана');
      }

      final hour = WorkHour(
        id: widget.initial?.id ?? const Uuid().v4(),
        companyId: activeCompanyId,
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
    return ResponsiveUtils.isDesktop(context)
        ? formatFullName(
            employee.lastName,
            employee.firstName,
            employee.middleName,
          )
        : formatAbbreviatedName(
            employee.lastName,
            employee.firstName,
            employee.middleName,
          );
  }

  @override
  Widget build(BuildContext context) {
    final activeCompanyId = ref.watch(activeCompanyIdProvider);
    final employeeState = ref.watch(employee_state.employeeProvider);
    final allEmployees = employeeState.employees;
    final workHoursAsync = ref.watch(workHoursProvider(widget.workId));
    final workAsync = ref.watch(workProvider(widget.workId));
    final theme = Theme.of(context);
    final isDesktop = ResponsiveUtils.isDesktop(context);

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
            .where(
              (e) =>
                  e.status == EmployeeStatus.working &&
                  e.objectIds.contains(workObjectId) &&
                  !busyEmployeeIds.contains(e.id),
            )
            .toList();
      } else {
        availableEmployees = allEmployees
            .where(
              (e) =>
                  e.status == EmployeeStatus.working &&
                  e.objectIds.contains(workObjectId) &&
                  (!busyEmployeeIds.contains(e.id) ||
                      e.id == widget.initial!.employeeId),
            )
            .toList();
      }
    } else {
      // Если объект смены не найден, показываем всех работающих
      if (widget.initial == null) {
        availableEmployees = allEmployees
            .where(
              (e) =>
                  e.status == EmployeeStatus.working &&
                  !busyEmployeeIds.contains(e.id),
            )
            .toList();
      } else {
        availableEmployees = allEmployees
            .where(
              (e) =>
                  e.status == EmployeeStatus.working &&
                  (!busyEmployeeIds.contains(e.id) ||
                      e.id == widget.initial!.employeeId),
            )
            .toList();
      }
    }

    // Сортируем по алфавиту (ФИО)
    availableEmployees.sort((a, b) {
      final nameA = _formatEmployeeName(a).toLowerCase();
      final nameB = _formatEmployeeName(b).toLowerCase();
      return nameA.compareTo(nameB);
    });

    final title = widget.initial == null
        ? 'Добавить сотрудника'
        : 'Редактировать часы';

    final formContent = Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Подзаголовок с пояснением
          Text(
            widget.initial == null
                ? 'Выберите сотрудника и укажите количество часов'
                : 'Измените количество часов или добавьте комментарий',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
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
                  ? availableEmployees
                        .where((e) => e.id == _selectedEmployeeId)
                        .firstOrNull
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
                  color: theme.colorScheme.outline.withValues(alpha: 0.1),
                  width: 1,
                ),
                borderRadius: BorderRadius.circular(16),
                color: theme.colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.3,
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Row(
                children: [
                  Icon(
                    Icons.person_outline,
                    color: theme.colorScheme.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _selectedEmployeeId != null
                          ? _formatEmployeeName(
                              allEmployees.firstWhere(
                                (employee) =>
                                    employee.id == _selectedEmployeeId,
                                orElse: () => Employee(
                                  id: '',
                                  companyId: activeCompanyId ?? '',
                                  firstName: '',
                                  lastName: '',
                                  middleName: null,
                                  position: '',
                                  phone: '',
                                  createdAt: DateTime.now(),
                                  updatedAt: DateTime.now(),
                                ),
                              ),
                            )
                          : '',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 20),

          // Поле ввода часов
          GTTextField(
            controller: hoursController,
            labelText: 'Часы',
            hintText: '0',
            suffixText: 'ч',
            prefixIcon: Icons.timer_outlined,
            helperText: 'Укажите количество отработанных часов',
            textAlign: TextAlign.center,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Пожалуйста, введите количество часов';
              }
              final val = value.replaceAll(',', '.');
              if (num.tryParse(val) == null) {
                return 'Пожалуйста, введите корректное число';
              }
              return null;
            },
          ),
          const SizedBox(height: 20),

          // Поле ввода комментария
          GTTextField(
            controller: commentController,
            labelText: 'Комментарий (необязательно)',
            hintText: 'Например: Работал в ночную смену',
            prefixIcon: Icons.comment_outlined,
            helperText: 'Добавьте комментарий при необходимости',
            maxLines: 3,
          ),
        ],
      ),
    );

    final footer = Row(
      children: [
        Expanded(
          child: GTSecondaryButton(
            onPressed: () => Navigator.pop(context),
            text: 'Отмена',
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: GTPrimaryButton(
            onPressed: _save,
            isLoading: _isLoading,
            text: 'Сохранить',
          ),
        ),
      ],
    );

    if (_isLoading) {
      return const Center(child: CupertinoActivityIndicator());
    }

    if (isDesktop) {
      return Center(
        child: DesktopDialogContent(
          title: title,
          footer: footer,
          child: formContent,
        ),
      );
    } else {
      return MobileBottomSheetContent(
        title: title,
        footer: footer,
        scrollController: widget.scrollController,
        child: formContent,
      );
    }
  }
}
