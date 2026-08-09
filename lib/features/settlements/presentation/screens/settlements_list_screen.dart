import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:projectgt/core/theme/theme_settings_provider.dart';
import 'package:projectgt/core/widgets/mobile_atmosphere_backdrop.dart';
import 'package:projectgt/core/widgets/mobile_atmosphere_main_surface.dart';
import 'package:projectgt/core/widgets/mobile_atmosphere_screen_header.dart';
import 'package:projectgt/features/employees/presentation/utils/employees_layout_utils.dart';
import 'package:projectgt/features/roles/application/permission_service.dart';
import 'package:projectgt/features/settlements/domain/entities/settlement_operation.dart';
import 'package:projectgt/features/settlements/presentation/state/settlement_state.dart';
import 'package:projectgt/features/settlements/presentation/utils/settlements_list_filters.dart';
import 'package:projectgt/features/settlements/presentation/widgets/settlement_details_dialog.dart';
import 'package:projectgt/features/settlements/presentation/widgets/settlement_form_dialog.dart';
import 'package:projectgt/features/settlements/presentation/widgets/settlements_filters_toolbar.dart';
import 'package:projectgt/features/settlements/presentation/widgets/settlements_mobile_search_field.dart';
import 'package:projectgt/features/settlements/presentation/widgets/settlements_operations_mobile_view.dart';
import 'package:projectgt/features/settlements/presentation/widgets/settlements_operations_table.dart';
import 'package:projectgt/presentation/widgets/app_drawer.dart';

const _kHeaderPadding = EdgeInsets.fromLTRB(16, 20, 16, 8);
const _kBodyPadding = EdgeInsets.fromLTRB(16, 0, 16, 10);

/// Экран реестра взаиморасчётов (шапка как у Табеля / ФОТ).
class SettlementsListScreen extends ConsumerStatefulWidget {
  /// Создаёт экран.
  const SettlementsListScreen({super.key});

  @override
  ConsumerState<SettlementsListScreen> createState() =>
      _SettlementsListScreenState();
}

class _SettlementsListScreenState extends ConsumerState<SettlementsListScreen> {
  SettlementsListFilters _filters = const SettlementsListFilters();

  static const _screenTitle = 'Взаиморасчёты';

