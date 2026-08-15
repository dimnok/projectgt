import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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
import 'package:projectgt/features/purchase_requests/presentation/widgets/purchase_request_card.dart';
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
  PurchaseRequestListFilter _filter = PurchaseRequestListFilter.onMe;
  String _search = '';

  PurchaseRequestListParams get _params => PurchaseRequestListParams(
        filter: _filter,
        search: _search.trim().isEmpty ? null : _search.trim(),
      );

  Future<void> _openCreate() async {
    final id = await PurchaseRequestCreateDialog.show(context);
    if (id == null || !mounted) return;
    context.pushNamed('purchase_request_details', pathParameters: {'id': id});
  }

  Future<void> _openSettings() async {
    await PurchaseRequestSettingsDialog.show(context);
    ref.invalidate(purchaseRequestSettingsProvider);
  }

  @override
  Widget build(BuildContext context) {
    final listState = ref.watch(purchaseRequestListProvider(_params));
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
                  else ...[
                    _FilterBar(
                    filter: _filter,
                    onChanged: (f) => setState(() => _filter = f),
                  ),
                  if (useMobile)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                      child: GTTextField(
                        hintText: 'Поиск',
                        prefixIcon: Icons.search,
                        onChanged: (v) => setState(() => _search = v),
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
                                          onTap: () => context.pushNamed(
                                            'purchase_request_details',
                                            pathParameters: {'id': item.id},
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                    ),
                  ],
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
    final settingsButton = isOwner
        ? MobileAtmosphereChromeCircleButton(
            appearance: appearance,
            tooltip: 'Настройка согласующих',
            icon: Icons.settings_outlined,
            onTap: _openSettings,
          )
        : null;
    final addButton = canCreate
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
          menuButton,
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Заявки',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
          themeButton,
          if (settingsButton != null) ...[
            const SizedBox(width: 8),
            settingsButton,
          ],
          if (addButton != null) ...[const SizedBox(width: 8), addButton],
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
        if (showSearch)
          SizedBox(
            width: 240,
            child: GTTextField(
              hintText: 'Поиск',
              prefixIcon: Icons.search,
              onChanged: (v) => setState(() => _search = v),
            ),
          ),
        const SizedBox(width: 8),
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
