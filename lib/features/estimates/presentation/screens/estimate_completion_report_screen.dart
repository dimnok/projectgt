import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:projectgt/core/di/providers.dart';
import 'package:projectgt/core/utils/formatters.dart';
import 'package:projectgt/presentation/widgets/app_bar_widget.dart';
import '../providers/estimate_completion_filter_provider.dart';
import '../widgets/estimate_completion_filters_action.dart';

/// Экран отчёта о выполнении смет.
///
/// Отображает таблицу со всеми сметными позициями и информацией о выполнении работ.
class EstimateCompletionReportScreen extends ConsumerStatefulWidget {
  /// Создаёт экран отчёта о выполнении смет.
  const EstimateCompletionReportScreen({super.key});

  @override
  ConsumerState<EstimateCompletionReportScreen> createState() =>
      _EstimateCompletionReportScreenState();
}

class _EstimateCompletionReportScreenState
    extends ConsumerState<EstimateCompletionReportScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final completionData = ref.watch(estimateCompletionProvider);
    final filter = ref.watch(estimateCompletionFilterProvider);

    // Загружаем если выбран объект (договор опционален)
    final shouldLoadData = filter.appliedObjectIds.isNotEmpty;

    // Проверяем есть ли перевыполнение (>100%)
    final hasOvercompletion = completionData.maybeWhen(
      data: (items) => items.any((item) => item.percentage > 100),
      orElse: () => false,
    );

    return Scaffold(
      appBar: AppBarWidget(
        title: 'Отчёт о выполнении смет',
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Назад',
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          // Индикатор перевыполнения
          if (hasOvercompletion)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Tooltip(
                message: 'Есть перевыполнение (>100%)',
                child: Icon(
                  Icons.warning_rounded,
                  color: Colors.red,
                  size: 24,
                ),
              ),
            ),
          const EstimateCompletionFiltersAction(),
        ],
      ),
      body: !shouldLoadData
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.filter_list,
                    size: 48,
                    color: theme.colorScheme.outline,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Выберите объект',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Нажмите кнопку фильтров чтобы выбрать объект',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            )
          : completionData.when(
              loading: () => _buildSkeleton(theme),
              error: (error, stackTrace) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline,
                        size: 48, color: theme.colorScheme.error),
                    const SizedBox(height: 16),
                    Text(
                      'Ошибка загрузки данных',
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      error.toString(),
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              data: (completionList) {
                // Применяем ПРИМЕНЁННЫЕ фильтры к данным
                final filteredList = completionList.where((item) {
                  final byObject = filter.appliedObjectIds.isEmpty ||
                      filter.appliedObjectIds.contains(item.objectId);
                  final byContract = filter.appliedContractIds.isEmpty ||
                      filter.appliedContractIds.contains(item.contractId);
                  final bySystem = filter.appliedSystems.isEmpty ||
                      filter.appliedSystems.contains(item.system);

                  return byObject && byContract && bySystem;
                }).toList();

                if (filteredList.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.inbox_outlined,
                          size: 48,
                          color: theme.colorScheme.outline,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Нет данных',
                          style: theme.textTheme.titleMedium,
                        ),
                      ],
                    ),
                  );
                }

                return _buildDataTable(filteredList, theme);
              },
            ),
    );
  }

  Widget _buildSkeleton(ThemeData theme) {
    const skeletonColor = Color(0xFFE0E0E0);

    return Padding(
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
          child: Column(
            children: [
              Container(
                color: theme.brightness == Brightness.dark
                    ? Colors.white.withValues(alpha: 0.06)
                    : Colors.black.withValues(alpha: 0.06),
                height: 48,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                child: const Row(
                  children: [
                    _SkeletonBox(width: 50, height: 16, color: skeletonColor),
                    SizedBox(width: 12),
                    _SkeletonBox(width: 70, height: 16, color: skeletonColor),
                    SizedBox(width: 12),
                    _SkeletonBox(width: 40, height: 16, color: skeletonColor),
                    SizedBox(width: 12),
                    Expanded(
                      child: _SkeletonBox(
                          width: double.infinity,
                          height: 16,
                          color: skeletonColor),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.separated(
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: 5,
                  separatorBuilder: (_, __) => Divider(
                    height: 1,
                    color: theme.colorScheme.outline.withValues(alpha: 0.18),
                  ),
                  itemBuilder: (_, __) => Container(
                    height: 48,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 12),
                    child: const Row(
                      children: [
                        _SkeletonBox(
                            width: 50, height: 16, color: skeletonColor),
                        SizedBox(width: 12),
                        _SkeletonBox(
                            width: 70, height: 16, color: skeletonColor),
                        SizedBox(width: 12),
                        _SkeletonBox(
                            width: 40, height: 16, color: skeletonColor),
                        SizedBox(width: 12),
                        Expanded(
                          child: _SkeletonBox(
                              width: double.infinity,
                              height: 16,
                              color: skeletonColor),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDataTable(List<dynamic> completionList, ThemeData theme) {
    // Кэшируем стили один раз
    final dividerColor = theme.colorScheme.outline.withValues(alpha: 0.18);
    final headerBackgroundColor = theme.brightness == Brightness.dark
        ? Colors.white.withValues(alpha: 0.06)
        : Colors.black.withValues(alpha: 0.06);
    final headerTextStyle = theme.textTheme.labelLarge?.copyWith(
          color: theme.colorScheme.onSurface,
          fontWeight: FontWeight.w600,
        ) ??
        const TextStyle();
    final bodyTextStyle = theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurface,
        ) ??
        const TextStyle();

    // Сортируем: система → подсистема → номер (1,2,3...10 потом д-1, Д-3, о-7)
    final sortedList = List.from(completionList)
      ..sort((a, b) {
        // Сначала сортируем по системе
        final systemCompare = a.system.compareTo(b.system);
        if (systemCompare != 0) return systemCompare;

        // Потом по подсистеме
        final subsystemCompare = a.subsystem.compareTo(b.subsystem);
        if (subsystemCompare != 0) return subsystemCompare;

        // Потом по номеру
        return _compareNumbers(a.number, b.number);
      });

    final tableRows = <TableRow>[
      // Заголовок
      TableRow(
        decoration: BoxDecoration(color: headerBackgroundColor),
        children: [
          _HeaderCell('Система', headerTextStyle, TextAlign.left),
          _HeaderCell('Подсистема', headerTextStyle, TextAlign.left),
          _HeaderCell('№', headerTextStyle, TextAlign.center),
          _HeaderCell('Наименование', headerTextStyle, TextAlign.left),
          _HeaderCell('Ед. изм.', headerTextStyle, TextAlign.center),
          _HeaderCell('Кол-во', headerTextStyle, TextAlign.center),
          _HeaderCell('Сумма', headerTextStyle, TextAlign.right),
          _HeaderCell('Кол-во вып.', headerTextStyle, TextAlign.center),
          _HeaderCell('Сумма вып.', headerTextStyle, TextAlign.right),
          _HeaderCell('%', headerTextStyle, TextAlign.center),
          _HeaderCell('Остаток', headerTextStyle, TextAlign.center),
        ],
      ),
      // Строки данных (отсортированные)
      for (var item in sortedList)
        TableRow(
          decoration: BoxDecoration(
            color: item.percentage > 100
                ? Colors.red.withValues(
                    alpha: 0.1) // > 100% → красный фон (перевыполнение)
                : item.percentage == 100
                    ? Colors.green.withValues(
                        alpha: 0.1) // == 100% → зелёный фон (выполнено)
                    : null, // < 100% → без цвета
          ),
          children: [
            _DataCell(Text(item.system), bodyTextStyle, TextAlign.left),
            _DataCell(Text(item.subsystem), bodyTextStyle, TextAlign.left),
            _DataCell(Text(item.number), bodyTextStyle, TextAlign.center),
            _DataCell(Text(item.name), bodyTextStyle, TextAlign.left),
            _DataCell(Text(item.unit), bodyTextStyle, TextAlign.center),
            _DataCell(Text(item.quantity.toStringAsFixed(0)), bodyTextStyle,
                TextAlign.center),
            _DataCell(Text(formatCurrency(item.total)), bodyTextStyle,
                TextAlign.right),
            _DataCell(Text(item.completedQuantity.toStringAsFixed(0)),
                bodyTextStyle, TextAlign.center),
            _DataCell(Text(formatCurrency(item.completedTotal)), bodyTextStyle,
                TextAlign.right),
            _DataCell(Text('${item.percentage.toStringAsFixed(0)}%'),
                bodyTextStyle, TextAlign.center),
            _DataCell(Text(item.remainingQuantity.toStringAsFixed(0)),
                bodyTextStyle, TextAlign.center),
          ],
        ),
    ];

    return Padding(
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
          child: SingleChildScrollView(
            child: Table(
              border: TableBorder(
                top: BorderSide(color: dividerColor, width: 1),
                bottom: BorderSide(color: dividerColor, width: 1),
                left: BorderSide(color: dividerColor, width: 1),
                right: BorderSide(color: dividerColor, width: 1),
                horizontalInside: BorderSide(color: dividerColor, width: 1),
                verticalInside: BorderSide(color: dividerColor, width: 1),
              ),
              defaultVerticalAlignment: TableCellVerticalAlignment.middle,
              columnWidths: const <int, TableColumnWidth>{
                0: FlexColumnWidth(0.24),
                1: FlexColumnWidth(0.432),
                2: IntrinsicColumnWidth(),
                3: FlexColumnWidth(2),
                4: IntrinsicColumnWidth(),
                5: IntrinsicColumnWidth(),
                6: IntrinsicColumnWidth(),
                7: IntrinsicColumnWidth(),
                8: IntrinsicColumnWidth(),
                9: IntrinsicColumnWidth(),
                10: IntrinsicColumnWidth(),
              },
              children: tableRows,
            ),
          ),
        ),
      ),
    );
  }
}

/// Сортирует номера: 1,2,3...10 (числа), потом д-1, Д-3, о-7 (буквы с цифрами)
int _compareNumbers(String a, String b) {
  final aNum = int.tryParse(a);
  final bNum = int.tryParse(b);

  // Оба числа - сортируем численно
  if (aNum != null && bNum != null) {
    return aNum.compareTo(bNum);
  }

  // Одно число, другое нет - число идёт первым
  if (aNum != null) return -1;
  if (bNum != null) return 1;

  // Оба не числа - сортируем строки
  return a.compareTo(b);
}

/// Преобразует TextAlign в Alignment
Alignment _alignmentFromTextAlign(TextAlign textAlign) {
  return switch (textAlign) {
    TextAlign.center => Alignment.center,
    TextAlign.right => Alignment.centerRight,
    _ => Alignment.centerLeft,
  };
}

/// Простой виджет для skeleton box
class _SkeletonBox extends StatelessWidget {
  final double width;
  final double height;
  final Color color;

  const _SkeletonBox({
    required this.width,
    required this.height,
    required this.color,
  });

  @override
  Widget build(BuildContext context) => Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(4),
        ),
      );
}

/// Ячейка заголовка
class _HeaderCell extends StatelessWidget {
  final String text;
  final TextStyle style;
  final TextAlign align;

  const _HeaderCell(this.text, this.style, this.align);

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        alignment: _alignmentFromTextAlign(align),
        child: Text(
          text,
          textAlign: align,
          style: style,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      );
}

/// Ячейка данных
class _DataCell extends StatelessWidget {
  final Widget child;
  final TextStyle style;
  final TextAlign align;

  const _DataCell(this.child, this.style, this.align);

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        alignment: _alignmentFromTextAlign(align),
        child: DefaultTextStyle(
          style: style,
          child: child,
        ),
      );
}
