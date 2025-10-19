import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/export_provider.dart';

/// Кнопка экспорта текущих отчётов в Excel (в AppBar).
///
/// Открывает диалог выбора колонок и опции агрегации, затем формирует
/// и сохраняет Excel-файл с данными текущего отчёта.
class ExportExcelAction extends ConsumerWidget {
  /// Создаёт кнопку экспорта в Excel на панели действий.
  const ExportExcelAction({super.key});

  @override

  /// Строит кнопку и обрабатывает открытие диалога настроек экспорта,
  /// включая выбор колонок и опцию агрегации данных.
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(exportProvider);
    final isExporting = state.isExporting;
    final hasData = state.reports.isNotEmpty;

    // Настройки по умолчанию и ключи
    // v2 - новый порядок колонок без даты (09.10.2025)
    const prefsColumnsKey = 'export_columns_v2';
    const prefsAggregateKey = 'export_aggregate_v2';
    const availableColumns = <MapEntry<String, String>>[
      MapEntry('object', 'Объект'),
      MapEntry('contract', 'Договор'),
      MapEntry('system', 'Система'),
      MapEntry('subsystem', 'Подсистема'),
      MapEntry('section', 'Участок'),
      MapEntry('floor', 'Этаж'),
      MapEntry('position', '№ позиции'),
      MapEntry('work', 'Наименование работы'),
      MapEntry('unit', 'Ед. изм.'),
      MapEntry('quantity', 'Кол-во'),
      MapEntry('price', 'Цена за единицу'),
      MapEntry('total', 'Сумма'),
    ];

    Future<void> doExport(
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
            state.reports,
            fileName,
            columns: columns,
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

    Future<void> openExportDialog() async {
      final prefs = await SharedPreferences.getInstance();
      const removedKeys = {'employee', 'hours', 'materials', 'date'};
      final savedColumns = prefs
          .getStringList(prefsColumnsKey)
          ?.where((k) => !removedKeys.contains(k))
          .toSet();
      final savedAggregate = prefs.getBool(prefsAggregateKey) ?? false;

      final Set<String> selected =
          (savedColumns ?? availableColumns.map((e) => e.key).toSet()).toSet();
      bool aggregate = savedAggregate;

      if (!context.mounted) return;
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        useSafeArea: true,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height -
              MediaQuery.of(context).padding.top,
        ),
        builder: (context) {
          final isDesktop = MediaQuery.of(context).size.width > 800;
          final theme = Theme.of(context);

          Widget modalContent = Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(28)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: DraggableScrollableSheet(
              initialChildSize: 0.75,
              minChildSize: 0.6,
              maxChildSize: 0.95,
              expand: false,
              builder: (context, scrollController) => SingleChildScrollView(
                controller: scrollController,
                child: Padding(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).viewInsets.bottom,
                  ),
                  child: StatefulBuilder(
                    builder: (context, setState) => Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Заголовок с иконкой
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primaryContainer,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Icons.download_rounded,
                                  color: theme.colorScheme.onPrimaryContainer,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Экспорт в Excel',
                                      style: theme.textTheme.headlineSmall
                                          ?.copyWith(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    Text(
                                      '${state.reports.length} записей',
                                      style:
                                          theme.textTheme.bodySmall?.copyWith(
                                        color: theme.colorScheme.onSurface
                                            .withValues(alpha: 0.6),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Контент в Flexible
                        Flexible(
                          child: SingleChildScrollView(
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 20),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Секция 1: Колонки
                                  Text(
                                    'Выберите колонки для выгрузки',
                                    style:
                                        theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Выбрано: ${selected.length} из ${availableColumns.length}',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurface
                                          .withValues(alpha: 0.5),
                                    ),
                                  ),
                                  const SizedBox(height: 12),

                                  // Контейнер с колонками
                                  Container(
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: theme.colorScheme.outline
                                            .withValues(alpha: 0.2),
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                      color:
                                          theme.colorScheme.surfaceContainerLow,
                                    ),
                                    child: Column(
                                      children: availableColumns
                                          .asMap()
                                          .entries
                                          .map((e) {
                                        final isLast = e.key ==
                                            availableColumns.length - 1;
                                        return Column(
                                          children: [
                                            CheckboxListTile(
                                              dense: false,
                                              visualDensity:
                                                  VisualDensity.compact,
                                              contentPadding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 16,
                                                vertical: 4,
                                              ),
                                              title: Text(
                                                e.value.value,
                                                style:
                                                    theme.textTheme.bodyMedium,
                                              ),
                                              value: selected
                                                  .contains(e.value.key),
                                              onChanged: (val) {
                                                setState(() {
                                                  if (val == true) {
                                                    selected.add(e.value.key);
                                                  } else {
                                                    if (selected.length > 1) {
                                                      selected
                                                          .remove(e.value.key);
                                                    }
                                                  }
                                                });
                                              },
                                            ),
                                            if (!isLast)
                                              Divider(
                                                height: 1,
                                                color: theme.colorScheme.outline
                                                    .withValues(alpha: 0.12),
                                              ),
                                          ],
                                        );
                                      }).toList(),
                                    ),
                                  ),
                                  const SizedBox(height: 20),

                                  // Секция 2: Опции
                                  Text(
                                    'Параметры выгрузки',
                                    style:
                                        theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 12),

                                  Container(
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: theme.colorScheme.outline
                                            .withValues(alpha: 0.2),
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                      color:
                                          theme.colorScheme.surfaceContainerLow,
                                    ),
                                    child: SwitchListTile(
                                      dense: false,
                                      visualDensity: VisualDensity.compact,
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 8,
                                      ),
                                      title: Text(
                                        'Объединять одинаковые позиции',
                                        style: theme.textTheme.bodyMedium,
                                      ),
                                      subtitle: Text(
                                        'Группирует записи по основным полям',
                                        style:
                                            theme.textTheme.bodySmall?.copyWith(
                                          color: theme.colorScheme.onSurface
                                              .withValues(alpha: 0.5),
                                        ),
                                      ),
                                      value: aggregate,
                                      onChanged: (val) =>
                                          setState(() => aggregate = val),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Кнопки
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              FilledButton.icon(
                                onPressed: () async {
                                  final filtered = selected
                                      .where((k) => !{
                                            'employee',
                                            'hours',
                                            'materials',
                                            'date'
                                          }.contains(k))
                                      .toList();
                                  await prefs.setStringList(
                                      prefsColumnsKey, filtered);
                                  await prefs.setBool(
                                      prefsAggregateKey, aggregate);
                                  if (!context.mounted) return;
                                  Navigator.of(context).pop();
                                  await doExport(
                                    columns: filtered,
                                    aggregate: aggregate,
                                  );
                                },
                                icon: const Icon(Icons.download_rounded),
                                label: const Text('Экспорт'),
                                style: FilledButton.styleFrom(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 14),
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(),
                                style: TextButton.styleFrom(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 14),
                                ),
                                child: const Text('Отмена'),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );

          // Для десктопа — ограничиваем ширину 50%
          if (isDesktop) {
            modalContent = Align(
              alignment: Alignment.bottomCenter,
              child: SizedBox(
                width: MediaQuery.of(context).size.width * 0.5,
                child: modalContent,
              ),
            );
          }

          return modalContent;
        },
      );
    }

    return IconButton(
      tooltip: 'Экспорт в Excel',
      onPressed: hasData && !isExporting ? openExportDialog : null,
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
