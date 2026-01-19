import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:projectgt/presentation/widgets/app_bar_widget.dart';
import 'package:projectgt/presentation/widgets/app_drawer.dart';
import 'package:projectgt/features/roles/presentation/widgets/permission_guard.dart';
import '../widgets/materials_import_action.dart';
import '../widgets/contracts_filter_chips.dart';
import '../widgets/materials_table_view.dart';
import '../widgets/materials_grouped_table_view.dart';
import '../providers/materials_providers.dart';

/// Экран раздела «Материал».
///
/// Поддерживает два режима отображения: "Материал по М-15" и
/// "Сгруппировано по смете" с плавной анимацией переключения.
class MaterialScreen extends ConsumerWidget {
  /// Создаёт экран «Материал».
  const MaterialScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isGrouped = ref.watch(isMaterialsGroupedProvider);

    return Scaffold(
      appBar: AppBarWidget(
        title: isGrouped ? 'Материалы (Сводно)' : 'Материал по М-15',
        showSearchField: false,
        actions: [
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
              duration: const Duration(milliseconds: 400),
              switchInCurve: Curves.easeInOutCubic,
              switchOutCurve: Curves.easeInOutCubic,
              transitionBuilder: (Widget child, Animation<double> animation) {
                return FadeTransition(
                  opacity: animation,
                  child: ScaleTransition(
                    scale: animation.drive(
                      Tween<double>(begin: 0.98, end: 1.0),
                    ),
                    child: child,
                  ),
                );
              },
              child: isGrouped
                  ? const MaterialsGroupedTableWidget(key: ValueKey('grouped'))
                  : const MaterialsTableWidget(key: ValueKey('m15')),
            ),
          ),
        ),
      ),
    );
  }
}
