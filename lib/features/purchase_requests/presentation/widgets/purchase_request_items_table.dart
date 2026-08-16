import 'package:flutter/material.dart';
import 'package:projectgt/core/utils/formatters.dart';
import 'package:projectgt/features/purchase_requests/domain/entities/purchase_request_item.dart';

/// Таблица позиций заявки в стиле реестра: №, наименование, кол-во, ед. изм., артикул.
class PurchaseRequestItemsTable extends StatelessWidget {
  /// Создаёт таблицу позиций.
  const PurchaseRequestItemsTable({
    super.key,
    required this.items,
    required this.canEdit,
    this.onDelete,
  });

  /// Позиции заявки.
  final List<PurchaseRequestItem> items;

  /// Можно удалять позиции.
  final bool canEdit;

  /// Удаление позиции по id.
  final ValueChanged<String>? onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final borderColor = theme.colorScheme.outline.withValues(alpha: 0.12);
    final headerBg = theme.colorScheme.onSurface.withValues(alpha: 0.03);
    final dividerColor = theme.colorScheme.outline.withValues(alpha: 0.08);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ColoredBox(
              color: headerBg,
              child: _ItemsTableRow(
                theme: theme,
                showActions: canEdit,
                index: _headerCell(theme, '№'),
                name: _headerCell(theme, 'Наименование'),
                qty: _headerCell(theme, 'Кол-во', align: TextAlign.end),
                unit: _headerCell(theme, 'Ед. изм.'),
                article: _headerCell(theme, 'Артикул'),
                action: const SizedBox.shrink(),
                dividerColor: dividerColor,
                isHeader: true,
              ),
            ),
            for (var i = 0; i < items.length; i++)
              _ItemsTableRow(
                theme: theme,
                showActions: canEdit,
                index: _indexCell(theme, i + 1),
                name: _nameCell(theme, items[i].name),
                qty: _valueCell(
                  theme,
                  formatQuantity(items[i].quantity),
                  align: TextAlign.end,
                  emphasized: true,
                ),
                unit: _valueCell(theme, items[i].unit),
                article: _valueCell(
                  theme,
                  _articleLabel(items[i].article),
                  muted: _articleLabel(items[i].article) == '—',
                ),
                action: canEdit
                    ? IconButton(
                        tooltip: 'Удалить позицию',
                        icon: Icon(
                          Icons.delete_outline,
                          size: 18,
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.45),
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints.tightFor(
                          width: 36,
                          height: 36,
                        ),
                        onPressed: onDelete == null
                            ? null
                            : () => onDelete!(items[i].id),
                      )
                    : const SizedBox.shrink(),
                dividerColor: dividerColor,
                showBottomDivider: i < items.length - 1,
              ),
          ],
        ),
      ),
    );
  }

  static String _articleLabel(String? article) {
    final value = article?.trim();
    if (value == null || value.isEmpty) return '—';
    return value;
  }

  static Widget _headerCell(
    ThemeData theme,
    String text, {
    TextAlign align = TextAlign.start,
  }) {
    return Text(
      text.toUpperCase(),
      textAlign: align,
      style: theme.textTheme.labelSmall?.copyWith(
        color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
        fontWeight: FontWeight.w600,
        letterSpacing: 0.4,
      ),
    );
  }

  static Widget _indexCell(ThemeData theme, int index) {
    return Container(
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: theme.colorScheme.onSurface.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        '$index',
        style: theme.textTheme.labelMedium?.copyWith(
          fontWeight: FontWeight.w700,
          color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
        ),
      ),
    );
  }

  static Widget _nameCell(ThemeData theme, String name) {
    return Text(
      name,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: theme.textTheme.bodyMedium?.copyWith(
        fontWeight: FontWeight.w600,
        height: 1.3,
      ),
    );
  }

  static Widget _valueCell(
    ThemeData theme,
    String value, {
    TextAlign align = TextAlign.start,
    bool emphasized = false,
    bool muted = false,
  }) {
    return Text(
      value,
      textAlign: align,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: theme.textTheme.bodyMedium?.copyWith(
        fontWeight: emphasized ? FontWeight.w600 : FontWeight.w500,
        color: muted
            ? theme.colorScheme.onSurface.withValues(alpha: 0.4)
            : theme.colorScheme.onSurface.withValues(
                alpha: emphasized ? 1 : 0.82,
              ),
      ),
    );
  }
}

class _ItemsTableRow extends StatelessWidget {
  const _ItemsTableRow({
    required this.theme,
    required this.showActions,
    required this.index,
    required this.name,
    required this.qty,
    required this.unit,
    required this.article,
    required this.action,
    required this.dividerColor,
    this.isHeader = false,
    this.showBottomDivider = true,
  });

  final ThemeData theme;
  final bool showActions;
  final Widget index;
  final Widget name;
  final Widget qty;
  final Widget unit;
  final Widget article;
  final Widget action;
  final Color dividerColor;
  final bool isHeader;
  final bool showBottomDivider;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: showBottomDivider
            ? Border(bottom: BorderSide(color: dividerColor))
            : null,
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: 12,
          vertical: isHeader ? 10 : 12,
        ),
        child: Row(
          children: [
            SizedBox(width: 40, child: index),
            const SizedBox(width: 12),
            Expanded(flex: 5, child: name),
            const SizedBox(width: 12),
            SizedBox(width: 72, child: qty),
            const SizedBox(width: 12),
            SizedBox(width: 72, child: unit),
            const SizedBox(width: 12),
            SizedBox(width: 96, child: article),
            if (showActions) ...[
              const SizedBox(width: 8),
              SizedBox(width: 36, child: action),
            ],
          ],
        ),
      ),
    );
  }
}
