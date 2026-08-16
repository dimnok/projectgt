import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:projectgt/core/theme/theme_settings_provider.dart';
import 'package:projectgt/core/widgets/gt_buttons.dart';
import 'package:projectgt/core/widgets/gt_text_field.dart';
import 'package:projectgt/core/widgets/mobile_atmosphere_backdrop.dart';
import 'package:projectgt/core/widgets/mobile_atmosphere_card_style.dart';
import 'package:projectgt/core/widgets/mobile_atmosphere_main_surface.dart';
import 'package:projectgt/core/widgets/mobile_atmosphere_screen_header.dart';
import 'package:projectgt/features/employees/presentation/utils/employees_layout_utils.dart';
import 'package:projectgt/features/roles/application/permission_service.dart';
import 'package:projectgt/features/purchase_requests/domain/entities/purchase_request_status.dart';
import 'package:projectgt/features/purchase_requests/presentation/state/purchase_request_providers.dart';
import 'package:projectgt/features/purchase_requests/presentation/screens/desktop/purchase_requests_list_desktop_view.dart';
import 'package:projectgt/features/purchase_requests/presentation/widgets/purchase_request_card.dart';
import 'package:projectgt/features/purchase_requests/presentation/widgets/purchase_request_details_panel.dart';
import 'package:projectgt/features/purchase_requests/presentation/widgets/purchase_request_create_dialog.dart';
import 'package:projectgt/features/purchase_requests/presentation/utils/purchase_request_module_utils.dart';
import 'package:projectgt/features/purchase_requests/presentation/widgets/purchase_request_settings_dialog.dart';
import 'package:projectgt/presentation/state/profile_state.dart';
import 'package:projectgt/presentation/widgets/app_drawer.dart';

/// Экран реестра заявок на закупку.
class PurchaseRequestsListScreen extends ConsumerStatefulWidget {
  /// Создаёт экран.
  const PurchaseRequestsListScreen({super.key});

  @override
  ConsumerState<PurchaseRequestsListScreen> createState() =>
      _PurchaseRequestsListScreenState();
}

