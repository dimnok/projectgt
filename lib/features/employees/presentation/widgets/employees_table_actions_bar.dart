import 'package:flutter/material.dart';

import 'package:projectgt/core/widgets/gt_text_action_link.dart';

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
              GtTextActionLink(
                label: 'Добавить сотрудника',
                onTap: onAddEmployee!,
              ),
            if (canExport && onExport != null)
              GtTextActionLink(
                label: 'Экспорт',
                onTap: onExport!,
              ),
            if (showDelete)
              GtTextActionLink(
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
