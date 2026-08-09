import 'package:flutter/material.dart';
import 'package:projectgt/features/settlements/domain/entities/settlement_operation.dart';
import 'package:projectgt/features/settlements/presentation/utils/settlement_ui_labels.dart';
import 'package:projectgt/features/settlements/presentation/widgets/settlements_toolbar_metrics.dart';

/// Есть ли активные дополнительные фильтры (тип операции / статус оплаты).
bool hasActiveSettlementsExtraFilters({
  required SettlementOperationType? typeFilter,
  required SettlementPaymentStatus? paymentStatusFilter,
}) {
  return typeFilter != null || paymentStatusFilter != null;
}

/// Подпись на кнопке объединённого фильтра «Тип / Оплата».
String settlementsExtraFilterTriggerLabel({
  required SettlementOperationType? typeFilter,
  required SettlementPaymentStatus? paymentStatusFilter,
}) {
  final parts = <String>[];
  if (typeFilter != null) {
    parts.add(settlementOperationTypeLabel(typeFilter));
  }
  if (paymentStatusFilter != null) {
    parts.add(settlementPaymentStatusLabel(paymentStatusFilter));
  }
  if (parts.isEmpty) return 'Фильтры';
  if (parts.length == 1) return parts.first;
  return parts.join(' · ');
}

/// Объединённый фильтр типа операции и статуса оплаты (стиль «Состав» в табеле).
class SettlementsExtraFiltersDropdown extends StatelessWidget {
  /// Создаёт выпадающий фильтр.
  const SettlementsExtraFiltersDropdown({
    super.key,
    required this.typeFilter,
    required this.paymentStatusFilter,
    required this.onTypeChanged,
    required this.onPaymentStatusChanged,
  });

  /// Фильтр типа операции.
  final SettlementOperationType? typeFilter;

  /// Фильтр статуса оплаты.
  final SettlementPaymentStatus? paymentStatusFilter;

  /// Колбэк смены типа.
  final ValueChanged<SettlementOperationType?> onTypeChanged;

  /// Колбэк смены статуса оплаты.
  final ValueChanged<SettlementPaymentStatus?> onPaymentStatusChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isActive = hasActiveSettlementsExtraFilters(
      typeFilter: typeFilter,
      paymentStatusFilter: paymentStatusFilter,
    );
    final label = settlementsExtraFilterTriggerLabel(
      typeFilter: typeFilter,
      paymentStatusFilter: paymentStatusFilter,
    );

    final borderColor = isActive
        ? SettlementsToolbarMetrics.activeBorder(scheme)
        : SettlementsToolbarMetrics.trackBorder(scheme);
    final fill = isActive
        ? SettlementsToolbarMetrics.activeFill(scheme)
        : SettlementsToolbarMetrics.trackFill(scheme);
    final iconMuted = scheme.onSurface.withValues(alpha: 0.55);
    final textStyle = theme.textTheme.labelLarge?.copyWith(
      fontWeight: FontWeight.w600,
      fontSize: SettlementsToolbarMetrics.fontSize,
      height: 1.2,
      color: isActive ? scheme.primary : scheme.onSurface,
    );

    void resetAll() {
      onTypeChanged(null);
      onPaymentStatusChanged(null);
    }

