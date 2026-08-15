import 'dart:typed_data';

import 'package:file_saver/file_saver.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:projectgt/core/widgets/app_snackbar.dart';
import 'package:projectgt/features/roles/application/permission_service.dart';
import 'package:projectgt/features/tmc/presentation/services/tmc_excel_export_service.dart';
import 'package:projectgt/features/tmc/presentation/state/tmc_providers.dart';
import 'package:projectgt/features/tmc/presentation/utils/tmc_ui_labels.dart';

/// Отчёты ТМЦ с экспортом в Excel.
class TmcReportsPanel extends ConsumerWidget {
  /// Создаёт панель отчётов.
  const TmcReportsPanel({super.key});

  Future<void> _export(
    BuildContext context,
    WidgetRef ref, {
    required String title,
    required String reportKey,
  }) async {
    final permissions = ref.read(permissionServiceProvider);
    if (!permissions.can('tmc', 'export')) {
      AppSnackBar.show(
        context: context,
        message: 'Недостаточно прав для экспорта',
        kind: AppSnackBarKind.error,
      );
      return;
    }

    final includeCost = permissions.can('tmc', 'view_cost');
    const exporter = TmcExcelExportService();
    final repo = ref.read(tmcRepositoryProvider);

    try {
      late final Uint8List bytes;
      switch (reportKey) {
        case 'write_offs':
          bytes = exporter.exportWriteOffs(
            await repo.listWriteOffs(limit: 5000),
          );
        case 'operations':
          bytes = exporter.exportOperations(
            await repo.listOperations(limit: 5000),
          );
        case 'repair':
          bytes = exporter.exportUnits(
            await repo.listUnits(status: 'in_repair'),
            includeCost: includeCost,
          );
        case 'employees':
          bytes = exporter.exportUnits(
            await repo.listUnits(status: 'issued'),
            includeCost: includeCost,
          );
        case 'objects':
          bytes = exporter.exportUnits(
            await repo.listUnits(status: 'on_object'),
            includeCost: includeCost,
          );
        case 'balances':
          bytes = exporter.exportUnits(
            await repo.listUnits(status: 'in_stock'),
            includeCost: includeCost,
          );
        case 'catalog':
          final page = await repo.listItems(limit: 5000, offset: 0);
          bytes = exporter.exportItems(page.items, includeCost: includeCost);
        default:
          throw StateError('Неизвестный отчёт: $reportKey');
      }

      await FileSaver.instance.saveFile(
        name: 'tmc_$reportKey',
        bytes: bytes,
        ext: 'xlsx',
        mimeType: MimeType.microsoftExcel,
      );

      if (!context.mounted) return;
      AppSnackBar.show(
        context: context,
        message: 'Файл «$title» сохранён',
        kind: AppSnackBarKind.success,
      );
    } catch (e) {
      if (!context.mounted) return;
      AppSnackBar.show(
        context: context,
        message: 'Ошибка экспорта: $e',
        kind: AppSnackBarKind.error,
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const reports = <({String key, String title, String hint})>[
      (
        key: 'balances',
        title: 'Единицы на складе',
        hint: 'Индивидуальные единицы со статусом «На складе»',
      ),
      (
        key: 'objects',
        title: 'Единицы на объектах',
        hint: 'Индивидуальные единицы со статусом «На объекте»',
      ),
      (
        key: 'employees',
        title: 'Единицы у сотрудников',
        hint: 'Индивидуальные единицы со статусом «Выдано»',
      ),
      (
        key: 'repair',
        title: TmcUiLabels.reportInRepair,
        hint: 'Единицы в ремонте',
      ),
      (
        key: 'write_offs',
        title: TmcUiLabels.reportWriteOffs,
        hint: 'Журнал списаний',
      ),
      (key: 'operations', title: 'История движения', hint: 'Журнал операций'),
      (key: 'catalog', title: 'Реестр позиций', hint: 'Каталог ТМЦ'),
    ];

    return ListView.separated(
      itemCount: reports.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final report = reports[index];
        return ListTile(
          title: Text(report.title),
          subtitle: Text(report.hint),
          trailing: const Icon(Icons.download_outlined),
          onTap: () =>
              _export(context, ref, title: report.title, reportKey: report.key),
        );
      },
    );
  }
}
