import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:projectgt/core/di/providers.dart';
import 'package:projectgt/core/widgets/app_snackbar.dart';
import 'package:projectgt/features/company/presentation/providers/company_providers.dart';

import '../providers/timesheet_provider.dart';
import '../services/timesheet_excel_export_service.dart';

/// Кнопка экспорта табеля в Excel.
///
/// Генерирует XLSX-файл на стороне сервера через Supabase Edge Function
/// и сохраняет его локально на устройстве пользователя.
class TimesheetExcelAction extends ConsumerWidget {
  /// Создает кнопку экспорта табеля в Excel.
  const TimesheetExcelAction({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(timesheetProvider);

    return IconButton(
      icon: Icon(
        Icons.table_chart_outlined,
        color: Theme.of(context).colorScheme.onSurface,
      ),
      tooltip: 'Экспорт в Excel',
      onPressed: state.isLoading ? null : () => _exportToExcel(context, ref),
    );
  }

  Future<void> _exportToExcel(BuildContext context, WidgetRef ref) async {
    final state = ref.read(timesheetProvider);
    final companyId = ref.read(activeCompanyIdProvider);

    if (companyId == null || companyId.isEmpty) {
      AppSnackBar.show(
        context: context,
        message: 'Не выбрана активная компания для экспорта',
        kind: AppSnackBarKind.error,
      );
      return;
    }

    final service = TimesheetExcelExportService(
      client: ref.read(supabaseClientProvider),
    );

    try {
      final filePath = await service.exportToExcel(
        companyId: companyId,
        startDate: state.startDate,
        endDate: state.endDate,
        objectIds: state.selectedObjectIds,
        positions: state.selectedPositions,
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
