import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:projectgt/presentation/widgets/app_bar_widget.dart';
import '../providers/materials_mapping_providers.dart';
import '../widgets/materials_search.dart';
import '../widgets/materials_link_button.dart';
import 'package:projectgt/core/di/providers.dart';
import '../widgets/contracts_filter_chips.dart';

/// Экран "Сопоставление материалов" (алиасы накладных → сметные позиции).
///
/// MVP: верстка таблицы. Логика и данные будут добавлены отдельной задачей.
class MaterialsMappingScreen extends ConsumerWidget {
  /// Конструктор экрана сопоставления материалов.
  const MaterialsMappingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: const AppBarWidget(
        title: 'Сопоставление материалов',
        showSearchField: false,
        leading: BackButton(),
        actions: [
          MaterialsSearchAction(scope: 'mapping'),
          SizedBox(width: 8),
          ContractsFilterChips(),
          SizedBox(width: 8)
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: theme.colorScheme.outline.withValues(alpha: 0.2),
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final dividerColor =
                    theme.colorScheme.outline.withValues(alpha: 0.18);
                final headerBackgroundColor =
                    theme.brightness == Brightness.dark
                        ? Colors.white.withValues(alpha: 0.06)
                        : Colors.black.withValues(alpha: 0.06);

                Widget headerCell(String text,
                    {double? minWidth, TextAlign align = TextAlign.left}) {
                  Alignment headerAlignment;
                  switch (align) {
                    case TextAlign.center:
                      headerAlignment = Alignment.center;
                      break;
                    case TextAlign.right:
                      headerAlignment = Alignment.centerRight;
                      break;
                    default:
                      headerAlignment = Alignment.centerLeft;
                  }
                  return Container(
                    constraints: BoxConstraints(minWidth: minWidth ?? 0),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                    alignment: headerAlignment,
                    child: Text(text,
                        textAlign: align,
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: theme.colorScheme.onSurface,
                          fontWeight: FontWeight.w600,
                        )),
                  );
                }

                Widget bodyCell(Widget child,
                    {Alignment align = Alignment.centerLeft, Color? color}) {
                  return Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                    alignment: align,
                    child: DefaultTextStyle(
                      style: theme.textTheme.bodyMedium!.copyWith(
                          color: color ?? theme.colorScheme.onSurface),
                      child: child,
                    ),
                  );
                }

                // Инициализация pager на первом билде, пересоздаётся при смене договора
                ref.read(estimatesMappingPagerProvider.notifier).loadInitial();
                final pager = ref.watch(estimatesMappingPagerProvider);

