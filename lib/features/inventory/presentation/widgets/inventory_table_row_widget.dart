import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:projectgt/core/utils/formatters.dart';
import 'package:projectgt/core/widgets/gt_context_menu.dart';
import 'package:projectgt/features/roles/application/permission_service.dart';

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

Widget _buildCell({
  required BuildContext context,
  required Map<String, dynamic> item,
  required void Function(String itemId, String action) onAction,
  required Widget child,
  Alignment align = Alignment.centerLeft,
}) {
  final theme = Theme.of(context);

  return Consumer(
    builder: (context, ref, _) {
      return GestureDetector(
        onTapDown: (TapDownDetails details) {
          final itemId = item['id'] as String? ?? '';
          final permissionService = ref.read(permissionServiceProvider);
          final canUpdate = permissionService.can('inventory', 'update');
          final canDelete = permissionService.can('inventory', 'delete');

          GTContextMenu.show(
            context: context,
            tapPosition: details.globalPosition,
            onDismiss: () {},
            items: [
              GTContextMenuItem(
                icon: Icons.visibility_outlined,
                label: 'Просмотр',
                onTap: () => onAction(itemId, 'view'),
              ),
              if (canUpdate) ...[
                const Divider(height: 4, indent: 8, endIndent: 8),
                GTContextMenuItem(
                  icon: Icons.edit_outlined,
                  label: 'Редактировать',
                  onTap: () => onAction(itemId, 'edit'),
                ),
              ],
              if (canDelete) ...[
                const Divider(height: 4, indent: 8, endIndent: 8),
                GTContextMenuItem(
                  icon: Icons.delete_outline,
                  label: 'Удалить',
                  isDestructive: true,
                  onTap: () => onAction(itemId, 'delete'),
                ),
              ],
            ],
          );
        },
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          alignment: align,
          width: double.infinity,
          child: DefaultTextStyle(
            style: theme.textTheme.bodyMedium!,
            child: child,
          ),
        ),
      );
    },
  );
}
