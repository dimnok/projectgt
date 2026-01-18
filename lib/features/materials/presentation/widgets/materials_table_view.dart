import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/di/providers.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/gt_adaptive_table.dart';
import '../../data/models/material_item.dart';
import '../providers/materials_pager.dart';
import '../providers/materials_providers.dart';

/// Адаптивная таблица материалов на базе [GTAdaptiveTable].
class MaterialsTableView extends ConsumerWidget {
  /// Список материалов.
  final List<MaterialItem> items;

  /// Флаг загрузки.
  final bool isLoading;

  /// Ошибка, если есть.
  final Object? error;

  /// Создаёт экземпляр [MaterialsTableView].
  const MaterialsTableView({
    super.key,
    required this.items,
    this.isLoading = false,
    this.error,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (error != null) {
      return Center(child: Text('Ошибка: $error'));
    }

    if (isLoading && items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    final columnFilters = ref.watch(materialsColumnFiltersProvider);

    void onFilterChanged(String column, String value) {
      final current = ref.read(materialsColumnFiltersProvider);
      ref.read(materialsColumnFiltersProvider.notifier).state = {
        ...current,
        column: value,
      };
    }

    Widget buildFilter(String column, String hint) {
      return _TableFilterInput(
        initialValue: columnFilters[column] ?? '',
        hintText: hint,
        onChanged: (v) => onFilterChanged(column, v),
      );
    }

    Color? getStatusColor(MaterialItem item) {
      final r = item.remaining;
      if (r == null) return null;
      if (r < 0) return Colors.red[700];
      if (r == 0) return Colors.green[700];
      return null;
    }

    final columns = [
      GTColumnConfig<MaterialItem>(
        title: '№',
        headerAlign: TextAlign.center,
        cellAlignment: Alignment.center,
        minWidth: 40,
        builder: (item, index, _) => Text(
          (index + 1).toString(),
          style: TextStyle(color: getStatusColor(item)),
        ),
      ),
      GTColumnConfig<MaterialItem>(
        title: 'Наименование материала',
        headerAlign: TextAlign.center,
        isFlexible: true,
        minWidth: 200,
        headerFilter: buildFilter('name', 'Поиск по названию...'),
        measureText: (item) => item.name,
        builder: (item, _, theme) {
          final r = item.remaining;
          final isNegative = r != null && r < 0;
          final color = getStatusColor(item);
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isNegative)
                const Padding(
                  padding: EdgeInsets.only(right: 6),
                  child: _RotatingWarningIcon(size: 20),
                ),
              Flexible(
                child: Text(item.name, style: TextStyle(color: color)),
              ),
              const SizedBox(width: 4),
              _HoverScaleIcon(
                onTap: () => onFilterChanged('name', item.name),
                child: Icon(
                  CupertinoIcons.search,
                  size: 14,
                  color: theme.colorScheme.primary.withValues(alpha: 0.5),
                ),
              ),
            ],
          );
        },
      ),
      GTColumnConfig<MaterialItem>(
        title: 'Ед. изм.',
        headerAlign: TextAlign.center,
        cellAlignment: Alignment.center,
        minWidth: 60,
        headerFilter: buildFilter('unit', 'Ед...'),
        builder: (item, _, __) => Text(
          item.unit ?? '—',
          style: TextStyle(color: getStatusColor(item)),
        ),
      ),
      GTColumnConfig<MaterialItem>(
        title: 'Кол-во',
        headerAlign: TextAlign.center,
        cellAlignment: Alignment.center,
        minWidth: 70,
        headerFilter: buildFilter('quantity', 'Кол...'),
        measureText: (item) => item.quantity?.toString(),
        builder: (item, _, __) => Text(
          item.quantity?.toString() ?? '—',
          style: TextStyle(color: getStatusColor(item)),
        ),
      ),
      GTColumnConfig<MaterialItem>(
        title: 'Цена за ед.',
        headerAlign: TextAlign.center,
        cellAlignment: Alignment.centerRight,
        minWidth: 100,
        headerFilter: buildFilter('price', 'Цена...'),
        measureText: (item) =>
            item.price != null ? formatCurrency(item.price!) : null,
        builder: (item, _, __) => Text(
          item.price != null ? formatCurrency(item.price!) : '—',
          style: TextStyle(color: getStatusColor(item)),
        ),
      ),
      GTColumnConfig<MaterialItem>(
        title: 'Стоимость',
        headerAlign: TextAlign.center,
        cellAlignment: Alignment.centerRight,
        minWidth: 100,
        headerFilter: buildFilter('total', 'Сумма...'),
        measureText: (item) =>
            item.total != null ? formatCurrency(item.total!) : null,
        builder: (item, _, __) => Text(
          item.total != null ? formatCurrency(item.total!) : '—',
          style: TextStyle(color: getStatusColor(item)),
        ),
      ),
      GTColumnConfig<MaterialItem>(
        title: '№ накладной',
        headerAlign: TextAlign.center,
        cellAlignment: Alignment.center,
        minWidth: 100,
        headerFilter: buildFilter('receipt_number', '№ накл...'),
        builder: (item, _, __) => Text(
          item.receiptNumber ?? '—',
          style: TextStyle(color: getStatusColor(item)),
        ),
      ),
      GTColumnConfig<MaterialItem>(
        title: 'Дата',
        headerAlign: TextAlign.center,
        cellAlignment: Alignment.center,
        minWidth: 90,
        headerFilter: buildFilter('receipt_date', 'Дата...'),
        builder: (item, _, __) => Text(
          item.receiptDate != null ? formatRuDate(item.receiptDate!) : '—',
          style: TextStyle(color: getStatusColor(item)),
        ),
      ),
      GTColumnConfig<MaterialItem>(
        title: 'Использовано',
        headerAlign: TextAlign.center,
        cellAlignment: Alignment.center,
        minWidth: 90,
        headerFilter: buildFilter('used', 'Исп...'),
        builder: (item, _, __) => Text(
          item.used?.toString() ?? '—',
          style: TextStyle(color: getStatusColor(item)),
        ),
      ),
      GTColumnConfig<MaterialItem>(
        title: 'Остаток',
        headerAlign: TextAlign.center,
        cellAlignment: Alignment.center,
        minWidth: 80,
        headerFilter: buildFilter('remaining', 'Ост...'),
        builder: (item, _, __) {
          final color = getStatusColor(item);
          return Text(
            item.remaining?.toString() ?? '—',
            style: TextStyle(
              color: color,
              fontWeight: color != null ? FontWeight.bold : null,
            ),
          );
        },
      ),
      GTColumnConfig<MaterialItem>(
        title: 'Файл',
        headerAlign: TextAlign.center,
        cellAlignment: Alignment.center,
        minWidth: 50,
        builder: (item, _, __) {
          if (item.fileUrl == null || item.fileUrl!.trim().isEmpty) {
            return const Text('—');
          }
          return _HoverScaleIcon(
            onTap: () => _downloadFile(context, ref, item),
            child: const Icon(
              Icons.table_view_rounded,
              size: 18,
              color: Colors.green,
            ),
          );
        },
      ),
    ];

