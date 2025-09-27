import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:projectgt/presentation/widgets/app_bar_widget.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:projectgt/core/di/providers.dart';
import 'package:projectgt/presentation/widgets/app_drawer.dart';
import 'package:projectgt/core/utils/formatters.dart';
import '../../data/models/material_item.dart';
import '../widgets/materials_search.dart';
import '../widgets/materials_date_filter.dart';
import '../widgets/materials_import_action.dart';
import '../widgets/materials_mapping_action.dart';
import '../widgets/contracts_filter_chips.dart';
import '../providers/materials_pager.dart';
import '../widgets/materials_export_action.dart';

/// Экран раздела «Материал».
///
/// Чистая страница с AppBar и подключённым боковым меню `AppDrawer`.
/// Используется минимальная разметка без дополнительного контента по требованию.
class MaterialScreen extends ConsumerWidget {
  /// Создаёт экран «Материал».
  const MaterialScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: const AppBarWidget(
        title: 'Материал по М-15',
        showSearchField: false,
        actions: [
          MaterialsMappingAction(),
          MaterialsSearchAction(scope: 'materials'),
          MaterialsDateRangeAction(),
          MaterialsExportAction(),
          MaterialsImportAction(),
          SizedBox(width: 8),
          ContractsFilterChips(),
          SizedBox(width: 8),
        ],
      ),
      drawer: const AppDrawer(activeRoute: AppRoute.material),
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
                // final maxW = constraints.maxWidth; // не требуется для автоширины сейчас
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

                // Автоподгонка ширины: остаток идёт в колонку «Наименование материала» через Flex.

                // Инициализация пагинатора при первом билде
                final pager = ref.watch(materialsPagerProvider);

