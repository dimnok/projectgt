import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/payroll_filter_providers.dart';
import 'payroll_toolbar_metrics.dart';

/// Кортеж «id + название» для строки фильтра объектов над ФОТ.
typedef _PayrollObjectRow = ({String id, String name});

/// Плотный выпадающий фильтр по объектам в панели ФОТ (стиль модуля «Табель»).
class PayrollObjectsBarDropdown extends ConsumerWidget {
  /// Создаёт выпадающий фильтр объектов.
  const PayrollObjectsBarDropdown({super.key, this.enabled = true});

  /// Если `false`, триггер неактивен (например, вкладка «Выплаты»).
  final bool enabled;

  static const double _triggerHeight = PayrollToolbarMetrics.height;
  static const double _triggerRadius = PayrollToolbarMetrics.radius;
  static const double _menuMaxHeight = 220;
  static const double _menuWidth = 200;

  static List<_PayrollObjectRow> _mapObjects(List<dynamic> raw) {
    final out = <_PayrollObjectRow>[];
    for (final o in raw) {
      final dynamic d = o;
      final id = d.id?.toString();
      if (id == null || id.isEmpty) continue;
      final name = (d.name as String?)?.trim();
      out.add((id: id, name: name == null || name.isEmpty ? id : name));
    }
    out.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return out;
  }

  static String _triggerLabel(List<String> selected, List<_PayrollObjectRow> rows) {
    if (selected.isEmpty) return 'Все объекты';
    if (selected.length == 1) {
      for (final r in rows) {
        if (r.id == selected.first) return r.name;
      }
      return selected.first;
    }
    return 'Объекты · ${selected.length}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final objectsRaw = ref.watch(availableObjectsForPayrollProvider);
    final filterState = ref.watch(payrollFilterProvider);
    final selected = List<String>.from(filterState.selectedObjectIds);
    final rows = _mapObjects(objectsRaw);
    final label = _triggerLabel(selected, rows);
    final textStyle = theme.textTheme.labelLarge?.copyWith(
      fontWeight: FontWeight.w600,
      fontSize: 14,
      height: 1.2,
      color: enabled
          ? scheme.onSurface
          : scheme.onSurface.withValues(alpha: 0.45),
    );
    final borderColor = PayrollToolbarMetrics.trackBorder(scheme);
    final fill = PayrollToolbarMetrics.trackFill(scheme);
    final iconMuted = scheme.onSurface.withValues(
      alpha: enabled ? 0.55 : 0.28,
    );

    if (!enabled) {
      return Tooltip(
        message: 'Фильтр объектов недоступен на вкладке «Выплаты»',
        child: Container(
          height: _triggerHeight,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(_triggerRadius),
            border: Border.all(color: borderColor),
            color: fill,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.apartment_outlined, size: 18, color: iconMuted),
              const SizedBox(width: 6),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: textStyle?.copyWith(fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      );
    }

    if (rows.isEmpty) {
      return Tooltip(
        message: 'Нет объектов для фильтра',
        child: Container(
          height: _triggerHeight,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(_triggerRadius),
            border: Border.all(color: borderColor),
            color: fill,
          ),
          child: Text(
            'Объекты',
            style: textStyle?.copyWith(
              color: scheme.onSurface.withValues(alpha: 0.45),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      );
    }

    void commitSelection(List<String> ids) {
      ref.read(payrollFilterProvider.notifier).setSelectedObjects(ids);
    }

    return MenuAnchor(
      style: MenuStyle(
        backgroundColor: WidgetStatePropertyAll(scheme.surface),
        elevation: const WidgetStatePropertyAll(6),
        shadowColor: WidgetStatePropertyAll(
          scheme.shadow.withValues(alpha: 0.18),
        ),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: BorderSide(color: borderColor),
          ),
        ),
        padding: const WidgetStatePropertyAll(EdgeInsets.zero),
      ),
      menuChildren: [
        _PayrollObjectFilterMenu(
          key: ValueKey(rows.map((e) => e.id).join('\x1e')),
          width: _menuWidth,
          maxScrollHeight: _menuMaxHeight,
          objects: rows,
          selectedIds: selected,
          onCommitSelection: commitSelection,
        ),
      ],
      builder: (context, menuController, _) {
        return Tooltip(
          message: 'Фильтр по объектам',
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(_triggerRadius),
            child: InkWell(
              borderRadius: BorderRadius.circular(_triggerRadius),
              onTap: () {
                if (menuController.isOpen) {
                  menuController.close();
                } else {
                  menuController.open();
                }
              },
              child: Ink(
                height: _triggerHeight,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(_triggerRadius),
                  border: Border.all(color: borderColor),
                  color: fill,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.apartment_outlined,
                        size: 18,
                        color: iconMuted,
                      ),
                      const SizedBox(width: 6),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 168),
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
                        color: iconMuted,
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

class _PayrollObjectFilterMenu extends StatelessWidget {
  const _PayrollObjectFilterMenu({
    super.key,
    required this.width,
    required this.maxScrollHeight,
    required this.objects,
    required this.selectedIds,
    required this.onCommitSelection,
  });

  final double width;
  final double maxScrollHeight;
  final List<_PayrollObjectRow> objects;
  final List<String> selectedIds;
  final ValueChanged<List<String>> onCommitSelection;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final headerStyle = theme.textTheme.labelMedium?.copyWith(
      fontWeight: FontWeight.w600,
      fontSize: 11,
      letterSpacing: 0.4,
      height: 1.1,
      color: scheme.onSurface.withValues(alpha: 0.65),
    );
    final rowTextStyle = theme.textTheme.bodyMedium?.copyWith(
      fontSize: 13.5,
      height: 1.15,
      color: scheme.onSurface,
    );

    Widget selectableRow({
      required String semanticLabel,
      required bool selected,
      required String label,
      required VoidCallback onTap,
    }) {
      return Semantics(
        button: true,
        selected: selected,
        label: semanticLabel,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
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
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 6, 10, 4),
            child: Text('ОБЪЕКТЫ', style: headerStyle),
          ),
          ConstrainedBox(
            constraints: BoxConstraints(maxHeight: maxScrollHeight),
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 4),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  selectableRow(
                    semanticLabel: 'Все объекты',
                    selected: selectedIds.isEmpty,
                    label: 'Все объекты',
                    onTap: () {
                      if (selectedIds.isNotEmpty) {
                        onCommitSelection(const []);
                      }
                    },
                  ),
                  for (final o in objects)
                    selectableRow(
                      semanticLabel: o.name,
                      selected: selectedIds.contains(o.id),
                      label: o.name,
                      onTap: () {
                        final next = List<String>.from(selectedIds);
                        if (next.contains(o.id)) {
                          next.remove(o.id);
                        } else {
                          next.add(o.id);
                        }
                        onCommitSelection(next);
                      },
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
