import 'package:flutter/material.dart';

/// Текстовая ссылка с подчёркиванием и лёгким масштабом при наведении (desktop).
///
/// Используется в панелях действий над таблицами и в навигации по разделам.
/// Цвет акцента задаётся автоматически по теме; при [danger] — [ColorScheme.error].
class GtTextActionLink extends StatefulWidget {
  /// Создаёт ссылку.
  const GtTextActionLink({
    super.key,
    required this.label,
    required this.onTap,
    this.danger = false,
    this.selected = false,
  });

  /// Отображаемый текст (как семантическая метка кнопки).
  final String label;

  /// Действие по нажатию.
  final VoidCallback onTap;

  /// Если `true`, цвет текста и подчёркивания — [ColorScheme.error].
  final bool danger;

  /// Выбранный пункт навигации: акцент [ColorScheme.primary], без подчёркивания, [FontWeight.w700].
  final bool selected;

  @override
  State<GtTextActionLink> createState() => _GtTextActionLinkState();
}

class _GtTextActionLinkState extends State<GtTextActionLink> {
  bool _hover = false;

  static Color _linkColor(ThemeData theme, bool danger, bool selected) {
    if (danger) {
      return theme.colorScheme.error;
    }
    if (selected) {
      return theme.colorScheme.primary;
    }
    return theme.brightness == Brightness.dark
        ? const Color(0xFF81D4FA)
        : const Color(0xFF039BE5);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _linkColor(theme, widget.danger, widget.selected);
    return Semantics(
      button: true,
      label: widget.label,
      child: MouseRegion(
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedScale(
            scale: _hover ? 1.06 : 1.0,
            duration: const Duration(milliseconds: 160),
            curve: Curves.easeOut,
            alignment: Alignment.center,
            child: Text(
              widget.label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: color,
                fontWeight:
                    widget.selected ? FontWeight.w700 : FontWeight.w500,
                decoration: widget.selected
                    ? TextDecoration.none
                    : TextDecoration.underline,
                decorationColor: color,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
