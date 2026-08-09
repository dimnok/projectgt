import 'package:flutter/material.dart';
import 'package:projectgt/features/settlements/domain/entities/settlement_operation.dart';
import 'package:projectgt/features/settlements/presentation/utils/settlements_filter_options.dart';
import 'package:projectgt/features/settlements/presentation/widgets/settlements_extra_filters_dropdown.dart';
import 'package:projectgt/features/settlements/presentation/widgets/settlements_option_bar_dropdown.dart';
import 'package:projectgt/features/settlements/presentation/widgets/settlements_toolbar_metrics.dart';

/// Компактная панель фильтров взаиморасчётов (стиль модуля «Табель»).
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
                  SettlementsOptionBarDropdown(
                    options: contractorOptions,
                    selectedId: contractorFilterId,
                    onChanged: onContractorChanged,
                    icon: Icons.business_outlined,
                    tooltip: 'Фильтр по контрагентам',
                    headerTitle: 'КОНТРАГЕНТЫ',
                    allLabel: 'Все контрагенты',
                    emptyPlaceholder: 'Контрагенты',
                  ),
                  const SizedBox(width: 8),
                  SettlementsOptionBarDropdown(
                    options: objectOptions,
                    selectedId: objectFilterId,
                    onChanged: onObjectChanged,
                    icon: Icons.apartment_outlined,
                    tooltip: 'Фильтр по объектам',
                    headerTitle: 'ОБЪЕКТЫ',
                    allLabel: 'Все объекты',
                    emptyPlaceholder: 'Объекты',
                  ),
                  const SizedBox(width: 8),
                  SettlementsOptionBarDropdown(
                    options: contractOptions,
                    selectedId: contractFilterId,
                    onChanged: onContractChanged,
                    icon: Icons.description_outlined,
                    tooltip: 'Фильтр по договорам',
                    headerTitle: 'ДОГОВОРЫ',
                    allLabel: 'Все договоры',
                    emptyPlaceholder: 'Договоры',
                  ),
                  const SizedBox(width: 8),
                  SettlementsExtraFiltersDropdown(
                    typeFilter: typeFilter,
                    paymentStatusFilter: paymentStatusFilter,
                    onTypeChanged: onTypeChanged,
                    onPaymentStatusChanged: onPaymentStatusChanged,
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
  late final FocusNode _focus;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
    _focus = FocusNode()..addListener(() => setState(() {}));
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

  BoxDecoration _searchDecoration(ThemeData theme, {required bool focused}) {
    final scheme = theme.colorScheme;
    final borderColor = focused
        ? scheme.primary.withValues(alpha: 0.85)
        : SettlementsToolbarMetrics.trackBorder(scheme);
    final width = focused ? 1.5 : 1.0;
    return BoxDecoration(
      borderRadius: BorderRadius.circular(SettlementsToolbarMetrics.radius),
      border: Border.all(color: borderColor, width: width),
      color: SettlementsToolbarMetrics.trackFill(scheme),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final textStyle = theme.textTheme.bodyMedium?.copyWith(
      fontSize: SettlementsToolbarMetrics.fontSize,
      height: 1.2,
      color: scheme.onSurface,
    );
    final iconMuted = scheme.onSurface.withValues(alpha: 0.55);

    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        final hasText = _controller.text.isNotEmpty;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          height: SettlementsToolbarMetrics.height,
          decoration: _searchDecoration(theme, focused: _focus.hasFocus),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(SettlementsToolbarMetrics.radius),
            child: Row(
              children: [
                const SizedBox(width: 10),
                Icon(Icons.search_rounded, size: SettlementsToolbarMetrics.iconSize, color: iconMuted),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _controller,
                    focusNode: _focus,
                    style: textStyle,
                    cursorHeight: SettlementsToolbarMetrics.fontSize + 2,
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
                  Tooltip(
                    message: 'Очистить',
                    waitDuration: const Duration(milliseconds: 400),
                    child: Semantics(
                      button: true,
                      label: 'Очистить поиск',
                      child: MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () {
                            _controller.clear();
                            widget.onChanged('');
                          },
                          child: SizedBox(
                            width: SettlementsToolbarMetrics.height,
                            height: SettlementsToolbarMetrics.height,
                            child: Center(
                              child: Icon(
                                Icons.close_rounded,
                                size: 20,
                                color: iconMuted,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
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
          borderRadius: BorderRadius.circular(SettlementsToolbarMetrics.radius),
          onTap: onTap,
          child: Container(
            height: SettlementsToolbarMetrics.height,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              borderRadius:
                  BorderRadius.circular(SettlementsToolbarMetrics.radius),
              border: Border.all(color: SettlementsToolbarMetrics.trackBorder(scheme)),
              color: SettlementsToolbarMetrics.trackFill(scheme),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.filter_alt_off_outlined,
                  size: SettlementsToolbarMetrics.iconSize,
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
          borderRadius: BorderRadius.circular(SettlementsToolbarMetrics.radius),
          onTap: onTap,
          child: Container(
            height: SettlementsToolbarMetrics.height,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              borderRadius:
                  BorderRadius.circular(SettlementsToolbarMetrics.radius),
              border: Border.all(
                color: SettlementsToolbarMetrics.activeBorder(scheme),
              ),
              color: SettlementsToolbarMetrics.activeFill(scheme),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.add_rounded, size: SettlementsToolbarMetrics.iconSize, color: scheme.primary),
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
