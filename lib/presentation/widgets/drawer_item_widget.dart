import 'package:flutter/material.dart';

/// Элемент бокового меню (Drawer) для навигации.
///
/// Поддерживает выделение, деструктивные действия и кастомизацию иконки/текста.
class DrawerItemWidget extends StatelessWidget {
  /// Иконка пункта меню.
  final IconData icon;
  /// Текст пункта меню.
  final String title;
  /// Колбэк при нажатии на пункт меню.
  final VoidCallback onTap;
  /// Выделен ли пункт как активный.
  final bool isSelected;
  /// Является ли действие деструктивным (например, выход).
  final bool isDestructive;

  /// Создаёт элемент бокового меню с иконкой, текстом и обработчиком нажатия.
  ///
  /// [icon] — иконка пункта, [title] — текст, [onTap] — обработчик, [isSelected] — выделение, [isDestructive] — деструктивный стиль.
  const DrawerItemWidget({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
    this.isSelected = false,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    final Color iconColor = isDestructive
        ? theme.colorScheme.error
        : isSelected
            ? Colors.green
            : theme.colorScheme.onSurface.withValues(alpha: 0.7);
            
    final Color textColor = isDestructive
        ? theme.colorScheme.error
        : isSelected
            ? Colors.green
            : theme.colorScheme.onSurface;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          splashColor: Colors.green.withValues(alpha: 0.1),
          highlightColor: Colors.green.withValues(alpha: 0.05),
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: isSelected
                  ? Colors.green.withValues(alpha: 0.1)
                  : Colors.transparent,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0),
              child: Row(
                children: [
                  const SizedBox(width: 8),
                  Icon(
                    icon,
                    size: 24,
                    color: iconColor,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: textColor,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                  if (isSelected)
                    Container(
                      width: 4,
                      height: 24,
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(4),
                      ),
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