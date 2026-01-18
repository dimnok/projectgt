import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/materials_mapping_providers.dart';
import 'materials_mapping_table_view.dart';

/// Обертка для управления состоянием таблицы сопоставления материалов.
class MaterialsMappingBody extends ConsumerWidget {
  /// Создаёт экземпляр [MaterialsMappingBody].
  const MaterialsMappingBody({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Инициализация pager на первом билде
    ref.read(estimatesMappingPagerProvider.notifier).loadInitial();
    final pager = ref.watch(estimatesMappingPagerProvider);

    return pager.when(
      loading: () => const MaterialsMappingTableView(items: [], isLoading: true),
      error: (e, _) => MaterialsMappingTableView(items: const [], error: e),
      data: (rows) => MaterialsMappingTableView(items: rows),
    );
  }
}
