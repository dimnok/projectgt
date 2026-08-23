import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:projectgt/core/di/providers.dart';
import 'package:projectgt/core/theme/theme_settings_provider.dart';
import 'package:projectgt/core/utils/formatters.dart';
import 'package:projectgt/core/utils/responsive_utils.dart';
import 'package:projectgt/core/utils/snackbar_utils.dart';
import 'package:projectgt/core/widgets/mobile_atmosphere_backdrop.dart';
import 'package:projectgt/core/widgets/mobile_atmosphere_screen_header.dart';
import 'package:projectgt/features/estimates/presentation/screens/estimate_details_screen.dart';
import 'package:projectgt/features/estimates/presentation/providers/estimate_providers.dart';
import 'package:projectgt/features/estimates/presentation/screens/import_estimate_form_modal.dart';
import 'package:projectgt/features/estimates/presentation/widgets/estimate_mobile_object_header.dart';
import 'package:projectgt/core/refresh/refresh_models.dart';
import 'package:projectgt/core/refresh/app_focus_refresh_coordinator.dart';
import 'package:projectgt/features/roles/application/permission_service.dart';
import 'package:projectgt/features/roles/presentation/widgets/permission_guard.dart';
import 'package:projectgt/presentation/widgets/app_badge.dart';
import 'package:projectgt/presentation/widgets/app_drawer.dart';
import 'package:projectgt/presentation/widgets/cupertino_dialog_widget.dart';

/// Экран со списком всех смет.
class EstimatesListScreen extends ConsumerStatefulWidget {
  /// Создаёт экран со списком смет.
  const EstimatesListScreen({super.key});

  @override
  ConsumerState<EstimatesListScreen> createState() =>
      _EstimatesListScreenState();
}

class _EstimatesListScreenState extends ConsumerState<EstimatesListScreen> {
  late final AppFocusRefreshCoordinator _refreshCoordinator;
  final Map<String, bool> _expandedObjects = {};