  void _resetFilters() {
    setState(() => _filters = _filters.cleared());
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(settlementListProvider);
    final operations = state.operations;
    final syncedFilters = _filters.syncedWith(operations);
    if (syncedFilters != _filters) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _filters = syncedFilters);
      });
    }

    final useMobileList = EmployeesLayoutUtils.useEmployeesMobileList(context);
    final filtered = syncedFilters.apply(operations);
    final appearance = MobileAtmosphereAppearance.of(context);
    final scheme = appearance.scheme;
    final isDark = appearance.isDark;
    final theme = Theme.of(context);
    final canCreate = ref
        .watch(permissionServiceProvider)
        .can('settlements', 'create');

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
        drawer: const AppDrawer(activeRoute: AppRoute.settlements),
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
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final narrow = constraints.maxWidth < 560;
                        final menuButton = Builder(
                          builder: (ctx) => MobileAtmosphereChromeCircleButton(
                            appearance: appearance,
                            tooltip: 'Меню',
                            icon: Icons.menu_rounded,
                            onTap: () => Scaffold.of(ctx).openDrawer(),
                          ),
                        );
                        final themeButton = MobileAtmosphereChromeCircleButton(
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
                        );

                        if (useMobileList) {
                          return Row(
                            children: [
                              menuButton,
                              const SizedBox(width: 8),
                              Expanded(
                                child: SettlementsMobileSearchField(
                                  searchQuery: syncedFilters.search,
                                  onSearchChanged: (v) => _updateFilters(
                                    syncedFilters.copyWith(search: v),
                                  ),
                                ),
                              ),
                              if (canCreate) ...[
                                const SizedBox(width: 4),
                                MobileAtmosphereChromeCircleButton(
                                  appearance: appearance,
                                  tooltip: 'Новый счёт',
                                  icon: Icons.add_rounded,
                                  iconColor: scheme.primary,
                                  iconSize: 26,
                                  onTap: () =>
                                      SettlementFormDialog.show(context),
                                ),
                              ],
                              const SizedBox(width: 4),
                              themeButton,
                            ],
                          );
                        }

                        if (narrow) {
                          return MobileAtmosphereScreenHeader(
                            appearance: appearance,
                            title: _screenTitle,
                            leading: menuButton,
                            trailing: themeButton,
                          );
                        }

                        return Row(
                          children: [
                            menuButton,
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _screenTitle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.titleLarge?.copyWith(
                                  color: scheme.onSurface,
                                ),
                              ),
                            ),
                            themeButton,
                          ],
                        );
                      },
                    ),
                  ),
                  Expanded(
                    child: useMobileList
                        ? _buildMobileBody(state, filtered)
                        : _buildDesktopBody(
                            state,
                            filtered,
                            syncedFilters,
                            operations,
                            canCreate,
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

  void _updateFilters(SettlementsListFilters next) {
    setState(() => _filters = next);
  }

  Widget _buildDesktopBody(
    SettlementListState state,
    List<SettlementOperation> filtered,
    SettlementsListFilters syncedFilters,
    List<SettlementOperation> operations,
    bool canCreate,
  ) {
    return Padding(
      padding: _kBodyPadding,
      child: MobileAtmosphereMainSurface(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SettlementsFiltersToolbar(
              searchQuery: syncedFilters.search,
              onSearchChanged: (v) =>
                  _updateFilters(syncedFilters.copyWith(search: v)),
              typeFilter: syncedFilters.operationType,
              onTypeChanged: (v) => _updateFilters(
                syncedFilters.copyWith(
                  operationType: v,
                  clearOperationType: v == null,
                ),
              ),
              paymentStatusFilter: syncedFilters.paymentStatus,
              onPaymentStatusChanged: (v) => _updateFilters(
                syncedFilters.copyWith(
                  paymentStatus: v,
                  clearPaymentStatus: v == null,
                ),
              ),
              contractorOptions: syncedFilters.contractorOptions(operations),
              contractorFilterId: syncedFilters.contractorId,
              onContractorChanged: (v) => _updateFilters(
                syncedFilters.withContractor(v, operations),
              ),
              objectOptions: syncedFilters.objectOptions(operations),
              objectFilterId: syncedFilters.objectId,
              onObjectChanged: (v) =>
                  _updateFilters(syncedFilters.withObject(v, operations)),
              contractOptions: syncedFilters.contractOptions(operations),
              contractFilterId: syncedFilters.contractId,
              onContractChanged: (v) =>
                  _updateFilters(syncedFilters.withContract(v, operations)),
              hasActiveFilters: syncedFilters.hasActive,
              onResetFilters: _resetFilters,
              onCreate: canCreate
                  ? () => SettlementFormDialog.show(context)
                  : null,
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _buildOperationsBody(state, filtered) ??
                  SettlementsOperationsTable(
                    operations: filtered,
                    onRowTap: (op) =>
                        SettlementDetailsDialog.show(context, operation: op),
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileBody(
    SettlementListState state,
    List<SettlementOperation> filtered,
  ) {
    final body = _buildOperationsBody(
      state,
      filtered,
      emptySearchMessage: 'Ничего не найдено по поиску',
    );
    if (body != null) return body;

    return SettlementsOperationsMobileView(
      operations: filtered,
      onCardTap: (op) => SettlementDetailsDialog.show(context, operation: op),
    );
  }

  /// Общие состояния списка (загрузка, ошибка, пусто). `null` — показывать данные.
  Widget? _buildOperationsBody(
    SettlementListState state,
    List<SettlementOperation> filtered, {
    String emptySearchMessage = 'Ничего не найдено по фильтрам',
  }) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    if (state.isLoading && state.operations.isEmpty) {
      return const Center(child: CupertinoActivityIndicator());
    }
    if (state.error != null && state.operations.isEmpty) {
      return Center(
        child: Text(
          state.error!,
          style: theme.textTheme.bodyMedium?.copyWith(color: scheme.error),
        ),
      );
    }
    if (filtered.isEmpty) {
      return Center(
        child: Text(
          state.operations.isEmpty
              ? 'Счетов пока нет — создайте первый'
              : emptySearchMessage,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: scheme.onSurface.withValues(alpha: 0.55),
          ),
        ),
      );
    }
    return null;
  }
}
