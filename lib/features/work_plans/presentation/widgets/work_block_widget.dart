import 'package:flutter/material.dart';
import 'package:projectgt/core/widgets/gt_dropdown.dart';
import 'package:projectgt/domain/entities/employee.dart' as domain_employee;
import 'package:projectgt/domain/entities/object.dart';
import 'package:projectgt/features/work_plans/presentation/widgets/work_block_state.dart';
import 'package:projectgt/features/work_plans/presentation/widgets/work_selection_widget.dart';

/// Виджет для отображения и редактирования блока работ.
///
/// Отображает все поля блока работ: ответственный, работники, участок,
/// этаж, система, работы. Поддерживает сворачивание/разворачивание.
/// Виджет карточки блока работ с редактируемыми полями и действиями.
class WorkBlockWidget extends StatelessWidget {
  /// Индекс блока в списке.
  final int blockIndex;

  /// Состояние блока работ.
  final WorkBlockState blockState;

  /// Список доступных сотрудников.
  final List<domain_employee.Employee> availableEmployees;

  /// Список доступных сотрудников, которые могут быть ответственными.
  final List<domain_employee.Employee> availableResponsibles;

  /// Список ID уже выбранных работников во всех блоках (для предотвращения дублей).
  final Set<String> alreadySelectedWorkerIds;

  /// Выбранный объект (для контекста).
  final ObjectEntity? selectedObject;

  /// Флаг состояния загрузки.
  final bool isLoading;

  /// Можно ли удалить блок.
  final bool canDelete;

  /// Колбэк при изменении ответственного.
  final Function(int blockIndex, domain_employee.Employee? responsible)?
      onResponsibleChanged;

  /// Колбэк при изменении работников.
  final Function(int blockIndex, List<domain_employee.Employee> workers)?
      onWorkersChanged;

  /// Колбэк при изменении участка.
  final Function(int blockIndex, String? section)? onSectionChanged;

  /// Колбэк при изменении этажа.
  final Function(int blockIndex, String? floor)? onFloorChanged;

  /// Колбэк при изменении системы.
  final Function(int blockIndex, String? system)? onSystemChanged;

  /// Колбэк при изменении работ.
  final Function(int blockIndex, List<SelectedWork> works)? onWorksChanged;

  /// Колбэк при удалении блока.
  final Function(int blockIndex)? onDeleteBlock;

  /// Колбэк при изменении состояния сворачивания блока.
  final Function(int blockIndex, bool isCollapsed)? onToggleCollapsed;

