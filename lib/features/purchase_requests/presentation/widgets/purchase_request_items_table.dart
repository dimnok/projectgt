import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:projectgt/core/utils/formatters.dart';
import 'package:projectgt/features/purchase_requests/domain/entities/purchase_request_item.dart';
import 'package:projectgt/features/purchase_requests/presentation/widgets/purchase_request_details_tokens.dart';

/// Таблица позиций заявки: №, наименование, кол-во, ед. изм., артикул.
///
/// На широком экране колонки «Наименование» и «Артикул» делят свободное
/// место; если ширины не хватает — таблица прокручивается по горизонтали.
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

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 600) {
          return _ItemsMobileList(
            items: items,
            canEdit: canEdit,
            onDelete: onDelete,
          );
        }
        return _ItemsDesktopTable(
          theme: theme,
          items: items,
          canEdit: canEdit,
          onDelete: onDelete,
        );
      },
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
    int maxLines = 1,
  }) {
    return Text(
      value,
      textAlign: align,
      maxLines: maxLines,
      overflow: TextOverflow.ellipsis,
      style: theme.textTheme.bodyMedium?.copyWith(
        fontWeight: emphasized ? FontWeight.w700 : FontWeight.w500,
        height: maxLines > 1 ? 1.35 : null,
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

class _ItemsDesktopTable extends StatelessWidget {
  const _ItemsDesktopTable({
    required this.theme,
    required this.items,
    required this.canEdit,
    this.onDelete,
  });

  final ThemeData theme;
  final List<PurchaseRequestItem> items;
  final bool canEdit;
  final ValueChanged<String>? onDelete;

  @override
  Widget build(BuildContext context) {
    final borderColor = PurchaseRequestDetailsTokens.borderColor(theme);
    final headerBg = PurchaseRequestDetailsTokens.tableHeaderBackground(theme);
    final zebraBg = PurchaseRequestDetailsTokens.tableZebraBackground(theme);

    final table = DecoratedBox(
      decoration: PurchaseRequestDetailsTokens.cardDecoration(theme),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(
          PurchaseRequestDetailsTokens.cardRadius,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ColoredBox(
              color: headerBg,
              child: _ItemsTableRow(
                showActions: canEdit,
                index: PurchaseRequestItemsTable._headerCell(theme, '№'),
                name: PurchaseRequestItemsTable._headerCell(
                  theme,
                  'Наименование',
                ),
                qty: PurchaseRequestItemsTable._headerCell(
                  theme,
                  'Кол-во',
                  align: TextAlign.end,
                ),
                unit: PurchaseRequestItemsTable._headerCell(theme, 'Ед.'),
                article: PurchaseRequestItemsTable._headerCell(
                  theme,
                  'Артикул',
                ),
                action: const SizedBox.shrink(),
                dividerColor: borderColor,
                isHeader: true,
              ),
            ),
            for (var i = 0; i < items.length; i++)
              ColoredBox(
                color: i.isOdd ? zebraBg : Colors.transparent,
                child: _ItemsTableRow(
                  showActions: canEdit,
                  index: PurchaseRequestItemsTable._indexCell(theme, i + 1),
                  name: PurchaseRequestItemsTable._nameCell(
                    theme,
                    items[i].name,
                  ),
                  qty: PurchaseRequestItemsTable._valueCell(
                    theme,
                    formatQuantity(items[i].quantity),
                    align: TextAlign.end,
                    emphasized: true,
                  ),
                  unit: PurchaseRequestItemsTable._valueCell(
                    theme,
                    items[i].unit,
                  ),
                  article: PurchaseRequestItemsTable._valueCell(
                    theme,
                    PurchaseRequestItemsTable._articleLabel(items[i].article),
                    maxLines: 2,
                    muted:
                        PurchaseRequestItemsTable._articleLabel(
                          items[i].article,
                        ) ==
                        '—',
                  ),
                  action: canEdit
                      ? IconButton(
                          tooltip: 'Удалить позицию',
                          icon: Icon(
                            Icons.delete_outline_rounded,
                            size: 18,
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.35,
                            ),
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

    return LayoutBuilder(
      builder: (context, constraints) {
        final tableWidth = math.max(
          constraints.maxWidth,
          _ItemsTableRow.minTableWidth(showActions: canEdit),
        );
        final sized = SizedBox(width: tableWidth, child: table);
        if (tableWidth <= constraints.maxWidth) return sized;
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: sized,
        );
      },
    );
  }
}

/// Карточки позиций на узком экране: название целиком, кол-во и артикул ниже.
class _ItemsMobileList extends StatelessWidget {
  const _ItemsMobileList({
    required this.items,
    required this.canEdit,
    this.onDelete,
  });

  final List<PurchaseRequestItem> items;
  final bool canEdit;
  final ValueChanged<String>? onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = PurchaseRequestDetailsTokens.mutedText(theme);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < items.length; i++) ...[
          DecoratedBox(
            decoration: PurchaseRequestDetailsTokens.cardDecoration(theme),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          items[i].name,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${formatQuantity(items[i].quantity)} ${items[i].unit}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (PurchaseRequestItemsTable._articleLabel(
                              items[i].article,
                            ) !=
                            '—') ...[
                          const SizedBox(height: 4),
                          Text(
                            PurchaseRequestItemsTable._articleLabel(
                              items[i].article,
                            ),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: muted,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (canEdit)
                    IconButton(
                      tooltip: 'Удалить позицию',
                      icon: Icon(
                        Icons.delete_outline_rounded,
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.45,
                        ),
                      ),
                      onPressed: onDelete == null
                          ? null
                          : () => onDelete!(items[i].id),
                    ),
                ],
              ),
            ),
          ),
          if (i < items.length - 1) const SizedBox(height: 8),
        ],
      ],
    );
  }
}

class _ItemsTableRow extends StatelessWidget {
  const _ItemsTableRow({
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

  static const double _hPad = 16;
  static const double _gap = 12;
  static const double _indexWidth = 28;
  static const double _qtyWidth = 72;
  static const double _unitWidth = 48;
  static const double _actionGap = 4;
  static const double _actionWidth = 36;
  static const double _nameMinWidth = 180;
  static const double _articleMinWidth = 180;

  /// Минимальная ширина строки, при которой все колонки читаются без сжатия.
  static double minTableWidth({required bool showActions}) {
    return (_hPad * 2) +
        _indexWidth +
        _gap +
        _nameMinWidth +
        _gap +
        _qtyWidth +
        _gap +
        _unitWidth +
        _gap +
        _articleMinWidth +
        (showActions ? _actionGap + _actionWidth : 0);
  }

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
          horizontal: _hPad,
          vertical: isHeader ? 11 : 13,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(width: _indexWidth, child: index),
            const SizedBox(width: _gap),
            Expanded(flex: 3, child: name),
            const SizedBox(width: _gap),
            SizedBox(width: _qtyWidth, child: qty),
            const SizedBox(width: _gap),
            SizedBox(width: _unitWidth, child: unit),
            const SizedBox(width: _gap),
            Expanded(flex: 2, child: article),
            if (showActions) ...[
              const SizedBox(width: _actionGap),
              SizedBox(width: _actionWidth, child: action),
            ],
          ],
        ),
      ),
    );
  }
}
