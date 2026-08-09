import 'package:flutter/material.dart';
import 'package:projectgt/features/settlements/domain/entities/settlement_operation.dart';
import 'package:projectgt/features/settlements/presentation/utils/settlement_ui_labels.dart';
import 'package:projectgt/features/settlements/presentation/utils/settlements_filter_options.dart';

/// Геометрия компактной панели фильтров взаиморасчётов (как Табель / ФОТ).
abstract final class SettlementsToolbarMetrics {
  /// Высота элементов панели.
  static const double height = 34;

  /// Радиус капсул.
  static const double radius = 18;
}

Color _barBorder(ColorScheme scheme) =>
    scheme.outline.withValues(alpha: 0.38);

Color _barFill(ColorScheme scheme) =>
    scheme.surfaceContainerHighest.withValues(alpha: 0.45);

/// Компактная панель: поиск, тип, действия.
class SettlementsFiltersToolbar extends StatelessWidget {
  /// Текст поиска.
  final String searchQuery;

  /// Колбэк изменения поиска.
  final ValueChanged<String> onSearchChanged;

  /// Фильтр типа.
  final SettlementOperationType? typeFilter;

  /// Колбэк типа.
  final ValueChanged<SettlementOperationType?> onTypeChanged;

  /// Фильтр статуса оплаты.
  final SettlementPaymentStatus? paymentStatusFilter;

  /// Колбэк статуса оплаты.
  final ValueChanged<SettlementPaymentStatus?> onPaymentStatusChanged;

  /// Опции фильтра по контрагенту.
  final List<SettlementsFilterOption> contractorOptions;

  /// Выбранный контрагент.
  final String? contractorFilterId;

  /// Колбэк контрагента.
  final ValueChanged<String?> onContractorChanged;

  /// Опции фильтра по объекту.
  final List<SettlementsFilterOption> objectOptions;

  /// Выбранный объект.
  final String? objectFilterId;

  /// Колбэк объекта.
  final ValueChanged<String?> onObjectChanged;

  /// Опции фильтра по договору.
  final List<SettlementsFilterOption> contractOptions;

  /// Выбранный договор.
  final String? contractFilterId;

  /// Колбэк договора.
  final ValueChanged<String?> onContractChanged;

  /// Создать счёт (null — скрыть).
  final VoidCallback? onCreate;

  /// Есть активные фильтры (для кнопки сброса).
  final bool hasActiveFilters;

  /// Сбросить все фильтры.
  final VoidCallback? onResetFilters;

  /// Создаёт панель.
  const SettlementsFiltersToolbar({
    super.key,
    required this.searchQuery,
    required this.onSearchChanged,
    required this.typeFilter,
    required this.onTypeChanged,
    required this.paymentStatusFilter,
    required this.onPaymentStatusChanged,
    required this.contractorOptions,
    required this.contractorFilterId,
    required this.onContractorChanged,
    required this.objectOptions,
    required this.objectFilterId,
    required this.onObjectChanged,
    required this.contractOptions,
    required this.contractFilterId,
    required this.onContractChanged,
    required this.hasActiveFilters,
    this.onResetFilters,
    this.onCreate,
  });

