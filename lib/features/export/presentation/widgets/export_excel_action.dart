import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/export_provider.dart';

/// Кнопка экспорта текущих отчётов в Excel (в AppBar)
class ExportExcelAction extends ConsumerWidget {
  const ExportExcelAction({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(exportProvider);
    final isExporting = state.isExporting;
    final hasData = state.reports.isNotEmpty;

    // Настройки по умолчанию и ключи
    const prefsColumnsKey = 'export_columns_v1';
    const prefsAggregateKey = 'export_aggregate_v1';
    const availableColumns = <MapEntry<String, String>>[
      MapEntry('date', 'Дата смены'),
      MapEntry('object', 'Объект'),
      MapEntry('contract', 'Договор'),
      MapEntry('system', 'Система'),
      MapEntry('subsystem', 'Подсистема'),
      MapEntry('position', '№ позиции'),
      MapEntry('work', 'Наименование работы'),
      MapEntry('section', 'Секция'),
      MapEntry('floor', 'Этаж'),
      MapEntry('unit', 'Единица измерения'),
      MapEntry('quantity', 'Количество'),
      MapEntry('price', 'Цена за единицу'),
      MapEntry('total', 'Итоговая сумма'),
    ];

    Future<void> _export(
        {List<String>? columns, bool aggregate = false}) async {
      final scaffoldMessenger = ScaffoldMessenger.of(context);
      final theme = Theme.of(context);
      // Дефолтное имя файла на основе данных
      String baseName;
      if (state.reports.isEmpty) {
        baseName = 'Отчет';
      } else {
        final objects = state.reports.map((e) => e.objectName).toSet();
        baseName = objects.length == 1 ? objects.first : 'Сводный отчет';
      }
      final dateStr =
          '${DateTime.now().day.toString().padLeft(2, '0')}.${DateTime.now().month.toString().padLeft(2, '0')}.${DateTime.now().year}';
      final fileName = '$baseName $dateStr.xlsx';

      final filePath = await ref.read(exportProvider.notifier).exportToExcel(
            fileName,
            columns: columns,
            aggregate: aggregate,
            sheetName: null,
          );

      if (!context.mounted) return;
      if (filePath != null) {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('Файл успешно сохранен: $filePath'),
            backgroundColor: theme.colorScheme.primary,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        final error = ref.read(exportProvider).error;
        if (error != null) {
          scaffoldMessenger.showSnackBar(
            SnackBar(
              content: Text(error),
              backgroundColor: theme.colorScheme.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }

    Future<void> _openExportDialog() async {
      final prefs = await SharedPreferences.getInstance();
      const removedKeys = {'employee', 'hours', 'materials'};
      final savedColumns = prefs
          .getStringList(prefsColumnsKey)
          ?.where((k) => !removedKeys.contains(k))
          .toSet();
      final savedAggregate = prefs.getBool(prefsAggregateKey) ?? false;

      final Set<String> selected =
          (savedColumns ?? availableColumns.map((e) => e.key).toSet()).toSet();
      bool aggregate = savedAggregate;

      if (!context.mounted) return;
      await showDialog<void>(
        context: context,
        builder: (context) {
          return StatefulBuilder(
            builder: (context, setState) {
              return AlertDialog(
                title: const Text('Экспорт в Excel'),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Выберите колонки:'),
                      const SizedBox(height: 8),
                      ...availableColumns.map((entry) => CheckboxListTile(
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            title: Text(entry.value),
                            value: selected.contains(entry.key),
                            onChanged: (val) {
                              setState(() {
                                if (val == true) {
                                  selected.add(entry.key);
                                } else {
                                  if (selected.length > 1) {
                                    selected.remove(entry.key);
                                  }
                                }
                              });
                            },
                          )),
                      const Divider(height: 16),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Объединять одинаковые позиции'),
                        value: aggregate,
                        onChanged: (val) => setState(() => aggregate = val),
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Отмена'),
                  ),
                  FilledButton(
                    onPressed: () async {
                      // Санитизируем выбранные колонки от удалённых ключей
                      final filtered = selected
                          .where((k) => !removedKeys.contains(k))
                          .toList();
                      await prefs.setStringList(prefsColumnsKey, filtered);
                      await prefs.setBool(prefsAggregateKey, aggregate);
                      if (!context.mounted) return;
                      Navigator.of(context).pop();
                      await _export(
                        columns: filtered,
                        aggregate: aggregate,
                      );
                    },
                    child: const Text('Экспорт'),
                  ),
                ],
              );
            },
          );
        },
      );
    }

    return IconButton(
      tooltip: 'Экспорт в Excel',
      onPressed: hasData && !isExporting ? _openExportDialog : null,
      icon: isExporting
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.file_download),
    );
  }
}