                List<TableRow> buildRows(List items) {
                  final list = <TableRow>[];
                  // Header
                  list.add(TableRow(
                    decoration: BoxDecoration(
                      color: headerBackgroundColor,
                    ),
                    children: [
                      headerCell('№', align: TextAlign.center),
                      headerCell('Наименование материала',
                          align: TextAlign.center),
                      headerCell('Ед. изм.', align: TextAlign.center),
                      headerCell('Кол-во', align: TextAlign.center),
                      headerCell('Цена за ед.', align: TextAlign.center),
                      headerCell('Стоимость', align: TextAlign.center),
                      headerCell('№ накладной', align: TextAlign.center),
                      headerCell('Дата', align: TextAlign.center),
                      headerCell('Использовано', align: TextAlign.center),
                      headerCell('Остаток', align: TextAlign.center),
                      headerCell('Файл', align: TextAlign.center),
                    ],
                  ));

                  // Поиск и фильтр дат применяем к уже загруженным записям
                  final q =
                      ref.watch(materialsSearchQueryProvider('materials'));
                  var filtered = filterMaterials(items.cast<MaterialItem>(), q);
                  final range = ref.watch(materialsDateRangeProvider);
                  if (range != null) {
                    final start = DateTime(
                        range.start.year, range.start.month, range.start.day);
                    final end = DateTime(
                        range.end.year, range.end.month, range.end.day);
                    bool inRange(DateTime? d) {
                      if (d == null) return false;
                      final dd = DateTime(d.year, d.month, d.day);
                      final afterStart =
                          dd.isAtSameMomentAs(start) || dd.isAfter(start);
                      final beforeEnd =
                          dd.isAtSameMomentAs(end) || dd.isBefore(end);
                      return afterStart && beforeEnd;
                    }

                    filtered =
                        filtered.where((m) => inRange(m.receiptDate)).toList();
                  }

                  int idx = 0;
                  for (final m in filtered) {
                    idx += 1;
                    final r = m.remaining;
                    Color? rowColor;
                    if (r != null) {
                      if (r < 0) {
                        rowColor = Colors.red;
                      } else if (r == 0) {
                        rowColor = Colors.green;
                      }
                    }
                    Widget c(Widget ch, {Alignment a = Alignment.centerLeft}) =>
                        bodyCell(ch, align: a, color: rowColor);
                    list.add(TableRow(children: [
                      c(Text(idx.toString()), a: Alignment.center),
                      c(Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if ((m.remaining ?? 0) < 0)
                            const Padding(
                              padding: EdgeInsets.only(right: 6),
                              child: _RotatingWarningIcon(size: 24),
                            ),
                          Flexible(child: Text(m.name)),
                        ],
                      )),
                      c(Text(m.unit ?? '—'), a: Alignment.center),
                      c(Text(m.quantity?.toString() ?? '—'),
                          a: Alignment.center),
                      c(Text(m.price != null ? formatCurrency(m.price!) : '—'),
                          a: Alignment.centerRight),
                      c(Text(m.total != null ? formatCurrency(m.total!) : '—'),
                          a: Alignment.centerRight),
                      c(Text(m.receiptNumber ?? '—'), a: Alignment.center),
                      c(
                          Text(m.receiptDate != null
                              ? formatRuDate(m.receiptDate!)
                              : '—'),
                          a: Alignment.center),
                      c(Text(m.used?.toString() ?? '—'), a: Alignment.center),
                      c(Text(m.remaining?.toString() ?? '—'),
                          a: Alignment.center),
                      c(
                          m.fileUrl != null && m.fileUrl!.trim().isNotEmpty
                              ? _HoverScaleIcon(
                                  onTap: () async {
                                    final confirmed =
                                        await showCupertinoDialog<bool>(
                                      context: context,
                                      builder: (ctx) => CupertinoAlertDialog(
                                        title: const Text('Скачать файл?'),
                                        content: Text(
                                            'Будет загружена накладная № ${m.receiptNumber ?? '—'}'),
                                        actions: [
                                          CupertinoDialogAction(
                                            onPressed: () =>
                                                Navigator.of(ctx).pop(false),
                                            child: const Text('Отмена'),
                                          ),
                                          CupertinoDialogAction(
                                            isDefaultAction: true,
                                            onPressed: () =>
                                                Navigator.of(ctx).pop(true),
                                            child: const Text('Скачать'),
                                          ),
                                        ],
                                      ),
                                    );
                                    // Обрабатываем результаты действий
                                    if (confirmed != true) return;
                                    final client =
                                        ref.read(supabaseClientProvider);
                                    try {
                                      final signed = await client.storage
                                          .from('receipts')
                                          .createSignedUrl(m.fileUrl!, 60);
                                      final uri = Uri.tryParse(signed);
                                      if (uri != null) {
                                        await launchUrl(uri,
                                            mode:
                                                LaunchMode.externalApplication);
                                      }
                                    } catch (_) {}
                                  },
                                  child: const Icon(
                                    Icons.table_view_rounded,
                                    size: 18,
                                    color: Colors.green,
                                  ),
                                )
                              : const Text('—'),
                          a: Alignment.center),
                    ]));
                  }

                  return list;
                }

                return NotificationListener<ScrollNotification>(
                  onNotification: (n) {
                    if (n.metrics.pixels >= n.metrics.maxScrollExtent - 200) {
                      ref.read(materialsPagerProvider.notifier).loadMore();
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
                          4: IntrinsicColumnWidth(),
                          5: IntrinsicColumnWidth(),
                          6: IntrinsicColumnWidth(),
                          7: IntrinsicColumnWidth(),
                          8: IntrinsicColumnWidth(),
                          9: IntrinsicColumnWidth(),
                          10: IntrinsicColumnWidth(),
                        },
                        children: pager.when(
                          loading: () => [
                            TableRow(
                                children: List.generate(
                                    11,
                                    (i) => bodyCell(const Text('...'),
                                        align: Alignment.center))),
                          ],
                          error: (e, _) => [
                            TableRow(children: [
                              bodyCell(Text('Ошибка: $e'),
                                  align: Alignment.center),
                              bodyCell(const Text('Нет данных')),
                              ...List.generate(
                                  9,
                                  (_) => bodyCell(const Text('—'),
                                      align: Alignment.center)),
                            ]),
                          ],
                          data: (items) => buildRows(items),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

// Удалены дублирующие приватные чипы — используется общий ContractsFilterChips

class _RotatingWarningIcon extends StatefulWidget {
  final double size;
  const _RotatingWarningIcon({required this.size});

  @override
  State<_RotatingWarningIcon> createState() => _RotatingWarningIconState();
}

class _RotatingWarningIconState extends State<_RotatingWarningIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RotationTransition(
      turns: _controller,
      child: Icon(
        Icons.warning_amber_rounded,
        size: widget.size,
        color: Colors.red,
      ),
    );
  }
}

class _HoverScaleIcon extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  const _HoverScaleIcon({required this.child, required this.onTap});

  @override
  State<_HoverScaleIcon> createState() => _HoverScaleIconState();
}

class _HoverScaleIconState extends State<_HoverScaleIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
      lowerBound: 0,
      upperBound: 1,
    );
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scale = Tween<double>(begin: 1.0, end: 1.12).animate(
      CurvedAnimation(parent: _c, curve: Curves.easeOut),
    );
    return MouseRegion(
      onEnter: (_) => _c.forward(),
      onExit: (_) => _c.reverse(),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedBuilder(
          animation: _c,
          builder: (context, _) => Transform.scale(
            scale: scale.value,
            child: widget.child,
          ),
        ),
      ),
    );
  }
}
