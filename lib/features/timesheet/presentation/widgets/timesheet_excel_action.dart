import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:projectgt/core/di/providers.dart';
import 'package:projectgt/core/widgets/app_snackbar.dart';
import 'package:projectgt/core/widgets/gt_buttons.dart';
import 'package:projectgt/features/company/presentation/providers/company_providers.dart';

import '../../data/timesheet_company_scope.dart';
import '../providers/timesheet_provider.dart';
import '../services/timesheet_excel_export_service.dart';

/// Текстовая кнопка «Скачать табель»: генерация XLSX на сервере (Edge Function)
/// и сохранение файла на устройстве.
///
/// Если в сетке табеля отмечены сотрудники чекбоксами, по нажатию открывается
/// меню: экспорт всего табеля или только выбранных строк.
class TimesheetExcelAction extends ConsumerStatefulWidget {
  /// Создаёт действие скачивания табеля в Excel.
  const TimesheetExcelAction({super.key});

  @override
  ConsumerState<TimesheetExcelAction> createState() =>
      _TimesheetExcelActionState();
}

class _TimesheetExcelActionState extends ConsumerState<TimesheetExcelAction> {
  final MenuController _menuController = MenuController();

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(timesheetProvider);
    final busy = state.isLoading;
    final scheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    final gridSelected = ref.watch(timesheetGridSelectedEmployeeIdsProvider);

    if (gridSelected.isEmpty) {
      return Tooltip(
        message: 'Скачать табель в формате Excel',
        child: GTTextButton(
          text: 'Скачать табель',
          color: scheme.primary,
          fontSize: 14,
          onPressed: busy ? null : () => unawaited(_exportToExcel(null)),
        ),
      );
    }

    final borderColor = scheme.outline.withValues(alpha: 0.38);

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
            side: BorderSide(color: borderColor),
          ),
        ),
        padding: const WidgetStatePropertyAll(EdgeInsets.zero),
      ),
      menuChildren: [
        _TimesheetExportMenuPanel(
          theme: theme,
          scheme: scheme,
          busy: busy,
          selectedCount: gridSelected.length,
          onExportFull: () {
            _menuController.close();
            unawaited(_exportToExcel(null));
          },
          onExportSelected: () {
            _menuController.close();
            unawaited(
              _exportToExcel(gridSelected.toList(growable: false)),
            );
          },
        ),
      ],
      builder: (context, menuController, _) {
        return Tooltip(
          message: 'Скачать целиком или по отмеченным в таблице',
          child: GTTextButton(
            text: 'Скачать табель',
            color: scheme.primary,
            fontSize: 14,
            onPressed: busy
                ? null
                : () {
                    if (menuController.isOpen) {
                      menuController.close();
                    } else {
                      menuController.open();
                    }
                  },
          ),
        );
      },
    );
  }

  Future<void> _exportToExcel(List<String>? employeeIds) async {
    final state = ref.read(timesheetProvider);
    final companyId = ref.read(activeCompanyIdProvider);
    final context = this.context;

    if (!timesheetHasActiveCompany(companyId)) {
      AppSnackBar.show(
        context: context,
        message: timesheetNoActiveCompanyMessage,
        kind: AppSnackBarKind.error,
      );
      return;
    }
    final scopedCompanyId = companyId!;

    final service = TimesheetExcelExportService(
      client: ref.read(supabaseClientProvider),
    );

    try {
      final filePath = await service.exportToExcel(
        companyId: scopedCompanyId,
        startDate: state.startDate,
        endDate: state.endDate,
        objectIds: state.selectedObjectIds,
        employeeIds: employeeIds,
      );

      if (!context.mounted) return;

      if (filePath == null) {
        AppSnackBar.show(
          context: context,
          message: 'Сохранение Excel-файла отменено',
          kind: AppSnackBarKind.warning,
        );
        return;
      }

      AppSnackBar.show(
        context: context,
        message: 'Excel-файл успешно сохранён: $filePath',
        kind: AppSnackBarKind.success,
      );
    } catch (error) {
      if (!context.mounted) return;

      AppSnackBar.show(
        context: context,
        message: 'Ошибка экспорта в Excel: $error',
        kind: AppSnackBarKind.error,
      );
    }
  }
}

/// Содержимое выпадающего меню экспорта в том же визуальном языке, что
/// [TimesheetObjectsBarDropdown] (плотная типографика, без лишней массы).
class _TimesheetExportMenuPanel extends StatelessWidget {
  /// Создаёт панель пунктов экспорта.
  const _TimesheetExportMenuPanel({
    required this.theme,
    required this.scheme,
    required this.busy,
    required this.selectedCount,
    required this.onExportFull,
    required this.onExportSelected,
  });

  final ThemeData theme;
  final ColorScheme scheme;
  final bool busy;
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

    final muted = busy ? 0.45 : 1.0;

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
          Opacity(
            opacity: muted,
            child: _ExportMenuRow(
              semanticLabel: 'Экспорт всего табеля за период',
              label: 'Весь табель',
              enabled: !busy,
              textStyle: rowStyle,
              onTap: onExportFull,
            ),
          ),
          Divider(
            height: 1,
            thickness: 1,
            indent: 10,
            endIndent: 10,
            color: borderColor.withValues(alpha: 0.55),
          ),
          Opacity(
            opacity: muted,
            child: _ExportMenuRow(
              semanticLabel:
                  'Экспорт только выбранных сотрудников, $selectedCount человек',
              label: 'Только выбранные ($selectedCount)',
              enabled: !busy,
              textStyle: rowStyle,
              onTap: onExportSelected,
            ),
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
    required this.enabled,
    required this.textStyle,
    required this.onTap,
  });

  final String semanticLabel;
  final String label;
  final bool enabled;
  final TextStyle? textStyle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: enabled,
      label: semanticLabel,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: enabled ? onTap : null,
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
