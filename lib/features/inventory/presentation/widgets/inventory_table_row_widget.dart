import 'package:flutter/material.dart';
import 'package:projectgt/core/utils/formatters.dart';

// Константы стилей меню
const double _menuWidth = 200;
const double _menuBorderRadius = 22;
const double _menuItemBorderRadius = 16;
const double _menuBorderWidth = 0.5;
const double _menuShadowBlur = 8;
const double _menuShadowOffsetY = 4;
const double _menuShadowOpacity = 0.3;

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

/// Строит TableRow для таблицы ТМЦ.
TableRow buildInventoryTableRow({
  required Map<String, dynamic> item,
  required int index,
  required void Function(String itemId, String action) onAction,
  required Widget Function(BuildContext, ThemeData, String) buildStatusChip,
  required BuildContext context,
}) {
  final theme = Theme.of(context);

  return TableRow(
    decoration: BoxDecoration(
      color: theme.colorScheme.surface,
    ),
    children: [
      _buildCell(
        context: context,
        item: item,
        onAction: onAction,
        child: Text(
          '${index + 1}',
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        align: Alignment.center,
      ),
      _buildCell(
        context: context,
        item: item,
        onAction: onAction,
        child: Text(
          item['name'] ?? '',
          overflow: TextOverflow.ellipsis,
        ),
      ),
      _buildCell(
        context: context,
        item: item,
        onAction: onAction,
        child: Text(
          item['category'] ?? '',
          overflow: TextOverflow.ellipsis,
        ),
        align: Alignment.center,
      ),
      _buildCell(
        context: context,
        item: item,
        onAction: onAction,
        child: Text(
          item['unit'] ?? 'шт.',
          overflow: TextOverflow.ellipsis,
        ),
        align: Alignment.center,
      ),
      _buildCell(
        context: context,
        item: item,
        onAction: onAction,
        child: Text(
          item['quantity']?.toString() ?? '1',
          overflow: TextOverflow.ellipsis,
        ),
        align: Alignment.center,
      ),
      _buildCell(
        context: context,
        item: item,
        onAction: onAction,
        child: Text(
          item['serial_number'] ?? '—',
          style: theme.textTheme.bodyMedium?.copyWith(
            fontFamily: 'monospace',
            color: item['serial_number'] != null
                ? theme.colorScheme.onSurface
                : theme.colorScheme.onSurfaceVariant,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        align: Alignment.center,
      ),
      _buildCell(
        context: context,
        item: item,
        onAction: onAction,
        child: buildStatusChip(
          context,
          theme,
          item['status'] ?? 'working',
        ),
        align: Alignment.center,
      ),
      _buildCell(
        context: context,
        item: item,
        onAction: onAction,
        child: Text(
          item['purchase_date'] != null
              ? formatRuDate(item['purchase_date'] as DateTime)
              : '—',
          overflow: TextOverflow.ellipsis,
        ),
        align: Alignment.center,
      ),
      _buildCell(
        context: context,
        item: item,
        onAction: onAction,
        child: Text(
          item['location'] ?? 'Склад',
          overflow: TextOverflow.ellipsis,
        ),
        align: Alignment.center,
      ),
    ],
  );
}

/// Строит ячейку таблицы с поддержкой клика на всю строку.
Widget _buildCell({
  required BuildContext context,
  required Map<String, dynamic> item,
  required void Function(String itemId, String action) onAction,
  required Widget child,
  Alignment align = Alignment.centerLeft,
}) {
  final theme = Theme.of(context);

  return GestureDetector(
    onTapDown: (TapDownDetails details) {
      final itemId = item['id'] as String? ?? '';
      _MaterialContextMenu.show(
        context: context,
        tapPosition: details.globalPosition,
        itemId: itemId,
        onAction: onAction,
      );
    },
    behavior: HitTestBehavior.opaque,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      alignment: align,
      width: double.infinity,
      child: DefaultTextStyle(
        style: theme.textTheme.bodyMedium!,
        child: child,
      ),
    ),
  );
}

/// Кастомное Material меню.
class _MaterialContextMenu extends StatelessWidget {
  final Offset tapPosition;
  final String itemId;
  final void Function(String itemId, String action) onAction;
  final VoidCallback onDismiss;

  const _MaterialContextMenu({
    required this.tapPosition,
    required this.itemId,
    required this.onAction,
    required this.onDismiss,
  });

  /// Показывает контекстное меню.
  static void show({
    required BuildContext context,
    required Offset tapPosition,
    required String itemId,
    required void Function(String itemId, String action) onAction,
  }) {
    final overlay = Overlay.of(context);
    final screenSize = MediaQuery.of(context).size;

    // Проверка на выход за экран и корректировка позиции
    final menuHeight = 120.0; // Примерная высота меню
    final adjustedPosition = Offset(
      tapPosition.dx + _menuWidth > screenSize.width
          ? screenSize.width - _menuWidth - 8
          : tapPosition.dx,
      tapPosition.dy + menuHeight > screenSize.height
          ? screenSize.height - menuHeight - 8
          : tapPosition.dy,
    );

    late OverlayEntry overlayEntry;
    overlayEntry = OverlayEntry(
      builder: (context) => _MaterialContextMenu(
        tapPosition: adjustedPosition,
        itemId: itemId,
        onAction: onAction,
        onDismiss: () => overlayEntry.remove(),
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
        // Прозрачный фон для закрытия меню по клику
        Positioned.fill(
          child: GestureDetector(
            onTap: onDismiss,
            child: Container(color: Colors.transparent),
          ),
        ),
        // Меню
        Positioned(
          left: tapPosition.dx,
          top: tapPosition.dy,
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: _menuWidth,
              decoration: BoxDecoration(
                color: menuColor,
                borderRadius: BorderRadius.circular(_menuBorderRadius),
                border: Border.all(
                  color: borderColor,
                  width: _menuBorderWidth,
                ),
                boxShadow: [_getMenuShadow()],
              ),
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _MenuItem(
                    icon: Icons.visibility_outlined,
                    label: 'Просмотр',
                    onTap: () {
                      onDismiss();
                      onAction(itemId, 'view');
                    },
                  ),
                  Container(
                    height: 0.5,
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    color: borderColor,
                  ),
                  _MenuItem(
                    icon: Icons.edit_outlined,
                    label: 'Редактировать',
                    onTap: () {
                      onDismiss();
                      onAction(itemId, 'edit');
                    },
                  ),
                  Container(
                    height: 0.5,
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    color: borderColor,
                  ),
                  _MenuItem(
                    icon: Icons.delete_outline,
                    label: 'Удалить',
                    isDestructive: true,
                    onTap: () {
                      onDismiss();
                      onAction(itemId, 'delete');
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Элемент меню в стиле Material.
class _MenuItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool isDestructive;
  final VoidCallback onTap;

  const _MenuItem({
    required this.icon,
    required this.label,
    this.isDestructive = false,
    required this.onTap,
  });

  @override
  State<_MenuItem> createState() => _MenuItemState();
}

class _MenuItemState extends State<_MenuItem> {
  bool _isHovered = false;

  Color _getTextColor(BuildContext context, bool isDestructive) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (isDestructive) {
      return isDark ? _darkDestructiveTextColor : _lightDestructiveTextColor;
    }
    return isDark ? Colors.white : Colors.black;
  }

  Color _getHoverColor(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return isDark ? _darkHoverColor : _lightHoverColor;
  }

  @override
  Widget build(BuildContext context) {
    final textColor = _getTextColor(context, widget.isDestructive);
    final hoverColor = _getHoverColor(context);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 6),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _isHovered ? hoverColor : Colors.transparent,
              borderRadius: BorderRadius.circular(_menuItemBorderRadius),
            ),
            child: Row(
              children: [
                Icon(
                  widget.icon,
                  size: 18,
                  color: _isHovered ? Colors.white : textColor,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    widget.label,
                    style: TextStyle(
                      fontSize: 14,
                      color: _isHovered ? Colors.white : textColor,
                      fontWeight: FontWeight.w400,
                    ),
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
