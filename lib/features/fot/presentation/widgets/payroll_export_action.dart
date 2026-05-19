import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:projectgt/core/widgets/app_snackbar.dart';
import 'package:projectgt/core/widgets/mobile_atmosphere_backdrop.dart';
import 'package:projectgt/core/widgets/mobile_atmosphere_screen_header.dart';
import 'package:projectgt/features/company/presentation/providers/company_providers.dart';
import 'package:projectgt/features/export/presentation/providers/repositories_providers.dart';

import '../providers/payroll_filter_providers.dart';
import '../providers/payroll_grid_selection_providers.dart';

/// Кнопка экспорта ФОТ в Excel: при отмеченных строках — меню «весь / выбранные».
class PayrollExportAction extends ConsumerStatefulWidget {
  /// Создаёт действие экспорта.
  const PayrollExportAction({super.key});

  @override
  ConsumerState<PayrollExportAction> createState() => _PayrollExportActionState();
}

class _PayrollExportActionState extends ConsumerState<PayrollExportAction> {
  final MenuController _menuController = MenuController();

  @override
  Widget build(BuildContext context) {
    final appearance = MobileAtmosphereAppearance.of(context);
    final gridSelected = ref.watch(payrollGridSelectedEmployeeIdsProvider);

    if (gridSelected.isEmpty) {
      return MobileAtmosphereChromeCircleButton(
        appearance: appearance,
        tooltip: 'Экспорт в Excel',
        icon: Icons.download_outlined,
        onTap: () => unawaited(_exportPayroll(null)),
      );
    }

    final scheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    return MenuAnchor(
      controller: _menuController,
      style: MenuStyle(
        backgroundColor: WidgetStatePropertyAll(scheme.surface),
        elevation: const WidgetStatePropertyAll(6),
        shadowColor: WidgetStatePropertyAll(
          scheme.shadow.withValues(alpha: 0.18),
        ),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: BorderSide(color: scheme.outline.withValues(alpha: 0.38)),
          ),
        ),
        padding: const WidgetStatePropertyAll(EdgeInsets.zero),
      ),
      menuChildren: [
        _PayrollExportMenuPanel(
          theme: theme,
          scheme: scheme,
          selectedCount: gridSelected.length,
          onExportFull: () {
            _menuController.close();
            unawaited(_exportPayroll(null));
          },
          onExportSelected: () {
            _menuController.close();
            unawaited(
              _exportPayroll(gridSelected.toList(growable: false)),
            );
          },
        ),
      ],
      builder: (context, controller, _) {
        return MobileAtmosphereChromeCircleButton(
          appearance: appearance,
          tooltip: 'Экспорт в Excel: весь ФОТ или выбранные',
          icon: Icons.download_outlined,
          onTap: () {
            if (controller.isOpen) {
              controller.close();
            } else {
              controller.open();
            }
          },
        );
      },
    );
  }

  Future<void> _exportPayroll(List<String>? employeeIds) async {
    final context = this.context;
    try {
      final filterState = ref.read(payrollFilterProvider);
      final activeCompanyId = ref.read(activeCompanyIdProvider);

      if (activeCompanyId == null) {
        if (!context.mounted) return;
        AppSnackBar.show(
          context: context,
          message: 'Ошибка: компания не выбрана',
          kind: AppSnackBarKind.error,
        );
        return;
      }

      if (!context.mounted) return;
      AppSnackBar.show(
        context: context,
        message: 'Подготовка Excel на сервере...',
        duration: const Duration(seconds: 2),
      );

      final exportService = ref.read(workSearchExportServerServiceProvider);
      final searchQuery = ref.read(payrollSearchQueryProvider);

      final result = await exportService.exportPayroll(
        year: filterState.selectedYear,
        month: filterState.selectedMonth,
        companyId: activeCompanyId,
        objectIds: filterState.selectedObjectIds,
        searchQuery: searchQuery,
        employeeIds: employeeIds,
      );

      if (!context.mounted) return;

      if (result.success) {
        if (result.filePath == 'cancelled') return;
        AppSnackBar.show(
          context: context,
          message: 'ФОТ успешно выгружена: ${result.filename}',
          kind: AppSnackBarKind.success,
        );
      } else {
        AppSnackBar.show(
          context: context,
          message: 'Ошибка: ${result.message}',
          kind: AppSnackBarKind.error,
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      AppSnackBar.show(
        context: context,
        message: 'Ошибка экспорта: $e',
        kind: AppSnackBarKind.error,
      );
    }
  }
}

class _PayrollExportMenuPanel extends StatelessWidget {
  const _PayrollExportMenuPanel({
    required this.theme,
    required this.scheme,
    required this.selectedCount,
    required this.onExportFull,
    required this.onExportSelected,
  });

  final ThemeData theme;
  final ColorScheme scheme;
  final int selectedCount;
  final VoidCallback onExportFull;
  final VoidCallback onExportSelected;

  static const double _menuWidth = 268;

  @override
  Widget build(BuildContext context) {
    final borderColor = scheme.outline.withValues(alpha: 0.38);
    final headerStyle = theme.textTheme.labelMedium?.copyWith(
      fontWeight: FontWeight.w600,
      fontSize: 11,
      letterSpacing: 0.4,
      height: 1.1,
      color: scheme.onSurface.withValues(alpha: 0.65),
    );
    final rowStyle = theme.textTheme.bodyMedium?.copyWith(
      fontSize: 13.5,
      height: 1.15,
      color: scheme.onSurface,
      fontWeight: FontWeight.w500,
    );

    return SizedBox(
      width: _menuWidth,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 4),
            child: Text('ЭКСПОРТ', style: headerStyle),
          ),
          _ExportMenuRow(
            semanticLabel: 'Экспорт всего ФОТ за период',
            label: 'Весь ФОТ',
            textStyle: rowStyle,
            onTap: onExportFull,
          ),
          Divider(
            height: 1,
            thickness: 1,
            indent: 10,
            endIndent: 10,
            color: borderColor.withValues(alpha: 0.55),
          ),
          _ExportMenuRow(
            semanticLabel:
                'Экспорт только выбранных сотрудников, $selectedCount человек',
            label: 'Только выбранные ($selectedCount)',
            textStyle: rowStyle,
            onTap: onExportSelected,
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}

class _ExportMenuRow extends StatelessWidget {
  const _ExportMenuRow({
    required this.semanticLabel,
    required this.label,
    required this.textStyle,
    required this.onTap,
  });

  final String semanticLabel;
  final String label;
  final TextStyle? textStyle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: textStyle,
            ),
          ),
        ),
      ),
    );
  }
}
