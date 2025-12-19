import 'package:collection/collection.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/providers.dart'; // Добавлен для провайдеров
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/snackbar_utils.dart';
import '../../../../core/widgets/gt_buttons.dart';
import '../../../../data/models/estimate_completion_model.dart';
import '../../../../domain/entities/estimate.dart';
import '../../../../domain/entities/object.dart';
import '../../../../features/estimates/presentation/screens/import_estimate_form_modal.dart';
import '../../../../features/roles/application/permission_service.dart';
import '../../../../features/roles/presentation/widgets/permission_guard.dart';
import '../../../../presentation/widgets/cupertino_dialog_widget.dart';
import '../mixins/estimate_actions_mixin.dart';
import '../providers/estimate_providers.dart';
import '../widgets/estimate_search_field.dart';
import '../widgets/estimate_filter_buttons.dart';
import '../widgets/estimate_table_view.dart';

/// Виджет для отображения списка смет и детальной информации (таблицы) в десктопном режиме.
class EstimateDesktopView extends ConsumerStatefulWidget {
  /// Создает экземпляр [EstimateDesktopView].
  const EstimateDesktopView({super.key});

  @override
  ConsumerState<EstimateDesktopView> createState() =>
      _EstimateDesktopViewState();
}

class _EstimateDesktopViewState extends ConsumerState<EstimateDesktopView>
    with EstimateActionsMixin {
  EstimateFile? _selectedEstimateFile;
  EstimateViewMode _viewMode = EstimateViewMode.planning;
  List<Estimate>? _displayedItems;
  String? _displayedFileKey;
  Map<String, EstimateCompletionModel>? _displayedCompletion;
  String? _displayedCompletionKey;
  String _searchQuery = '';
  EstimateStatusFilter _statusFilter = EstimateStatusFilter.none;

  @override
  EstimateDetailArgs? get currentEstimateArgs {
    if (_selectedEstimateFile == null) return null;
    return EstimateDetailArgs(
      estimateTitle: _selectedEstimateFile!.estimateTitle,
      objectId: _selectedEstimateFile!.objectId,
      contractId: _selectedEstimateFile!.contractId,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final groupsAsync = ref.watch(estimateGroupsProvider);
    // contracts больше не нужны для поиска номера договора, так как он есть в EstimateFile
    final objects = ref.watch(objectProvider).objects;
    final permissionService = ref.watch(permissionServiceProvider);
    final canDelete = permissionService.can('estimates', 'delete');

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Container(
          decoration: BoxDecoration(
            color: isDark
                ? const Color.fromRGBO(38, 40, 42, 1)
                : const Color.fromRGBO(248, 249, 250, 1),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  width: 350,
                  margin: const EdgeInsets.only(right: 16),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey[900] : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark ? Colors.grey[800]! : Colors.grey[300]!,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: PermissionGuard(
                          module: 'estimates',
                          permission: 'import',
                          child: SizedBox(
                            width: double.infinity,
                            child: GTPrimaryButton(
                              text: 'Импорт сметы',
                              icon: CupertinoIcons.arrow_up_doc,
                              onPressed: () =>
                                  _showImportEstimateBottomSheet(context),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: groupsAsync.when(
                          data: (estimateFiles) {
                            if (estimateFiles.isEmpty) {
                              return const Center(
                                  child: Text('Сметы не найдены'));
                            }
                            return ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: ListView.separated(
                                itemCount: estimateFiles.length,
                                separatorBuilder: (context, index) => Divider(
                                  height: 1,
                                  indent: 16,
                                  endIndent: 16,
                                  color: theme.colorScheme.outlineVariant
                                      .withValues(alpha: 0.5),
                                ),
                                itemBuilder: (context, index) {
                                  final file = estimateFiles[index];
                                  final isSelected =
                                      _selectedEstimateFile?.estimateTitle ==
                                              file.estimateTitle &&
                                          _selectedEstimateFile?.objectId ==
                                              file.objectId &&
                                          _selectedEstimateFile?.contractId ==
                                              file.contractId;

                                  return _EstimateListTile(
                                    file: file,
                                    objects: objects,
                                    isSelected: isSelected,
                                    canDelete: canDelete,
                                    onTap: () {
                                      setState(
                                          () => _selectedEstimateFile = file);
                                    },
                                    onDelete: () => _deleteEstimateFile(file),
                                  );
                                },
                              ),
                            );
                          },
                          loading: () =>
                              const Center(child: CupertinoActivityIndicator()),
                          error: (e, s) =>
                              Center(child: Text('Ошибка списка: $e')),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _selectedEstimateFile == null
                      ? _EmptyDesktopSelection(theme: theme)
                      : _buildDetailPanel(context, _selectedEstimateFile!),
                ),
              ],
            ),
          ),
        ),
      ),
    );
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

  Widget _buildDetailPanel(BuildContext context, EstimateFile file) {
    final theme = Theme.of(context);
    // Используем геттер из миксина для уверенности в консистентности
    final args = currentEstimateArgs!;

    final itemsAsync = ref.watch(estimateItemsProvider(args));
    final items = itemsAsync.valueOrNull;
    final isItemsLoading = itemsAsync.isLoading;
    final fileCacheKey =
        '${file.estimateTitle}_${file.objectId}_${file.contractId}';

    List<Estimate>? effectiveItems;
    if (items != null) {
      _displayedItems = items;
      _displayedFileKey = fileCacheKey;
      effectiveItems = items;
    } else {
      effectiveItems = _displayedItems;
    }

    Widget buildTableSection() {
      final itemsToDisplay = effectiveItems;
      final isSameFileAsDisplayed = _displayedFileKey == fileCacheKey;
      final isShowingStaleData =
          !isSameFileAsDisplayed && itemsToDisplay != null && items == null;

      if (itemsAsync.hasError && itemsToDisplay == null) {
        return _ErrorState(
          message: 'Ошибка загрузки деталей: ${itemsAsync.error}',
          onRetry: () => ref.invalidate(estimateItemsProvider(args)),
        );
      }

      if (itemsToDisplay == null) {
        return const _EstimateTableSkeleton();
      }

      final nonNullItems = itemsToDisplay;

      final shouldLoadCompletion =
          _viewMode == EstimateViewMode.execution && nonNullItems.isNotEmpty;

      final completionProvider = shouldLoadCompletion
          ? estimateCompletionByIdsProvider(
              EstimateIds(nonNullItems.map((e) => e.id).toList()),
            )
          : null;

      final completionAsyncValue =
          shouldLoadCompletion && completionProvider != null
              ? ref.watch(completionProvider)
              : const AsyncValue<List<EstimateCompletionModel>>.data(
                  <EstimateCompletionModel>[]);

      if (shouldLoadCompletion &&
          completionAsyncValue.hasError &&
          completionAsyncValue.valueOrNull == null) {
        return _ErrorState(
          message: 'Ошибка загрузки выполнения: ${completionAsyncValue.error}',
          onRetry: () {
            if (completionProvider != null) {
              ref.invalidate(completionProvider);
            }
          },
        );
      }

      Map<String, EstimateCompletionModel> completionMap = {};
      final completionData = completionAsyncValue.valueOrNull;
      if (completionData != null) {
        completionMap = {
          for (final item in completionData) item.estimateId: item
        };
        _displayedCompletion = completionMap;
        _displayedCompletionKey = fileCacheKey;
      } else if (_displayedCompletionKey == fileCacheKey &&
          _displayedCompletion != null) {
        completionMap = _displayedCompletion!;
      }

      final filteredItems = nonNullItems.where((item) {
        // 1. Поиск по тексту
        if (_searchQuery.isNotEmpty) {
          final query = _searchQuery.toLowerCase();
          if (!item.name.toLowerCase().contains(query) &&
              !item.number.toLowerCase().contains(query)) {
            return false;
          }
        }

        // 2. Фильтрация по статусу
        if (_statusFilter != EstimateStatusFilter.none) {
          final completion = completionMap[item.id];
          final percentage = completion?.percentage ?? 0;

          switch (_statusFilter) {
            case EstimateStatusFilter.overExecution:
              if (percentage <= 100) return false;
              break;
            case EstimateStatusFilter.completed:
              // Считаем выполненным, если близко к 100% (с учетом погрешности float)
              if ((percentage - 100).abs() > 0.01) return false;
              break;
            case EstimateStatusFilter.zeroExecution:
              if (percentage > 0) return false;
              break;
            case EstimateStatusFilter.none:
              break;
          }
        }

        return true;
      }).toList();

      if (nonNullItems.isEmpty) {
        return const Center(child: Text('Нет позиций'));
      }

      final isCompletionLoading =
          shouldLoadCompletion && completionAsyncValue.isLoading;

      String? overlayMessage;
      if (isShowingStaleData) {
        overlayMessage = 'Загружаем данные сметы...';
      } else if (isItemsLoading) {
        overlayMessage = 'Обновляем данные...';
      } else if (isCompletionLoading) {
        overlayMessage = 'Загружаем выполнение...';
      }

      return Stack(
        children: [
          EstimateTableView(
            items: filteredItems,
            completionData: completionMap,
            viewMode: _viewMode,
            onEdit: (estimate) => openEditDialog(
              context,
              estimate: estimate,
              estimateTitle: file.estimateTitle,
              objectId: file.objectId,
              contractId: file.contractId,
            ),
            onDuplicate: (estimate) => duplicateEstimateItem(context, estimate),
            onDelete: (id) => deleteEstimateItem(context, id),
          ),
          if (overlayMessage != null)
            _TableLoadingOverlay(message: overlayMessage),
        ],
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        file.estimateTitle,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 400),
                            child: CupertinoSlidingSegmentedControl<
                                EstimateViewMode>(
                              groupValue: _viewMode,
                              children: const {
                                EstimateViewMode.planning: Text(
                                  'Смета',
                                  style: TextStyle(fontSize: 14),
                                ),
                                EstimateViewMode.execution: Text(
                                  'Выполнение',
                                  style: TextStyle(fontSize: 14),
                                ),
                              },
                              onValueChanged: (value) {
                                if (value != null) {
                                  setState(() {
                                    _viewMode = value;
                                    if (value == EstimateViewMode.planning) {
                                      _statusFilter = EstimateStatusFilter.none;
                                    }
                                  });
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          EstimateSearchField(
                            onChanged: (value) {
                              setState(() {
                                _searchQuery = value;
                              });
                            },
                          ),
                          const SizedBox(width: 8),
                          if (_viewMode == EstimateViewMode.execution)
                            EstimateFilterButtons(
                              selectedFilter: _statusFilter,
                              onChanged: (filter) {
                                setState(() {
                                  _statusFilter = filter;
                                });
                              },
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                PermissionGuard(
                  module: 'estimates',
                  permission: 'manual_edit',
                  child: GTPrimaryButton(
                    icon: CupertinoIcons.add,
                    text: 'Добавить позицию',
                    onPressed: () => openEditDialog(
                      context,
                      estimateTitle: file.estimateTitle,
                      objectId: file.objectId,
                      contractId: file.contractId,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: buildTableSection(),
            ),
          ),
        ],
      ),
    );
  }

  void _deleteEstimateFile(EstimateFile file) async {
    final confirmed = await CupertinoDialogs.showDeleteConfirmDialog<bool>(
      context: context,
      title: 'Удаление сметы',
      message:
          'Вы действительно хотите удалить смету "${file.estimateTitle}" и все её позиции?',
      onConfirm: () {},
    );

    if (confirmed == true) {
      final items = await ref.read(estimateItemsProvider(EstimateDetailArgs(
        estimateTitle: file.estimateTitle,
        objectId: file.objectId,
        contractId: file.contractId,
      )).future);

      final notifier = ref.read(estimateNotifierProvider.notifier);
      for (final item in items) {
        await notifier.deleteEstimate(item.id);
      }
      ref.invalidate(estimateGroupsProvider);

      if (_selectedEstimateFile?.estimateTitle == file.estimateTitle) {
        setState(() {
          _selectedEstimateFile = null;
        });
      }
    }
  }
}

class _EmptyDesktopSelection extends StatelessWidget {
  final ThemeData theme;

  const _EmptyDesktopSelection({required this.theme});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            CupertinoIcons.list_bullet,
            size: 64,
            color: theme.colorScheme.outline.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'Выберите смету из списка',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.outline,
            ),
          ),
        ],
      ),
    );
  }
}

