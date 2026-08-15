import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:projectgt/core/theme/theme_settings_provider.dart';
import 'package:projectgt/core/widgets/gt_buttons.dart';
import 'package:projectgt/core/widgets/mobile_atmosphere_backdrop.dart';
import 'package:projectgt/core/widgets/mobile_atmosphere_main_surface.dart';
import 'package:projectgt/core/widgets/mobile_atmosphere_screen_header.dart';
import 'package:projectgt/features/roles/application/permission_service.dart';
import 'package:projectgt/features/tmc/domain/entities/tmc_category.dart';
import 'package:projectgt/features/tmc/presentation/screens/tmc_item_details_screen.dart';
import 'package:projectgt/features/tmc/presentation/state/tmc_providers.dart';
import 'package:projectgt/features/tmc/presentation/utils/tmc_ui_labels.dart';
import 'package:projectgt/features/tmc/presentation/widgets/tmc_catalogs_panel.dart';
import 'package:projectgt/features/tmc/presentation/widgets/tmc_filters_toolbar.dart';
import 'package:projectgt/features/tmc/presentation/widgets/tmc_inventory_panel.dart';
import 'package:projectgt/features/tmc/presentation/widgets/tmc_item_form_dialog.dart';
import 'package:projectgt/features/tmc/presentation/widgets/tmc_items_table.dart';
import 'package:projectgt/features/tmc/presentation/widgets/tmc_kpi_cards.dart';
import 'package:projectgt/features/tmc/presentation/widgets/tmc_notifications_panel.dart';
import 'package:projectgt/features/tmc/presentation/widgets/tmc_operations_panel.dart';
import 'package:projectgt/features/tmc/presentation/widgets/tmc_reports_panel.dart';
import 'package:projectgt/features/tmc/presentation/widgets/tmc_section_nav.dart';
import 'package:projectgt/features/tmc/presentation/widgets/tmc_stock_panel.dart';
import 'package:projectgt/presentation/widgets/app_drawer.dart';

const _kHeaderPadding = EdgeInsets.fromLTRB(16, 20, 16, 8);
const _kBodyPadding = EdgeInsets.fromLTRB(16, 0, 16, 10);

/// Экран модуля ТМЦ: шапка модуля постоянна, разделы и карточка
/// открываются внутри основной области.
class TmcListScreen extends ConsumerStatefulWidget {
  /// Если задан — сразу показать карточку этой позиции.
  final String? openedItemId;

  /// Создаёт экран.
  const TmcListScreen({super.key, this.openedItemId});

  @override
  ConsumerState<TmcListScreen> createState() => _TmcListScreenState();
}

class _TmcListScreenState extends ConsumerState<TmcListScreen> {
  String? _openedItemId;
  TmcModuleSection _section = TmcModuleSection.registry;

  @override
  void initState() {
    super.initState();
    _openedItemId = widget.openedItemId;
  }

