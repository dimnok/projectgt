import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_saver/file_saver.dart';
import 'package:projectgt/core/utils/snackbar_utils.dart';
import 'package:projectgt/features/export/data/repositories/vor_repository_impl.dart';
import 'package:projectgt/features/export/presentation/widgets/export_search_action.dart';
import 'package:projectgt/features/export/presentation/providers/work_search_date_provider.dart';

/// Формат файла для скачивания ВОР.
enum VorFormat {
  /// Excel таблица.
  xlsx,

  /// PDF документ.
  pdf,
}

/// Виджет действий для скачивания отчета ВОР (Ведомость Объемов Работ).
///
/// Отображает кнопки для скачивания отчета в форматах PDF и Excel.
/// При нажатии проверяет выбран ли период, и если нет - предлагает выбрать.
class VorDownloadAction extends ConsumerWidget {
  /// Создает виджет действий для скачивания ВОР.
  const VorDownloadAction({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final objectId = ref.watch(exportSelectedObjectIdProvider);
    final isEnabled = objectId != null;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.picture_as_pdf_rounded),
          tooltip: 'Скачать ВОР (PDF)',
          onPressed: isEnabled
              ? () => _handleDownload(context, ref, objectId, VorFormat.pdf)
              : null,
        ),
        IconButton(
          icon: const Icon(Icons.receipt_long_rounded),
          tooltip: 'Скачать ВОР (Excel)',
          onPressed: isEnabled
              ? () => _handleDownload(context, ref, objectId, VorFormat.xlsx)
              : null,
        ),
      ],
    );
  }

  Future<void> _handleDownload(BuildContext context, WidgetRef ref,
      String objectId, VorFormat format) async {
    final dateRange = ref.read(workSearchDateRangeProvider);

    if (dateRange != null) {
      await _downloadReport(
          context, ref, objectId, dateRange.start, dateRange.end, format);
    } else {
      await _showDateRangeDialog(context, ref, objectId, format);
    }
  }

  Future<void> _showDateRangeDialog(BuildContext context, WidgetRef ref,
      String objectId, VorFormat format) async {
    final dateRange = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      helpText: 'Выберите период для ВОР',
      cancelText: 'Отмена',
      confirmText: 'Скачать',
      saveText: 'СКАЧАТЬ',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            datePickerTheme: DatePickerThemeData(
              headerBackgroundColor: Theme.of(context).colorScheme.primary,
              headerForegroundColor: Theme.of(context).colorScheme.onPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (dateRange == null) return;

    if (!context.mounted) return;

    await _downloadReport(
        context, ref, objectId, dateRange.start, dateRange.end, format);
  }

  Future<void> _downloadReport(BuildContext context, WidgetRef ref,
      String objectId, DateTime start, DateTime end, VorFormat format) async {
    try {
      final ext = format == VorFormat.xlsx ? 'xlsx' : 'pdf';
      SnackBarUtils.showInfo(context, 'Генерация ВОР ($ext)...');

      // Получаем текущие фильтры и поисковый запрос
      final filters = ref.read(exportSearchFilterProvider);
      final searchQuery = ref.read(exportSearchQueryProvider);

      final repository = ref.read(vorRepositoryProvider);
      final reportFuture = format == VorFormat.xlsx
          ? repository.downloadVorReport
          : repository.downloadVorPdfReport;

      final bytes = await reportFuture(
        objectId: objectId,
        dateFrom: start,
        dateTo: end,
        systemFilters: filters['system']?.toList(),
        sectionFilters: filters['section']?.toList(),
        floorFilters: filters['floor']?.toList(),
        searchQuery: searchQuery.trim().isNotEmpty ? searchQuery.trim() : null,
      );

      final mimeType =
          format == VorFormat.xlsx ? MimeType.microsoftExcel : MimeType.pdf;

      await FileSaver.instance.saveFile(
        name: 'VOR_${objectId}_${DateTime.now().millisecondsSinceEpoch}',
        bytes: bytes,
        ext: ext,
        mimeType: mimeType,
      );

      if (context.mounted) {
        SnackBarUtils.showSuccess(context, 'ВОР успешно сохранен');
      }
    } catch (e) {
      if (context.mounted) {
        SnackBarUtils.showError(context, 'Ошибка генерации ВОР: $e');
      }
    }
  }
}
