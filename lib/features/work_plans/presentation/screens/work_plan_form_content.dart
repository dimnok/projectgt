import 'package:flutter/material.dart';
import 'package:projectgt/core/widgets/gt_buttons.dart';
import 'package:projectgt/core/widgets/gt_text_field.dart';
import 'package:projectgt/features/objects/domain/entities/object.dart';
import 'package:projectgt/domain/entities/employee.dart' as domain_employee;
import 'package:projectgt/core/widgets/gt_dropdown.dart';
import 'package:projectgt/features/work_plans/presentation/widgets/work_block_widget.dart';
import 'package:projectgt/features/work_plans/presentation/widgets/work_block_state.dart';
import 'package:projectgt/features/work_plans/presentation/widgets/work_selection_widget.dart';

/// Контент формы создания плана работ с поддержкой блоков.
///
/// Отображает форму для ввода данных плана работ с возможностью добавления
/// множественных блоков работ.
class WorkPlanFormContent extends StatelessWidget {
  /// Является ли форма созданием нового плана работ.
  final bool isNew;

  /// Флаг состояния загрузки.
  final bool isLoading;

  /// Контроллер для поля "Дата".
  final TextEditingController dateController;

  /// Выбранная дата.
  final DateTime? selectedDate;

  /// Колбэк при изменении даты.
  final void Function(DateTime?) onDateChanged;

  /// Список доступных объектов.
  final List<ObjectEntity> availableObjects;

  /// Выбранный объект.
  final ObjectEntity? selectedObject;

  /// Колбэк при изменении выбранного объекта.
  final void Function(ObjectEntity?) onObjectChanged;

  /// Список доступных сотрудников.
  final List<domain_employee.Employee> availableEmployees;

  /// Список доступных сотрудников, которые могут быть ответственными.
  final List<domain_employee.Employee> availableResponsibles;

  /// Список ID уже выбранных работников во всех блоках (для предотвращения дублей).
  final Set<String> alreadySelectedWorkerIds;

  /// Список состояний блоков работ.
  final List<WorkBlockState> workBlocks;

  /// Колбэк при изменении ответственного в блоке.
  final Function(int blockIndex, domain_employee.Employee? responsible)?
      onBlockResponsibleChanged;

  /// Колбэк при изменении работников в блоке.
  final Function(int blockIndex, List<domain_employee.Employee> workers)?
      onBlockWorkersChanged;

  /// Колбэк при изменении участка в блоке.
  final Function(int blockIndex, String? section)? onBlockSectionChanged;

  /// Колбэк при изменении этажа в блоке.
  final Function(int blockIndex, String? floor)? onBlockFloorChanged;

  /// Колбэк при изменении системы в блоке.
  final Function(int blockIndex, String? system)? onBlockSystemChanged;

  /// Колбэк при изменении работ в блоке.
  final Function(int blockIndex, List<SelectedWork> works)? onBlockWorksChanged;

  /// Колбэк при добавлении нового блока.
  final VoidCallback? onAddBlock;

  /// Колбэк при удалении блока.
  final Function(int blockIndex)? onDeleteBlock;

  /// Колбэк при изменении состояния сворачивания блока.
  final Function(int blockIndex, bool isCollapsed)? onToggleCollapsed;

  /// Колбэк для сохранения формы.
  final VoidCallback onSave;

  /// Колбэк для отмены/закрытия формы.
  final VoidCallback onCancel;

  /// Конструктор [WorkPlanFormContent].
  const WorkPlanFormContent({
    super.key,
    required this.isNew,
    required this.isLoading,
    required this.dateController,
    required this.selectedDate,
    required this.onDateChanged,
    required this.availableObjects,
    required this.selectedObject,
    required this.onObjectChanged,
    required this.availableEmployees,
    required this.availableResponsibles,
    required this.alreadySelectedWorkerIds,
    required this.workBlocks,
    this.onBlockResponsibleChanged,
    this.onBlockWorkersChanged,
    this.onBlockSectionChanged,
    this.onBlockFloorChanged,
    this.onBlockSystemChanged,
    this.onBlockWorksChanged,
    this.onAddBlock,
    this.onDeleteBlock,
    this.onToggleCollapsed,
    required this.onSave,
    required this.onCancel,
    this.isSaveEnabled,
  });

