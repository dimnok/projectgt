import 'package:flutter/material.dart';
import 'package:projectgt/features/auth/presentation/widgets/profile_completion_form.dart';

/// Экран для обязательного завершения заполнения профиля пользователя.
///
/// Этот экран отображается сразу после первой авторизации (например, по номеру телефона),
/// если у пользователя еще не указано полное имя (ФИО). Без заполнения этих данных
/// доступ к основному функционалу приложения ограничен.
///
/// Содержит логотип приложения, приветственный текст и форму [ProfileCompletionForm].
class ProfileCompletionScreen extends StatelessWidget {
  /// Создает экземпляр [ProfileCompletionScreen].
  const ProfileCompletionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 600;
    final contentWidth = isDesktop ? 450.0 : double.infinity;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: SizedBox(
              width: contentWidth,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Логотип (соответствует размеру на экране входа)
                  Image.asset(
                    'assets/images/logo.png',
                    width: 200,
                    height: 200,
                  ),
                  const SizedBox(height: 40),

                  // Основной контейнер с формой
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: isDesktop
                        ? BoxDecoration(
                            color: theme.colorScheme.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: theme.colorScheme.onSurface.withValues(
                                alpha: 0.1,
                              ),
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: theme.colorScheme.shadow.withValues(
                                  alpha: 0.05,
                                ),
                                blurRadius: 10,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          )
                        : null,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Завершение регистрации',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Введите ваше имя для начала работы',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.6,
                            ),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 32),
                        const ProfileCompletionForm(),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),
                  Text(
                    'Вы сможете изменить эти данные позже в профиле',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
