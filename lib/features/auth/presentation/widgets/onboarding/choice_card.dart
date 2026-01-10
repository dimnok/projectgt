import 'package:flutter/material.dart';

/// Виджет карточки выбора для процесса онбординга.
///
/// Используется для представления пользователю различных вариантов действий
/// (например, "Создать компанию" или "Вступить в компанию") с иконкой, заголовком и подзаголовком.
/// Поддерживает состояния наведения (hover) и нажатия (pressed) с анимацией.
class ChoiceCard extends StatefulWidget {
  /// Иконка, отображаемая в верхней части карточки.
  final IconData icon;

  /// Основной заголовок карточки.
  final String title;

  /// Дополнительный текст описания под заголовком.
  final String subtitle;

  /// Обработчик нажатия на карточку.
  final VoidCallback onTap;

  /// Флаг состояния загрузки. Если [true], нажатия игнорируются.
  final bool isLoading;

  /// Вертикальный внутренний отступ содержимого карточки.
  final double verticalPadding;

  /// Флаг видимости иконки.
  final bool showIcon;

  /// Создает экземпляр [ChoiceCard].
  const ChoiceCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.isLoading = false,
    this.verticalPadding = 32,
    this.showIcon = true,
  });

  @override
  State<ChoiceCard> createState() => _ChoiceCardState();
}

class _ChoiceCardState extends State<ChoiceCard> {
  bool _isPressed = false;
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        onTap: widget.isLoading ? null : widget.onTap,
        child: AnimatedScale(
          scale: _isPressed ? 0.97 : (_isHovered ? 1.02 : 1.0),
          duration: const Duration(milliseconds: 100),
          curve: Curves.easeInOut,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 100),
            padding: EdgeInsets.symmetric(
              vertical: widget.verticalPadding,
              horizontal: 16,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              color: isDark
                  ? Color.alphaBlend(
                      theme.colorScheme.primary.withValues(
                          alpha: _isPressed
                              ? 0.01
                              : (_isHovered ? 0.06 : 0.03)),
                      theme.colorScheme.surfaceContainerHigh,
                    )
                  : theme.colorScheme.surface,
              boxShadow: _isPressed
                  ? []
                  : [
                      if (!isDark)
                        BoxShadow(
                          color: Colors.black.withValues(
                              alpha: _isHovered ? 0.15 : 0.12),
                          blurRadius: _isHovered ? 28 : 24,
                          offset: Offset(0, _isHovered ? 14 : 12),
                          spreadRadius: _isHovered ? -6 : -8,
                        ),
                      if (isDark) ...[
                        // Глубокая основная тень (нижняя)
                        BoxShadow(
                          color: Colors.black
                              .withValues(alpha: _isHovered ? 0.9 : 0.8),
                          blurRadius: _isHovered ? 25 : 20,
                          offset: Offset(_isHovered ? 8 : 6, _isHovered ? 8 : 6),
                          spreadRadius: 1,
                        ),
                        // Неоморфный блик (верхний левый)
                        BoxShadow(
                          color: Colors.white.withValues(
                              alpha: _isHovered ? 0.07 : 0.05),
                          blurRadius: _isHovered ? 18 : 15,
                          offset: Offset(_isHovered ? -5 : -4, _isHovered ? -5 : -4),
                          spreadRadius: 0,
                        ),
                        // Внутреннее свечение
                        BoxShadow(
                          color: theme.colorScheme.primary.withValues(
                              alpha: _isHovered ? 0.08 : 0.05),
                          blurRadius: _isHovered ? 12 : 10,
                          offset: const Offset(0, 0),
                          spreadRadius: _isHovered ? -1 : -2,
                        ),
                      ],
                    ],
            ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.showIcon) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.05),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    widget.icon,
                    size: 32,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 16),
              ],
              Text(
                widget.title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                widget.subtitle,
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
  );
}
}