  @override
  void didUpdateWidget(covariant TmcListScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.openedItemId != oldWidget.openedItemId) {
      _openedItemId = widget.openedItemId;
    }
  }

  void _openItem(String itemId) {
    setState(() => _openedItemId = itemId);
  }

  void _closeOpenedItem() {
    setState(() => _openedItemId = null);
  }

  void _selectSection(TmcModuleSection section) {
    setState(() {
      _section = section;
      _openedItemId = null;
    });
  }

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
    final canViewCost = permissions.can('tmc', 'view_cost');
    final canCatalogs = permissions.can('tmc', 'manage_catalogs');

    final section = _section == TmcModuleSection.catalogs && !canCatalogs
        ? TmcModuleSection.registry
        : _section;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        systemNavigationBarColor: appearance.atmosphereBase,
        systemNavigationBarDividerColor: Colors.transparent,
        systemNavigationBarIconBrightness: isDark
            ? Brightness.light
            : Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: isDark
            ? appearance.atmosphereBase
            : Colors.transparent,
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
                            ref
                                .read(themeSettingsProvider.notifier)
                                .setThemeMode(
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
                                padding: const EdgeInsets.only(bottom: 10),
                                child: TmcKpiCards(
                                  stats: stats,
                                  showCost: canViewCost,
                                ),
                              ),
                              loading: () => const Padding(
                                padding: EdgeInsets.only(bottom: 10),
                                child: LinearProgressIndicator(),
                              ),
                              error: (e, _) => Text(e.toString()),
                            ),
                            TmcSectionNavBar(
                              selected: section,
                              onSelected: _selectSection,
                              showCatalogs: canCatalogs,
                            ),
                            const SizedBox(height: 10),
                            Expanded(
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  Offstage(
                                    offstage: _openedItemId != null,
                                    child: TickerMode(
                                      enabled: _openedItemId == null,
                                      child: _buildSection(
                                        section: section,
                                        listState: listState,
                                        categories:
                                            categoriesAsync.valueOrNull ??
                                            const [],
                                        canCreate: canCreate,
                                        canViewCost: canViewCost,
                                      ),
                                    ),
                                  ),
                                  if (_openedItemId != null)
                                    _buildOpenedItem(_openedItemId!),
                                ],
                              ),
                            ),
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

  Widget _buildSection({
    required TmcModuleSection section,
    required TmcItemsListState listState,
    required List<TmcCategory> categories,
    required bool canCreate,
    required bool canViewCost,
  }) {
    switch (section) {
      case TmcModuleSection.registry:
        final searchQuery = listState.filters.search ?? '';
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TmcFiltersToolbar(
              searchQuery: searchQuery,
              onSearchChanged: (v) {
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
              accountingType: listState.filters.accountingType,
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
              onClearFilters: () {
                ref.read(tmcItemsListProvider.notifier).applyFilters(
                  listState.filters.copyWith(
                    clearSearch: true,
                    clearCategoryId: true,
                    clearAccountingType: true,
                  ),
                );
              },
              categories: categories,
              onRefresh: () => ref.read(tmcItemsListProvider.notifier).load(),
              onCreate: canCreate
                  ? () => TmcItemFormDialog.show(context)
                  : null,
            ),
            const SizedBox(height: 8),
            Expanded(child: _buildRegistryBody(listState, canViewCost)),
            _buildRegistryPagination(listState),
          ],
        );
      case TmcModuleSection.operations:
        return const TmcOperationsPanel();
      case TmcModuleSection.stock:
        return TmcStockPanel(onOpenItem: _openItem);
      case TmcModuleSection.reports:
        return const TmcReportsPanel();
      case TmcModuleSection.inventory:
        return const TmcInventoryPanel();
      case TmcModuleSection.notifications:
        return const TmcNotificationsPanel();
      case TmcModuleSection.catalogs:
        return const TmcCatalogsPanel();
    }
  }

  Widget _buildRegistryBody(TmcItemsListState state, bool showCost) {
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
      final hasSearch = (state.filters.search ?? '').trim().isNotEmpty;
      return Center(
        child: Text(
          hasSearch ? TmcUiLabels.emptyFiltered : TmcUiLabels.emptyItems,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: scheme.onSurface.withValues(alpha: 0.55),
          ),
        ),
      );
    }

    return TmcItemsTable(
      items: state.items,
      showCost: showCost,
      rowNumberOffset: state.filters.offset,
      onRowTap: (item) => _openItem(item.id),
    );
  }

  Widget _buildRegistryPagination(TmcItemsListState state) {
    if (state.totalCount <= state.filters.limit) {
      return const SizedBox.shrink();
    }

    final notifier = ref.read(tmcItemsListProvider.notifier);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final from = state.filters.offset + 1;
    final to = state.filters.offset + state.items.length;

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          GTTextButton(
            text: 'Назад',
            onPressed: notifier.hasPreviousPage && !state.isLoading
                ? notifier.goToPreviousPage
                : null,
          ),
          const SizedBox(width: 8),
          Text(
            TmcUiLabels.itemsPageRange(from, to, state.totalCount),
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(width: 8),
          GTTextButton(
            text: 'Далее',
            onPressed: notifier.hasNextPage && !state.isLoading
                ? notifier.goToNextPage
                : null,
          ),
          if (state.isLoading) ...[
            const SizedBox(width: 8),
            const SizedBox(
              width: 16,
              height: 16,
              child: CupertinoActivityIndicator(radius: 8),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildOpenedItem(String itemId) {
    final appearance = MobileAtmosphereAppearance.of(context);
    final theme = Theme.of(context);
    final itemAsync = ref.watch(tmcItemProvider(itemId));
    final title = itemAsync.valueOrNull?.name ?? TmcUiLabels.itemCard;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            MobileAtmosphereChromeCircleButton(
              appearance: appearance,
              tooltip: _section == TmcModuleSection.registry
                  ? TmcUiLabels.backToRegistry
                  : TmcUiLabels.back,
              icon: Icons.arrow_back_rounded,
              onTap: _closeOpenedItem,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Expanded(child: TmcItemDetailsPanel(itemId: itemId)),
      ],
    );
  }
}
