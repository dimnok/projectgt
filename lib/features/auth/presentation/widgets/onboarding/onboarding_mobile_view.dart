import 'package:flutter/material.dart';
import 'choice_card.dart';

/// Мобильная версия представления экрана онбординга.
///
/// Отображает карточки выбора [ChoiceCard] вертикально (в колонку).
/// В мобильном виде иконки скрыты ([showIcon: false]) для экономии места на экране.
class OnboardingMobileView extends StatelessWidget {
  /// Функция, вызываемая при нажатии на кнопку создания компании.
  final VoidCallback onCreateCompany;

  /// Функция, вызываемая при нажатии на кнопку вступления в компанию.
  final VoidCallback onJoinCompany;

  /// Указывает на состояние выполнения асинхронной операции (загрузки).
  /// Блокирует повторные нажатия на карточки.
  final bool isLoading;

  /// Создает экземпляр [OnboardingMobileView].
  ///
  /// Все параметры обязательны для инициализации действий и управления состоянием.
  const OnboardingMobileView({
    super.key,
    required this.onCreateCompany,
    required this.onJoinCompany,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ChoiceCard(
          icon: Icons.add_business_rounded,
          title: 'Создать компанию',
          subtitle: 'Станьте владельцем и управляйте процессами',
          onTap: onCreateCompany,
          isLoading: isLoading,
          verticalPadding: 16,
          showIcon: false, // Убираем иконку для мобильного вида
        ),
        const SizedBox(height: 16),
        ChoiceCard(
          icon: Icons.group_add_rounded,
          title: 'Вступить в организацию',
          subtitle: 'Введите код, полученный от администратора',
          onTap: onJoinCompany,
          isLoading: isLoading,
          verticalPadding: 16,
          showIcon: false, // Убираем иконку для мобильного вида
        ),
      ],
    );
  }
}

