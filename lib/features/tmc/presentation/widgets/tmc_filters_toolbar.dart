import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:projectgt/core/widgets/gt_buttons.dart';
import 'package:projectgt/features/tmc/domain/entities/tmc_category.dart';
import 'package:projectgt/features/tmc/domain/entities/tmc_enums.dart';
import 'package:projectgt/features/tmc/presentation/utils/tmc_ui_labels.dart';

/// Геометрия панели фильтров ТМЦ.
abstract final class TmcToolbarMetrics {
  /// Высота элементов.
  static const double height = 34;

  /// Радиус капсул.
  static const double radius = 18;
}

Color _barBorder(ColorScheme scheme) =>
    scheme.outline.withValues(alpha: 0.38);

Color _barFill(ColorScheme scheme) =>
    scheme.surfaceContainerHighest.withValues(alpha: 0.45);

/// Панель фильтров и действий реестра ТМЦ.
class TmcFiltersToolbar extends StatelessWidget {
  /// Поиск.
  final String searchQuery;

  /// Колбэк поиска.
  final ValueChanged<String> onSearchChanged;

  /// Категория.
  final String? categoryId;

  /// Колбэк категории.
  final ValueChanged<String?> onCategoryChanged;

  /// Тип учёта.
  final TmcAccountingType? accountingType;

  /// Колбэк типа учёта.
  final ValueChanged<TmcAccountingType?> onAccountingTypeChanged;

  /// Список категорий.
  final List<TmcCategory> categories;

  /// Обновить.
  final VoidCallback? onRefresh;

  /// Создать позицию.
  final VoidCallback? onCreate;

  /// Справочники.
  final VoidCallback? onCatalogs;

  /// Журнал операций.
  final VoidCallback? onOperations;

  /// Остатки по складам.
  final VoidCallback? onStock;

  /// Отчёты.
  final VoidCallback? onReports;

  /// Инвентаризация.
  final VoidCallback? onInventory;

  /// Уведомления.
  final VoidCallback? onNotifications;

  /// Создаёт панель.
  const TmcFiltersToolbar({
    super.key,
    required this.searchQuery,
    required this.onSearchChanged,
    required this.categoryId,
    required this.onCategoryChanged,
    required this.accountingType,
    required this.onAccountingTypeChanged,
    required this.categories,
    this.onRefresh,
    this.onCreate,
    this.onCatalogs,
    this.onOperations,
    this.onStock,
    this.onReports,
    this.onInventory,
    this.onNotifications,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        _SearchField(
          value: searchQuery,
          onChanged: onSearchChanged,
          scheme: scheme,
          theme: theme,
        ),
        _CategoryChip(
          categories: categories,
          categoryId: categoryId,
          onChanged: onCategoryChanged,
          scheme: scheme,
          theme: theme,
        ),
        _AccountingChip(
          value: accountingType,
          onChanged: onAccountingTypeChanged,
          scheme: scheme,
          theme: theme,
        ),
        if (onRefresh != null)
          _IconAction(
            tooltip: 'Обновить',
            icon: CupertinoIcons.arrow_clockwise,
            onTap: onRefresh!,
            scheme: scheme,
          ),
        if (onOperations != null)
          GTTextButton(
            text: TmcUiLabels.operationsJournal,
            onPressed: onOperations,
          ),
        if (onStock != null)
          GTTextButton(
            text: TmcUiLabels.stockBalances,
            onPressed: onStock,
          ),
        if (onReports != null)
          GTTextButton(
            text: TmcUiLabels.reports,
            onPressed: onReports,
          ),
        if (onInventory != null)
          GTTextButton(
            text: TmcUiLabels.inventory,
            onPressed: onInventory,
          ),
        if (onNotifications != null)
          GTTextButton(
            text: 'Уведомления',
            onPressed: onNotifications,
          ),
        if (onCatalogs != null)
          GTTextButton(
            text: TmcUiLabels.catalogs,
            onPressed: onCatalogs,
          ),
        if (onCreate != null)
          GTPrimaryButton(
            text: TmcUiLabels.newItem,
            onPressed: onCreate,
          ),
      ],
    );
  }
}

class _SearchField extends StatefulWidget {
  final String value;
  final ValueChanged<String> onChanged;
  final ColorScheme scheme;
  final ThemeData theme;

