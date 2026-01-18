import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:projectgt/presentation/widgets/app_bar_widget.dart';
import 'package:projectgt/presentation/widgets/app_drawer.dart';
import 'package:projectgt/features/roles/presentation/widgets/permission_guard.dart';
import '../widgets/materials_import_action.dart';
import '../widgets/materials_mapping_action.dart';
import '../widgets/contracts_filter_chips.dart';
import '../widgets/materials_table_view.dart';
import '../widgets/materials_grouped_table_view.dart';
import '../widgets/materials_mapping_body.dart';
import '../providers/materials_providers.dart';

/// Экран раздела «Материал».
///
/// Поддерживает три режима отображения: "Материал по М-15",
/// "Сгруппировано по смете" и "Сопоставление материалов"
/// с плавной анимацией переключения.
class MaterialScreen extends ConsumerWidget {
  /// Создаёт экран «Материал».
  const MaterialScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final viewMode = ref.watch(materialsViewModeProvider);
    final isGrouped = ref.watch(isMaterialsGroupedProvider);
    final isMapping = viewMode == MaterialsViewMode.mapping;

    String getTitle() {
      if (isMapping) return 'Сопоставление материалов';
      if (isGrouped) return 'Материалы (Сводно)';
      return 'Материал по М-15';
    }

    return Scaffold(
      appBar: AppBarWidget(
        title: getTitle(),
        showSearchField: false,
        actions: [
          if (!isMapping)
            IconButton(
              icon: Icon(
                isGrouped ? Icons.layers_clear : Icons.layers,
                color: isGrouped ? theme.colorScheme.primary : null,
              ),
              tooltip: isGrouped
                  ? 'Показать накладные (M-15)'
                  : 'Сгруппировать по смете',
              onPressed: () =>
                  ref.read(isMaterialsGroupedProvider.notifier).state =
                      !isGrouped,
            ),
          const PermissionGuard(
            module: 'materials',
            permission: 'update',
            child: MaterialsMappingAction(),
          ),
          const PermissionGuard(
            module: 'materials',
            permission: 'import',
            child: MaterialsImportAction(),
          ),
          const SizedBox(width: 8),
          const ContractsFilterChips(),
          const SizedBox(width: 8),
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
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 500),
              switchInCurve: Curves.easeInOutCubic,
              switchOutCurve: Curves.easeInOutCubic,
              transitionBuilder: (Widget child, Animation<double> animation) {
                // Определяем направление анимации по ключу виджета
                final isMappingChild = child.key == const ValueKey('mapping');
                final isGroupedChild = child.key == const ValueKey('grouped');

                if (isMappingChild) {
                  return SlideTransition(
                    position: animation.drive(
                      Tween<Offset>(
                        begin: const Offset(0, -1),
                        end: Offset.zero,
                      ),
                    ),
                    child: child,
                  );
                } else if (isGroupedChild) {
                  return FadeTransition(
                    opacity: animation,
                    child: ScaleTransition(
                      scale: animation.drive(
                        Tween<double>(begin: 0.95, end: 1.0),
                      ),
                      child: child,
                    ),
                  );
                } else {
                  return SlideTransition(
                    position: animation.drive(
                      Tween<Offset>(
                        begin: const Offset(0, 1),
                        end: Offset.zero,
                      ),
                    ),
                    child: child,
                  );
                }
              },
              layoutBuilder:
                  (Widget? currentChild, List<Widget> previousChildren) {
                    return Stack(
                      children: [
                        ...previousChildren,
                        if (currentChild != null) currentChild,
                      ],
                    );
                  },
              child: isMapping
                  ? const MaterialsMappingBody(key: ValueKey('mapping'))
                  : isGrouped
                  ? const MaterialsGroupedTableWidget(key: ValueKey('grouped'))
                  : const MaterialsTableWidget(key: ValueKey('m15')),
            ),
          ),
        ),
      ),
    );
  }
}
