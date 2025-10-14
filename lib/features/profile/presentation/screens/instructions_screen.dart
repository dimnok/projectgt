import 'package:flutter/material.dart';
import 'package:projectgt/presentation/widgets/app_bar_widget.dart';

/// Экран с инструкциями по работе с приложением.
///
/// Содержит подробные руководства по каждому модулю системы:
/// - Как правильно заполнять данные
/// - Пошаговые инструкции для каждого раздела
/// - Примеры корректного использования функций
/// - Часто задаваемые вопросы (FAQ)
class InstructionsScreen extends StatelessWidget {
  /// Создаёт экран инструкций.
  const InstructionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.brightness == Brightness.light
          ? const Color(0xFFF2F2F7)
          : const Color(0xFF1C1C1E),
      appBar: const AppBarWidget(
        title: 'Инструкции',
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
                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(60),
                  ),
                  child: Icon(
                    Icons.menu_book_rounded,
                    size: 64,
                    color: theme.colorScheme.primary,
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
                  'Раздел с инструкциями находится в разработке',
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
                        'Что будет доступно:',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const _FeatureItem(
                        icon: Icons.dashboard_outlined,
                        title: 'Руководства по модулям',
                        description:
                            'Подробные инструкции для работы с табелем, сметами, работами, ФОТ и другими разделами приложения',
                      ),
                      const SizedBox(height: 12),
                      const _FeatureItem(
                        icon: Icons.checklist_rounded,
                        title: 'Пошаговые действия',
                        description:
                            'Детальные инструкции по заполнению форм, созданию документов и выполнению типовых операций',
                      ),
                      const SizedBox(height: 12),
                      const _FeatureItem(
                        icon: Icons.lightbulb_outline,
                        title: 'Примеры и советы',
                        description:
                            'Практические примеры корректного использования функций системы и рекомендации по работе',
                      ),
                      const SizedBox(height: 12),
                      const _FeatureItem(
                        icon: Icons.help_outline,
                        title: 'Часто задаваемые вопросы',
                        description:
                            'Ответы на популярные вопросы пользователей и решения типовых проблем',
                      ),
                      const SizedBox(height: 12),
                      const _FeatureItem(
                        icon: Icons.video_library_outlined,
                        title: 'Видео-уроки',
                        description:
                            'Наглядные видео-инструкции по работе с основными функциями приложения',
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

/// Элемент списка возможностей.
class _FeatureItem extends StatelessWidget {
  /// Иконка возможности.
  final IconData icon;

  /// Заголовок.
  final String title;

  /// Описание.
  final String description;

  /// Создаёт элемент списка возможностей.
  const _FeatureItem({
    required this.icon,
    required this.title,
    required this.description,
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
            color: theme.colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 20,
            color: theme.colorScheme.primary,
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
