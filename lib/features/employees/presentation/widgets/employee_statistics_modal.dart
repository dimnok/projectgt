import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:projectgt/domain/entities/employee.dart';
import 'package:go_router/go_router.dart';
import 'package:projectgt/core/utils/responsive_utils.dart';

/// Тип отображаемой статистики.
enum StatisticsType {
  /// Статистика по статусам сотрудников.
  status,

  /// Статистика по должностям.
  position,
}

/// Модальное окно для отображения статистики сотрудников.
///
/// Показывает общее количество сотрудников и разбивку по статусам или должностям
/// с цветовыми индикаторами и счетчиками.
class EmployeeStatisticsModal extends StatefulWidget {
  /// Список сотрудников для анализа статистики.
  final List<Employee> employees;

  /// Создаёт модальное окно статистики сотрудников.
  const EmployeeStatisticsModal({
    super.key,
    required this.employees,
  });

  /// Показывает модальное окно статистики.
  static void show(BuildContext context, List<Employee> employees) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => EmployeeStatisticsModal(employees: employees),
    );
  }

  @override
  State<EmployeeStatisticsModal> createState() =>
      _EmployeeStatisticsModalState();
}

class _EmployeeStatisticsModalState extends State<EmployeeStatisticsModal> {
  StatisticsType _currentType = StatisticsType.status;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Заголовок с переключателем
            _buildHeader(theme, context),

            const SizedBox(height: 24),

