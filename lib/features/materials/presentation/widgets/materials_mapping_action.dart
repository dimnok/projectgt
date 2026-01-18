import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/materials_providers.dart';

/// Действие AppBar: переключение между М-15 и сопоставлением материалов.
///
/// Кнопка-шестерёнка переключает режим отображения на текущем экране.
class MaterialsMappingAction extends ConsumerWidget {
  /// Конструктор действия переключения режима материалов.
  const MaterialsMappingAction({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewMode = ref.watch(materialsViewModeProvider);
    final isMapping = viewMode == MaterialsViewMode.mapping;

    return IconButton(
      tooltip: isMapping ? 'К материалам М-15' : 'Сопоставление материалов',
      icon: Icon(isMapping ? Icons.list_alt : Icons.settings_outlined),
      onPressed: () {
        ref.read(materialsViewModeProvider.notifier).state = isMapping
            ? MaterialsViewMode.m15
            : MaterialsViewMode.mapping;
      },
    );
  }
}
