import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:projectgt/core/widgets/gt_dropdown.dart';
import 'package:projectgt/core/di/providers.dart';
import '../providers/estimate_completion_filter_provider.dart';

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

/// Кнопка в AppBar для открытия компактного блока фильтров отчёта о выполнении.
///
/// Отображает иконку "Фильтры" и по нажатию открывает всплывающее меню
/// с компактной панелью выбора фильтров (объекты, договоры, системы).
class EstimateCompletionFiltersAction extends ConsumerWidget {
  /// Создаёт кнопку фильтров для раскрытия всплывающей панели.
  const EstimateCompletionFiltersAction({super.key});

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
            child: _EstimateCompletionFiltersPanel(),
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
class _EstimateCompletionFiltersPanel extends ConsumerStatefulWidget {
  const _EstimateCompletionFiltersPanel();

  @override
  ConsumerState<_EstimateCompletionFiltersPanel> createState() =>
      _EstimateCompletionFiltersPanelState();
}

class _EstimateCompletionFiltersPanelState
    extends ConsumerState<_EstimateCompletionFiltersPanel> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final objects = ref.watch(availableObjectsForCompletionProvider);
    final contracts = ref.watch(availableContractsForCompletionProvider);
    final systems = ref.watch(availableSystemsForCompletionProvider);
    final st = ref.watch(estimateCompletionFilterProvider);

    final objectOptions =
        objects.map<_Option>((o) => _Option(o.id as String, o.name)).toList();
    final contractOptions = contracts
        .map<_Option>((c) => _Option(
              c.id as String,
              '${c.number} (${(c.contractorName ?? 'Без контрагента') as String})',
            ))
        .toList();
    final systemOptions = systems.map<_Option>((s) => _Option(s, s)).toList();

    List<_Option> selectedByIds(List<String> ids, List<_Option> options) =>
        options.where((o) => ids.contains(o.value)).toList();
    final selectedObjects = selectedByIds(st.objectIds, objectOptions);
    final selectedContracts = selectedByIds(st.contractIds, contractOptions);
    final selectedSystems = selectedByIds(st.systems, systemOptions);

    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 360, maxWidth: 420),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Фильтры отчёта',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),

            // Объекты
            GTDropdown<_Option>(
              items: objectOptions,
              itemDisplayBuilder: (o) => o.label,
              selectedItems: selectedObjects,
              onMultiSelectionChanged: (opts) => ref
                  .read(estimateCompletionFilterProvider.notifier)
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
                  .read(estimateCompletionFilterProvider.notifier)
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
                  .read(estimateCompletionFilterProvider.notifier)
                  .setSystemFilter(opts.map((e) => e.value).toList()),
              labelText: 'Система',
              hintText: 'Выберите...',
              allowMultipleSelection: true,
            ),
            const SizedBox(height: 16),

            // Кнопки действий
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => ref
                      .read(estimateCompletionFilterProvider.notifier)
                      .resetFilters(),
                  child: const Text('Сброс'),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: () {
                    // Применяем выбранные фильтры
                    ref
                        .read(estimateCompletionFilterProvider.notifier)
                        .applyFilters();
                    // Инициируем загрузку данных
                    ref.read(estimateCompletionProvider);
                    Navigator.pop(context);
                  },
                  child: const Text('Применить'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