            // Статистика с прокруткой
            Flexible(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.5,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ..._buildStatisticsList(theme),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  /// Строит заголовок модального окна с переключателем.
  Widget _buildHeader(ThemeData theme, BuildContext context) {
    return Column(
      children: [
        // Основной заголовок
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.analytics_outlined,
                color: theme.colorScheme.primary,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Статистика сотрудников',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Всего: ${widget.employees.length} сотрудников',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
            CupertinoButton(
              padding: EdgeInsets.zero,
              child: Icon(
                Icons.close,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Переключатель типа статистики
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: theme.colorScheme.outline.withValues(alpha: 0.2),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: _buildToggleButton(
                  'По статусам',
                  StatisticsType.status,
                  Icons.work_outline,
                  theme,
                ),
              ),
              Expanded(
                child: _buildToggleButton(
                  'По должностям',
                  StatisticsType.position,
                  Icons.badge_outlined,
                  theme,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Строит кнопку переключателя.
  Widget _buildToggleButton(
    String text,
    StatisticsType type,
    IconData icon,
    ThemeData theme,
  ) {
    final isSelected = _currentType == type;

    return GestureDetector(
      onTap: () {
        setState(() {
          _currentType = type;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? theme.colorScheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected
                  ? theme.colorScheme.onPrimary
                  : theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
            const SizedBox(width: 8),
            Text(
              text,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isSelected
                    ? theme.colorScheme.onPrimary
                    : theme.colorScheme.onSurface.withValues(alpha: 0.7),
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Получает статистику в зависимости от выбранного типа.
  Map<String, int> _getStatistics() {
    if (_currentType == StatisticsType.status) {
      final Map<String, int> statistics = {};
      for (final status in EmployeeStatus.values) {
        final statusName = _getStatusName(status);
        statistics[statusName] =
            widget.employees.where((emp) => emp.status == status).length;
      }
      return statistics;
    } else {
      // Статистика по должностям
      final Map<String, int> statistics = {};
      for (final employee in widget.employees) {
        final position = employee.position ?? 'Не указана';
        statistics[position] = (statistics[position] ?? 0) + 1;
      }
      return statistics;
    }
  }

  /// Получает цвет для элемента статистики.
  Color _getItemColor(String key, int index) {
    if (_currentType == StatisticsType.status) {
      // Находим статус по названию
      for (final status in EmployeeStatus.values) {
        if (_getStatusName(status) == key) {
          return _getStatusColor(status);
        }
      }
      return Colors.grey;
    } else {
      // Для должностей используем циклические цвета
      final colors = [
        Colors.blue,
        Colors.green,
        Colors.orange,
        Colors.purple,
        Colors.teal,
        Colors.red,
        Colors.indigo,
        Colors.pink,
      ];
      return colors[index % colors.length];
    }
  }

  /// Строит список статистики.
  List<Widget> _buildStatisticsList(ThemeData theme) {
    final statistics = _getStatistics();

    // Сортируем по убыванию количества
    final sortedEntries = statistics.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sortedEntries.asMap().entries.map((entry) {
      final index = entry.key;
      final key = entry.value.key;
      final count = entry.value.value;

      // Скрываем элементы с нулевым количеством
      if (count == 0) return const SizedBox.shrink();

      final itemColor = _getItemColor(key, index);

      return GestureDetector(
        onTap: () => _onStatisticItemTap(key),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(
              color: itemColor.withValues(alpha: 0.3),
              width: 1,
            ),
            borderRadius: BorderRadius.circular(12),
            color: itemColor.withValues(alpha: 0.05),
          ),
          child: Row(
            children: [
              // Цветной индикатор
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: itemColor,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              const SizedBox(width: 16),
              // Название
              Expanded(
                child: Text(
                  key,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              // Счетчик
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: itemColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  count.toString(),
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: itemColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              // Иконка для показа, что элемент кликабельный (только для статусов)
              if (_currentType == StatisticsType.status) ...[
                const SizedBox(width: 8),
                Icon(
                  Icons.chevron_right,
                  color: itemColor.withValues(alpha: 0.7),
                  size: 20,
                ),
              ],
            ],
          ),
        ),
      );
    }).toList();
  }

  /// Обрабатывает нажатие на элемент статистики.
  void _onStatisticItemTap(String key) {
    if (_currentType == StatisticsType.status) {
      // Показываем список сотрудников для выбранного статуса
      _showEmployeeListForStatus(key);
    }
    // Для должностей пока ничего не делаем
  }

  /// Показывает список сотрудников для выбранного статуса.
  void _showEmployeeListForStatus(String statusName) {
    // Находим соответствующий enum статуса
    EmployeeStatus? targetStatus;
    for (final status in EmployeeStatus.values) {
      if (_getStatusName(status) == statusName) {
        targetStatus = status;
        break;
      }
    }

    if (targetStatus == null) return;

    // Фильтруем сотрудников по статусу
    final employeesWithStatus =
        widget.employees.where((emp) => emp.status == targetStatus).toList();

    // Сортируем по фамилии
    employeesWithStatus.sort((a, b) {
      final cmp = a.lastName.toLowerCase().compareTo(b.lastName.toLowerCase());
      if (cmp != 0) return cmp;
      return a.firstName.toLowerCase().compareTo(b.firstName.toLowerCase());
    });

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _EmployeeListModal(
        employees: employeesWithStatus,
        title: statusName,
        statusColor: _getItemColor(statusName, 0),
      ),
    );
  }

  /// Возвращает название статуса на русском языке.
  String _getStatusName(EmployeeStatus status) {
    switch (status) {
      case EmployeeStatus.working:
        return 'Работает';
      case EmployeeStatus.vacation:
        return 'Отпуск';
      case EmployeeStatus.sickLeave:
        return 'На больничном';
      case EmployeeStatus.unpaidLeave:
        return 'Без содержания';
      case EmployeeStatus.fired:
        return 'Уволено';
    }
  }

  /// Возвращает цвет для статуса сотрудника.
  Color _getStatusColor(EmployeeStatus status) {
    switch (status) {
      case EmployeeStatus.working:
        return Colors.green;
      case EmployeeStatus.vacation:
        return Colors.blue;
      case EmployeeStatus.sickLeave:
        return Colors.orange;
      case EmployeeStatus.unpaidLeave:
        return Colors.purple;
      case EmployeeStatus.fired:
        return Colors.red;
    }
  }
}

/// Модальное окно со списком сотрудников для выбранного статуса.
class _EmployeeListModal extends StatelessWidget {
  final List<Employee> employees;
  final String title;
  final Color statusColor;

  const _EmployeeListModal({
    required this.employees,
    required this.title,
    required this.statusColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Заголовок
            _buildHeader(theme, context),

            const SizedBox(height: 16),

            // Список сотрудников
            Flexible(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.6,
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: employees.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final employee = employees[index];
                    return _buildEmployeeItem(context, employee, theme);
                  },
                ),
              ),
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  /// Строит заголовок модального окна.
  Widget _buildHeader(ThemeData theme, BuildContext context) {
    return Row(
      children: [
        // Кнопка "Назад"
        CupertinoButton(
          padding: EdgeInsets.zero,
          child: Icon(
            Icons.arrow_back,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),

        const SizedBox(width: 12),

        // Цветной индикатор статуса
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: statusColor,
            borderRadius: BorderRadius.circular(8),
          ),
        ),

        const SizedBox(width: 12),

        // Заголовок
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: statusColor,
                ),
              ),
              Text(
                '${employees.length} сотрудников',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),

        // Кнопка закрытия
        CupertinoButton(
          padding: EdgeInsets.zero,
          child: Icon(
            Icons.close,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
          onPressed: () {
            Navigator.of(context).pop(); // Закрываем текущее окно
            Navigator.of(context).pop(); // Закрываем статистику
          },
        ),
      ],
    );
  }

  /// Строит элемент списка сотрудника.
  Widget _buildEmployeeItem(
      BuildContext context, Employee employee, ThemeData theme) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => _onEmployeeTap(context, employee),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(
              color: theme.colorScheme.outline.withValues(alpha: 0.2),
            ),
            borderRadius: BorderRadius.circular(8),
            color: theme.colorScheme.surface.withValues(alpha: 0.5),
          ),
          child: Row(
            children: [
              // Аватар (инициалы)
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: statusColor.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Center(
                  child: Text(
                    _getInitials(employee),
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 12),

              // ФИО и должность
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${employee.lastName} ${employee.firstName} ${employee.middleName ?? ""}'
                          .trim(),
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (employee.position != null)
                      Text(
                        employee.position!,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.7),
                        ),
                      ),
                  ],
                ),
              ),

              // Иконка для показа, что элемент кликабельный
              Icon(
                Icons.chevron_right,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Обрабатывает нажатие на сотрудника.
  void _onEmployeeTap(BuildContext context, Employee employee) {
    // Закрываем все модальные окна
    Navigator.of(context).pop(); // Закрываем список сотрудников
    Navigator.of(context).pop(); // Закрываем статистику

    // Переходим к детальному экрану сотрудника
    if (ResponsiveUtils.isMobile(context)) {
      // На мобильных устройствах используем навигацию
      context.pushNamed(
        'employee_details',
        pathParameters: {'employeeId': employee.id},
      );
    } else {
      // На десктопе можем использовать другую логику
      // Например, обновить выбранного сотрудника в главном экране
      // Или также перейти к детальному экрану
      context.pushNamed(
        'employee_details',
        pathParameters: {'employeeId': employee.id},
      );
    }
  }

  /// Получает инициалы сотрудника.
  String _getInitials(Employee employee) {
    final firstLetter = employee.firstName.isNotEmpty
        ? employee.firstName[0].toUpperCase()
        : '';
    final lastLetter =
        employee.lastName.isNotEmpty ? employee.lastName[0].toUpperCase() : '';
    return '$lastLetter$firstLetter';
  }
}