  /// Создаёт виджет блока работ с индексом [blockIndex], состоянием [blockState]
  /// и наборами колбэков для изменения полей блока.
  const WorkBlockWidget({
    super.key,
    required this.blockIndex,
    required this.blockState,
    required this.availableEmployees,
    required this.availableResponsibles,
    required this.alreadySelectedWorkerIds,
    required this.selectedObject,
    this.isLoading = false,
    this.canDelete = true,
    this.onResponsibleChanged,
    this.onWorkersChanged,
    this.onSectionChanged,
    this.onFloorChanged,
    this.onSystemChanged,
    this.onWorksChanged,
    this.onDeleteBlock,
    this.onToggleCollapsed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Фильтруем доступных работников - исключаем уже выбранных в других блоках
    final currentBlockWorkerIds =
        blockState.selectedWorkers.map((w) => w.id).toSet();
    final availableWorkersForSelection = availableEmployees.where((employee) {
      return !alreadySelectedWorkerIds.contains(employee.id) ||
          currentBlockWorkerIds.contains(employee.id);
    }).toList();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: blockState.isComplete
              ? Colors.green.withValues(alpha: 0.3)
              : theme.colorScheme.outline.withValues(alpha: 0.2),
          width: blockState.isComplete ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Заголовок блока с кнопками управления
          _buildBlockHeader(context, theme),

          // Содержимое блока (сворачивается)
          if (!blockState.isCollapsed) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(20),
              child: _buildBlockContent(
                  context, theme, availableWorkersForSelection),
            ),
          ],
        ],
      ),
    );
  }

  /// Строит заголовок блока.
  Widget _buildBlockHeader(BuildContext context, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF97D699),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // Иконка блока
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: blockState.isComplete
                  ? Colors.green.withValues(alpha: 0.1)
                  : theme.colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              blockState.isComplete
                  ? Icons.check_circle_outline
                  : Icons.work_outline,
              color: blockState.isComplete
                  ? Colors.green
                  : theme.colorScheme.primary,
              size: 20,
            ),
          ),

          const SizedBox(width: 12),

          // Информация о блоке
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  () {
                    final parts = <String>[];

                    if (blockState.selectedSection != null &&
                        blockState.selectedSection!.isNotEmpty) {
                      parts.add(blockState.selectedSection!);
                    }

                    if (blockState.selectedFloor != null &&
                        blockState.selectedFloor!.isNotEmpty) {
                      parts.add(blockState.selectedFloor!);
                    }

                    if (blockState.selectedSystem != null &&
                        blockState.selectedSystem!.isNotEmpty) {
                      parts.add(blockState.selectedSystem!);
                    }

                    if (parts.isEmpty) {
                      return 'Блок ${blockIndex + 1}';
                    }

                    return parts.join(' • ');
                  }(),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  () {
                    if (blockState.selectedResponsible != null) {
                      final responsible = blockState.selectedResponsible!;
                      final firstNameInitial = responsible.firstName.isNotEmpty
                          ? responsible.firstName[0].toUpperCase()
                          : '';
                      final middleNameInitial =
                          responsible.middleName != null &&
                                  responsible.middleName!.isNotEmpty
                              ? responsible.middleName![0].toUpperCase()
                              : '';
                      return 'Ответственный: ${responsible.lastName} $firstNameInitial${middleNameInitial.isNotEmpty ? '.$middleNameInitial.' : firstNameInitial.isNotEmpty ? '.' : ''}';
                    }

                    return 'Ответственный не назначен';
                  }(),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
                if (blockState.selectedSystem != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (blockState.worksCount > 0) ...[
                        Icon(
                          Icons.construction,
                          size: 14,
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.6),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${blockState.worksCount} работ',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                      if (blockState.workersCount > 0) ...[
                        if (blockState.worksCount > 0)
                          Text(
                            ' • ',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface
                                  .withValues(alpha: 0.6),
                            ),
                          ),
                        Icon(
                          Icons.people_outline,
                          size: 14,
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.6),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${blockState.workersCount} чел.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                      if (blockState.totalCost > 0) ...[
                        if (blockState.worksCount > 0 ||
                            blockState.workersCount > 0)
                          Text(
                            ' • ',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface
                                  .withValues(alpha: 0.6),
                            ),
                          ),
                        Icon(
                          Icons.payments_outlined,
                          size: 14,
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.6),
                        ),
                        Text(
                          _formatCurrency(blockState.totalCost),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.6),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ],
            ),
          ),

          // Кнопки управления
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Кнопка сворачивания/разворачивания
              IconButton(
                onPressed: isLoading
                    ? null
                    : () => onToggleCollapsed?.call(
                        blockIndex, !blockState.isCollapsed),
                icon: Icon(
                  blockState.isCollapsed
                      ? Icons.expand_more
                      : Icons.expand_less,
                ),
                tooltip: blockState.isCollapsed ? 'Развернуть' : 'Свернуть',
              ),

              // Кнопка удаления (если можно удалить)
              if (canDelete && !isLoading)
                IconButton(
                  onPressed: () => onDeleteBlock?.call(blockIndex),
                  icon: const Icon(Icons.delete_outline),
                  iconSize: 20,
                  tooltip: 'Удалить блок',
                  color: Colors.red.withValues(alpha: 0.7),
                ),
            ],
          ),
        ],
      ),
    );
  }

  /// Строит содержимое блока.
  Widget _buildBlockContent(BuildContext context, ThemeData theme,
      List<domain_employee.Employee> availableWorkersForSelection) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Dropdown для выбора ответственного
        GTDropdown<domain_employee.Employee>(
          items: availableResponsibles,
          itemDisplayBuilder: (employee) =>
              '${employee.lastName} ${employee.firstName}${employee.middleName != null ? ' ${employee.middleName}' : ''}',
          selectedItem: blockState.selectedResponsible,
          onSelectionChanged: isLoading
              ? (_) {}
              : (responsible) {
                  onResponsibleChanged?.call(blockIndex, responsible);
                },
          labelText: 'Ответственный',
          hintText: availableResponsibles.isEmpty && selectedObject != null
              ? 'Нет сотрудников для данного объекта'
              : 'Выберите ответственного сотрудника',
          allowClear: true,
          readOnly: isLoading || availableResponsibles.isEmpty,
        ),

        const SizedBox(height: 16),

        // 2. Dropdown для выбора работников
        GTDropdown<domain_employee.Employee>(
          items: availableWorkersForSelection,
          itemDisplayBuilder: (employee) =>
              '${employee.lastName} ${employee.firstName}${employee.middleName != null ? ' ${employee.middleName}' : ''}',
          selectedItems: blockState.selectedWorkers,
          onSelectionChanged: (_) {
            // Пустой callback для одинарного выбора
          },
          onMultiSelectionChanged: isLoading
              ? (_) {}
              : (workers) {
                  onWorkersChanged?.call(blockIndex, workers);
                },
          labelText: 'Работники',
          hintText:
              availableWorkersForSelection.isEmpty && selectedObject != null
                  ? availableEmployees.isEmpty
                      ? 'Нет сотрудников для данного объекта'
                      : 'Все доступные работники уже выбраны'
                  : 'Выберите работников',
          allowMultipleSelection: true,
          allowClear: true,
          readOnly: isLoading || availableWorkersForSelection.isEmpty,
        ),

        const SizedBox(height: 16),

        // 3. Поле "Участок"
        GTDropdown<String>(
          items: blockState.availableSections,
          itemDisplayBuilder: (section) => section,
          selectedItem: blockState.selectedSection,
          onSelectionChanged: isLoading
              ? (_) {}
              : (section) {
                  if (section != null &&
                      !blockState.availableSections.contains(section)) {
                    blockState.availableSections =
                        List<String>.from(blockState.availableSections)
                          ..add(section);
                  }
                  onSectionChanged?.call(blockIndex, section);
                },
          labelText: 'Участок',
          hintText: 'Выберите участок',
          allowClear: true,
          readOnly: isLoading || selectedObject == null,
          allowCustomInput: true,
          showAddNewOption: true,
          customInputBuilder: (input) => input,
        ),

        const SizedBox(height: 16),

        // 4. Поле "Этаж"
        GTDropdown<String>(
          items: blockState.availableFloors,
          itemDisplayBuilder: (floor) => floor,
          selectedItem: blockState.selectedFloor,
          onSelectionChanged: isLoading
              ? (_) {}
              : (floor) {
                  if (floor != null &&
                      !blockState.availableFloors.contains(floor)) {
                    blockState.availableFloors =
                        List<String>.from(blockState.availableFloors)
                          ..add(floor);
                  }
                  onFloorChanged?.call(blockIndex, floor);
                },
          labelText: 'Этаж',
          hintText: 'Выберите этаж',
          allowClear: true,
          readOnly: isLoading || blockState.selectedSection == null,
          allowCustomInput: true,
          showAddNewOption: true,
          customInputBuilder: (input) => input,
        ),

        const SizedBox(height: 16),

        // 5. Поле "Система" (обязательное)
        GTDropdown<String>(
          items: blockState.availableSystems,
          itemDisplayBuilder: (system) => system,
          selectedItem: blockState.selectedSystem,
          onSelectionChanged: isLoading
              ? (_) {}
              : (system) => onSystemChanged?.call(blockIndex, system),
          labelText: 'Система *',
          hintText: 'Выберите систему',
          allowClear: true,
          readOnly: isLoading || selectedObject == null,
          validator: (value) {
            if (blockState.selectedSystem == null ||
                blockState.selectedSystem!.isEmpty) {
              return 'Система обязательна для заполнения';
            }
            return null;
          },
        ),

        const SizedBox(height: 16),

        // 6. Выбор работ с объемами
        WorkSelectionWidget(
          availableWorks: blockState.availableWorks,
          selectedWorks: blockState.selectedWorks,
          onSelectionChanged: isLoading
              ? (_) {}
              : (works) => onWorksChanged?.call(blockIndex, works),
          title: 'Работы *',
          isLoading: isLoading,
          readOnly: isLoading ||
              selectedObject == null ||
              blockState.selectedSystem == null,
        ),

        // Статус блока
        if (blockState.selectedSystem != null) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: blockState.isComplete
                  ? Colors.green.withValues(alpha: 0.05)
                  : Colors.orange.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: blockState.isComplete
                    ? Colors.green.withValues(alpha: 0.2)
                    : Colors.orange.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  blockState.isComplete
                      ? Icons.check_circle_outline
                      : Icons.warning_outlined,
                  color: blockState.isComplete ? Colors.green : Colors.orange,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    blockState.isComplete
                        ? 'Блок заполнен корректно'
                        : 'Выберите работы и укажите объемы',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: blockState.isComplete
                          ? Colors.green.withValues(alpha: 0.8)
                          : Colors.orange.withValues(alpha: 0.8),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  /// Форматирует сумму с разделителями тысяч
  String _formatCurrency(double amount) {
    final formatted = amount.toStringAsFixed(0);
    final regex = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    return '${formatted.replaceAllMapped(regex, (Match match) => '${match[1]} ')} ₽';
  }
}
