import 'package:flutter/material.dart';

// Константы стилей меню в едином стиле проекта (на базе модуля Склад/Кэшфлоу)
const double _menuWidth = 200;
const double _menuBorderRadius = 20;
const double _menuItemBorderRadius = 14;
const double _menuBorderWidth = 0.5;
const double _menuShadowBlur = 8;
const double _menuShadowOffsetY = 4;
const double _menuShadowOpacity = 0.25;

const Color _darkMenuColor = Color(0xFF2D2D2D);
const Color _lightMenuColor = Color(0xFFF5F5F5);
const Color _darkBorderColor = Color(0xFF404040);
const Color _lightBorderColor = Color(0xFFE0E0E0);
const Color _darkHoverColor = Color(0xFF3E6FC7);
const Color _lightHoverColor = Color(0xFF007AFF);
const Color _darkDestructiveTextColor = Color(0xFF999999);
const Color _lightDestructiveTextColor = Color(0xFF666666);

BoxShadow _getMenuShadow() => BoxShadow(
  color: Colors.black.withValues(alpha: _menuShadowOpacity),
  blurRadius: _menuShadowBlur,
  offset: const Offset(0, _menuShadowOffsetY),
);

/// Элемент данных для контекстного меню.
class GTContextMenuItem {
  /// Иконка элемента.
  final IconData icon;

  /// Текст элемента.
  final String label;

  /// Действие при нажатии.
  final VoidCallback onTap;

  /// Является ли действие деструктивным (удаление и т.д.).
  final bool isDestructive;

  /// Доступен ли элемент для нажатия.
  final bool enabled;

  /// Создаёт описание элемента меню.
  const GTContextMenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isDestructive = false,
    this.enabled = true,
  });
}

/// Универсальное контекстное меню в едином стиле проекта.
class GTContextMenu extends StatelessWidget {
  /// Позиция нажатия.
  final Offset tapPosition;

  /// Список элементов меню.
  final List<dynamic> items; // Может содержать GTContextMenuItem или Divider

  /// Обратный вызов при закрытии меню.
  final VoidCallback onDismiss;

  /// Ширина меню (по умолчанию 200).
  final double width;

  /// Создаёт универсальное контекстное меню.
  ///
  /// - [tapPosition] — координаты нажатия для позиционирования меню.
  /// - [items] — список элементов (может содержать [GTContextMenuItem] или [Divider]).
  /// - [onDismiss] — колбэк, вызываемый при закрытии меню (нажатие вне области или выбор пункта).
  /// - [width] — фиксированная ширина меню.
  const GTContextMenu({
    super.key,
    required this.tapPosition,
    required this.items,
    required this.onDismiss,
    this.width = _menuWidth,
  });

  /// Показывает контекстное меню.
  static void show({
    required BuildContext context,
    required Offset tapPosition,
    required List<dynamic> items,
    required VoidCallback onDismiss,
    double? width,
  }) {
    final overlay = Overlay.of(context);
    final screenSize = MediaQuery.of(context).size;
    final effectiveWidth = width ?? _menuWidth;

    // Примерная высота меню для расчета выхода за границы экрана
    final menuHeight = items.length * 40.0;
    final adjustedPosition = Offset(
      tapPosition.dx + effectiveWidth > screenSize.width
          ? screenSize.width - effectiveWidth - 16
          : tapPosition.dx,
      tapPosition.dy + menuHeight > screenSize.height
          ? screenSize.height - menuHeight - 16
          : tapPosition.dy,
    );

    late OverlayEntry overlayEntry;
    overlayEntry = OverlayEntry(
      builder: (context) => GTContextMenu(
        tapPosition: adjustedPosition,
        items: items,
        onDismiss: () {
          overlayEntry.remove();
          onDismiss();
        },
        width: effectiveWidth,
      ),
    );
    overlay.insert(overlayEntry);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final menuColor = isDark ? _darkMenuColor : _lightMenuColor;
    final borderColor = isDark ? _darkBorderColor : _lightBorderColor;

    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            onTap: onDismiss,
            behavior: HitTestBehavior.opaque,
            child: Container(color: Colors.transparent),
          ),
        ),
        Positioned(
          left: tapPosition.dx,
          top: tapPosition.dy,
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: width,
              decoration: BoxDecoration(
                color: menuColor,
                borderRadius: BorderRadius.circular(_menuBorderRadius),
                border: Border.all(color: borderColor, width: _menuBorderWidth),
                boxShadow: [_getMenuShadow()],
              ),
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: items.map<Widget>((item) {
                  if (item is Divider) return item;
                  if (item is GTContextMenuItem) {
                    return _GTContextMenuItemWidget(
                      item: item,
                      onDismiss: onDismiss,
                    );
                  }
                  return const SizedBox.shrink();
                }).toList(),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _GTContextMenuItemWidget extends StatefulWidget {
  final GTContextMenuItem item;
  final VoidCallback onDismiss;

  const _GTContextMenuItemWidget({required this.item, required this.onDismiss});

  @override
  State<_GTContextMenuItemWidget> createState() =>
      _GTContextMenuItemWidgetState();
}

class _GTContextMenuItemWidgetState extends State<_GTContextMenuItemWidget> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final textColor = widget.item.isDestructive
        ? (isDark ? _darkDestructiveTextColor : _lightDestructiveTextColor)
        : (isDark ? Colors.white : Colors.black87);

    final hoverColor = isDark ? _darkHoverColor : _lightHoverColor;

    return MouseRegion(
      cursor: widget.item.enabled
          ? SystemMouseCursors.click
          : SystemMouseCursors.basic,
      onEnter: (_) {
        if (widget.item.enabled) setState(() => _isHovered = true);
      },
      onExit: (_) {
        if (widget.item.enabled) setState(() => _isHovered = false);
      },
      child: GestureDetector(
        onTap: widget.item.enabled
            ? () {
                widget.onDismiss();
                widget.item.onTap();
              }
            : null,
        behavior: HitTestBehavior.opaque,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Opacity(
            opacity: widget.item.enabled ? 1.0 : 0.4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: _isHovered ? hoverColor : Colors.transparent,
                borderRadius: BorderRadius.circular(_menuItemBorderRadius),
              ),
              child: Row(
                children: [
                  Icon(
                    widget.item.icon,
                    size: 16,
                    color: _isHovered ? Colors.white : textColor,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      widget.item.label,
                      style: TextStyle(
                        fontSize: 13,
                        color: _isHovered ? Colors.white : textColor,
                        fontWeight: FontWeight.w500,
                      ),
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
