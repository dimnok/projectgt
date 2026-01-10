import 'package:flutter/material.dart';
import 'choice_card.dart';

/// Десктопная версия представления экрана онбординга.
///
/// Отображает две карточки выбора [ChoiceCard] в один ряд (горизонтально),
/// используя [IntrinsicHeight] для выравнивания их высоты.
class OnboardingDesktopView extends StatelessWidget {
  /// Функция, вызываемая при нажатии на кнопку создания компании.
  final VoidCallback onCreateCompany;

  /// Функция, вызываемая при нажатии на кнопку вступления в компанию.
  final VoidCallback onJoinCompany;

  /// Указывает на состояние выполнения асинхронной операции (загрузки).
  /// Передается в карточки для блокировки нажатий.
  final bool isLoading;

  /// Создает экземпляр [OnboardingDesktopView].
  ///
  /// Все параметры являются обязательными для корректной работы кнопок и индикации загрузки.
  const OnboardingDesktopView({
    super.key,
    required this.onCreateCompany,
    required this.onJoinCompany,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: ChoiceCard(
              icon: Icons.add_business_rounded,
              title: 'Создать',
              subtitle: 'зарегистрировать новую компанию',
              onTap: onCreateCompany,
              isLoading: isLoading,
              verticalPadding: 48, // Слегка вытянутые по вертикали
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ChoiceCard(
              icon: Icons.group_add_rounded,
              title: 'Вступить',
              subtitle: 'по коду приглашения',
              onTap: onJoinCompany,
              isLoading: isLoading,
              verticalPadding: 48, // Слегка вытянутые по вертикали
            ),
          ),
        ],
      ),
    );
  }
}