    return MenuAnchor(
      style: MenuStyle(
        backgroundColor: WidgetStatePropertyAll(scheme.surface),
        elevation: const WidgetStatePropertyAll(8),
        shadowColor: WidgetStatePropertyAll(
          scheme.shadow.withValues(alpha: 0.2),
        ),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: borderColor),
          ),
        ),
        padding: const WidgetStatePropertyAll(EdgeInsets.zero),
      ),
      menuChildren: [
        _SettlementsExtraFiltersMenu(
          width: SettlementsToolbarMetrics.extraMenuWidth,
          typeFilter: typeFilter,
          paymentStatusFilter: paymentStatusFilter,
          isActive: isActive,
          onTypeChanged: onTypeChanged,
          onPaymentStatusChanged: onPaymentStatusChanged,
          onReset: resetAll,
        ),
      ],
      builder: (context, menuController, _) {
        return Tooltip(
          message: 'Фильтр по типу операции и статусу оплаты',
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(SettlementsToolbarMetrics.radius),
            child: InkWell(
              borderRadius: BorderRadius.circular(SettlementsToolbarMetrics.radius),
              onTap: () {
                if (menuController.isOpen) {
                  menuController.close();
                } else {
                  menuController.open();
                }
              },
              child: Ink(
                height: SettlementsToolbarMetrics.height,
                decoration: BoxDecoration(
                  borderRadius:
                      BorderRadius.circular(SettlementsToolbarMetrics.radius),
                  border: Border.all(
                    color: borderColor,
                    width: isActive ? 1.25 : 1,
                  ),
                  color: fill,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.tune_rounded,
                        size: SettlementsToolbarMetrics.iconSize,
                        color: isActive ? scheme.primary : iconMuted,
                      ),
                      const SizedBox(width: 6),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 160),
                        child: Text(
                          label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: textStyle,
                        ),
                      ),
                      const SizedBox(width: 2),
                      Icon(
                        menuController.isOpen
                            ? Icons.expand_less_rounded
                            : Icons.expand_more_rounded,
                        size: 20,
                        color: isActive ? scheme.primary : iconMuted,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SettlementsExtraFiltersMenu extends StatelessWidget {
  const _SettlementsExtraFiltersMenu({
    required this.width,
    required this.typeFilter,
    required this.paymentStatusFilter,
    required this.isActive,
    required this.onTypeChanged,
    required this.onPaymentStatusChanged,
    required this.onReset,
  });

  final double width;
  final SettlementOperationType? typeFilter;
  final SettlementPaymentStatus? paymentStatusFilter;
  final bool isActive;
  final ValueChanged<SettlementOperationType?> onTypeChanged;
  final ValueChanged<SettlementPaymentStatus?> onPaymentStatusChanged;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final headerStyle = theme.textTheme.labelMedium?.copyWith(
      fontWeight: FontWeight.w600,
      fontSize: 11,
      letterSpacing: 0.4,
      height: 1.1,
      color: scheme.onSurface.withValues(alpha: 0.55),
    );
    final rowTextStyle = theme.textTheme.bodyMedium?.copyWith(
      fontSize: 13.5,
      height: 1.15,
      color: scheme.onSurface,
    );
    final dividerColor = scheme.outline.withValues(alpha: 0.14);

    Widget sectionHeader(String title) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
        child: Text(title, style: headerStyle),
      );
    }

    Widget radioRow({
      required String label,
      required String semanticsLabel,
      required bool selected,
      required VoidCallback onTap,
    }) {
      return Semantics(
        button: true,
        selected: selected,
        label: semanticsLabel,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Row(
                children: [
                  SizedBox(
                    width: 22,
                    child: selected
                        ? Icon(
                            Icons.check_rounded,
                            size: 18,
                            color: scheme.primary,
                          )
                        : null,
                  ),
                  Expanded(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: rowTextStyle?.copyWith(
                        fontWeight:
                            selected ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return SizedBox(
      width: width,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          sectionHeader('ТИП ОПЕРАЦИИ'),
          radioRow(
            label: 'Все типы',
            semanticsLabel: 'Тип: все',
            selected: typeFilter == null,
            onTap: () => onTypeChanged(null),
          ),
          for (final type in SettlementOperationType.values)
            radioRow(
              label: settlementOperationTypeLabel(type),
              semanticsLabel: 'Тип: ${settlementOperationTypeLabel(type)}',
              selected: typeFilter == type,
              onTap: () => onTypeChanged(type),
            ),
          Divider(height: 1, thickness: 1, color: dividerColor),
          sectionHeader('СТАТУС ОПЛАТЫ'),
          radioRow(
            label: 'Все статусы',
            semanticsLabel: 'Оплата: все',
            selected: paymentStatusFilter == null,
            onTap: () => onPaymentStatusChanged(null),
          ),
          for (final status in SettlementPaymentStatus.values)
            radioRow(
              label: settlementPaymentStatusLabel(status),
              semanticsLabel:
                  'Оплата: ${settlementPaymentStatusLabel(status)}',
              selected: paymentStatusFilter == status,
              onTap: () => onPaymentStatusChanged(status),
            ),
          if (isActive) ...[
            Divider(height: 1, thickness: 1, color: dividerColor),
            Semantics(
              button: true,
              label: 'Сбросить фильтры типа и оплаты',
              child: TextButton(
                onPressed: onReset,
                style: TextButton.styleFrom(
                  foregroundColor: scheme.primary,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  textStyle: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                child: const Text('Сбросить'),
              ),
            ),
          ] else
            const SizedBox(height: 6),
        ],
      ),
    );
  }
}
