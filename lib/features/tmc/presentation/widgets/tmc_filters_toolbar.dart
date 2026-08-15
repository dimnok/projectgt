import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:projectgt/core/widgets/gt_buttons.dart';
import 'package:projectgt/core/widgets/gt_text_field.dart';
import 'package:projectgt/features/tmc/domain/entities/tmc_category.dart';
import 'package:projectgt/features/tmc/domain/entities/tmc_enums.dart';
import 'package:projectgt/features/tmc/presentation/utils/tmc_ui_labels.dart';

/// Геометрия панели фильтров ТМЦ.
abstract final class TmcToolbarMetrics {
  /// Высота элементов управления.
  static const double height = 34;

  /// Радиус скругления кнопок и полей.
  static const double radius = 8;
}

/// Панель поиска, фильтров и создания позиции реестра ТМЦ.
class TmcFiltersToolbar extends StatelessWidget {
  /// Поисковый запрос.
  final String searchQuery;

  /// Колбэк изменения поиска.
  final ValueChanged<String> onSearchChanged;

  /// Выбранная категория.
  final String? categoryId;

  /// Колбэк изменения категории.
  final ValueChanged<String?> onCategoryChanged;

  /// Выбранный тип учёта.
  final TmcAccountingType? accountingType;

  /// Колбэк типа учёта.
  final ValueChanged<TmcAccountingType?> onAccountingTypeChanged;

  /// Список категорий.
  final List<TmcCategory> categories;

  /// Обновить данные.
  final VoidCallback? onRefresh;

  /// Создать новую позицию.
  final VoidCallback? onCreate;

  /// Сбросить все фильтры реестра одним действием.
  final VoidCallback? onClearFilters;

  /// Создаёт панель фильтров реестра.
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
    this.onClearFilters,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final hasActiveFilters =
        searchQuery.trim().isNotEmpty ||
        categoryId != null ||
        accountingType != null;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _SearchField(
                  value: searchQuery,
                  onChanged: onSearchChanged,
                  scheme: scheme,
                  theme: theme,
                  isDark: isDark,
                ),
                const SizedBox(width: 8),
                _CategoryFilterChip(
                  categories: categories,
                  categoryId: categoryId,
                  onChanged: onCategoryChanged,
                  scheme: scheme,
                  theme: theme,
                  isDark: isDark,
                ),
                const SizedBox(width: 8),
                _AccountingFilterChip(
                  value: accountingType,
                  onChanged: onAccountingTypeChanged,
                  scheme: scheme,
                  theme: theme,
                  isDark: isDark,
                ),
                if (hasActiveFilters && onClearFilters != null) ...[
                  const SizedBox(width: 6),
                  _ClearFiltersButton(
                    onTap: onClearFilters!,
                    scheme: scheme,
                    theme: theme,
                  ),
                ],
                if (onRefresh != null) ...[
                  const SizedBox(width: 6),
                  _IconAction(
                    tooltip: 'Обновить список',
                    icon: CupertinoIcons.arrow_clockwise,
                    onTap: onRefresh!,
                    scheme: scheme,
                    isDark: isDark,
                  ),
                ],
              ],
            ),
          ),
        ),
        if (onCreate != null) ...[
          const SizedBox(width: 12),
          GTPrimaryButton(
            text: TmcUiLabels.newItem,
            icon: CupertinoIcons.plus,
            onPressed: onCreate,
          ),
        ],
      ],
    );
  }
}

/// Поле поиска с иконкой и кнопкой быстрой очистки.
class _SearchField extends StatefulWidget {
  final String value;
  final ValueChanged<String> onChanged;
  final ColorScheme scheme;
  final ThemeData theme;
  final bool isDark;

