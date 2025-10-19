import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../data/models/month_group.dart';
import '../providers/month_groups_provider.dart';
import '../providers/month_summary_provider.dart';
import 'package:projectgt/core/utils/formatters.dart';
import 'package:projectgt/core/utils/responsive_utils.dart';
import 'package:projectgt/presentation/widgets/app_bar_widget.dart';

/// Виджет для отображения детальной информации о месяце.
///
/// Показывается в правой панели на десктопе при клике на заголовок месяца.
/// Загружает детальные данные смен для расчёта статистики по объектам, системам и сотрудникам.
class MonthDetailsPanel extends ConsumerStatefulWidget {
  /// Группа месяца для отображения.
  final MonthGroup group;

  /// Флаг, указывающий, что панель используется как самостоятельный мобильный экран.
  final bool showMobileAppBar;

  /// Использовать ли grouped background (серый фон в стиле iOS секций).
  final bool useGroupedBackground;

  /// Создаёт панель с информацией о месяце.
  const MonthDetailsPanel({
    super.key,
    required this.group,
    this.showMobileAppBar = false,
    this.useGroupedBackground = false,
  });

  @override
  ConsumerState<MonthDetailsPanel> createState() => _MonthDetailsPanelState();
}

class _MonthDetailsPanelState extends ConsumerState<MonthDetailsPanel> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final monthName =
        DateFormat('LLLL yyyy', 'ru_RU').format(widget.group.month);
    final isMobileLayout =
        widget.showMobileAppBar || ResponsiveUtils.isMobile(context);

    // Получаем актуальное состояние группы из provider
    final monthGroupsState = ref.watch(monthGroupsProvider);
    final currentGroup = monthGroupsState.groups.firstWhere(
      (g) => g.month == widget.group.month,
      orElse: () => widget.group,
    );

    final works = currentGroup.works;
    final isLoading = works == null;

    // Загружаем детальные данные после загрузки смен
    if (works != null && works.isNotEmpty) {}

    // Рассчитываем дополнительную статистику
    final totalEmployees = _calculateTotalEmployees();
    final totalHours = _calculateTotalHours();

    final formattedMonthTitle = monthName
        .split(' ')
        .map((word) => word.isEmpty
            ? word
            : '${word[0].toUpperCase()}${word.substring(1)}')
        .join(' ');

    final isGroupedBackground =
        widget.useGroupedBackground || widget.showMobileAppBar;
    final groupedBackgroundColor = theme.brightness == Brightness.light
        ? const Color(0xFFF2F2F7)
        : const Color(0xFF1C1C1E);
    final scaffoldBackgroundColor = isGroupedBackground
        ? groupedBackgroundColor
        : theme.colorScheme.surface;

    return Scaffold(
      backgroundColor: scaffoldBackgroundColor,
      appBar: widget.showMobileAppBar
          ? AppBarWidget(
              title: formattedMonthTitle,
              leading: const BackButton(),
              centerTitle: true,
              showThemeSwitch: false,
            )
          : null,
      body: isLoading
          ? const Center(child: CupertinoActivityIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: isMobileLayout ? 16 : 24,
                vertical: isMobileLayout ? 20 : 24,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (!isMobileLayout) ...[
                    Center(
                      child: Column(
                        children: [
                          Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primaryContainer,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.calendar_month_rounded,
                              size: 50,
                              color: theme.colorScheme.onPrimaryContainer,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            monthName.split(' ').map((word) {
                              return word[0].toUpperCase() + word.substring(1);
                            }).join(' '),
                            style: theme.textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (currentGroup.isCurrentMonth) ...[
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 6),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primaryContainer,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(
                                'Текущий месяц',
                                style: theme.textTheme.labelMedium?.copyWith(
                                  color: theme.colorScheme.onPrimaryContainer,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                  ] else ...[
                    const SizedBox(height: 12),
                  ],

                  // Основная статистика (в 2 столбца)
                  _buildSectionTitle(context, 'Общая статистика'),
                  const SizedBox(height: 12),
                  if (isMobileLayout)
                    _AppleMenuGroup(
                      children: [
                        _AppleMenuItem(
                          icon: Icons.work_outline,
                          iconColor: Colors.blue,
                          title: 'Всего смен',
                          trailing: Text(
                            '${currentGroup.worksCount}',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        _AppleMenuItem(
                          icon: Icons.payments_outlined,
                          iconColor: Colors.green,
                          title: 'Общая сумма',
                          trailing: Text(
                            formatCurrency(currentGroup.totalAmount),
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        _AppleMenuItem(
                          icon: Icons.calculate_outlined,
                          iconColor: Colors.orange,
                          title: 'Средняя смена',
                          trailing: Text(
                            currentGroup.worksCount > 0
                                ? formatCurrency(
                                    currentGroup.totalAmount /
                                        currentGroup.worksCount,
                                  )
                                : formatCurrency(0),
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        _AppleMenuItem(
                          icon: Icons.person_outline,
                          iconColor: Colors.purple,
                          title: 'Средняя выработка',
                          trailing: Text(
                            _calculateAveragePerEmployee(works),
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        _AppleMenuItem(
                          icon: Icons.people_outline,
                          iconColor: Colors.teal,
                          title: 'Всего специалистов',
                          trailing: Text(
                            '$totalEmployees',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        _AppleMenuItem(
                          icon: Icons.schedule_outlined,
                          iconColor: Colors.deepOrange,
                          title: 'Всего часов',
                          trailing: Text(
                            totalHours > 0
                                ? totalHours.toStringAsFixed(0)
                                : '0',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    )
                  else ...[
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            context: context,
                            icon: Icons.work_rounded,
                            label: 'Всего смен',
                            value: '${currentGroup.worksCount}',
                            color: Colors.blue,
                            isCompact: true,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard(
                            context: context,
                            icon: Icons.payments_rounded,
                            label: 'Общая сумма',
                            value: formatCurrency(currentGroup.totalAmount),
                            color: Colors.green,
                            isCompact: true,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            context: context,
                            icon: Icons.calculate_rounded,
                            label: 'Средняя смена',
                            value: currentGroup.worksCount > 0
                                ? formatCurrency(
                                    currentGroup.totalAmount /
                                        currentGroup.worksCount,
                                  )
                                : formatCurrency(0),
                            color: Colors.orange,
                            isCompact: true,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard(
                            context: context,
                            icon: Icons.person_rounded,
                            label: 'Средняя выработка',
                            value: _calculateAveragePerEmployee(works),
                            color: Colors.purple,
                            isCompact: true,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            context: context,
                            icon: Icons.people_rounded,
                            label: 'Всего специалистов',
                            value: '$totalEmployees',
                            color: Colors.teal,
                            isCompact: true,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard(
                            context: context,
                            icon: Icons.schedule_rounded,
                            label: 'Всего часов',
                            value: totalHours > 0
                                ? totalHours.toStringAsFixed(0)
                                : '0',
                            color: Colors.deepOrange,
                            isCompact: true,
                          ),
                        ),
                      ],
                    ),
                  ],

                  const SizedBox(height: 32),

                  // Статистика по системам (вертикально)
                  _buildSectionTitle(context, 'По системам'),
                  const SizedBox(height: 12),
                  _buildSystemsStats(context, works),

                  const SizedBox(height: 32),

                  // Статистика по объектам (вертикально)
                  _buildSectionTitle(context, 'По объектам'),
                  const SizedBox(height: 12),
                  _buildObjectsStats(context, works),

                  const SizedBox(height: 32),

                  // Hint
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: theme.colorScheme.outlineVariant,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 20,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Кликните на заголовок месяца, чтобы раскрыть/свернуть список смен',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  /// Заголовок секции.
  Widget _buildSectionTitle(BuildContext context, String title) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: theme.colorScheme.onSurface,
        ),
      ),
    );
  }

  /// Рассчитывает среднюю выработку на специалиста.
  String _calculateAveragePerEmployee(List works) {
    if (works.isEmpty) return '0 ₽';

    final totalEmployees = works.fold<int>(
      0,
      (sum, work) => sum + ((work.employeesCount ?? 0) as int),
    );

    if (totalEmployees == 0) return '0 ₽';

    final totalAmount = works.fold<double>(
      0,
      (sum, work) => sum + ((work.totalAmount ?? 0) as double),
    );

    return formatCurrency(totalAmount / totalEmployees);
  }

  /// Рассчитывает общее количество уникальных специалистов.
  int _calculateTotalEmployees() {
    final employeesAsync =
        ref.watch(monthTotalEmployeesProvider(widget.group.month));
    return employeesAsync.when(
      data: (summary) => summary.totalEmployees,
      loading: () => 0,
      error: (_, __) => 0,
    );
  }

  /// Рассчитывает общее количество часов.
  double _calculateTotalHours() {
    final hoursAsync = ref.watch(monthTotalHoursProvider(widget.group.month));
    return hoursAsync.when(
      data: (summary) => summary.totalHours,
      loading: () => 0,
      error: (_, __) => 0,
    );
  }

  /// Строит статистику по системам.
  Widget _buildSystemsStats(BuildContext context, List works) {
    if (works.isEmpty) {
      return _buildEmptyState(context, 'Нет данных по системам');
    }

    // Загружаем полную статистику по системам с сервера
    final systemsSummaryAsync =
        ref.watch(systemsSummaryProvider(widget.group.month));

    return systemsSummaryAsync.when(
      data: (summaries) {
        if (summaries.isEmpty) {
          return _buildEmptyState(context, 'Нет данных по системам');
        }

        return Column(
          children: summaries.map((stat) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: _buildSystemCard(
                context: context,
                systemName: stat.system,
                itemsCount: stat.itemsCount,
                totalAmount: stat.totalAmount,
              ),
            );
          }).toList(),
        );
      },
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: CircularProgressIndicator(),
        ),
      ),
      error: (error, stackTrace) => _buildEmptyState(
        context,
        'Ошибка загрузки: $error',
      ),
    );
  }

  /// Строит статистику по объектам.
  Widget _buildObjectsStats(BuildContext context, List works) {
    if (works.isEmpty) {
      return _buildEmptyState(context, 'Нет данных по объектам');
    }

    // Загружаем полную статистику по объектам с сервера
    final objectsSummaryAsync =
        ref.watch(objectsSummaryProvider(widget.group.month));

    return objectsSummaryAsync.when(
      data: (summaries) {
        if (summaries.isEmpty) {
          return _buildEmptyState(context, 'Нет данных по объектам');
        }

        return Column(
          children: summaries.map((stat) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _buildObjectCard(
                context: context,
                objectName: stat.objectName,
                worksCount: stat.worksCount,
                totalAmount: stat.totalAmount,
              ),
            );
          }).toList(),
        );
      },
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: CircularProgressIndicator(),
        ),
      ),
      error: (error, stackTrace) => _buildEmptyState(
        context,
        'Ошибка загрузки: $error',
      ),
    );
  }

  /// Карточка объекта.
  Widget _buildObjectCard({
    required BuildContext context,
    required String objectName,
    required int worksCount,
    required double totalAmount,
  }) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outlineVariant,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.location_on_rounded,
                size: 20,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  objectName,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildMiniStat(
                context: context,
                label: 'Смен',
                value: '$worksCount',
                color: Colors.blue,
              ),
              _buildMiniStat(
                context: context,
                label: 'Сумма',
                value: formatCurrency(totalAmount),
                color: Colors.green,
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Мини-статистика внутри карточки.
  Widget _buildMiniStat({
    required BuildContext context,
    required String label,
    required String value,
    required Color color,
  }) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  /// Карточка системы.
  Widget _buildSystemCard({
    required BuildContext context,
    required String systemName,
    required int itemsCount,
    required double totalAmount,
  }) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.outlineVariant,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.construction_rounded,
            size: 16,
            color: theme.colorScheme.secondary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              systemName,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '$itemsCount раб.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.indigo,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            formatCurrency(totalAmount),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.green,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  /// Пустое состояние.
  Widget _buildEmptyState(BuildContext context, String message) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Text(
          message,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }

  /// Создаёт карточку со статистикой.
  Widget _buildStatCard({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    bool isCompact = false,
  }) {
    final theme = Theme.of(context);

    if (isCompact) {
      // Компактная версия для сетки 2x2
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withValues(alpha: 0.3),
            width: 1.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    size: 20,
                    color: color,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    label,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      );
    }

    // Полная версия
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              size: 24,
              color: color,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Группа элементов в стиле iOS для компактного отображения статистики.
class _AppleMenuGroup extends StatelessWidget {
  const _AppleMenuGroup({
    required this.children,
  });

  final List<_AppleMenuItem> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: _buildChildrenWithDividers(context),
        ),
      ),
    );
  }

  List<Widget> _buildChildrenWithDividers(BuildContext context) {
    final theme = Theme.of(context);
    final List<Widget> widgets = [];

    for (var i = 0; i < children.length; i++) {
      widgets.add(children[i]);
      if (i < children.length - 1) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(left: 60, right: 16),
            child: Divider(
              height: 1,
              thickness: 1,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.05),
            ),
          ),
        );
      }
    }

    return widgets;
  }
}

class _AppleMenuItem extends StatelessWidget {
  const _AppleMenuItem({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.trailing,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
          trailing,
        ],
      ),
    );
  }
}