  const _SearchField({
    required this.value,
    required this.onChanged,
    required this.scheme,
    required this.theme,
  });

  @override
  State<_SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends State<_SearchField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value);
  }

  @override
  void didUpdateWidget(covariant _SearchField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != _controller.text) {
      _controller.text = widget.value;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      height: TmcToolbarMetrics.height,
      child: TextField(
        controller: _controller,
        onChanged: widget.onChanged,
        style: widget.theme.textTheme.bodySmall,
        decoration: InputDecoration(
          hintText: 'Поиск…',
          prefixIcon: Icon(
            CupertinoIcons.search,
            size: 16,
            color: widget.scheme.onSurface.withValues(alpha: 0.45),
          ),
          isDense: true,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          filled: true,
          fillColor: _barFill(widget.scheme),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(TmcToolbarMetrics.radius),
            borderSide: BorderSide(color: _barBorder(widget.scheme)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(TmcToolbarMetrics.radius),
            borderSide: BorderSide(color: _barBorder(widget.scheme)),
          ),
        ),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final List<TmcCategory> categories;
  final String? categoryId;
  final ValueChanged<String?> onChanged;
  final ColorScheme scheme;
  final ThemeData theme;

  const _CategoryChip({
    required this.categories,
    required this.categoryId,
    required this.onChanged,
    required this.scheme,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    TmcCategory? selected;
    for (final c in categories) {
      if (c.id == categoryId) selected = c;
    }

    return PopupMenuButton<String?>(
      tooltip: 'Категория',
      onSelected: onChanged,
      itemBuilder: (context) => [
        const PopupMenuItem<String?>(
          value: null,
          child: Text('Все категории'),
        ),
        ...categories.map(
          (c) => PopupMenuItem<String?>(
            value: c.id,
            child: Text(c.name),
          ),
        ),
      ],
      child: Container(
        height: TmcToolbarMetrics.height,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: _barFill(scheme),
          borderRadius: BorderRadius.circular(TmcToolbarMetrics.radius),
          border: Border.all(color: _barBorder(scheme)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              selected?.name ?? 'Категория',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(width: 4),
            Icon(
              CupertinoIcons.chevron_down,
              size: 14,
              color: scheme.onSurface.withValues(alpha: 0.5),
            ),
          ],
        ),
      ),
    );
  }
}

class _AccountingChip extends StatelessWidget {
  final TmcAccountingType? value;
  final ValueChanged<TmcAccountingType?> onChanged;
  final ColorScheme scheme;
  final ThemeData theme;

  const _AccountingChip({
    required this.value,
    required this.onChanged,
    required this.scheme,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<TmcAccountingType?>(
      tooltip: 'Тип учёта',
      onSelected: onChanged,
      itemBuilder: (context) => [
        const PopupMenuItem<TmcAccountingType?>(
          value: null,
          child: Text('Все типы учёта'),
        ),
        ...TmcAccountingType.values.map(
          (t) => PopupMenuItem<TmcAccountingType?>(
            value: t,
            child: Text(TmcUiLabels.accountingType(t)),
          ),
        ),
      ],
      child: Container(
        height: TmcToolbarMetrics.height,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: _barFill(scheme),
          borderRadius: BorderRadius.circular(TmcToolbarMetrics.radius),
          border: Border.all(color: _barBorder(scheme)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value != null
                  ? TmcUiLabels.accountingType(value!)
                  : 'Тип учёта',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(width: 4),
            Icon(
              CupertinoIcons.chevron_down,
              size: 14,
              color: scheme.onSurface.withValues(alpha: 0.5),
            ),
          ],
        ),
      ),
    );
  }
}

class _IconAction extends StatelessWidget {
  final String tooltip;
  final IconData icon;
  final VoidCallback onTap;
  final ColorScheme scheme;

  const _IconAction({
    required this.tooltip,
    required this.icon,
    required this.onTap,
    required this.scheme,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(TmcToolbarMetrics.radius),
        child: Container(
          width: TmcToolbarMetrics.height,
          height: TmcToolbarMetrics.height,
          decoration: BoxDecoration(
            color: _barFill(scheme),
            borderRadius: BorderRadius.circular(TmcToolbarMetrics.radius),
            border: Border.all(color: _barBorder(scheme)),
          ),
          child: Icon(icon, size: 16),
        ),
      ),
    );
  }
}
