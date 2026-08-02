import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:projectgt/core/common/app_router.dart';
import 'package:projectgt/core/theme/theme_settings_provider.dart';
import 'package:projectgt/core/widgets/mobile_atmosphere_backdrop.dart';
import 'package:projectgt/core/widgets/mobile_atmosphere_main_surface.dart';
import 'package:projectgt/core/widgets/mobile_atmosphere_screen_header.dart';
import 'package:projectgt/features/roles/application/permission_service.dart';
import 'package:projectgt/features/tmc/domain/entities/tmc_enums.dart';
import 'package:projectgt/features/tmc/domain/entities/tmc_item.dart';
import 'package:projectgt/features/tmc/presentation/state/tmc_providers.dart';
import 'package:projectgt/features/tmc/presentation/utils/tmc_ui_labels.dart';
import 'package:projectgt/features/tmc/presentation/widgets/tmc_catalogs_dialog.dart';
import 'package:projectgt/features/tmc/presentation/widgets/tmc_filters_toolbar.dart';
import 'package:projectgt/features/tmc/presentation/widgets/tmc_item_form_dialog.dart';
import 'package:projectgt/features/tmc/presentation/widgets/tmc_items_table.dart';
import 'package:projectgt/features/tmc/presentation/widgets/tmc_kpi_cards.dart';
import 'package:projectgt/features/tmc/presentation/widgets/tmc_operation_dialog.dart';
import 'package:projectgt/presentation/widgets/app_drawer.dart';

const _kHeaderPadding = EdgeInsets.fromLTRB(16, 20, 16, 8);
const _kBodyPadding = EdgeInsets.fromLTRB(16, 0, 16, 10);

/// Desktop-first экран реестра ТМЦ.
class TmcListScreen extends ConsumerStatefulWidget {
  /// Создаёт экран.
  const TmcListScreen({super.key});

  @override
  ConsumerState<TmcListScreen> createState() => _TmcListScreenState();
}

