import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:projectgt/core/widgets/app_snackbar.dart';

/// Карточка с информацией о компании.
class CompanyInfoCard extends StatelessWidget {
  /// Заголовок карточки.
  final String title;

  /// Список строк с информацией.
  final List<Widget> children;

  /// Иконка заголовка.
  final IconData? icon;

  /// Цвет акцентной линии слева.
  final Color? accentColor;

  /// Дополнительный виджет в заголовке (например, кнопка).
  final Widget? action;

  /// Создаёт карточку с информацией о компании.
  const CompanyInfoCard({
    super.key,
    required this.title,
    required this.children,
    this.icon,
    this.accentColor,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = accentColor ?? theme.colorScheme.primary;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.all(Radius.circular(12)),
        border: Border.all(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.all(Radius.circular(12)),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Акцентная линия слева (теперь тоньше и строже)
              Container(width: 3, color: color),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          if (icon != null) ...[
                            Icon(icon, size: 18, color: color),
                            const SizedBox(width: 8),
                          ],
                          Expanded(
                            child: Text(
                              title.toUpperCase(),
                              style: theme.textTheme.labelSmall?.copyWith(
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.2,
                                color: color,
                                fontSize: 10,
                              ),
                            ),
                          ),
                          if (action != null) action!,
                        ],
                      ),
                      const SizedBox(height: 12),
                      ...children,
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Строка с данными внутри карточки.
class CompanyInfoRow extends StatelessWidget {
  /// Метка поля.
  final String label;

  /// Значение поля.
  final String? value;

  /// Иконка поля.
  final IconData? icon;

  /// Признак возможности копирования.
  final bool canCopy;

  /// Коллбэк для дополнительного действия (позвонить, сайт и т.д.).
  final VoidCallback? onAction;

  /// Иконка дополнительного действия.
  final IconData? actionIcon;

  /// Коллбэк для редактирования строки.
  final VoidCallback? onEdit;

  /// Коллбэк для удаления строки.
  final VoidCallback? onDelete;

  /// Признак последней строки в списке (убирает отступ).
  final bool isLast;

  /// Создаёт строку с данными.
  const CompanyInfoRow({
    super.key,
    required this.label,
    this.value,
    this.icon,
    this.canCopy = false,
    this.onAction,
    this.actionIcon,
    this.onEdit,
    this.onDelete,
    this.isLast = false,
  });

  void _copyToClipboard(BuildContext context) {
    if (value == null) return;
    Clipboard.setData(ClipboardData(text: value!));
    AppSnackBar.show(
      context: context,
      message: 'Скопировано: $value',
      kind: AppSnackBarKind.info,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final displayValue = (value == null || value!.isEmpty) ? '—' : value!;

    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Icon(
                icon,
                size: 14,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                    fontWeight: FontWeight.w600,
                    fontSize: 10,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: SelectableText(
                        displayValue,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (canCopy && displayValue != '—') ...[
                          IconButton(
                            onPressed: () => _copyToClipboard(context),
                            icon: Icon(
                              Icons.copy_rounded,
                              size: 14,
                              color: theme.colorScheme.onSurface.withValues(
                                alpha: 0.4,
                              ),
                            ),
                            visualDensity: VisualDensity.compact,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            tooltip: 'Копировать',
                          ),
                        ],
                        if (onAction != null &&
                            actionIcon != null &&
                            displayValue != '—') ...[
                          const SizedBox(width: 8),
                          IconButton(
                            onPressed: onAction,
                            icon: Icon(
                              actionIcon,
                              size: 16,
                              color: theme.colorScheme.primary,
                            ),
                            visualDensity: VisualDensity.compact,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                        if (onEdit != null) ...[
                          const SizedBox(width: 8),
                          IconButton(
                            onPressed: onEdit,
                            icon: Icon(
                              CupertinoIcons.pencil,
                              size: 16,
                              color: theme.colorScheme.primary.withValues(
                                alpha: 0.7,
                              ),
                            ),
                            visualDensity: VisualDensity.compact,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            tooltip: 'Редактировать',
                          ),
                        ],
                        if (onDelete != null) ...[
                          const SizedBox(width: 8),
                          IconButton(
                            onPressed: onDelete,
                            icon: Icon(
                              CupertinoIcons.trash,
                              size: 16,
                              color: theme.colorScheme.error.withValues(
                                alpha: 0.7,
                              ),
                            ),
                            visualDensity: VisualDensity.compact,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            tooltip: 'Удалить',
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
