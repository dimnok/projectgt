import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:projectgt/core/refresh/app_focus_refresh_coordinator.dart';
import 'package:projectgt/core/refresh/refresh_models.dart';
import 'package:projectgt/core/theme/theme_settings_provider.dart';
import 'package:projectgt/core/widgets/mobile_atmosphere_backdrop.dart';
import 'package:projectgt/core/widgets/mobile_atmosphere_screen_header.dart';
import 'package:projectgt/features/roles/presentation/widgets/permission_guard.dart';
import 'package:projectgt/presentation/widgets/app_drawer.dart';
import '../providers/materials_context_providers.dart';
import '../providers/materials_providers.dart';
import '../widgets/materials_grouped_table_view.dart';
import '../widgets/materials_import_action.dart';
import '../widgets/materials_list_chrome.dart';
import '../widgets/materials_list_filters_bar.dart';
import '../widgets/materials_table_view.dart';
import '../widgets/materials_vor_export_action.dart';

/// Экран раздела «Материал».
///
/// Оформление согласовано с модулем «Договоры»: атмосфера, шапка с «хромом»,
/// полоса фильтров и таблица без обёртки [Card].
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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _refreshCoordinator.registerTarget(
        RefreshTarget(
          id: 'materials',
          callback: (ref) async {
            ref.invalidate(materialsListProvider);
            ref.invalidate(materialsGroupedListProvider);
          },
        ),
      );
    });
  }

  @override
  void dispose() {
    _refreshCoordinator.unregisterTarget('materials');
    super.dispose();
  }

  String _screenTitle(bool isGrouped) {
    return isGrouped ? 'Материалы (Сводно)' : 'Материал по М-15';
  }

  Widget _buildHeaderTrailing({
    required MobileAtmosphereAppearance appearance,
    required bool hasContract,
    required bool isGrouped,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (hasContract) ...[
          MobileAtmosphereChromeCircleButton(
            appearance: appearance,
            tooltip: isGrouped
                ? 'Показать накладные (M-15)'
                : 'Сгруппировать по смете',
            icon: isGrouped ? Icons.layers_clear_rounded : Icons.layers_rounded,
            iconColor: isGrouped ? appearance.scheme.primary : null,
            onTap: () => ref.read(isMaterialsGroupedProvider.notifier).state =
                !isGrouped,
          ),
          const SizedBox(width: 4),
          MaterialsVorExportAction(appearance: appearance),
          const SizedBox(width: 4),
          PermissionGuard(
            module: 'materials',
            permission: 'import',
            child: MaterialsImportAction(appearance: appearance),
          ),
          const SizedBox(width: 4),
        ],
        MobileAtmosphereChromeCircleButton(
          appearance: appearance,
          tooltip: appearance.isDark ? 'Светлая тема' : 'Тёмная тема',
          icon: appearance.isDark
              ? Icons.light_mode_outlined
              : Icons.dark_mode_outlined,
          onTap: () {
            ref.read(themeSettingsProvider.notifier).setThemeMode(
                  appearance.isDark ? ThemeMode.light : ThemeMode.dark,
                );
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final appearance = MobileAtmosphereAppearance.of(context);
    final isDark = appearance.isDark;
    final contractNumber = ref.watch(selectedContractNumberProvider);
    final hasContract = hasMaterialsContractSelection(contractNumber);
    final isGrouped = ref.watch(isMaterialsGroupedProvider);

    ref.listen<String?>(selectedContractNumberProvider, (previous, next) {
      if (!hasMaterialsContractSelection(next) &&
          ref.read(isMaterialsGroupedProvider)) {
        ref.read(isMaterialsGroupedProvider.notifier).state = false;
      }
    });

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        systemNavigationBarColor: appearance.atmosphereBase,
        systemNavigationBarDividerColor: Colors.transparent,
        systemNavigationBarIconBrightness:
            isDark ? Brightness.light : Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor:
            isDark ? appearance.atmosphereBase : Colors.transparent,
        drawer: const AppDrawer(activeRoute: AppRoute.material),
        body: Stack(
          fit: StackFit.expand,
          children: [
            const MobileAtmosphereBackdrop(),
            SafeArea(
              bottom: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: MaterialsListScreenChrome.headerOuterPadding,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        MobileAtmosphereScreenHeader(
                          appearance: appearance,
                          title: _screenTitle(isGrouped),
                          leading: Builder(
                            builder: (ctx) => MobileAtmosphereChromeCircleButton(
                              appearance: appearance,
                              tooltip: 'Меню',
                              icon: Icons.menu_rounded,
                              onTap: () => Scaffold.of(ctx).openDrawer(),
                            ),
                          ),
                          trailing: _buildHeaderTrailing(
                            appearance: appearance,
                            hasContract: hasContract,
                            isGrouped: isGrouped,
                          ),
                        ),
                        const SizedBox(height: 10),
                        MaterialsListFiltersBar(
                          borderSide: BorderSide(
                            color: appearance.chromeBorder,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: MaterialsListScreenChrome.bodyOuterPadding,
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        switchInCurve: Curves.easeInOutCubic,
                        switchOutCurve: Curves.easeInOutCubic,
                        child: isGrouped
                            ? const MaterialsGroupedTableWidget(
                                key: ValueKey('grouped'),
                              )
                            : const MaterialsTableWidget(
                                key: ValueKey('m15'),
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
