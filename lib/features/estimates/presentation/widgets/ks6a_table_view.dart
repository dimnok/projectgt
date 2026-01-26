import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/formatters.dart';
import '../../../../domain/entities/ks6a_period.dart' as entity;
import '../providers/estimate_providers.dart';
import '../utils/ks6a_processor.dart';

/// Виджет для отображения журнала КС-6а с поддержкой периодов и согласования.
///
/// Позволяет формировать новые отчетные периоды на основе ежедневных отчетов
/// и фиксировать их для отчетности.
class Ks6aTableView extends ConsumerStatefulWidget {
  /// Идентификатор договора.
  final String contractId;

  const Ks6aTableView({super.key, required this.contractId});

  @override
  ConsumerState<Ks6aTableView> createState() => _Ks6aTableViewState();
}

class _Ks6aTableViewState extends ConsumerState<Ks6aTableView> {
  /// Контроллер для вертикального скролла основной таблицы.
  final ScrollController _verticalController = ScrollController();

  /// Контроллер для вертикального скролла фиксированных колонок.
  final ScrollController _verticalFixedController = ScrollController();

  /// Контроллер для горизонтального скролла тела таблицы.
  final ScrollController _horizontalController = ScrollController();

  /// Контроллер для горизонтального скролла заголовка (синхронизирован с телом).
  final ScrollController _headerHorizontalController = ScrollController();

  bool _isSyncingVertical = false;
  bool _isSyncingHeader = false;

  @override
  void initState() {
    super.initState();
    _verticalController.addListener(_syncVerticalScroll);
    _verticalFixedController.addListener(_syncVerticalFixedScroll);
    _horizontalController.addListener(_syncHeaderScroll);
  }

  /// Синхронизирует вертикальный скролл фиксированной части с основной.
  void _syncVerticalScroll() {
    if (_isSyncingVertical || !_verticalFixedController.hasClients) return;
    _isSyncingVertical = true;
    _verticalFixedController.jumpTo(_verticalController.offset);
    _isSyncingVertical = false;
  }

  /// Синхронизирует вертикальный скролл основной части с фиксированной.
  void _syncVerticalFixedScroll() {
    if (_isSyncingVertical || !_verticalController.hasClients) return;
    _isSyncingVertical = true;
    _verticalController.jumpTo(_verticalFixedController.offset);
    _isSyncingVertical = false;
  }

  /// Синхронизирует горизонтальный скролл заголовка с телом таблицы.
  void _syncHeaderScroll() {
    if (_isSyncingHeader || !_headerHorizontalController.hasClients) return;
    _isSyncingHeader = true;
    _headerHorizontalController.jumpTo(_horizontalController.offset);
    _isSyncingHeader = false;
  }

