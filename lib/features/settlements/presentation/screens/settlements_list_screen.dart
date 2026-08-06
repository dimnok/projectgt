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

    final contractorOptions = syncedFilters.contractorOptions(operations);
    final objectOptions = syncedFilters.objectOptions(operations);
    final contractOptions = syncedFilters.contractOptions(operations);
    final filtered = syncedFilters.apply(operations);
    final appearance = MobileAtmosphereAppearance.of(context);
    final scheme = appearance.scheme;
    final isDark = appearance.isDark;
    final useMobileList = EmployeesLayoutUtils.useEmployeesMobileList(context);
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
                                child: Text(
                                  _screenTitle,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    color: scheme.onSurface,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
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
                    child: Padding(
                      padding: _kBodyPadding,
                      child: MobileAtmosphereMainSurface(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            SettlementsFiltersToolbar(
                              searchQuery: syncedFilters.search,
                              onSearchChanged: (v) => setState(
                                () => _filters = syncedFilters.copyWith(
                                  search: v,
                                ),
                              ),
                              typeFilter: syncedFilters.operationType,
                              onTypeChanged: (v) => setState(
                                () => _filters = syncedFilters.copyWith(
                                  operationType: v,
                                  clearOperationType: v == null,
                                ),
                              ),
                              paymentStatusFilter: syncedFilters.paymentStatus,
                              onPaymentStatusChanged: (v) => setState(
                                () => _filters = syncedFilters.copyWith(
                                  paymentStatus: v,
                                  clearPaymentStatus: v == null,
                                ),
                              ),
                              contractorOptions: contractorOptions,
                              contractorFilterId: syncedFilters.contractorId,
                              onContractorChanged: (v) => setState(
                                () => _filters = syncedFilters.withContractor(
                                  v,
                                  operations,
                                ),
                              ),
                              objectOptions: objectOptions,
                              objectFilterId: syncedFilters.objectId,
                              onObjectChanged: (v) => setState(
                                () => _filters = syncedFilters.withObject(
                                  v,
                                  operations,
                                ),
                              ),
                              contractOptions: contractOptions,
                              contractFilterId: syncedFilters.contractId,
                              onContractChanged: (v) => setState(
                                () => _filters = syncedFilters.withContract(
                                  v,
                                  operations,
                                ),
                              ),
                              hasActiveFilters: syncedFilters.hasActive,
                              onResetFilters: _resetFilters,
                              onCreate: canCreate
                                  ? () => SettlementFormDialog.show(context)
                                  : null,
                            ),
                            const SizedBox(height: 12),
                            Expanded(child: _buildBody(state, filtered)),
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
    SettlementListState state,
    List<SettlementOperation> filtered,
  ) {
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
              : 'Ничего не найдено по фильтрам',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: scheme.onSurface.withValues(alpha: 0.55),
          ),
        ),
      );
    }

    return SettlementsOperationsTable(
      operations: filtered,
      onRowTap: (op) => SettlementDetailsDialog.show(context, operation: op),
    );
  }
}
