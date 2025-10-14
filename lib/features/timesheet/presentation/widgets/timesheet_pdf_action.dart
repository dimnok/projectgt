import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:projectgt/core/di/providers.dart';
import '../providers/timesheet_provider.dart';
import '../services/timesheet_pdf_service.dart';

/// Кнопка экспорта табеля в PDF в AppBar.
///
/// Сохраняет табель в PDF файл при нажатии.
class TimesheetPdfAction extends ConsumerWidget {
  /// Создает кнопку экспорта табеля в PDF.
  const TimesheetPdfAction({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(timesheetProvider);

    return IconButton(
      icon: Icon(
        Icons.picture_as_pdf_outlined,
        color: Theme.of(context).colorScheme.onSurface,
      ),
      tooltip: 'Экспорт в PDF',
      onPressed: state.isLoading || state.entries.isEmpty
          ? null
          : () => _showExportDialog(context, ref),
    );
  }

  /// Сразу экспортирует табель в PDF файл (без диалога).
  Future<void> _showExportDialog(BuildContext context, WidgetRef ref) async {
    await _exportToPdf(context, ref);
  }

  /// Экспортирует табель в PDF файл.
  Future<void> _exportToPdf(BuildContext context, WidgetRef ref) async {
    final state = ref.read(timesheetProvider);
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final theme = Theme.of(context);

    try {
      // Генерируем имя файла
      final dateFormatter = DateFormat('dd.MM.yyyy');
      final startDateStr = dateFormatter.format(state.startDate);
      final endDateStr = dateFormatter.format(state.endDate);
      final fileName = 'Табель_${startDateStr}_$endDateStr.pdf';

      // Создаем сервис с репозиторием и экспортируем
      final employeeRepository = ref.read(employeeRepositoryProvider);
      final service = TimesheetPdfService(employeeRepository);
      final filePath = await service.exportToPdf(
        entries: state.entries,
        fileName: fileName,
        startDate: state.startDate,
        endDate: state.endDate,
      );

      if (!context.mounted) return;

      if (filePath != null) {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('PDF файл успешно сохранен: $filePath'),
            backgroundColor: theme.colorScheme.primary,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
          ),
        );
      } else {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: const Text('Ошибка при сохранении PDF файла'),
            backgroundColor: theme.colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text('Ошибка при экспорте: $e'),
          backgroundColor: theme.colorScheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}