class _PurchaseRequestsListScreenState
    extends ConsumerState<PurchaseRequestsListScreen> {
  String? _selectedRequestId;
  final _mobileSearchController = TextEditingController();

  @override
  void dispose() {
    _mobileSearchController.dispose();
    super.dispose();
  }

  Future<void> _openCreate() async {
    final id = await PurchaseRequestCreateDialog.show(context);
    if (id == null || !mounted) return;
    setState(() => _selectedRequestId = id);
  }

  void _selectRequest(String id) {
    setState(() => _selectedRequestId = id);
  }

  void _closeDetails() {
    setState(() => _selectedRequestId = null);
  }

  Future<void> _openSettings() async {
    await PurchaseRequestSettingsDialog.show(context);
    ref.invalidate(purchaseRequestSettingsProvider);
  }

  @override
  Widget build(BuildContext context) {
    final listState = ref.watch(purchaseRequestListProvider);
    final listNotifier = ref.read(purchaseRequestListProvider.notifier);

    ref.listen(purchaseRequestListProvider, (previous, next) {
      if (_selectedRequestId == null) return;
      final stillVisible =
          next.items.any((item) => item.id == _selectedRequestId);
      if (!stillVisible && !next.isLoading) {
        setState(() => _selectedRequestId = null);
      }
    });
    final settingsAsync = ref.watch(purchaseRequestSettingsProvider);
    final appearance = MobileAtmosphereAppearance.of(context);
    final isDark = appearance.isDark;
    final useMobile = EmployeesLayoutUtils.useEmployeesMobileList(context);
    final isOwner =
        ref.watch(currentUserProfileProvider).profile?.systemRole == 'owner';
    final settingsConfigured = isPurchaseRequestSettingsConfigured(
      settingsAsync.valueOrNull,
    );
    final canCreate = ref
        .watch(permissionServiceProvider)
        .can('purchase_requests', 'create');

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
        drawer: const AppDrawer(activeRoute: AppRoute.purchaseRequests),
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
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                    child: _buildHeader(
                      context,
                      appearance,
                      isDark,
                      useMobile,
                      isOwner: isOwner,
                      canCreate: canCreate && settingsConfigured,
                      showSearch: settingsConfigured,
                      showBack: useMobile && _selectedRequestId != null,
                      onBack: _closeDetails,
                    ),
                  ),
                  if (!settingsConfigured)
                    Expanded(
                      child: _ModuleSetupPlaceholder(
                        isOwner: isOwner,
                        isLoading: settingsAsync.isLoading,
                        onConfigure: _openSettings,
                      ),
                    )
                  else if (useMobile && _selectedRequestId != null)
                    Expanded(
                      child: MobileAtmosphereMainSurface(
                        padding: EdgeInsets.zero,
                        child: PurchaseRequestDetailsPanel(
                          requestId: _selectedRequestId!,
                        ),
                      ),
                    )
                  else if (useMobile) ...[
                      _FilterBar(
                        filter: listState.filter,
                        onChanged: listNotifier.setFilter,
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                        child: GTTextField(
                          controller: _mobileSearchController,
                          hintText: 'Поиск',
                          prefixIcon: Icons.search,
                          onChanged: listNotifier.setSearchQuery,
                        ),
                      ),
                      Expanded(
                        child: listState.isLoading && listState.items.isEmpty
                            ? const Center(child: CupertinoActivityIndicator())
                            : listState.error != null
                                ? Center(child: Text(listState.error!))
                                : listState.items.isEmpty
                                    ? const Center(child: Text('Нет заявок'))
                                    : MobileAtmosphereMainSurface(
                                        child: ListView.builder(
                                          padding: const EdgeInsets.only(top: 4),
                                          itemCount: listState.items.length,
                                          itemBuilder: (context, index) {
                                            final item = listState.items[index];
                                            final cardStyle =
                                                MobileAtmosphereCardStyle
                                                    .fromAppearance(appearance);
                                            return PurchaseRequestCard(
                                              item: item,
                                              style: cardStyle,
                                              onTap: () =>
                                                  _selectRequest(item.id),
                                            );
                                          },
                                        ),
                                      ),
                      ),
                    ]
                  else
                    Expanded(
                      child: PurchaseRequestsListDesktopView(
                        key: const ValueKey('purchase_requests_desktop'),
                        canCreate: canCreate,
                        isOwner: isOwner,
                        selectedRequestId: _selectedRequestId,
                        onSelectRequest: _selectRequest,
                        onCloseDetails: _closeDetails,
                        onCreate: _openCreate,
                        onSettings: _openSettings,
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

  Widget _buildHeader(
    BuildContext context,
    MobileAtmosphereAppearance appearance,
    bool isDark,
    bool useMobile, {
    required bool isOwner,
    required bool canCreate,
    required bool showSearch,
    bool showBack = false,
    VoidCallback? onBack,
  }) {
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
      icon: isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
      onTap: () {
        ref.read(themeSettingsProvider.notifier).setThemeMode(
              isDark ? ThemeMode.light : ThemeMode.dark,
            );
      },
    );
    final settingsButton = isOwner && useMobile
        ? MobileAtmosphereChromeCircleButton(
            appearance: appearance,
            tooltip: 'Настройки',
            icon: Icons.settings_outlined,
            onTap: _openSettings,
          )
        : null;
    final addButton = canCreate && useMobile
        ? MobileAtmosphereChromeCircleButton(
            appearance: appearance,
            tooltip: 'Новая заявка',
            icon: Icons.add_rounded,
            onTap: _openCreate,
          )
        : null;

    if (useMobile) {
      return Row(
        children: [
          if (showBack && onBack != null)
            MobileAtmosphereChromeCircleButton(
              appearance: appearance,
              tooltip: 'Назад',
              icon: Icons.arrow_back_rounded,
              onTap: onBack,
            )
          else
            menuButton,
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              showBack ? 'Заявка' : 'Заявки',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
          themeButton,
          if (!showBack && settingsButton != null) ...[
            const SizedBox(width: 8),
            settingsButton,
          ],
          if (!showBack && addButton != null) ...[
            const SizedBox(width: 8),
            addButton,
          ],
        ],
      );
    }

    return Row(
      children: [
        menuButton,
        const SizedBox(width: 12),
        Text(
          'Заявки на закупку',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const Spacer(),
        if (showSearch && useMobile)
          SizedBox(
            width: 240,
            child: GTTextField(
              controller: _mobileSearchController,
              hintText: 'Поиск',
              prefixIcon: Icons.search,
              onChanged: ref.read(purchaseRequestListProvider.notifier).setSearchQuery,
            ),
          ),
        if (showSearch && useMobile) const SizedBox(width: 8),
        themeButton,
        if (settingsButton != null) ...[
          const SizedBox(width: 8),
          settingsButton,
        ],
        if (addButton != null) ...[const SizedBox(width: 8), addButton],
      ],
    );
  }
}

/// Плейсхолдер до настройки маршрута заявок.
class _ModuleSetupPlaceholder extends StatelessWidget {
  const _ModuleSetupPlaceholder({
    required this.isOwner,
    required this.isLoading,
    required this.onConfigure,
  });

  final bool isOwner;
  final bool isLoading;
  final VoidCallback onConfigure;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CupertinoActivityIndicator());
    }

    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.account_tree_outlined,
              size: 48,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 16),
            Text(
              isOwner ? 'Настройте согласующих' : 'Модуль ещё не настроен',
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              isOwner
                  ? 'Укажите, кто согласует заявки, счета и оплату. '
                      'После этого сотрудники смогут создавать заявки.'
                  : 'Обратитесь к владельцу компании — '
                      'он должен настроить маршрут заявок.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
            if (isOwner) ...[
              const SizedBox(height: 24),
              GTPrimaryButton(
                text: 'Настройка согласующих',
                onPressed: onConfigure,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _FilterBar extends StatelessWidget {
  const _FilterBar({
    required this.filter,
    required this.onChanged,
  });

  final PurchaseRequestListFilter filter;
  final ValueChanged<PurchaseRequestListFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: PurchaseRequestListFilter.values.map((f) {
          final selected = f == filter;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(f.label),
              selected: selected,
              onSelected: (_) => onChanged(f),
            ),
          );
        }).toList(),
      ),
    );
  }
}