  @override
  void initState() {
    super.initState();
    _refreshCoordinator = ref.read(appFocusRefreshProvider.notifier);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _refreshCoordinator.registerTarget(
          RefreshTarget(
            id: 'estimates',
            callback: (ref) async {
              ref.invalidate(estimateGroupsProvider);
              ref.invalidate(estimateItemsProvider);
            },
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _refreshCoordinator.unregisterTarget('estimates');
    super.dispose();
  }

  void _showImportEstimateBottomSheet(BuildContext context) {
    ImportEstimateFormModal.show(
      context,
      ref,
      onSuccess: () async {
        if (context.mounted) context.pop();
        SnackBarUtils.showSuccess(context, 'Смета успешно импортирована');
        ref.invalidate(estimateGroupsProvider);
      },
    );
  }

  Future<void> _deleteEstimateFile(EstimateFile file) async {
    final notifier = ref.read(estimateNotifierProvider.notifier);

    try {
      final items = await ref.read(
        estimateItemsProvider(
          EstimateDetailArgs(
            estimateTitle: file.estimateTitle,
            objectId: file.objectId,
            contractId: file.contractId,
          ),
        ).future,
      );

      for (final item in items) {
        await notifier.deleteEstimate(item.id);
      }

      ref.invalidate(estimateGroupsProvider);

      if (!mounted) return;
      SnackBarUtils.showSuccess(
        context,
        'Смета "${file.estimateTitle}" удалена',
      );
    } catch (e) {
      if (!mounted) return;
      SnackBarUtils.showError(context, 'Ошибка удаления: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final groupsAsync = ref.watch(estimateFilesByObjectProvider);
    final permissionService = ref.watch(permissionServiceProvider);
    final canDelete = permissionService.can('estimates', 'delete');
    final isDesktop = ResponsiveUtils.isDesktop(context);
    final isSidebarVisible = ref.watch(estimateSidebarVisibleProvider);
    final appearance = MobileAtmosphereAppearance.of(context);
    final isDark = appearance.isDark;
    final scheme = appearance.scheme;

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
        drawer: const AppDrawer(activeRoute: AppRoute.estimates),
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
                    child: MobileAtmosphereScreenHeader(
                      appearance: appearance,
                      title: 'Сметы',
                      leading: isDesktop
                          ? Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Builder(
                                  builder: (ctx) =>
                                      MobileAtmosphereChromeCircleButton(
                                        appearance: appearance,
                                        tooltip: 'Меню',
                                        icon: Icons.menu_rounded,
                                        onTap: () =>
                                            Scaffold.of(ctx).openDrawer(),
                                      ),
                                ),
                                const SizedBox(width: 4),
                                MobileAtmosphereChromeCircleButton(
                                  appearance: appearance,
                                  tooltip: isSidebarVisible
                                      ? 'Скрыть панель'
                                      : 'Показать панель',
                                  icon: isSidebarVisible
                                      ? Icons.view_sidebar_outlined
                                      : Icons.view_sidebar,
                                  onTap: () => ref
                                      .read(
                                        estimateSidebarVisibleProvider.notifier,
                                      )
                                      .update((state) => !state),
                                ),
                              ],
                            )
                          : Builder(
                              builder: (ctx) =>
                                  MobileAtmosphereChromeCircleButton(
                                    appearance: appearance,
                                    tooltip: 'Меню',
                                    icon: Icons.menu_rounded,
                                    onTap: () => Scaffold.of(ctx).openDrawer(),
                                  ),
                            ),
                      trailing: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        reverse: true,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            MobileAtmosphereChromeCircleButton(
                              appearance: appearance,
                              tooltip: 'Обновить данные',
                              icon: Icons.refresh_rounded,
                              onTap: () {
                                ref.invalidate(estimateGroupsProvider);
                                ref.invalidate(estimateItemsProvider);
                                ref.invalidate(estimateCompletionByIdsProvider);
                              },
                            ),
                            if (!isDesktop) ...[
                              const SizedBox(width: 4),
                              PermissionGuard(
                                module: 'estimates',
                                permission: 'import',
                                child: MobileAtmosphereChromeCircleButton(
                                  appearance: appearance,
                                  tooltip: 'Импорт сметы',
                                  icon: Icons.add_rounded,
                                  iconSize: 26,
                                  onTap: () =>
                                      _showImportEstimateBottomSheet(context),
                                ),
                              ),
                            ],
                            const SizedBox(width: 4),
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
                    ),
                  ),
                  Expanded(
                    child: groupsAsync.when(
                      loading: () => Center(
                        child: CupertinoActivityIndicator(
                          color: scheme.primary,
                        ),
                      ),
                      error: (e, s) => Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Center(child: Text('Ошибка: $e')),
                      ),
                      data: (objectGroups) {
                        return LayoutBuilder(
                          builder: (context, constraints) {
                            if (isDesktop) {
                              return const EstimateDetailsScreen(
                                showAppBar: false,
                              );
                            }
                            return Padding(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                              child: _buildMobileLayout(
                                objectGroups,
                                canDelete,
                              ),
                            );
                          },
                        );
                      },
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

  Widget _buildMobileLayout(
    List<EstimateObjectGroup> objectGroups,
    bool canDelete,
  ) {
    if (objectGroups.isEmpty) {
      return const Center(child: Text('Сметы не найдены'));
    }

    return ListView.builder(
      padding: const EdgeInsets.only(top: 4),
      itemCount: objectGroups.length,
      itemBuilder: (context, index) {
        final group = objectGroups[index];
        final isExpanded = _expandedObjects[group.name] ?? false;

        return Column(
          key: ValueKey(group.name),
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            EstimateMobileObjectHeader(
              name: group.name,
              estimatesCount: group.files.length,
              total: group.total,
              isExpanded: isExpanded,
              onTap: () {
                setState(() {
                  _expandedObjects[group.name] = !isExpanded;
                });
              },
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              alignment: Alignment.topCenter,
              child: isExpanded
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (final file in group.files)
                          _buildEstimateCard(
                            file: file,
                            canDelete: canDelete,
                            onTap: () =>
                                context.go(estimateDetailAppPath(file)),
                          ),
                      ],
                    )
                  : const SizedBox(width: double.infinity),
            ),
          ],
        );
      },
    );
  }

  Widget _buildEstimateCard({
    required EstimateFile file,
    required bool canDelete,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final contractNumber = file.contractNumber ?? '—';

    return Dismissible(
      key: Key(
        '${file.estimateTitle}_${file.objectId ?? "null"}_${file.contractId ?? "null"}',
      ),
      direction: canDelete
          ? DismissDirection.endToStart
          : DismissDirection.none,
      confirmDismiss: (direction) async {
        return CupertinoDialogs.showDeleteConfirmDialog<bool>(
          context: context,
          title: 'Удаление сметы',
          message:
              'Вы действительно хотите удалить смету "${file.estimateTitle}" и все её позиции?',
          onConfirm: () {
            _deleteEstimateFile(file);
          },
        );
      },
      background: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: theme.colorScheme.error,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(CupertinoIcons.trash, color: theme.colorScheme.onError),
      ),
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 4),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: theme.colorScheme.outline.withValues(alpha: 0.1),
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        file.estimateTitle,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    AppBadge(
                      text: formatPercentage(
                        file.completionPercent,
                        decimalDigits: 1,
                      ),
                      color: theme.colorScheme.primary,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _buildInfoRow(theme, 'Договор:', contractNumber),
                const SizedBox(height: 4),
                _buildInfoRow(theme, 'Сумма:', formatCurrency(file.total)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(ThemeData theme, String label, String value) {
    return Row(
      children: [
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
