import 'package:flutter/material.dart';

/// Строка текстовых действий над таблицей сотрудников: выравнивание вправо,
/// подчёркнутые ссылки с лёгким увеличением при наведении (desktop).
///
/// Бизнес-логику задаёт родитель: [onAddEmployee], [onExport], [onDeleteSelected].
/// Ссылка «Удалить» показывается только если [onDeleteSelected] не `null`
/// (родитель обычно передаёт колбэк при выбранных строках и праве на удаление).
class EmployeesTableActionsBar extends StatelessWidget {
  /// Создаёт панель действий над таблицей.
  const EmployeesTableActionsBar({
    super.key,
    required this.canCreate,
    required this.canExport,
    this.onAddEmployee,
    this.onExport,
    this.onDeleteSelected,
  });

  /// Показывать ссылку «Добавить сотрудника».
  final bool canCreate;

  /// Показывать ссылку «Экспорт».
  final bool canExport;

  /// Вызывается при нажатии «Добавить сотрудника» (если [canCreate]).
  final VoidCallback? onAddEmployee;

  /// Вызывается при нажатии «Экспорт» (если [canExport]).
  final VoidCallback? onExport;

  /// Удаление выбранных строк; если `null`, ссылка «Удалить» скрыта.
  final VoidCallback? onDeleteSelected;

  @override
  Widget build(BuildContext context) {
    final showDelete = onDeleteSelected != null;
    if (!canCreate && !canExport && !showDelete) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Align(
        alignment: Alignment.centerRight,
        child: Wrap(
          alignment: WrapAlignment.end,
          spacing: 20,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            if (canCreate && onAddEmployee != null)
              _EmployeesTableActionLink(
                label: 'Добавить сотрудника',
                onTap: onAddEmployee!,
              ),
            if (canExport && onExport != null)
              _EmployeesTableActionLink(
                label: 'Экспорт',
                onTap: onExport!,
              ),
            if (showDelete)
              _EmployeesTableActionLink(
                label: 'Удалить',
                onTap: onDeleteSelected!,
                danger: true,
              ),
          ],
        ),
      ),
    );
  }
}

/// Одна текстовая ссылка: акцентный или опасный цвет, hover-scale.
class _EmployeesTableActionLink extends StatefulWidget {
  const _EmployeesTableActionLink({
    required this.label,
    required this.onTap,
    this.danger = false,
  });

  final String label;
  final VoidCallback onTap;

  /// Если `true`, цвет ссылки — [ColorScheme.error] (действие удаления).
  final bool danger;

  @override
  State<_EmployeesTableActionLink> createState() =>
      _EmployeesTableActionLinkState();
}

class _EmployeesTableActionLinkState extends State<_EmployeesTableActionLink> {
  bool _hover = false;

  static Color _linkColor(ThemeData theme, bool danger) {
    if (danger) {
      return theme.colorScheme.error;
    }
    return theme.brightness == Brightness.dark
        ? const Color(0xFF81D4FA)
        : const Color(0xFF039BE5);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _linkColor(theme, widget.danger);
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
                decoration: TextDecoration.underline,
                decorationColor: color,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