  const _SearchField({
    required this.value,
    required this.onChanged,
    required this.scheme,
    required this.theme,
    required this.isDark,
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
      width: 260,
      height: TmcToolbarMetrics.height,
      child: GTTextField(
        controller: _controller,
        onChanged: widget.onChanged,
        hintText: TmcUiLabels.searchHint,
        prefixIcon: CupertinoIcons.search,
        prefixIconSize: 14,
        prefixIconConstraints: const BoxConstraints(
          minWidth: 30,
          minHeight: 30,
        ),
        suffixIcon: _controller.text.isNotEmpty
            ? GestureDetector(
                onTap: () {
                  _controller.clear();
                  widget.onChanged('');
                },
                child: Icon(
                  CupertinoIcons.clear_circled_solid,
                  size: 14,
                  color: widget.scheme.onSurface.withValues(alpha: 0.4),
                ),
              )
            : null,
        suffixIconConstraints: const BoxConstraints(
          minWidth: 28,
          minHeight: 28,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        borderRadius: TmcToolbarMetrics.radius,
        style: widget.theme.textTheme.bodySmall,
        fillColor: widget.scheme.surfaceContainerHighest.withValues(
          alpha: widget.isDark ? 0.35 : 0.25,
        ),
        borderSide: BorderSide(
          color: widget.scheme.outline.withValues(
            alpha: widget.isDark ? 0.25 : 0.16,
          ),
        ),
        focusedBorderSide: BorderSide(color: widget.scheme.onSurface),
      ),
    );
  }
}

/// Фильтр по категории позиции.
class _CategoryFilterChip extends StatelessWidget {
  final List<TmcCategory> categories;
  final String? categoryId;
  final ValueChanged<String?> onChanged;
  final ColorScheme scheme;
  final ThemeData theme;
  final bool isDark;

  const _CategoryFilterChip({
    required this.categories,
    required this.categoryId,
    required this.onChanged,
    required this.scheme,
    required this.theme,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    TmcCategory? selected;
    for (final c in categories) {
      if (c.id == categoryId) selected = c;
    }

    return PopupMenuButton<String?>(
      tooltip: 'Фильтр по категории',
      onSelected: onChanged,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      itemBuilder: (context) => [
        PopupMenuItem<String?>(
          value: null,
          child: Row(
            children: [
              if (selected == null)
                const Icon(CupertinoIcons.checkmark, size: 14)
              else
                const SizedBox(width: 14),
              const SizedBox(width: 8),
              const Text('Все категории'),
            ],
          ),
        ),
        ...categories.map(
          (c) => PopupMenuItem<String?>(
            value: c.id,
            child: Row(
              children: [
                if (c.id == categoryId)
                  const Icon(CupertinoIcons.checkmark, size: 14)
                else
                  const SizedBox(width: 14),
                const SizedBox(width: 8),
                Text(c.name),
              ],
            ),
          ),
        ),
      ],
      child: _FilterButtonContainer(
        icon: CupertinoIcons.folder,
        label: selected?.name ?? 'Категория',
        active: selected != null,
        scheme: scheme,
        theme: theme,
        isDark: isDark,
      ),
    );
  }
}

/// Фильтр по типу учёта.
class _AccountingFilterChip extends StatelessWidget {
  final TmcAccountingType? value;
  final ValueChanged<TmcAccountingType?> onChanged;
  final ColorScheme scheme;
  final ThemeData theme;
  final bool isDark;

