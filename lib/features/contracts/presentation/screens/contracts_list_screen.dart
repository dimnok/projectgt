import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:projectgt/core/di/providers.dart';
import 'package:projectgt/core/refresh/app_focus_refresh_coordinator.dart';
import 'package:projectgt/core/refresh/refresh_models.dart';
import 'package:projectgt/core/theme/theme_settings_provider.dart';
import 'package:projectgt/core/utils/responsive_utils.dart';
import 'package:projectgt/core/widgets/gt_text_field.dart';
import 'package:projectgt/core/widgets/mobile_atmosphere_backdrop.dart';
import 'package:projectgt/core/widgets/mobile_atmosphere_screen_header.dart';
import 'package:projectgt/domain/entities/contract.dart';
import 'package:projectgt/features/contracts/presentation/screens/desktop/contracts_list_inline_detail_view.dart';
import 'package:projectgt/features/contracts/presentation/widgets/contract_detail_navigation_section.dart';
import 'package:projectgt/features/contracts/presentation/widgets/contract_list_shared.dart';
import 'package:projectgt/features/contracts/presentation/widgets/contracts_list_filters_bar.dart';
import 'package:projectgt/features/contracts/presentation/widgets/contracts_quick_actions_sidebar.dart';
import 'package:projectgt/features/roles/presentation/widgets/permission_guard.dart';
import 'package:projectgt/presentation/state/contract_state.dart';
import 'package:projectgt/presentation/widgets/app_drawer.dart';

import 'contract_form_screen.dart';

/// Экран списка договоров: один хром сетки (поиск, фильтры, таблица).
///
/// Тело списка — [ContractsListInlineDetailView] (детали вместо таблицы).
/// Режим с модальным диалогом сохранён в `contracts_list_desktop_view.dart`
/// (`ContractsListDesktopView`).
///
/// Отдельная мобильная вёрстка не используется — на узкой ширине остаётся тот же
/// хром без панели быстрых действий. [MobileAtmosphereBackdrop], кнопки в шапке,
/// без классического [AppBar].
class ContractsListScreen extends ConsumerStatefulWidget {
  /// Создаёт экран списка договоров.
  const ContractsListScreen({super.key});

  @override
  ConsumerState<ContractsListScreen> createState() =>
      _ContractsListScreenState();
}

class _ContractsListScreenState extends ConsumerState<ContractsListScreen> {
  late final TextEditingController _searchController;
  late final AppFocusRefreshCoordinator _refreshCoordinator;
  final GlobalKey _filtersBarKey = GlobalKey();

  /// Синхронизация верхнего отступа сайдбара с режимом «таблица / встроенные детали».
  bool _contractsInlineDetailActive = false;
  double? _filtersBarHeight;

  ContractKind? _filterKind;
  String? _filterContractorId;
  String? _filterObjectId;

  /// Выбранный во встроенных деталях договор (контекст сайдбара).
  Contract? _sidebarDetailContract;

  /// Активный подраздел навигации карточки (сайдбар «Быстрые действия»).
  ContractDetailNavigationSection _sidebarDetailSection =
      ContractDetailNavigationSection.general;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _searchController.addListener(() {
      if (mounted) setState(() {});
    });