  @override
  void dispose() {
    _verticalController.dispose();
    _verticalFixedController.dispose();
    _horizontalController.dispose();
    _headerHorizontalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dividerColor = theme.colorScheme.outline.withValues(alpha: 0.18);
    final headerColor = theme.brightness == Brightness.dark
        ? Colors.grey[800]!
        : Colors.grey[200]!;

    final estimatesAsync = ref.watch(
      contractEstimatesProvider(widget.contractId),
    );
    final ks6aDataAsync = ref.watch(ks6aDataProvider(widget.contractId));

    return ks6aDataAsync.when(
      data: (ks6aData) {
        return estimatesAsync.when(
          data: (estimates) {
            if (estimates.isEmpty) {
              return const Center(
                child: Text('По данному договору сметные позиции не найдены'),
              );
            }

            // Подготовка данных через процессор
            final rowViewModels = Ks6aTableProcessor.process(
              estimates: estimates,
              ks6aData: ks6aData,
            );

            const leftWidths = _Constants.leftWidths;
            const leftTotalWidth = _Constants.leftTotalWidth;

            final periodCount = ks6aData.periods.length;
            final rightWidths = {
              for (int i = 0; i < (periodCount + 1) * 2; i++)
                i: FixedColumnWidth(i % 2 == 0 ? 80 : 100),
            };
            final rightTotalWidth = (periodCount + 1) * (80 + 100);
            final totalTableWidth = leftTotalWidth + rightTotalWidth;

            return Container(
              decoration: BoxDecoration(
                border: Border.all(color: dividerColor),
              ),
              child: Stack(
                children: [
                  // --- ОСНОВНОЙ СЛОЙ (СКРОЛЛИРУЕМАЯ ЧАСТЬ) ---
                  Column(
                    children: [
                      _HeaderContainer(
                        color: headerColor,
                        controller: _headerHorizontalController,
                        child: _Ks6aHeader(
                          contractId: widget.contractId,
                          totalWidth: totalTableWidth,
                          dividerColor: dividerColor,
                          ks6aData: ks6aData,
                          leftWidths: leftWidths,
                          rightWidths: rightWidths,
                          isFixed: false,
                        ),
                      ),
                      Expanded(
                        child: Scrollbar(
                          controller: _verticalController,
                          thumbVisibility: true,
                          child: SingleChildScrollView(
                            controller: _verticalController,
                            physics: const ClampingScrollPhysics(),
                            child: Scrollbar(
                              controller: _horizontalController,
                              thumbVisibility: true,
                              notificationPredicate: (n) => n.depth == 1,
                              child: SingleChildScrollView(
                                controller: _horizontalController,
                                scrollDirection: Axis.horizontal,
                                physics: const ClampingScrollPhysics(),
                                child: SizedBox(
                                  width: totalTableWidth,
                                  child: _Ks6aBodyTable(
                                    contractId: widget.contractId,
                                    rows: rowViewModels,
                                    ks6aData: ks6aData,
                                    leftWidths: leftWidths,
                                    rightWidths: rightWidths,
                                    dividerColor: dividerColor,
                                    isFixed: false,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  // --- НАКЛАДНОЙ СЛОЙ (ФИКСИРОВАННЫЕ КОЛОНКИ СЛЕВА) ---
                  Positioned(
                    left: 0,
                    top: 0,
                    bottom: 0,
                    width: leftTotalWidth,
                    child: Container(
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        border: Border(
                          right: BorderSide(color: dividerColor),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: theme.shadowColor.withValues(
                              alpha: 0.1,
                            ),
                            blurRadius: 8,
                            offset: const Offset(2, 0),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          _HeaderContainer(
                            color: headerColor,
                            child: _Ks6aHeader(
                              contractId: widget.contractId,
                              totalWidth: totalTableWidth,
                              dividerColor: dividerColor,
                              ks6aData: ks6aData,
                              leftWidths: leftWidths,
                              rightWidths: rightWidths,
                              isFixed: true,
                            ),
                          ),
                          Expanded(
                            child: SingleChildScrollView(
                              controller: _verticalFixedController,
                              physics: const ClampingScrollPhysics(),
                              child: _Ks6aBodyTable(
                                contractId: widget.contractId,
                                rows: rowViewModels,
                                ks6aData: ks6aData,
                                leftWidths: leftWidths,
                                rightWidths: rightWidths,
                                dividerColor: dividerColor,
                                isFixed: true,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
          loading: () => const Center(child: CupertinoActivityIndicator()),
          error: (e, s) => Center(child: Text('Ошибка загрузки смет: $e')),
        );
      },
      loading: () => const Center(child: CupertinoActivityIndicator()),
      error: (e, s) => Center(child: Text('Ошибка загрузки данных КС-6а: $e')),
    );
  }
}

/// Обертка для заголовка таблицы с поддержкой горизонтальной синхронизации.
class _HeaderContainer extends StatelessWidget {
  /// Цвет фона заголовка.
  final Color color;

  /// Дочерний виджет (строка заголовка).
  final Widget child;

  /// Контроллер для синхронизации скролла с телом таблицы.
  final ScrollController? controller;

  const _HeaderContainer({
    required this.color,
    required this.child,
    this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color,
      ),
      child: SingleChildScrollView(
        controller: controller,
        physics: controller != null
            ? const NeverScrollableScrollPhysics()
            : null,
        scrollDirection: Axis.horizontal,
        child: child,
      ),
    );
  }
}

/// Компонент заголовка таблицы КС-6а.
/// Отображает базовые колонки сметы, периоды и накопительный итог.
class _Ks6aHeader extends ConsumerWidget {
  /// Идентификатор договора.
  final String contractId;

  /// Полная ширина заголовка.
  final double totalWidth;

  /// Цвет разделителей.
  final Color dividerColor;

  /// Данные по периодам.
  final entity.Ks6aContractData ks6aData;

  /// Ширины колонок левой части.
  final Map<int, TableColumnWidth> leftWidths;

  /// Ширины колонок правой части (периоды).
  final Map<int, TableColumnWidth> rightWidths;

  /// Флаг фиксированной части.
  final bool isFixed;

  const _Ks6aHeader({
    required this.contractId,
    required this.totalWidth,
    required this.dividerColor,
    required this.ks6aData,
    required this.leftWidths,
    required this.rightWidths,
    required this.isFixed,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final style = theme.textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.bold,
          fontSize: 11,
        ) ??
        const TextStyle(fontWeight: FontWeight.bold, fontSize: 11);

    double getLeftW(int i) => (leftWidths[i] as FixedColumnWidth).value;
    double getRightW(int i) => (rightWidths[i] as FixedColumnWidth).value;

    final periods = ks6aData.periods;

    return SizedBox(
      width: totalWidth,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Левая часть заголовка
            _headerCell('№', getLeftW(0), dividerColor, style, hasLeft: true),
            _headerCell('Наименование', getLeftW(1), dividerColor, style),
            _headerCell('Ед. изм.', getLeftW(2), dividerColor, style),
            _headerCell('Кол-во по смете', getLeftW(3), dividerColor, style),
            _headerCell('Цена', getLeftW(4), dividerColor, style),
            _headerCell('Стоимость', getLeftW(5), dividerColor, style),

            // Периоды (всегда рендерим структуру для совпадения высоты)
            for (int i = 0; i < periods.length; i++)
              Column(
                children: [
                  Container(
                    width: getRightW(i * 2) + getRightW(i * 2 + 1),
                    padding: const EdgeInsets.symmetric(
                      vertical: 4,
                      horizontal: 4,
                    ),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: dividerColor),
                        right: BorderSide(color: dividerColor),
                      ),
                    ),
                    child: Text(
                      periods[i].title ?? 'Период ${i + 1}',
                      style: style,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Row(
                    children: [
                      _headerCell(
                        'Кол-во',
                        getRightW(i * 2),
                        dividerColor,
                        style,
                      ),
                      _headerCell(
                        'Стоимость',
                        getRightW(i * 2 + 1),
                        dividerColor,
                        style,
                      ),
                    ],
                  ),
                ],
              ),

            // ИТОГО (Накопительный итог) (всегда рендерим структуру)
            Column(
              children: [
                Container(
                  width: getRightW(periods.length * 2) +
                      getRightW(periods.length * 2 + 1),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: dividerColor),
                      right: BorderSide(color: dividerColor),
                    ),
                  ),
                  child: Text('ИТОГО', style: style),
                ),
                Row(
                  children: [
                    _headerCell(
                      'Кол-во',
                      getRightW(periods.length * 2),
                      dividerColor,
                      style,
                    ),
                    _headerCell(
                      'Стоимость',
                      getRightW(periods.length * 2 + 1),
                      dividerColor,
                      style,
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Вспомогательный метод для отрисовки ячейки заголовка.
  Widget _headerCell(
    String text,
    double width,
    Color dividerColor,
    TextStyle style, {
    bool hasLeft = false,
  }) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(8),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        border: Border(
          left: hasLeft ? BorderSide(color: dividerColor) : BorderSide.none,
          right: BorderSide(color: dividerColor),
          bottom: BorderSide(color: dividerColor),
        ),
      ),
      child: Text(text, textAlign: TextAlign.center, style: style),
    );
  }
}

/// Компонент тела таблицы КС-6а.
/// Использует стандартный виджет `Table` для отрисовки строк данных.
class _Ks6aBodyTable extends ConsumerWidget {
  /// Идентификатор договора.
  final String contractId;

  /// Подготовленные строки для отображения.
  final List<Ks6aRowViewModel> rows;

  /// Все данные КС-6а.
  final entity.Ks6aContractData ks6aData;

  /// Ширины левых колонок.
  final Map<int, TableColumnWidth> leftWidths;

  /// Ширины правых колонок.
  final Map<int, TableColumnWidth> rightWidths;

  /// Цвет разделителей.
  final Color dividerColor;

  /// Флаг фиксированной части (левой).
  final bool isFixed;

  const _Ks6aBodyTable({
    required this.contractId,
    required this.rows,
    required this.ks6aData,
    required this.leftWidths,
    required this.rightWidths,
    required this.dividerColor,
    required this.isFixed,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Table(
      columnWidths: {
        ...leftWidths,
        ...rightWidths.map((k, v) => MapEntry(k + leftWidths.length, v)),
      },
      border: TableBorder(
        horizontalInside: BorderSide(color: dividerColor, width: 1),
        verticalInside: BorderSide(color: dividerColor, width: 1),
      ),
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      children: rows.map((row) => _buildRow(context, ref, row)).toList(),
    );
  }

  /// Формирует строку таблицы в зависимости от её типа.
  TableRow _buildRow(
    BuildContext context,
    WidgetRef ref,
    Ks6aRowViewModel row,
  ) {
    final theme = Theme.of(context);
    switch (row.type) {
      case Ks6aRowType.groupHeader:
        return TableRow(
          decoration: BoxDecoration(
            color: theme.colorScheme.secondaryContainer.withValues(alpha: 0.3),
          ),
          children: [
            _bodyCell('', theme, dividerColor),
            _bodyCell(
              row.label,
              theme,
              dividerColor,
              align: Alignment.centerLeft,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 10,
                letterSpacing: 0.5,
                color: theme.colorScheme.onSecondaryContainer,
              ),
            ),
            for (int i = 0; i < 4; i++) _bodyCell('', theme, dividerColor),
            ...List.generate(
              (ks6aData.periods.length + 1) * 2,
              (_) => _bodyCell('', theme, dividerColor),
            ),
          ],
        );
      case Ks6aRowType.item:
        final color = rows.indexOf(row).isEven
            ? theme.colorScheme.primary.withValues(alpha: 0.04)
            : null;

        final periodCells = <Widget>[];
        double cumulativeQty = 0;
        double cumulativeAmt = 0;

        for (int i = 0; i < ks6aData.periods.length; i++) {
          final val = row.periodValues[i];
          cumulativeQty += val.quantity;
          cumulativeAmt += val.amount;

          periodCells.add(
            _bodyCell(
              val.quantity > 0 ? formatQuantity(val.quantity) : '',
              theme,
              dividerColor,
            ),
          );
          periodCells.add(
            _bodyCell(
              val.amount > 0 ? formatCurrency(val.amount) : '',
              theme,
              dividerColor,
              align: Alignment.centerRight,
            ),
          );
        }
        // Итоговая колонка (накопительный итог)
        periodCells.add(
          _bodyCell(
            cumulativeQty > 0 ? formatQuantity(cumulativeQty) : '',
            theme,
            dividerColor,
          ),
        );
        periodCells.add(
          _bodyCell(
            cumulativeAmt > 0 ? formatCurrency(cumulativeAmt) : '',
            theme,
            dividerColor,
            align: Alignment.centerRight,
            style: TextStyle(color: theme.colorScheme.primary),
          ),
        );

        return TableRow(
          decoration: color != null ? BoxDecoration(color: color) : null,
          children: [
            _bodyCell(
              row.number ?? '',
              theme,
              dividerColor,
            ),
            _bodyCell(
              row.label,
              theme,
              dividerColor,
              align: Alignment.centerLeft,
            ),
            _bodyCell(row.unit ?? '', theme, dividerColor),
            _bodyCell(
              formatQuantity(row.quantity),
              theme,
              dividerColor,
            ),
            _bodyCell(
              formatCurrency(row.price),
              theme,
              dividerColor,
              align: Alignment.centerRight,
            ),
            _bodyCell(
              formatCurrency(row.total),
              theme,
              dividerColor,
              align: Alignment.centerRight,
            ),
            ...periodCells,
          ],
        );
      case Ks6aRowType.groupTotal:
        final style = TextStyle(
          fontSize: 10,
          color: theme.colorScheme.onSurface,
        );

        final periodCells = <Widget>[];
        double cumulativeAmt = 0;
        for (int i = 0; i < ks6aData.periods.length; i++) {
          final val = row.periodValues[i];
          cumulativeAmt += val.amount;
          periodCells.add(_bodyCell('', theme, dividerColor)); // Кол-во итог не пишем
          periodCells.add(
            _bodyCell(
              val.amount > 0 ? formatCurrency(val.amount) : '',
              theme,
              dividerColor,
              align: Alignment.centerRight,
              style: style.copyWith(color: theme.colorScheme.primary),
            ),
          );
        }
        periodCells.add(_bodyCell('', theme, dividerColor));
        periodCells.add(
          _bodyCell(
            formatCurrency(cumulativeAmt),
            theme,
            dividerColor,
            align: Alignment.centerRight,
            style: style.copyWith(color: theme.colorScheme.primary),
          ),
        );

        return TableRow(
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer.withValues(alpha: 0.15),
          ),
          children: [
            _bodyCell('', theme, dividerColor),
            _bodyCell(
              'ИТОГО ПО СМЕТЕ:',
              theme,
              dividerColor,
              align: Alignment.centerRight,
              style: style,
            ),
            _bodyCell('', theme, dividerColor),
            _bodyCell('', theme, dividerColor),
            _bodyCell('', theme, dividerColor),
            _bodyCell(
              formatCurrency(row.total),
              theme,
              dividerColor,
              align: Alignment.centerRight,
              style: style.copyWith(color: theme.colorScheme.primary),
            ),
            ...periodCells,
          ],
        );
    }
  }

  /// Вспомогательный метод для отрисовки текстовой ячейки данных.
  Widget _bodyCell(
    String text,
    ThemeData theme,
    Color dividerColor, {
    Alignment align = Alignment.center,
    TextStyle? style,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      constraints: const BoxConstraints(minHeight: 32),
      alignment: align,
      child: Text(
        text,
        style: (theme.textTheme.bodySmall ?? const TextStyle(fontSize: 11)).merge(style),
        textAlign: align == Alignment.centerRight ? TextAlign.right : (align == Alignment.centerLeft ? TextAlign.left : TextAlign.center),
      ),
    );
  }
}

/// Константы размеров для таблицы КС-6а.
class _Constants {
  /// Ширины фиксированных колонок слева.
  static const Map<int, TableColumnWidth> leftWidths = {
    0: FixedColumnWidth(45),
    1: FixedColumnWidth(450),
    2: FixedColumnWidth(60),
    3: FixedColumnWidth(85),
    4: FixedColumnWidth(95),
    5: FixedColumnWidth(110),
  };

  /// Суммарная ширина левой части.
  static const double leftTotalWidth = 45 + 450 + 60 + 85 + 95 + 110;
}
