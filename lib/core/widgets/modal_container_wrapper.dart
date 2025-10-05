import 'package:flutter/material.dart';

/// Обёртка для модальных окон с единообразной стилизацией.
///
/// Предоставляет стандартный контейнер с тенью, скруглёнными углами и
/// адаптивным позиционированием для desktop и mobile устройств.
///
/// **Использование:**
/// ```dart
/// showModalBottomSheet(
///   context: context,
///   isScrollControlled: true,
///   backgroundColor: Colors.transparent,
///   builder: (ctx) => ModalContainerWrapper(
///     child: DraggableScrollableSheet(
///       // ... содержимое модального окна
///     ),
///   ),
/// );
/// ```
///
/// **Особенности:**
/// - Автоматическая адаптация для desktop (центрирование, ограничение ширины)
/// - Единообразная стилизация (тень, границы, скругления)
/// - Корректный отступ от верхней части экрана
class ModalContainerWrapper extends StatelessWidget {
  /// Содержимое модального окна.
  final Widget child;

  /// Создаёт обёртку для модального окна с единообразной стилизацией.
  ///
  /// [child] — содержимое модального окна (обычно DraggableScrollableSheet).
  const ModalContainerWrapper({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDesktop = MediaQuery.of(context).size.width >= 900;
    final screenWidth = MediaQuery.of(context).size.width;

    final modalContent = Container(
      margin: isDesktop
          ? const EdgeInsets.only(top: 48)
          : EdgeInsets.only(
              top: kToolbarHeight + MediaQuery.of(context).padding.top,
            ),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 24,
            offset: const Offset(0, -8),
          ),
        ],
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.12),
          width: 1.5,
        ),
      ),
      child: child,
    );

    if (isDesktop) {
      return Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: screenWidth * 0.5),
          child: modalContent,
        ),
      );
    } else {
      return modalContent;
    }
  }
}