    _refreshCoordinator = ref.read(appFocusRefreshProvider.notifier);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _refreshCoordinator.registerTarget(
        RefreshTarget(
          id: 'contracts',
          callback: (ref) async {
            await ref
                .read(contractProvider.notifier)
                .loadContracts(quiet: true);
          },
        ),
      );
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _refreshCoordinator.unregisterTarget('contracts');
    super.dispose();
  }

  void _captureFiltersBarHeight() {
    final height = _filtersBarKey.currentContext?.size?.height;
    if (height == null || height == _filtersBarHeight) return;
    setState(() => _filtersBarHeight = height);
  }

  Future<void> _showContractForm([Contract? contract]) async {
    final isDesktop = ResponsiveUtils.isDesktop(context);

    if (isDesktop) {
      await ContractFormModal.show(context, contract: contract);
    } else {
      await showModalBottomSheet<void>(
        context: context,
        useRootNavigator: true,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        useSafeArea: true,
        builder: (context) => ContractFormModal(contract: contract),
      );
    }
  }

  Widget _buildSearchField(MobileAtmosphereAppearance appearance) {
    final scheme = appearance.scheme;
    return GTTextField(
      controller: _searchController,
      hintText: 'Поиск по номеру, контрагенту или объекту…',
      prefixIcon: Icons.search_rounded,
      prefixIconConstraints: const BoxConstraints(minWidth: 44, minHeight: 40),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      borderRadius: 22,
      fillColor: appearance.chromeFill,
      borderSide: BorderSide(color: appearance.chromeBorder),
      focusedBorderSide: BorderSide(color: scheme.primary, width: 1.5),
      prefixIconColor: scheme.onSurface.withValues(alpha: 0.75),
      suffixIcon: _searchController.text.isEmpty
          ? null
          : IconButton(
              tooltip: 'Очистить',
              icon: Icon(
                Icons.clear_rounded,
                color: scheme.onSurface.withValues(alpha: 0.65),
              ),
              onPressed: () {
                _searchController.clear();
                setState(() {});
              },
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appearance = MobileAtmosphereAppearance.of(context);
    final scheme = appearance.scheme;
    final isDark = appearance.isDark;
    final isDesktop = ResponsiveUtils.isDesktop(context);

    final state = ref.watch(contractProvider);
    final contracts = state.contracts;
    final isLoading = state.status == ContractStatusState.loading;
    final isError = state.status == ContractStatusState.error;

    final q = _searchController.text.trim().toLowerCase();
    Iterable<Contract> filtered = contracts;
    if (q.isNotEmpty) {
      filtered = filtered.where((c) {
        return c.number.toLowerCase().contains(q) ||
            (c.contractorName?.toLowerCase().contains(q) ?? false) ||
            (c.objectName?.toLowerCase().contains(q) ?? false);
      });
    }
    if (_filterKind != null) {
      filtered = filtered.where((c) => c.kind == _filterKind);
    }
    if (_filterContractorId != null) {
      filtered = filtered.where((c) => c.contractorId == _filterContractorId);
    }
    if (_filterObjectId != null) {
      filtered = filtered.where((c) => c.objectId == _filterObjectId);
    }

    final filteredContracts = List<Contract>.from(filtered)
      ..sort((a, b) => b.date.compareTo(a.date));

    final hasActiveFilters =
        q.isNotEmpty ||
        _filterKind != null ||
        _filterContractorId != null ||
        _filterObjectId != null;

    if (!_contractsInlineDetailActive) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _captureFiltersBarHeight();
      });
    }

    final detailTopInset = ContractsListInlineDetailLayout.detailTopAlignInset(
      context,
      filtersBarHeight: _filtersBarHeight,
    );

    final contractsBody = ContractsListInlineDetailView(
      filteredContracts: filteredContracts,
      isLoading: isLoading,
      isError: isError,
      errorMessage: state.errorMessage,
      hasActiveSearch: hasActiveFilters,
      onEditContract: (c) => _showContractForm(c),
      detailTopInset: detailTopInset,
      onDisplayedContractChanged: (c) {
        setState(() {
          _sidebarDetailContract = c;
          if (c == null) {
            _sidebarDetailSection = ContractDetailNavigationSection.general;
          }
        });
      },
      onDetailSectionChanged: (section) =>
          setState(() => _sidebarDetailSection = section),
      onPresentationModeChanged: (inlineDetail) {
        if (_contractsInlineDetailActive == inlineDetail) return;
        setState(() => _contractsInlineDetailActive = inlineDetail);
      },
    );

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
        drawer: const AppDrawer(activeRoute: AppRoute.contracts),
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
                    padding: ContractListScreenDesktopChrome
                        .desktopHeaderOuterPadding,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Builder(
                              builder: (ctx) =>
                                  MobileAtmosphereChromeCircleButton(
                                    appearance: appearance,
                                    tooltip: 'Меню',
                                    icon: Icons.menu_rounded,
                                    onTap: () => Scaffold.of(ctx).openDrawer(),
                                  ),
                            ),
                            const SizedBox(width: 12),
                            SizedBox(
                              width: 420,
                              child: _buildSearchField(appearance),
                            ),
                            const Spacer(),
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
                            PermissionGuard(
                              module: 'contracts',
                              permission: 'create',
                              child: Padding(
                                padding: const EdgeInsets.only(left: 8),
                                child: MobileAtmosphereChromeCircleButton(
                                  appearance: appearance,
                                  tooltip: 'Новый договор',
                                  icon: Icons.add_rounded,
                                  iconColor: scheme.primary,
                                  iconSize: 26,
                                  onTap: () => _showContractForm(),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        if (!_contractsInlineDetailActive)
                          ContractsListFiltersBar(
                            key: _filtersBarKey,
                            allContracts: contracts,
                            selectedKind: _filterKind,
                            onKindChanged: (k) =>
                                setState(() => _filterKind = k),
                            selectedContractorId: _filterContractorId,
                            onContractorChanged: (id) =>
                                setState(() => _filterContractorId = id),
                            selectedObjectId: _filterObjectId,
                            onObjectChanged: (id) =>
                                setState(() => _filterObjectId = id),
                            borderSide: BorderSide(
                              color: appearance.chromeBorder,
                            ),
                            compact: true,
                          ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: ContractListScreenDesktopChrome
                          .desktopBodyOuterPadding,
                      child: isDesktop
                          ? Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Expanded(child: contractsBody),
                                const SizedBox(
                                  width: ContractListScreenDesktopChrome
                                      .listToSidebarRowGap,
                                ),
                                Padding(
                                  padding: EdgeInsets.only(
                                    top: _contractsInlineDetailActive
                                        ? detailTopInset
                                        : ContractListTableLayout.offsetTopToFirstCard(
                                            context,
                                          ),
                                  ),
                                  child: ContractsQuickActionsSidebar(
                                    contextContract: _sidebarDetailContract,
                                    sidebarDetailSection: _sidebarDetailSection,
                                  ),
                                ),
                              ],
                            )
                          : contractsBody,
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
