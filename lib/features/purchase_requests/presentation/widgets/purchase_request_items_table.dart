import 'package:flutter/material.dart';
import 'package:projectgt/core/utils/formatters.dart';
import 'package:projectgt/features/purchase_requests/domain/entities/purchase_request_item.dart';
import 'package:projectgt/features/purchase_requests/presentation/widgets/purchase_request_details_tokens.dart';

/// Таблица позиций заявки: №, наименование, кол-во, ед. изм., артикул.
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
    final borderColor = PurchaseRequestDetailsTokens.borderColor(theme);
    final headerBg = PurchaseRequestDetailsTokens.tableHeaderBackground(theme);
    final zebraBg = PurchaseRequestDetailsTokens.tableZebraBackground(theme);

    return DecoratedBox(
      decoration: PurchaseRequestDetailsTokens.cardDecoration(theme),
      child: ClipRRect(
        borderRadius:
            BorderRadius.circular(PurchaseRequestDetailsTokens.cardRadius),
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
                unit: _headerCell(theme, 'Ед.'),
                article: _headerCell(theme, 'Артикул'),
                action: const SizedBox.shrink(),
                dividerColor: borderColor,
                isHeader: true,
              ),
            ),
            for (var i = 0; i < items.length; i++)
              ColoredBox(
                color: i.isOdd ? zebraBg : Colors.transparent,
                child: _ItemsTableRow(
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
                            Icons.delete_outline_rounded,
                            size: 18,
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.35),
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
                  dividerColor: borderColor,
                  showBottomDivider: i < items.length - 1,
                ),
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

  static Widget _headerCell(ThemeData theme, String text,
      {TextAlign align = TextAlign.start}) {
    return Text(
      text.toUpperCase(),
      textAlign: align,
      style: theme.textTheme.labelSmall?.copyWith(
        color: PurchaseRequestDetailsTokens.mutedText(theme),
        fontWeight: FontWeight.w700,
        letterSpacing: 0.8,
        fontSize: 10,
      ),
    );
  }

  static Widget _indexCell(ThemeData theme, int index) {
    return Text(
      '$index',
      textAlign: TextAlign.center,
      style: theme.textTheme.labelMedium?.copyWith(
        fontWeight: FontWeight.w600,
        color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
        fontFeatures: const [FontFeature.tabularFigures()],
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
        height: 1.35,
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
        fontWeight: emphasized ? FontWeight.w700 : FontWeight.w500,
        fontFeatures: const [FontFeature.tabularFigures()],
        color: muted
            ? theme.colorScheme.onSurface.withValues(alpha: 0.35)
            : theme.colorScheme.onSurface.withValues(
                alpha: emphasized ? 1 : 0.75,
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
          horizontal: 16,
          vertical: isHeader ? 11 : 13,
        ),
        child: Row(
          children: [
            SizedBox(width: 28, child: index),
            const SizedBox(width: 12),
            Expanded(flex: 5, child: name),
            const SizedBox(width: 12),
            SizedBox(width: 64, child: qty),
            const SizedBox(width: 12),
            SizedBox(width: 56, child: unit),
            const SizedBox(width: 12),
            SizedBox(width: 88, child: article),
            if (showActions) ...[
              const SizedBox(width: 4),
              SizedBox(width: 36, child: action),
            ],
          ],
        ),
      ),
    );
  }
}
