import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:projectgt/core/refresh/refresh_models.dart';
import 'package:projectgt/core/refresh/app_focus_refresh_coordinator.dart';
import 'package:projectgt/presentation/widgets/app_bar_widget.dart';
import 'package:projectgt/presentation/widgets/app_drawer.dart';
import 'package:projectgt/features/roles/presentation/widgets/permission_guard.dart';
import '../widgets/materials_import_action.dart';
import '../widgets/contracts_filter_chips.dart';
import '../widgets/materials_vor_export_action.dart';
import '../widgets/materials_table_view.dart';
import '../widgets/materials_grouped_table_view.dart';
import '../providers/materials_providers.dart';

/// Экран раздела «Материал».
///
/// Поддерживает два режима отображения: "Материал по М-15" и
/// "Сгруппировано по смете" с плавной анимацией переключения.
class MaterialScreen extends ConsumerStatefulWidget {
  /// Создаёт экран «Материал».
  const MaterialScreen({super.key});

  @override
  ConsumerState<MaterialScreen> createState() => _MaterialScreenState();
}

class _MaterialScreenState extends ConsumerState<MaterialScreen> {
  late final AppFocusRefreshCoordinator _refreshCoordinator;

  @override
  void initState() {
    super.initState();
    _refreshCoordinator = ref.read(appFocusRefreshProvider.notifier);

    // Регистрация цели автоматического обновления для модуля материалов
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _refreshCoordinator.registerTarget(
          RefreshTarget(
            id: 'materials',
            callback: (ref) async {
              // Обновляем материалы
              ref.invalidate(materialsListProvider);
              ref.invalidate(materialsGroupedListProvider);
            },
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _refreshCoordinator.unregisterTarget('materials');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
          const MaterialsVorExportAction(),
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
