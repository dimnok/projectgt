import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/gt_buttons.dart';
import '../../../../data/models/estimate_completion_model.dart';
import '../../../../domain/entities/estimate.dart';
import '../../../../features/roles/application/permission_service.dart';
import '../../../../features/roles/presentation/widgets/permission_guard.dart';
import '../../../../presentation/widgets/app_bar_widget.dart';
import '../mixins/estimate_actions_mixin.dart';
import '../providers/estimate_providers.dart';
import '../utils/estimate_sorter.dart';
import '../widgets/estimate_item_card.dart';
import '../widgets/estimate_mobile_header.dart';
import 'estimate_details_screen.dart';

/// Мобильное представление раздела смет.
class EstimateMobileView extends ConsumerStatefulWidget {
  /// Заголовок (название) сметы.
  final String? estimateTitle;

  /// Идентификатор объекта.
  final String? objectId;

  /// Идентификатор контракта.
  final String? contractId;

  /// Флаг отображения AppBar.
  final bool showAppBar;

  /// Создает экземпляр [EstimateMobileView].
  const EstimateMobileView({
    super.key,
    required this.estimateTitle,
    this.objectId,
    this.contractId,
    required this.showAppBar,
  });

  @override
  ConsumerState<EstimateMobileView> createState() => _EstimateMobileViewState();
}

