import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

/// Группа элементов меню в стиле Apple Settings.
///
/// Объединяет несколько [AppleMenuItem] в одну карточку с закругленными углами.
class AppleMenuGroup extends StatelessWidget {
  /// Список элементов меню внутри группы.
  final List<Widget> children;

  /// Создаёт группу элементов меню.
  const AppleMenuGroup({
    required this.children,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Column(
          children: _buildChildrenWithDividers(context),
        ),
      ),
    );
  }

  /// Добавляет разделители между элементами списка.
  List<Widget> _buildChildrenWithDividers(BuildContext context) {
    final theme = Theme.of(context);
    final List<Widget> widgets = [];

    for (int i = 0; i < children.length; i++) {
      widgets.add(children[i]);
      if (i < children.length - 1) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(left: 56, right: 16),
            child: Divider(
              height: 1,
              thickness: 1,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.05),
            ),
          ),
        );
      }
    }

    return widgets;
  }
}

/// Элемент меню в стиле Apple Settings.
///
/// Отображает иконку, заголовок, опциональный подзаголовок и стрелку вправо.
class AppleMenuItem extends StatelessWidget {
  /// Иконка элемента.
  final IconData icon;

  /// Цвет иконки.
  final Color iconColor;

  /// Основной текст элемента.
  final String title;

  /// Дополнительный текст под заголовком (опционально).
  final String? subtitle;

  /// Максимальное количество строк для подзаголовка.
  /// Если null, то без ограничений.
  final int? subtitleMaxLines;

  /// Виджет справа (опционально, вместо стрелки).
  final Widget? trailing;

  /// Показывать ли стрелку вправо.
  final bool showChevron;

  /// Коллбэк при нажатии.
  final VoidCallback? onTap;

  /// Создаёт элемент меню в стиле Apple.
  const AppleMenuItem({
    required this.icon,
    required this.iconColor,
    required this.title,
    this.subtitle,
    this.subtitleMaxLines,
    this.trailing,
    this.showChevron = true,
    this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final content = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // Иконка без фона
          Icon(
            icon,
            color: iconColor,
            size: 24,
          ),
          const SizedBox(width: 12),
          // Текст
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w400,
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                    maxLines: subtitleMaxLines,
                    overflow:
                        subtitleMaxLines != null ? TextOverflow.ellipsis : null,
                  ),
              ],
            ),
          ),
          // Trailing виджет или стрелка
          if (trailing != null)
            trailing!
          else if (showChevron)
            Icon(
              CupertinoIcons.chevron_right,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
              size: 20,
            ),
        ],
      ),
    );

    if (onTap != null) {
      return IOSTapEffect(
        onTap: onTap!,
        child: content,
      );
    }

    return content;
  }
}

/// Виджет для создания iOS-подобного эффекта затемнения при нажатии.
///
/// При нажатии элемент затемняется серым фоном, как в iOS Settings.
class IOSTapEffect extends StatefulWidget {
  /// Дочерний виджет.
  final Widget child;

  /// Коллбэк при нажатии.
  final VoidCallback onTap;

  /// Создаёт виджет с iOS-подобным эффектом нажатия.
  const IOSTapEffect({
    required this.child,
    required this.onTap,
    super.key,
  });

  @override
  State<IOSTapEffect> createState() => _IOSTapEffectState();
}

/// Состояние для [IOSTapEffect].
class _IOSTapEffectState extends State<IOSTapEffect> {
  /// Флаг нажатия.
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        color: _isPressed
            ? theme.colorScheme.onSurface.withValues(alpha: 0.08)
            : Colors.transparent,
        child: widget.child,
      ),
    );
  }
}