  String _optionChipLabel({
    required String placeholder,
    required List<SettlementsFilterOption> options,
    required String? selectedId,
  }) {
    final selectedLabel =
        SettlementsFilterOptionsBuilder.labelForId(options, selectedId);
    if (selectedLabel == null) return placeholder;
    return _truncateChipLabel(selectedLabel);
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: SettlementsToolbarMetrics.height,
      child: Row(
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  SizedBox(
                    width: 200,
                    child: _SettlementsToolbarSearch(
                      initialValue: searchQuery,
                      onChanged: onSearchChanged,
                    ),
                  ),
                  const SizedBox(width: 8),
                  _SettlementsFilterChip<String>(
                    label: _optionChipLabel(
                      placeholder: 'Контрагент',
                      options: contractorOptions,
                      selectedId: contractorFilterId,
                    ),
                    values: [
                      for (final o in contractorOptions) o.id,
                    ],
                    selected: contractorFilterId,
                    itemLabel: (id) =>
                        SettlementsFilterOptionsBuilder.labelForId(
                          contractorOptions,
                          id,
                        ) ??
                        id,
                    onChanged: onContractorChanged,
                    allLabel: 'Все контрагенты',
                  ),
                  const SizedBox(width: 8),
                  _SettlementsFilterChip<String>(
                    label: _optionChipLabel(
                      placeholder: 'Объект',
                      options: objectOptions,
                      selectedId: objectFilterId,
                    ),
                    values: [
                      for (final o in objectOptions) o.id,
                    ],
                    selected: objectFilterId,
                    itemLabel: (id) =>
                        SettlementsFilterOptionsBuilder.labelForId(
                          objectOptions,
                          id,
                        ) ??
                        id,
                    onChanged: onObjectChanged,
                    allLabel: 'Все объекты',
                  ),
                  const SizedBox(width: 8),
                  _SettlementsFilterChip<String>(
                    label: _optionChipLabel(
                      placeholder: 'Договор',
                      options: contractOptions,
                      selectedId: contractFilterId,
                    ),
                    values: [
                      for (final o in contractOptions) o.id,
                    ],
                    selected: contractFilterId,
                    itemLabel: (id) =>
                        SettlementsFilterOptionsBuilder.labelForId(
                          contractOptions,
                          id,
                        ) ??
                        id,
                    onChanged: onContractChanged,
                    allLabel: 'Все договоры',
                  ),
                  const SizedBox(width: 8),
                  _SettlementsFilterChip<SettlementOperationType>(
                    label: typeFilter == null
                        ? 'Тип'
                        : settlementOperationTypeLabel(typeFilter!),
                    values: SettlementOperationType.values,
                    selected: typeFilter,
                    itemLabel: settlementOperationTypeLabel,
                    onChanged: onTypeChanged,
                    allLabel: 'Все типы',
                  ),
                  const SizedBox(width: 8),
                  _SettlementsFilterChip<SettlementPaymentStatus>(
                    label: paymentStatusFilter == null
                        ? 'Оплата'
                        : settlementPaymentStatusLabel(paymentStatusFilter!),
                    values: SettlementPaymentStatus.values,
                    selected: paymentStatusFilter,
                    itemLabel: settlementPaymentStatusLabel,
                    onChanged: onPaymentStatusChanged,
                    allLabel: 'Все статусы',
                  ),
                  if (hasActiveFilters && onResetFilters != null) ...[
                    const SizedBox(width: 8),
                    _ResetFiltersCapsuleButton(onTap: onResetFilters!),
                  ],
                ],
              ),
            ),
          ),
          if (onCreate != null) ...[
            const SizedBox(width: 8),
            _CreateCapsuleButton(onTap: onCreate!),
          ],
        ],
      ),
    );
  }
}

String _truncateChipLabel(String value, {int maxLength = 22}) {
  if (value.length <= maxLength) return value;
  return '${value.substring(0, maxLength - 1)}…';
}

class _SettlementsToolbarSearch extends StatefulWidget {
  final String initialValue;
  final ValueChanged<String> onChanged;

  const _SettlementsToolbarSearch({
    required this.initialValue,
    required this.onChanged,
  });

  @override
  State<_SettlementsToolbarSearch> createState() =>
      _SettlementsToolbarSearchState();
}