class _EstimateMobileViewState extends ConsumerState<EstimateMobileView>
    with EstimateActionsMixin {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  EstimateDetailArgs? get currentEstimateArgs {
    if (widget.estimateTitle == null) return null;
    return EstimateDetailArgs(
      estimateTitle: widget.estimateTitle!,
      objectId: widget.objectId,
      contractId: widget.contractId,
    );
  }

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    // 1. Если передано название сметы - показываем детали
    if (widget.estimateTitle != null) {
      final args = currentEstimateArgs!;
      final itemsAsync = ref.watch(estimateItemsProvider(args));

      return itemsAsync.when(
        data: (items) {
          final itemIds = items.map((e) => e.id).toList();
          final completionAsync =
              ref.watch(estimateCompletionByIdsProvider(EstimateIds(itemIds)));

          return Scaffold(
            appBar: AppBarWidget(
              title: widget.estimateTitle ?? 'Детали сметы',
              leading: IconButton(
                icon: const Icon(CupertinoIcons.back),
                onPressed: () => context.go('/estimates'),
              ),
              actions: [
                IconButton(
                  icon: const Icon(CupertinoIcons.refresh),
                  tooltip: 'Обновить данные',
                  onPressed: () {
                    ref.invalidate(estimateGroupsProvider);
                    ref.invalidate(estimateItemsProvider);
                    ref.invalidate(estimateCompletionByIdsProvider);
                  },
                ),
              ],
            ),
            body: completionAsync.when(
              data: (completions) {
                final completionMap = {
                  for (final c in completions) c.estimateId: c
                };
                final filteredItems = _filterAndSortItems(items);
                return _buildMobileBody(
                  context,
                  filteredItems,
                  widget.estimateTitle,
                  completionMap,
                );
              },
              loading: () => const Center(child: CupertinoActivityIndicator()),
              error: (e, s) => Center(child: Text('Ошибка выполнения: $e')),
            ),
            floatingActionButton: PermissionGuard(
              module: 'estimates',
              permission: 'create',
              child: FloatingActionButton(
                heroTag: 'addItem',
                backgroundColor: Theme.of(context).colorScheme.primary,
                child: const Icon(CupertinoIcons.add),
                onPressed: () => openEditDialog(
                  context,
                  estimateTitle: widget.estimateTitle,
                  objectId: widget.objectId,
                  contractId: widget.contractId,
                ),
              ),
            ),
          );
        },
        loading: () => Scaffold(
          appBar: AppBarWidget(title: widget.estimateTitle ?? 'Загрузка...'),
          body: const Center(child: CupertinoActivityIndicator()),
        ),
        error: (e, s) => Scaffold(
          appBar: const AppBarWidget(title: 'Ошибка'),
          body: Center(child: Text('Ошибка: $e')),
        ),
      );
    }

    // 2. Иначе показываем список групп (файлов смет)
    final groupsAsync = ref.watch(estimateGroupsProvider);
    return Scaffold(
      appBar: const AppBarWidget(title: 'Сметы'),
      body: groupsAsync.when(
        data: (groups) {
          if (groups.isEmpty) {
            return const Center(child: Text('Нет смет'));
          }
          return ListView.builder(
            itemCount: groups.length,
            itemBuilder: (context, index) {
              final group = groups[index];
              return ListTile(
                title: Text(group.estimateTitle),
                subtitle: Text(formatCurrency(group.total)),
                trailing: const Icon(CupertinoIcons.chevron_right),
                onTap: () {
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (ctx) => EstimateDetailsScreen(
                      estimateTitle: group.estimateTitle,
                      objectId: group.objectId,
                      contractId: group.contractId,
                      showAppBar: true,
                    ),
                  ));
                },
              );
            },
          );
        },
        loading: () => const Center(child: CupertinoActivityIndicator()),
        error: (e, s) => Center(child: Text('Ошибка: $e')),
      ),
    );
  }

  List<Estimate> _filterAndSortItems(List<Estimate> items) {
    final searchQuery = _searchController.text.toLowerCase().trim();
    var filteredItems = items;

    if (searchQuery.isNotEmpty) {
      filteredItems = items.where((item) {
        return item.name.toLowerCase().contains(searchQuery) ||
            item.system.toLowerCase().contains(searchQuery) ||
            item.subsystem.toLowerCase().contains(searchQuery) ||
            item.article.toLowerCase().contains(searchQuery) ||
            item.manufacturer.toLowerCase().contains(searchQuery) ||
            item.number.toString().contains(searchQuery);
      }).toList();
    }

    return [...filteredItems]..sort(EstimateSorter.compareByNumber);
  }

  Widget _buildMobileBody(
    BuildContext context,
    List<Estimate> filteredItems,
    String? title,
    Map<String, EstimateCompletionModel> completionMap,
  ) {
    if (filteredItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Нет позиций'),
            const SizedBox(height: 16),
            if (title != null)
              PermissionGuard(
                module: 'estimates',
                permission: 'create',
                child: GTPrimaryButton(
                  icon: CupertinoIcons.add,
                  text: 'Добавить позицию',
                  onPressed: () => openEditDialog(
                    context,
                    estimateTitle: title,
                    objectId: widget.objectId,
                    contractId: widget.contractId,
                  ),
                ),
              ),
          ],
        ),
      );
    }

    return Column(
      children: [
        EstimateMobileHeader(
          searchController: _searchController,
          items: filteredItems,
          filteredCount: filteredItems.length,
        ),
        Expanded(
          child: ListView.separated(
            controller: _scrollController,
            itemCount: filteredItems.length,
            separatorBuilder: (_, __) =>
                const SizedBox(height: 0), // Отступы теперь внутри карточек
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemBuilder: (context, index) {
              final item = filteredItems[index];
              final completion = completionMap[item.id];

              final permissionService = ref.watch(permissionServiceProvider);
              // Используем стандартные права для проверки доступа
              final canUpdate = permissionService.can('estimates', 'update');
              final canDelete = permissionService.can('estimates', 'delete');

              return EstimateItemCard(
                item: item,
                completion: completion,
                canEdit: canUpdate,
                canDelete: canDelete,
                canDuplicate: canUpdate,
                onEdit: (estimate) => openEditDialog(context,
                    estimate: estimate, estimateTitle: title),
                onDuplicate: (estimate) =>
                    duplicateEstimateItem(context, estimate),
                onDelete: (id) => deleteEstimateItem(context, id),
              )
                  .animate()
                  .fadeIn(
                      duration: 300.ms,
                      delay: Duration(milliseconds: 30 * index))
                  .slideX(begin: 0.05, end: 0);
            },
          ),
        ),
      ],
    );
  }
}