                return pager.when(
                  loading: () => const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                  error: (e, _) => Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text('Ошибка загрузки: $e'),
                    ),
                  ),
                  data: (rows) {
                    // Поиск выполняется на сервере. Локальной фильтрации нет.
                    final expanded = ref.watch(expandedEstimatesProvider);

                    List<TableRow> buildRows() {
                      final list = <TableRow>[];
                      // header
                      list.add(TableRow(
                        decoration: BoxDecoration(color: headerBackgroundColor),
                        children: [
                          headerCell('№', align: TextAlign.center),
                          headerCell('Наименование', align: TextAlign.center),
                          headerCell('Ед. изм.', align: TextAlign.center),
                          headerCell('Связь', align: TextAlign.center),
                        ],
                      ));

                      if (rows.isEmpty) {
                        list.add(TableRow(children: [
                          bodyCell(const Text('—'), align: Alignment.center),
                          bodyCell(const Text('Нет данных')),
                          bodyCell(const Text('—'), align: Alignment.center),
                          bodyCell(const Text('—'), align: Alignment.center),
                        ]));
                        return list;
                      }

                      void toggle(String id) {
                        final notifier =
                            ref.read(expandedEstimatesProvider.notifier);
                        final current = notifier.state;
                        final next = {...current};
                        if (next.contains(id)) {
                          next.remove(id);
                        } else {
                          next.add(id);
                        }
                        notifier.state = next;
                      }

                      final client = ref.read(supabaseClientProvider);

                      Future<void> unlinkWithConfirm(
                          {required String aliasId,
                          required String estimateRowId}) async {
                        final confirmed = await showCupertinoDialog<bool>(
                          context: context,
                          builder: (ctx) => CupertinoAlertDialog(
                            title: const Text('Удалить связь?'),
                            content: const Text(
                                'Вы уверены, что хотите отвязать этот материал?'),
                            actions: [
                              CupertinoDialogAction(
                                onPressed: () => Navigator.of(ctx).pop(false),
                                child: const Text('Отмена'),
                              ),
                              CupertinoDialogAction(
                                isDestructiveAction: true,
                                onPressed: () => Navigator.of(ctx).pop(true),
                                child: const Text('Удалить'),
                              ),
                            ],
                          ),
                        );
                        if (confirmed != true) return;
                        try {
                          await client
                              .from('material_aliases')
                              .delete()
                              .eq('id', aliasId);
                          // сбрасываем раскрытие строки
                          final exp =
                              ref.read(expandedEstimatesProvider.notifier);
                          final s = {...exp.state};
                          s.remove(estimateRowId);
                          exp.state = s;
                          // обновляем данные
                          ref
                              .read(estimatesMappingPagerProvider.notifier)
                              .refresh();
                        } catch (_) {}
                      }

                      for (final r in rows) {
                        final isExpanded = expanded.contains(r.id);
                        final Color? parentBg = isExpanded
                            ? Colors.green.withValues(alpha: 0.12)
                            : null;
                        final Color childBg =
                            Colors.green.withValues(alpha: 0.06);
                        final parentTextStyle =
                            theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        );
                        final childTextStyle =
                            theme.textTheme.bodyMedium?.copyWith(
                          fontStyle: FontStyle.italic,
                        );

                        list.add(TableRow(
                          decoration: parentBg != null
                              ? BoxDecoration(color: parentBg)
                              : null,
                          children: [
                            GestureDetector(
                              onTap: r.aliases.isNotEmpty
                                  ? () => toggle(r.id)
                                  : null,
                              child: bodyCell(
                                Text(
                                  r.number.isEmpty ? '—' : r.number,
                                  style: isExpanded ? parentTextStyle : null,
                                ),
                                align: Alignment.center,
                              ),
                            ),
                            GestureDetector(
                              onTap: r.aliases.isNotEmpty
                                  ? () => toggle(r.id)
                                  : null,
                              child: bodyCell(
                                Text(r.name,
                                    style: isExpanded ? parentTextStyle : null),
                              ),
                            ),
                            GestureDetector(
                              onTap: r.aliases.isNotEmpty
                                  ? () => toggle(r.id)
                                  : null,
                              child: bodyCell(
                                  Text(r.unit,
                                      style:
                                          isExpanded ? parentTextStyle : null),
                                  align: Alignment.center),
                            ),
                            bodyCell(
                              MaterialsLinkButton(
                                estimateId: r.id,
                                aliasCount: r.aliasCount,
                              ),
                              align: Alignment.center,
                            ),
                          ],
                        ));

                        if (isExpanded && r.aliases.isNotEmpty) {
                          for (final a in r.aliases) {
                            list.add(TableRow(children: [
                              const SizedBox.shrink(),
                              Container(
                                color: childBg,
                                padding: const EdgeInsets.symmetric(
                                    vertical: 6, horizontal: 8),
                                child: Text(a.aliasRaw, style: childTextStyle),
                              ),
                              Container(
                                color: childBg,
                                padding: const EdgeInsets.symmetric(
                                    vertical: 6, horizontal: 8),
                                child: Text(
                                  a.uomRaw ?? '—',
                                  textAlign: TextAlign.center,
                                  style: childTextStyle,
                                ),
                              ),
                              // Колонка «Связь»: жёлтая кнопка минус (unlink)
                              Container(
                                color: childBg,
                                alignment: Alignment.center,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 4),
                                child: CupertinoButton(
                                  padding: EdgeInsets.zero,
                                  onPressed: () => unlinkWithConfirm(
                                      aliasId: a.id, estimateRowId: r.id),
                                  minimumSize: const Size(0, 0),
                                  child: Container(
                                    width: 18,
                                    height: 18,
                                    decoration: const BoxDecoration(
                                      color: Colors.amber,
                                      shape: BoxShape.circle,
                                    ),
                                    alignment: Alignment.center,
                                    child: const Icon(
                                      Icons.remove,
                                      size: 12,
                                      color: Colors.black,
                                    ),
                                  ),
                                ),
                              ),
                            ]));
                          }
                        }
                      }
                      return list;
                    }

                    return NotificationListener<ScrollNotification>(
                      onNotification: (n) {
                        if (n.metrics.pixels >=
                            n.metrics.maxScrollExtent - 200) {
                          ref
                              .read(estimatesMappingPagerProvider.notifier)
                              .loadMore();
                        }
                        return false;
                      },
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(12.0),
                        child: SizedBox(
                          width: constraints.maxWidth,
                          child: Table(
                            border: TableBorder(
                              top: BorderSide(color: dividerColor, width: 1),
                              bottom: BorderSide(color: dividerColor, width: 1),
                              left: BorderSide(color: dividerColor, width: 1),
                              right: BorderSide(color: dividerColor, width: 1),
                              horizontalInside:
                                  BorderSide(color: dividerColor, width: 1),
                              verticalInside:
                                  BorderSide(color: dividerColor, width: 1),
                            ),
                            defaultVerticalAlignment:
                                TableCellVerticalAlignment.middle,
                            columnWidths: const <int, TableColumnWidth>{
                              0: IntrinsicColumnWidth(),
                              1: FlexColumnWidth(1),
                              2: IntrinsicColumnWidth(),
                              3: IntrinsicColumnWidth(),
                            },
                            children: buildRows(),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
