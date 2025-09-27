import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:projectgt/core/widgets/gt_dropdown.dart';
import '../../domain/entities/export_filter.dart';
import '../providers/export_filter_provider.dart';
import '../providers/export_provider.dart';

class _Option {
  final String value;
  final String label;
  const _Option(this.value, this.label);
  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is _Option && other.value == value);
  @override
  int get hashCode => value.hashCode;
}

/// Кнопка в AppBar для открытия компактного блока фильтров выгрузки
class ExportFiltersAction extends ConsumerWidget {
  const ExportFiltersAction({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final iconKey = GlobalKey();

    Future<void> openPopup() async {
      final box = iconKey.currentContext!.findRenderObject() as RenderBox;
      final overlay =
          Overlay.of(context).context.findRenderObject() as RenderBox;
      final offset = box.localToGlobal(Offset.zero, ancestor: overlay);
      final position = RelativeRect.fromLTRB(
        offset.dx,
        offset.dy + box.size.height,
        offset.dx + box.size.width,
        offset.dy,
      );

      await showMenu(
        context: context,
        position: position,
        elevation: 0,
        color: Theme.of(context).colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
          ),
        ),
        items: const [
          PopupMenuItem(
            enabled: false,
            padding: EdgeInsets.zero,
            child: _ExportFiltersPanel(),
          ),
        ],
      );
    }

    return Container(
      key: iconKey,
      child: IconButton(
        tooltip: 'Фильтры',
        icon: const Icon(Icons.tune),
        onPressed: openPopup,
      ),
    );
  }
}

/// Компактная панель фильтров для всплывающего меню
class _ExportFiltersPanel extends ConsumerStatefulWidget {
  const _ExportFiltersPanel();

  @override
  ConsumerState<_ExportFiltersPanel> createState() =>
      _ExportFiltersPanelState();
}

class _ExportFiltersPanelState extends ConsumerState<_ExportFiltersPanel> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final objects = ref.watch(availableObjectsForExportProvider);
    final contracts = ref.watch(availableContractsForExportProvider);
    final systems = ref.watch(availableSystemsForExportProvider);
    final subsystems = ref.watch(availableSubsystemsForExportProvider);
    final st = ref.watch(exportFilterProvider);

    final objectOptions =
        objects.map<_Option>((o) => _Option(o.id as String, o.name)).toList();
    final contractOptions = contracts
        .map<_Option>((c) => _Option(
              c.id as String,
              '${c.number} (${(c.contractorName ?? 'Без контрагента') as String})',
            ))
        .toList();
    final systemOptions = systems.map<_Option>((s) => _Option(s, s)).toList();
    final subsystemOptions =
        subsystems.map<_Option>((s) => _Option(s, s)).toList();

    List<_Option> selectedByIds(List<String> ids, List<_Option> options) =>
        options.where((o) => ids.contains(o.value)).toList();
    final selectedObjects = selectedByIds(st.objectIds, objectOptions);
    final selectedContracts = selectedByIds(st.contractIds, contractOptions);
    final selectedSystems = selectedByIds(st.systems, systemOptions);
    final selectedSubsystems = selectedByIds(st.subsystems, subsystemOptions);

    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 360, maxWidth: 420),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Фильтры',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),

            // Объекты
            GTDropdown<_Option>(
              items: objectOptions,
              itemDisplayBuilder: (o) => o.label,
              selectedItems: selectedObjects,
              onMultiSelectionChanged: (opts) => ref
                  .read(exportFilterProvider.notifier)
                  .setObjectFilter(opts.map((e) => e.value).toList()),
              labelText: 'Объект',
              hintText: 'Выберите...',
              allowMultipleSelection: true,
            ),
            const SizedBox(height: 12),

            // Договоры
            GTDropdown<_Option>(
              items: contractOptions,
              itemDisplayBuilder: (o) => o.label,
              selectedItems: selectedContracts,
              onMultiSelectionChanged: (opts) => ref
                  .read(exportFilterProvider.notifier)
                  .setContractFilter(opts.map((e) => e.value).toList()),
              labelText: 'Договор',
              hintText: 'Выберите...',
              allowMultipleSelection: true,
            ),
            const SizedBox(height: 12),

            // Системы
            GTDropdown<_Option>(
              items: systemOptions,
              itemDisplayBuilder: (o) => o.label,
              selectedItems: selectedSystems,
              onMultiSelectionChanged: (opts) => ref
                  .read(exportFilterProvider.notifier)
                  .setSystemFilter(opts.map((e) => e.value).toList()),
              labelText: 'Система',
              hintText: 'Выберите...',
              allowMultipleSelection: true,
            ),
            const SizedBox(height: 12),

            // Подсистемы
            GTDropdown<_Option>(
              items: subsystemOptions,
              itemDisplayBuilder: (o) => o.label,
              selectedItems: selectedSubsystems,
              onMultiSelectionChanged: (opts) => ref
                  .read(exportFilterProvider.notifier)
                  .setSubsystemFilter(opts.map((e) => e.value).toList()),
              labelText: 'Подсистема',
              hintText: 'Выберите...',
              allowMultipleSelection: true,
            ),

            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () {
                    ref.read(exportFilterProvider.notifier).resetFilters();
                    final st = ref.read(exportFilterProvider);
                    final filter = ExportFilter(
                      objectIds: st.objectIds,
                      contractIds: st.contractIds,
                      systems: st.systems,
                      subsystems: st.subsystems,
                      dateFrom: st.dateFrom,
                      dateTo: st.dateTo,
                    );
                    ref.read(exportProvider.notifier).loadReportData(filter);
                  },
                  child: const Text('Сброс'),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: () {
                    final st = ref.read(exportFilterProvider);
                    final filter = ExportFilter(
                      objectIds: st.objectIds,
                      contractIds: st.contractIds,
                      systems: st.systems,
                      subsystems: st.subsystems,
                      dateFrom: st.dateFrom,
                      dateTo: st.dateTo,
                    );
                    ref.read(exportProvider.notifier).loadReportData(filter);
                    Navigator.of(context).pop();
                  },
                  child: const Text('Сформировать'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