class _SettlementsToolbarSearchState extends State<_SettlementsToolbarSearch> {
  late final TextEditingController _controller;
  final FocusNode _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
    _focus.addListener(() => setState(() {}));
  }

  @override
  void didUpdateWidget(covariant _SettlementsToolbarSearch oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialValue != _controller.text &&
        widget.initialValue != oldWidget.initialValue) {
      _controller.text = widget.initialValue;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final focused = _focus.hasFocus;
    final hasText = _controller.text.isNotEmpty;
    final textStyle = theme.textTheme.bodyMedium?.copyWith(
      fontSize: 14,
      height: 1.2,
      color: scheme.onSurface,
    );

    return AnimatedContainer(
      duration: const Duration(milliseconds: 120),
      height: SettlementsToolbarMetrics.height,
      decoration: BoxDecoration(
        borderRadius:
            BorderRadius.circular(SettlementsToolbarMetrics.radius),
        border: Border.all(
          color: focused
              ? scheme.primary.withValues(alpha: 0.7)
              : _barBorder(scheme),
        ),
        color: _barFill(scheme),
      ),
      child: Row(
        children: [
          const SizedBox(width: 10),
          Icon(
            Icons.search_rounded,
            size: 18,
            color: scheme.onSurface.withValues(alpha: 0.55),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _controller,
              focusNode: _focus,
              style: textStyle,
              cursorHeight: 16,
              decoration: InputDecoration(
                isDense: true,
                border: InputBorder.none,
                hintText: 'Поиск…',
                hintStyle: textStyle?.copyWith(
                  color: scheme.onSurface.withValues(alpha: 0.42),
                ),
                contentPadding: EdgeInsets.zero,
              ),
              onChanged: (v) {
                setState(() {});
                widget.onChanged(v);
              },
            ),
          ),
          if (hasText)
            InkWell(
              borderRadius:
                  BorderRadius.circular(SettlementsToolbarMetrics.radius),
              onTap: () {
                _controller.clear();
                setState(() {});
                widget.onChanged('');
              },
              child: SizedBox(
                width: SettlementsToolbarMetrics.height,
                height: SettlementsToolbarMetrics.height,
                child: Icon(
                  Icons.close_rounded,
                  size: 16,
                  color: scheme.onSurface.withValues(alpha: 0.55),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SettlementsFilterChip<T> extends StatelessWidget {
  final String label;
  final List<T> values;
  final T? selected;
  final String Function(T) itemLabel;
  final ValueChanged<T?> onChanged;
  final String allLabel;

  const _SettlementsFilterChip({
    required this.label,
    required this.values,
    required this.selected,
    required this.itemLabel,
    required this.onChanged,
    required this.allLabel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final active = selected != null;

    return PopupMenuButton<T?>(
      tooltip: label,
      constraints: const BoxConstraints(maxHeight: 320),
      onSelected: onChanged,
      itemBuilder: (context) => [
        PopupMenuItem<T?>(
          onTap: () => onChanged(null),
          child: Text(allLabel),
        ),
        ...values.map(
          (v) => PopupMenuItem<T?>(
            value: v,
            child: Text(
              itemLabel(v),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ],
      child: Container(
        height: SettlementsToolbarMetrics.height,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          borderRadius:
              BorderRadius.circular(SettlementsToolbarMetrics.radius),
          border: Border.all(
            color: active
                ? scheme.primary.withValues(alpha: 0.62)
                : _barBorder(scheme),
          ),
          color: active
              ? scheme.primary.withValues(alpha: 0.14)
              : _barFill(scheme),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: theme.textTheme.labelLarge?.copyWith(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: active ? scheme.primary : scheme.onSurface,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.expand_more_rounded,
              size: 18,
              color: active
                  ? scheme.primary
                  : scheme.onSurface.withValues(alpha: 0.55),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResetFiltersCapsuleButton extends StatelessWidget {
  final VoidCallback onTap;

  const _ResetFiltersCapsuleButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Tooltip(
      message: 'Сбросить фильтры',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius:
              BorderRadius.circular(SettlementsToolbarMetrics.radius),
          onTap: onTap,
          child: Container(
            height: SettlementsToolbarMetrics.height,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              borderRadius:
                  BorderRadius.circular(SettlementsToolbarMetrics.radius),
              border: Border.all(color: _barBorder(scheme)),
              color: _barFill(scheme),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.filter_alt_off_outlined,
                  size: 18,
                  color: scheme.onSurface.withValues(alpha: 0.72),
                ),
                const SizedBox(width: 4),
                Text(
                  'Сбросить',
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: scheme.onSurface.withValues(alpha: 0.85),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CreateCapsuleButton extends StatelessWidget {
  final VoidCallback onTap;

  const _CreateCapsuleButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Tooltip(
      message: 'Новый счёт',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius:
              BorderRadius.circular(SettlementsToolbarMetrics.radius),
          onTap: onTap,
          child: Container(
            height: SettlementsToolbarMetrics.height,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              borderRadius:
                  BorderRadius.circular(SettlementsToolbarMetrics.radius),
              border: Border.all(
                color: scheme.primary.withValues(alpha: 0.62),
              ),
              color: scheme.primary.withValues(alpha: 0.14),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.add_rounded, size: 18, color: scheme.primary),
                const SizedBox(width: 4),
                Text(
                  'Новый',
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: scheme.primary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
