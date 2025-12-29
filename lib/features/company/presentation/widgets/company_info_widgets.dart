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
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.08),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Акцентная линия слева
              Container(
                width: 4,
                color: color.withValues(alpha: 0.7),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          if (icon != null) ...[
                            Icon(icon, size: 20, color: color),
                            const SizedBox(width: 10),
                          ],
                          Expanded(
                            child: Text(
                              title.toUpperCase(),
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.1,
                                color: color,
                              ),
                            ),
                          ),
                          if (action != null) action!,
                        ],
                      ),
                      const SizedBox(height: 16),
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
  final String value;

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
    this.value = '—',
    this.icon,
    this.canCopy = false,
    this.onAction,
    this.actionIcon,
    this.onEdit,
    this.onDelete,
    this.isLast = false,
  });

  void _copyToClipboard(BuildContext context) {
    Clipboard.setData(ClipboardData(text: value));
    AppSnackBar.show(
      context: context,
      message: 'Скопировано: $value',
      kind: AppSnackBarKind.info,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Icon(
                icon,
                size: 16,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
              ),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Flexible(
                      child: SelectableText(
                        value,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (canCopy && value != '—') ...[
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: () => _copyToClipboard(context),
                        icon: Icon(
                          Icons.copy_rounded,
                          size: 18,
                          color:
                              theme.colorScheme.primary.withValues(alpha: 0.6),
                        ),
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        tooltip: 'Копировать',
                      ),
                    ],
                    if (onAction != null &&
                        actionIcon != null &&
                        value != '—') ...[
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: onAction,
                        icon: Icon(
                          actionIcon,
                          size: 18,
                          color:
                              theme.colorScheme.primary.withValues(alpha: 0.8),
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
                          size: 18,
                          color:
                              theme.colorScheme.primary.withValues(alpha: 0.6),
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
                          size: 18,
                          color: theme.colorScheme.error.withValues(alpha: 0.6),
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
          ),
        ],
      ),
    );
  }
}
