import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/di/providers.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/gt_adaptive_table.dart';
import '../../../company/presentation/providers/company_providers.dart';
import '../providers/materials_mapping_providers.dart';
import 'materials_link_button.dart';

/// Адаптивная таблица сопоставления материалов на базе [GTAdaptiveTable].
class MaterialsMappingTableView extends ConsumerWidget {
  /// Список строк сопоставления.
  final List<EstimateMappingRow> items;

  /// Флаг загрузки.
  final bool isLoading;

  /// Ошибка, если есть.
  final Object? error;

  /// Создаёт экземпляр [MaterialsMappingTableView].
  const MaterialsMappingTableView({
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

    final columnFilters = ref.watch(materialsMappingColumnFiltersProvider);
    final expanded = ref.watch(expandedEstimatesProvider);

    void onFilterChanged(String column, String value) {
      final current = ref.read(materialsMappingColumnFiltersProvider);
      ref.read(materialsMappingColumnFiltersProvider.notifier).state = {
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

    void toggleExpand(String id) {
      final notifier = ref.read(expandedEstimatesProvider.notifier);
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

    Future<void> unlinkWithConfirm({required String aliasId, required String estimateRowId}) async {
      final confirmed = await showCupertinoDialog<bool>(
        context: context,
        builder: (ctx) => CupertinoAlertDialog(
          title: const Text('Удалить связь?'),
          content: const Text('Вы уверены, что хотите отвязать этот материал?'),
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
        final activeCompanyId = ref.read(activeCompanyIdProvider);
        await client
            .from('material_aliases')
            .delete()
            .eq('id', aliasId)
            .eq('company_id', activeCompanyId ?? '');
        
        final exp = ref.read(expandedEstimatesProvider.notifier);
        final s = {...exp.state};
        s.remove(estimateRowId);
        exp.state = s;
        
        ref.read(estimatesMappingPagerProvider.notifier).refresh();
      } catch (_) {}
    }

    final columns = [
      GTColumnConfig<EstimateMappingRow>(
        title: '№',
        headerAlign: TextAlign.center,
        cellAlignment: Alignment.center,
        minWidth: 50,
        headerFilter: buildFilter('number', '№...'),
        builder: (item, _, __) {
          final isExpanded = expanded.contains(item.id);
          return Text(
            item.number.isEmpty ? '—' : item.number,
            style: isExpanded ? const TextStyle(fontWeight: FontWeight.bold) : null,
          );
        },
      ),
      GTColumnConfig<EstimateMappingRow>(
        title: 'Наименование',
        headerAlign: TextAlign.center,
        isFlexible: true,
        minWidth: 250,
        headerFilter: buildFilter('name', 'Поиск по названию...'),
        measureText: (item) => item.name,
        builder: (item, _, theme) {
          final isExpanded = expanded.contains(item.id);
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  item.name,
                  style: isExpanded ? const TextStyle(fontWeight: FontWeight.bold) : null,
                ),
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
      GTColumnConfig<EstimateMappingRow>(
        title: 'Ед. изм.',
        headerAlign: TextAlign.center,
        cellAlignment: Alignment.center,
        minWidth: 60,
        headerFilter: buildFilter('unit', 'Ед...'),
        builder: (item, _, __) {
          final isExpanded = expanded.contains(item.id);
          return Text(
            item.unit,
            style: isExpanded ? const TextStyle(fontWeight: FontWeight.bold) : null,
          );
        },
      ),
      GTColumnConfig<EstimateMappingRow>(
        title: 'Связь',
        headerAlign: TextAlign.center,
        cellAlignment: Alignment.center,
        minWidth: 80,
        builder: (item, _, __) => MaterialsLinkButton(
          estimateId: item.id,
          aliasCount: item.aliasCount,
        ),
      ),
    ];

    return NotificationListener<ScrollNotification>(
      onNotification: (n) {
        // Подгружаем данные только при вертикальном скролле
        if (n.metrics.axis == Axis.vertical &&
            n.metrics.pixels >= n.metrics.maxScrollExtent - 200) {
          ref.read(estimatesMappingPagerProvider.notifier).loadMore();
        }
        return false;
      },
      child: GTAdaptiveTable<EstimateMappingRow>(
        items: items,
        columns: columns,
        onRowTapDown: (item, _) {
          if (item.aliases.isNotEmpty) toggleExpand(item.id);
        },
        additionalRowsBuilder: (item, index, theme) {
          final isExpanded = expanded.contains(item.id);
          if (!isExpanded || item.aliases.isEmpty) return [];

          final childBg = Colors.green.withValues(alpha: 0.06);
          final childTextStyle = theme.textTheme.bodyMedium?.copyWith(
            fontStyle: FontStyle.italic,
            fontSize: 12,
            color: Colors.blue,
          );

          return item.aliases.map((a) {
            return TableRow(
              children: [
                // №
                Container(
                  color: childBg,
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                  child: a.isKitComponent
                      ? const Icon(Icons.widgets_outlined, size: 14, color: Colors.blue)
                      : const SizedBox.shrink(),
                ),
                // Наименование
                Container(
                  color: childBg,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(a.aliasRaw, style: childTextStyle),
                      ),
                      if (a.isKitComponent && a.qtyPerKit != null) ...[
                        const SizedBox(width: 6),
                        _MultiplierBadge(text: '×${formatQuantity(a.qtyPerKit!)}'),
                      ],
                      if (!a.isKitComponent && a.multiplier != null) ...[
                        const SizedBox(width: 6),
                        _MultiplierBadge(text: '×${formatQuantity(a.multiplier!)}'),
                      ],
                    ],
                  ),
                ),
                // Ед. изм.
                Container(
                  color: childBg,
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  child: Text(a.uomRaw ?? '—', style: childTextStyle),
                ),
                // Связь (кнопка удаления)
                Container(
                  color: childBg,
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () => unlinkWithConfirm(aliasId: a.id, estimateRowId: item.id),
                    minimumSize: Size.zero,
                    child: Container(
                      width: 18,
                      height: 18,
                      decoration: const BoxDecoration(color: Colors.amber, shape: BoxShape.circle),
                      alignment: Alignment.center,
                      child: const Icon(Icons.remove, size: 12, color: Colors.black),
                    ),
                  ),
                ),
              ],
            );
          }).toList();
        },
      ),
    );
  }
}

class _MultiplierBadge extends StatelessWidget {
  final String text;
  const _MultiplierBadge({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: Colors.blue.withValues(alpha: 0.4), width: 0.5),
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 11, color: Colors.blue, fontWeight: FontWeight.bold),
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
          borderSide: BorderSide(color: theme.colorScheme.outline.withValues(alpha: 0.1)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: BorderSide(color: theme.colorScheme.outline.withValues(alpha: 0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: BorderSide(color: theme.colorScheme.primary.withValues(alpha: 0.3)),
        ),
      ),
    );
  }
}
