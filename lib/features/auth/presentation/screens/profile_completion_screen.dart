import 'package:flutter/material.dart';
import 'package:projectgt/features/auth/presentation/widgets/profile_completion_form.dart';

/// Экран для завершения заполнения профиля пользователя.
///
/// Показывается при первой авторизации, когда необходимо заполнить
/// основные данные пользователя (ФИО и телефон).
/// После успешного заполнения перенаправляет на главный экран.
class ProfileCompletionScreen extends StatelessWidget {
  /// Конструктор [ProfileCompletionScreen].
  const ProfileCompletionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 800;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: isDesktop ? 480 : double.infinity,
              maxHeight: isDesktop ? 600 : double.infinity,
            ),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Иконка приветствия
                  Container(
                    width: isDesktop ? 120 : 100,
                    height: isDesktop ? 120 : 100,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.person_add_outlined,
                      size: isDesktop ? 60 : 50,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Приветственный текст
                  Text(
                    'Добро пожаловать!',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),

                  Text(
                    'Прежде чем начать работу, давайте заполним ваш профиль. '
                    'Это займёт всего пару минут.',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),

                  // Форма заполнения профиля
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.1),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: theme.colorScheme.shadow
                                .withValues(alpha: 0.05),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: const ProfileCompletionForm(),
                    ),
                  ),

                  // Нижний текст
                  if (!isDesktop) ...[
                    const SizedBox(height: 24),
                    Text(
                      'Ваши данные защищены и используются только для улучшения сервиса',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color:
                            theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
