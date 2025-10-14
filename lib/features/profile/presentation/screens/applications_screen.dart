import 'package:flutter/material.dart';
import 'package:projectgt/presentation/widgets/app_bar_widget.dart';

/// Экран с заявлениями сотрудников.
///
/// Предоставляет доступ к различным типам заявлений:
/// - Заявление на отпуск (ежегодный оплачиваемый)
/// - Заявление на отпуск без сохранения заработной платы
/// - Заявление на увольнение по собственному желанию
/// - Заявление на перевод на другую должность
/// - Заявление на материальную помощь
/// - Заявление на командировку
/// - Заявление на изменение графика работы
class ApplicationsScreen extends StatelessWidget {
  /// Создаёт экран заявлений.
  const ApplicationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.brightness == Brightness.light
          ? const Color(0xFFF2F2F7)
          : const Color(0xFF1C1C1E),
      appBar: const AppBarWidget(
        title: 'Заявления',
        leading: BackButton(),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Иконка
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(60),
                  ),
                  child: const Icon(
                    Icons.description_rounded,
                    size: 64,
                    color: Colors.orange,
                  ),
                ),
                const SizedBox(height: 32),

                // Заголовок
                Text(
                  'В разработке',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),

                // Основное описание
                Text(
                  'Раздел с заявлениями находится в разработке',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),

                // Карточка с описанием функционала
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Доступные типы заявлений:',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const _ApplicationTypeItem(
                        icon: Icons.beach_access_outlined,
                        title: 'Отпуск',
                        description:
                            'Заявление на ежегодный оплачиваемый отпуск с указанием дат начала и окончания',
                        color: Colors.blue,
                      ),
                      const SizedBox(height: 12),
                      const _ApplicationTypeItem(
                        icon: Icons.event_busy_outlined,
                        title: 'Отпуск без содержания',
                        description:
                            'Заявление на отпуск без сохранения заработной платы на указанный период',
                        color: Colors.purple,
                      ),
                      const SizedBox(height: 12),
                      const _ApplicationTypeItem(
                        icon: Icons.logout_outlined,
                        title: 'Увольнение',
                        description:
                            'Заявление на увольнение по собственному желанию с указанием желаемой даты',
                        color: Colors.red,
                      ),
                      const SizedBox(height: 12),
                      const _ApplicationTypeItem(
                        icon: Icons.swap_horiz_outlined,
                        title: 'Перевод на другую должность',
                        description:
                            'Заявление на перевод на другую должность или в другое подразделение',
                        color: Colors.green,
                      ),
                      const SizedBox(height: 12),
                      const _ApplicationTypeItem(
                        icon: Icons.attach_money_outlined,
                        title: 'Материальная помощь',
                        description:
                            'Заявление на получение материальной помощи с указанием причины и суммы',
                        color: Colors.orange,
                      ),
                      const SizedBox(height: 12),
                      const _ApplicationTypeItem(
                        icon: Icons.flight_takeoff_outlined,
                        title: 'Командировка',
                        description:
                            'Заявление на служебную командировку с указанием места назначения и сроков',
                        color: Colors.teal,
                      ),
                      const SizedBox(height: 12),
                      const _ApplicationTypeItem(
                        icon: Icons.schedule_outlined,
                        title: 'Изменение графика работы',
                        description:
                            'Заявление на изменение графика работы или режима рабочего времени',
                        color: Colors.indigo,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Дополнительная информация
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer
                        .withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: theme.colorScheme.primary.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: theme.colorScheme.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Все заявления будут автоматически направляться на согласование руководителю',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Элемент типа заявления.
class _ApplicationTypeItem extends StatelessWidget {
  /// Иконка типа заявления.
  final IconData icon;

  /// Название типа заявления.
  final String title;

  /// Описание типа заявления.
  final String description;

  /// Цвет иконки.
  final Color color;

  /// Создаёт элемент типа заявления.
  const _ApplicationTypeItem({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
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
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