  const _AccountingFilterChip({
    required this.value,
    required this.onChanged,
    required this.scheme,
    required this.theme,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<TmcAccountingType?>(
      tooltip: 'Фильтр по типу учёта',
      onSelected: onChanged,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      itemBuilder: (context) => [
        PopupMenuItem<TmcAccountingType?>(
          value: null,
          child: Row(
            children: [
              if (value == null)
                const Icon(CupertinoIcons.checkmark, size: 14)
              else
                const SizedBox(width: 14),
              const SizedBox(width: 8),
              const Text('Все типы учёта'),
            ],
          ),
        ),
        ...TmcAccountingType.values.map(
          (t) => PopupMenuItem<TmcAccountingType?>(
            value: t,
            child: Row(
              children: [
                if (value == t)
                  const Icon(CupertinoIcons.checkmark, size: 14)
                else
                  const SizedBox(width: 14),
                const SizedBox(width: 8),
                Text(TmcUiLabels.accountingType(t)),
              ],
            ),
          ),
        ),
      ],
      child: _FilterButtonContainer(
        icon: CupertinoIcons.tag,
        label: value != null ? TmcUiLabels.accountingType(value!) : 'Тип учёта',
        active: value != null,
        scheme: scheme,
        theme: theme,
        isDark: isDark,
      ),
    );
  }
}

/// Кнопка контейнера фильтра.
class _FilterButtonContainer extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final ColorScheme scheme;
  final ThemeData theme;
  final bool isDark;

  const _FilterButtonContainer({
    required this.icon,
    required this.label,
    required this.active,
    required this.scheme,
    required this.theme,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: TmcToolbarMetrics.height,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: active
            ? scheme.surfaceContainerHighest.withValues(
                alpha: isDark ? 0.6 : 0.5,
              )
            : scheme.surfaceContainerHighest.withValues(
                alpha: isDark ? 0.35 : 0.25,
              ),
        borderRadius: BorderRadius.circular(TmcToolbarMetrics.radius),
        border: Border.all(
          color: active
              ? scheme.onSurface.withValues(alpha: isDark ? 0.5 : 0.4)
              : scheme.outline.withValues(alpha: isDark ? 0.25 : 0.16),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 13,
            color: active
                ? scheme.onSurface
                : scheme.onSurface.withValues(alpha: 0.55),
          ),
          const SizedBox(width: 6),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 160),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                color: active
                    ? scheme.onSurface
                    : scheme.onSurface.withValues(alpha: 0.8),
              ),
            ),
          ),
          const SizedBox(width: 4),
          Icon(
            CupertinoIcons.chevron_down,
            size: 11,
            color: scheme.onSurface.withValues(alpha: 0.45),
          ),
        ],
      ),
    );
  }
}

/// Кнопка быстрой очистки фильтров.
class _ClearFiltersButton extends StatelessWidget {
  final VoidCallback onTap;
  final ColorScheme scheme;
  final ThemeData theme;

  const _ClearFiltersButton({
    required this.onTap,
    required this.scheme,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Сбросить фильтры',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(TmcToolbarMetrics.radius),
        child: Container(
          height: TmcToolbarMetrics.height,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(TmcToolbarMetrics.radius),
            border: Border.all(color: scheme.outline.withValues(alpha: 0.2)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                CupertinoIcons.xmark,
                size: 12,
                color: scheme.onSurface.withValues(alpha: 0.6),
              ),
              const SizedBox(width: 4),
              Text(
                'Сбросить',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: scheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Кнопка действия с иконкой.
class _IconAction extends StatelessWidget {
  final String tooltip;
  final IconData icon;
  final VoidCallback onTap;
  final ColorScheme scheme;
  final bool isDark;

  const _IconAction({
    required this.tooltip,
    required this.icon,
    required this.onTap,
    required this.scheme,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(TmcToolbarMetrics.radius),
        hoverColor: scheme.onSurface.withValues(alpha: 0.05),
        child: Container(
          width: TmcToolbarMetrics.height,
          height: TmcToolbarMetrics.height,
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHighest.withValues(
              alpha: isDark ? 0.35 : 0.25,
            ),
            borderRadius: BorderRadius.circular(TmcToolbarMetrics.radius),
            border: Border.all(
              color: scheme.outline.withValues(alpha: isDark ? 0.25 : 0.16),
            ),
          ),
          child: Icon(
            icon,
            size: 15,
            color: scheme.onSurface.withValues(alpha: 0.75),
          ),
        ),
      ),
    );
  }
}