class _EstimateTableSkeleton extends StatelessWidget {
  const _EstimateTableSkeleton();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView.separated(
      itemCount: 8,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, index) => Container(
        height: 48,
        decoration: BoxDecoration(
          color:
              theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}

class _TableLoadingOverlay extends StatelessWidget {
  final String message;

  const _TableLoadingOverlay({this.message = 'Загрузка...'});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Positioned.fill(
      child: ColoredBox(
        color: theme.colorScheme.surface.withValues(alpha: 0.65),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CupertinoActivityIndicator(radius: 14),
              const SizedBox(height: 12),
              Text(
                message,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: theme.colorScheme.onSurface),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          GTPrimaryButton(
            text: 'Повторить',
            onPressed: onRetry,
          ),
        ],
      ),
    );
  }
}

class _EstimateListTile extends StatelessWidget {
  final EstimateFile file;
  final List<ObjectEntity> objects;
  final bool isSelected;
  final bool canDelete;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _EstimateListTile({
    required this.file,
    required this.objects,
    required this.isSelected,
    required this.canDelete,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final contractNumber = file.contractNumber ?? '—';
    final object = objects.firstWhereOrNull((o) => o.id == file.objectId);
    final objectName = object?.name ?? '—';

    return Material(
      color: isSelected ? theme.colorScheme.primary : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
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
                        color: isSelected ? theme.colorScheme.onPrimary : null,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (canDelete)
                    IconButton(
                      icon: Icon(
                        CupertinoIcons.trash,
                        size: 20,
                        color: isSelected
                            ? theme.colorScheme.onPrimary
                            : theme.colorScheme.error,
                      ),
                      onPressed: onDelete,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                'Договор: $contractNumber',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: isSelected
                      ? theme.colorScheme.onPrimary.withValues(alpha: 0.8)
                      : theme.colorScheme.onSurfaceVariant,
                  fontSize: 11,
                ),
              ),
              Text(
                'Объект: $objectName',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: isSelected
                      ? theme.colorScheme.onPrimary.withValues(alpha: 0.8)
                      : theme.colorScheme.onSurfaceVariant,
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    formatCurrency(file.total),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isSelected ? theme.colorScheme.onPrimary : null,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