class _TmcListScreenState extends ConsumerState<TmcListScreen> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final listState = ref.watch(tmcItemsListProvider);
    final dashboardAsync = ref.watch(tmcDashboardProvider);
    final categoriesAsync = ref.watch(tmcCategoriesProvider);
    final permissions = ref.watch(permissionServiceProvider);
    final appearance = MobileAtmosphereAppearance.of(context);
    final scheme = appearance.scheme;
    final isDark = appearance.isDark;
    final theme = Theme.of(context);

    final canCreate = permissions.can('tmc', 'create');
    final canIssue = permissions.can('tmc', 'issue');
    final canMove = permissions.can('tmc', 'move');
    final canViewCost = permissions.can('tmc', 'view_cost');
    final canCatalogs = permissions.can('tmc', 'manage_catalogs');

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
        drawer: const AppDrawer(activeRoute: AppRoute.tmc),
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
                    padding: _kHeaderPadding,
                    child: Row(
                      children: [
                        Builder(
                          builder: (ctx) => MobileAtmosphereChromeCircleButton(
                            appearance: appearance,
                            tooltip: 'Меню',
                            icon: Icons.menu_rounded,
                            onTap: () => Scaffold.of(ctx).openDrawer(),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            TmcUiLabels.moduleTitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleLarge?.copyWith(
                              color: scheme.onSurface,
                            ),
                          ),
                        ),
                        MobileAtmosphereChromeCircleButton(
                          appearance: appearance,
                          tooltip: isDark ? 'Светлая тема' : 'Тёмная тема',
                          icon: isDark
                              ? Icons.light_mode_outlined
                              : Icons.dark_mode_outlined,
                          onTap: () {
                            ref.read(themeSettingsProvider.notifier).setThemeMode(
                                  isDark ? ThemeMode.light : ThemeMode.dark,
                                );
                          },
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: _kBodyPadding,
                      child: MobileAtmosphereMainSurface(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            dashboardAsync.when(
                              data: (stats) => Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: TmcKpiCards(
                                  stats: stats,
                                  showCost: canViewCost,
                                ),
                              ),
                              loading: () => const Padding(
                                padding: EdgeInsets.all(12),
                                child: LinearProgressIndicator(),
                              ),
                              error: (e, _) => Text(e.toString()),
                            ),
                            categoriesAsync.when(
                              data: (categories) => TmcFiltersToolbar(
                                searchQuery: _search,
                                onSearchChanged: (v) {
                                  setState(() => _search = v);
                                  ref
                                      .read(tmcItemsListProvider.notifier)
                                      .applyFilters(
                                        listState.filters.copyWith(
                                          search: v.trim().isEmpty ? null : v,
                                          clearSearch: v.trim().isEmpty,
                                        ),
                                      );
                                },
                                categoryId: listState.filters.categoryId,
                                onCategoryChanged: (id) {
                                  ref
                                      .read(tmcItemsListProvider.notifier)
                                      .applyFilters(
                                        listState.filters.copyWith(
                                          categoryId: id,
                                          clearCategoryId: id == null,
                                        ),
                                      );
                                },
                                accountingType:
                                    listState.filters.accountingType,
                                onAccountingTypeChanged: (t) {
                                  ref
                                      .read(tmcItemsListProvider.notifier)
                                      .applyFilters(
                                        listState.filters.copyWith(
                                          accountingType: t,
                                          clearAccountingType: t == null,
                                        ),
                                      );
                                },
                                categories: categories,
                                onRefresh: () =>
                                    ref.read(tmcItemsListProvider.notifier).load(),
                                onCreate: canCreate
                                    ? () => TmcItemFormDialog.show(context)
                                    : null,
                                onCatalogs: canCatalogs
                                    ? () => TmcCatalogsDialog.show(context)
                                    : null,
                                onOperations: () =>
                                    context.push(AppRoutes.tmcOperations),
                                onStock: () =>
                                    context.push(AppRoutes.tmcStock),
                                onReports: () =>
                                    context.push(AppRoutes.tmcReports),
                                onNotifications: () =>
                                    context.push(AppRoutes.tmcNotifications),
                              ),
                              loading: () => const LinearProgressIndicator(),
                              error: (e, _) => Text(e.toString()),
                            ),
                            const SizedBox(height: 12),
                            Expanded(child: _buildBody(listState, canIssue, canMove, canViewCost)),
                          ],
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

  Widget _buildBody(
    TmcItemsListState state,
    bool canIssue,
    bool canMove,
    bool showCost,
  ) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    if (state.isLoading && state.items.isEmpty) {
      return const Center(child: CupertinoActivityIndicator());
    }
    if (state.error != null && state.items.isEmpty) {
      return Center(
        child: Text(
          state.error!,
          style: theme.textTheme.bodyMedium?.copyWith(color: scheme.error),
        ),
      );
    }
    if (state.items.isEmpty) {
      return Center(
        child: Text(
          _search.trim().isEmpty
              ? TmcUiLabels.emptyItems
              : TmcUiLabels.emptyFiltered,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: scheme.onSurface.withValues(alpha: 0.55),
          ),
        ),
      );
    }

    return TmcItemsTable(
      items: state.items,
      showCost: showCost,
      onRowTap: (item) => context.push('${AppRoutes.tmc}/items/${item.id}'),
      onIssue: canIssue ? _quickIssue : null,
      onReturn: canIssue ? _quickReturn : null,
      onMove: canMove ? _quickMove : null,
    );
  }

  void _quickIssue(TmcItem item) {
    TmcOperationDialog.show(
      context,
      operationType: TmcOperationType.issue,
      item: item,
    );
  }

  void _quickReturn(TmcItem item) {
    TmcOperationDialog.show(
      context,
      operationType: TmcOperationType.returnFromEmployee,
      item: item,
    );
  }

  void _quickMove(TmcItem item) {
    TmcOperationDialog.show(
      context,
      operationType: TmcOperationType.moveBetweenWarehouses,
      item: item,
    );
  }
}