    return NotificationListener<ScrollNotification>(
      onNotification: (n) {
        // Подгружаем данные только при вертикальном скролле,
        // чтобы горизонтальный скролл колонок не сбивал логику.
        if (n.metrics.axis == Axis.vertical) {
          final isAtBottom = n.metrics.pixels >= n.metrics.maxScrollExtent - 200;
          
          if (isAtBottom) {
            ref.read(materialsPagerProvider.notifier).loadMore();
          }
        }
        return false;
      },
      child: GTAdaptiveTable<MaterialItem>(
        items: items,
        columns: columns,
      ),
    );
  }

  Future<void> _downloadFile(
    BuildContext context,
    WidgetRef ref,
    MaterialItem item,
  ) async {
    final confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Скачать файл?'),
        content: Text(
          'Будет загружена накладная № ${item.receiptNumber ?? '—'}',
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Отмена'),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Скачать'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    final client = ref.read(supabaseClientProvider);
    try {
      final signed = await client.storage
          .from('receipts')
          .createSignedUrl(item.fileUrl!, 60);
      final uri = Uri.tryParse(signed);
      if (uri != null) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {}
  }
}

/// Основной виджет раздела материалов, отображающий таблицу с пагинацией.
class MaterialsTableWidget extends ConsumerWidget {
  /// Создаёт экземпляр [MaterialsTableWidget].
  const MaterialsTableWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pagerState = ref.watch(materialsPagerProvider);

    return pagerState.when(
      loading: () =>
          const MaterialsTableView(items: <MaterialItem>[], isLoading: true),
      error: (e, _) =>
          MaterialsTableView(items: const <MaterialItem>[], error: e),
      data: (items) => MaterialsTableView(items: items),
    );
  }
}

/// Виджет ввода для фильтрации в таблице.
class _TableFilterInput extends StatefulWidget {
  final String initialValue;
  final String hintText;
  final ValueChanged<String> onChanged;

  const _TableFilterInput({
    required this.initialValue,
    required this.hintText,
    required this.onChanged,
  });

  @override
  State<_TableFilterInput> createState() => _TableFilterInputState();
}

class _TableFilterInputState extends State<_TableFilterInput> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void didUpdateWidget(_TableFilterInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialValue != oldWidget.initialValue &&
        widget.initialValue != _controller.text) {
      _controller.value = _controller.value.copyWith(
        text: widget.initialValue,
        selection: TextSelection.collapsed(offset: widget.initialValue.length),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return TextField(
      controller: _controller,
      onChanged: widget.onChanged,
      style: const TextStyle(fontSize: 11),
      decoration: InputDecoration(
        hintText: widget.hintText,
        hintStyle: TextStyle(
          fontSize: 10,
          color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        isDense: true,
        filled: true,
        fillColor: theme.colorScheme.surface.withValues(alpha: 0.6),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: BorderSide(
            color: theme.colorScheme.outline.withValues(alpha: 0.1),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: BorderSide(
            color: theme.colorScheme.outline.withValues(alpha: 0.1),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: BorderSide(
            color: theme.colorScheme.primary.withValues(alpha: 0.3),
          ),
        ),
      ),
    );
  }
}

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
    );
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scale = Tween<double>(
      begin: 1.0,
      end: 1.12,
    ).animate(CurvedAnimation(parent: _c, curve: Curves.easeOut));
    return MouseRegion(
      onEnter: (_) => _c.forward(),
      onExit: (_) => _c.reverse(),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedBuilder(
          animation: _c,
          builder: (context, _) =>
              Transform.scale(scale: scale.value, child: widget.child),
        ),
      ),
    );
  }
}