  /// Явно передаваемый признак доступности сохранения (из родителя).
  final bool? isSaveEnabled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Поле "Дата"
        GTTextField(
          controller: dateController,
          enabled: !isLoading,
          readOnly: true,
          onTap: () async {
            if (isLoading) return;

            final pickedDate = await showDatePicker(
              context: context,
              initialDate: selectedDate ?? DateTime.now(),
              firstDate: DateTime.now(),
              lastDate: DateTime.now().add(const Duration(days: 365)),
              builder: (context, child) {
                return Theme(
                  data: theme.copyWith(
                    colorScheme: theme.colorScheme.copyWith(
                      primary: Colors.green,
                      onPrimary: Colors.white,
                      surface: theme.colorScheme.surface,
                      onSurface: theme.colorScheme.onSurface,
                    ),
                  ),
                  child: child!,
                );
              },
            );

            if (pickedDate != null) {
              onDateChanged(pickedDate);
            }
          },
          labelText: 'Дата плана работ',
          hintText: 'Выберите дату',
          prefixIcon: Icons.calendar_today_rounded,
          suffixIcon: IconButton(
            icon: Icon(
              Icons.calendar_view_month_rounded,
              color: theme.colorScheme.primary,
            ),
            onPressed: () async {
              if (isLoading) return;

              final pickedDate = await showDatePicker(
                context: context,
                initialDate: selectedDate ?? DateTime.now(),
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 365)),
                builder: (context, child) {
                  return Theme(
                    data: theme.copyWith(
                      colorScheme: theme.colorScheme.copyWith(
                        primary: Colors.green,
                        onPrimary: Colors.white,
                        surface: theme.colorScheme.surface,
                        onSurface: theme.colorScheme.onSurface,
                      ),
                    ),
                    child: child!,
                  );
                },
              );

              if (pickedDate != null) {
                onDateChanged(pickedDate);
              }
            },
          ),
        ),

        const SizedBox(height: 20),

        // 2. Поле "Объект"
        GTDropdown<ObjectEntity>(
          items: availableObjects,
          itemDisplayBuilder: (object) => object.name,
          selectedItem: selectedObject,
          onSelectionChanged: isLoading ? (_) {} : onObjectChanged,
          labelText: 'Объект',
          hintText: 'Выберите объект',
          allowClear: true,
          validator: (value) {
            if (selectedObject == null) {
              return 'Пожалуйста, выберите объект';
            }
            return null;
          },
          readOnly: isLoading,
        ),

        const SizedBox(height: 24),

        // Кнопка добавления блока
        if (selectedObject != null && !isLoading)
          Align(
            alignment: Alignment.centerRight,
            child: GTSecondaryButton(
              onPressed: onAddBlock,
              icon: Icons.add,
              text: 'Добавить блок',
            ),
          ),

        const SizedBox(height: 16),

        // Список блоков работ
        if (selectedObject != null) ...[
          if (workBlocks.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest
                    .withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: theme.colorScheme.outline.withValues(alpha: 0.2),
                  style: BorderStyle.solid,
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.work_off_outlined,
                    color: theme.colorScheme.onSurfaceVariant,
                    size: 48,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Блоки работ не добавлены',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Нажмите "Добавить блок" чтобы создать первый блок работ',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          else
            ...workBlocks.asMap().entries.map((entry) {
              final index = entry.key;
              final blockState = entry.value;

              return WorkBlockWidget(
                blockIndex: index,
                blockState: blockState,
                availableEmployees: availableEmployees,
                availableResponsibles: availableResponsibles,
                alreadySelectedWorkerIds: alreadySelectedWorkerIds,
                selectedObject: selectedObject,
                isLoading: isLoading,
                canDelete: workBlocks.length > 1,
                onResponsibleChanged: onBlockResponsibleChanged,
                onWorkersChanged: onBlockWorkersChanged,
                onSectionChanged: onBlockSectionChanged,
                onFloorChanged: onBlockFloorChanged,
                onSystemChanged: onBlockSystemChanged,
                onWorksChanged: onBlockWorksChanged,
                onDeleteBlock: onDeleteBlock,
                onToggleCollapsed: onToggleCollapsed,
              );
            }),
        ],
      ],
    );
  }

  /// Проверяет, можно ли сохранить план работ (для использования в родителе).
  bool canSave() {
    if (selectedDate == null || selectedObject == null) return false;
    if (workBlocks.isEmpty) return false;

    // Проверяем каждый блок
    for (final block in workBlocks) {
      if (block.selectedSystem == null) return false;
      if (block.selectedWorks.isEmpty) return false;

      // Проверяем что у всех работ указано количество > 0
      for (final work in block.selectedWorks) {
        if (work.quantity <= 0) return false;
      }
    }

    return true;
  }
}
