import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:projectgt/core/utils/formatters.dart';
import 'package:projectgt/core/widgets/gt_section_title.dart';
import 'package:projectgt/features/purchase_requests/domain/entities/purchase_request_list_item.dart';
import 'package:projectgt/features/purchase_requests/presentation/utils/purchase_request_module_utils.dart';
import 'package:projectgt/features/purchase_requests/presentation/widgets/purchase_request_status_badge.dart';

/// Таблица реестра заявок на закупку для десктопной раскладки.
class PurchaseRequestsTable extends StatelessWidget {
  /// Создаёт таблицу.
  const PurchaseRequestsTable({
    super.key,
    required this.items,
    required this.isLoading,
    required this.onRowTap,
  });

  /// Строки реестра.
  final List<PurchaseRequestListItem> items;

  /// Идёт загрузка.
  final bool isLoading;

  /// Открыть заявку по клику на строку.
  final ValueChanged<PurchaseRequestListItem> onRowTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: GTSectionTitle(title: 'Заявки (${items.length})'),
        ),
        _buildHeader(theme),
        Divider(
          height: 1,
          thickness: 1,
          color: theme.colorScheme.outline.withValues(alpha: 0.12),
        ),
        Expanded(child: _buildBody(theme)),
      ],
    );
  }

  Widget _buildBody(ThemeData theme) {
    if (items.isEmpty) {
      return isLoading
          ? const Center(child: CupertinoActivityIndicator())
          : Center(
              child: Text(
                'Нет заявок',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.hintColor,
                ),
              ),
            );
    }

    return Stack(
      children: [
        ListView.separated(
          itemCount: items.length,
          separatorBuilder: (_, __) => Divider(
            height: 1,
            thickness: 1,
            color: theme.colorScheme.outline.withValues(alpha: 0.08),
          ),
          itemBuilder: (context, index) {
            return _PurchaseRequestRow(
              item: items[index],
              onTap: () => onRowTap(items[index]),
            );
          },
        ),
        if (isLoading)
          const Align(
            alignment: Alignment.topCenter,
            child: Padding(
              padding: EdgeInsets.all(8),
              child: CupertinoActivityIndicator(),
            ),
          ),
      ],
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        children: [
          Expanded(flex: 2, child: _headerText('Номер', theme)),
          Expanded(flex: 2, child: _headerText('Объект', theme)),
          Expanded(flex: 2, child: _headerText('Инициатор', theme)),
          Expanded(flex: 2, child: _headerText('Дата', theme)),
          Expanded(flex: 2, child: _headerText('Сумма', theme)),
          Expanded(flex: 2, child: _headerText('Статус', theme)),
        ],
      ),
    );
  }

  Widget _headerText(String text, ThemeData theme) {
    return Text(
      text.toUpperCase(),
      style: theme.textTheme.labelSmall?.copyWith(
        color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      ),
    );
  }
}

class _PurchaseRequestRow extends StatelessWidget {
  const _PurchaseRequestRow({
    required this.item,
    required this.onTap,
  });

  final PurchaseRequestListItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        hoverColor: theme.colorScheme.onSurface.withValues(alpha: 0.04),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: Text(
                  item.number,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  item.objectName,
                  style: theme.textTheme.bodySmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  item.initiatorLabel,
                  style: theme.textTheme.bodySmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  formatRuDate(item.createdAt),
                  style: theme.textTheme.bodySmall,
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  formatPurchaseRequestAmount(item.totalAmount),
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: PurchaseRequestStatusBadge(status: item.status),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
