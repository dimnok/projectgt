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
import '../../../../features/estimates/presentation/screens/import_estimate_form_modal.dart';
import '../../../../features/roles/application/permission_service.dart';
import '../../../../features/roles/presentation/widgets/permission_guard.dart';
import '../../../../presentation/widgets/cupertino_dialog_widget.dart';
import '../mixins/estimate_actions_mixin.dart';
import '../../../../data/models/ks6a_model.dart' show Ks6aStatus;
import '../providers/estimate_providers.dart';
import '../widgets/estimate_search_field.dart';
import '../widgets/estimate_filter_buttons.dart';
import '../widgets/estimate_table_view.dart';
import '../widgets/ks6a_table_view.dart';
import '../widgets/estimate_completion_history_panel.dart';

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
  bool _isKs6aMode = false;
  String? _selectedContractNumber;
  String? _selectedContractId;
  List<Estimate>? _displayedItems;
  String? _displayedFileKey;
  Map<String, EstimateCompletionModel>? _displayedCompletion;
  String? _displayedCompletionKey;
  String _searchQuery = '';
  EstimateStatusFilter _statusFilter = EstimateStatusFilter.none;
  Estimate? _selectedHistoryEstimate;

  // Состояние свернутых групп
  final Map<String, bool> _expandedObjects = {};
  final Map<String, bool> _expandedContracts = {};

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
    final groupsAsync = ref.watch(groupedEstimateFilesProvider);
    final isSidebarVisible = ref.watch(estimateSidebarVisibleProvider);
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
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Stack(
              children: [
                // 1. Основной фон
                Positioned.fill(
                  child: ColoredBox(
                    color: isDark
                        ? const Color.fromRGBO(38, 40, 42, 1)
                        : const Color.fromRGBO(248, 249, 250, 1),
                  ),
                ),

                // 2. Левая панель (Список)
                Positioned(
                  left: 16,
                  top: 16,
                  bottom: 16,
                  width: 350,
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 400),
                    opacity: isSidebarVisible ? 1.0 : 0.0,
                    curve: Curves.easeInOut,
                    child: AnimatedScale(
                      duration: const Duration(milliseconds: 400),
                      scale: isSidebarVisible ? 1.0 : 0.95,
                      curve: Curves.easeInOut,
                      child: _selectedHistoryEstimate != null
                          ? EstimateCompletionHistoryPanel(
                              estimate: _selectedHistoryEstimate!,
                              completedQuantity: _displayedCompletion?[
                                      _selectedHistoryEstimate!.id]
                                  ?.completedQuantity,
                              onClose: () => setState(
                                  () => _selectedHistoryEstimate = null),
                            )
                          : Container(
                              decoration: BoxDecoration(
                                color: isDark ? Colors.grey[900] : Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isDark
                                      ? Colors.grey[800]!
                                      : Colors.grey[300]!,
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
                                              _showImportEstimateBottomSheet(
                                                  context),
                                        ),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: groupsAsync.when(
                                      data: (groupedEstimates) {
                                        if (groupedEstimates.isEmpty) {
                                          return const Center(
                                            child: Text('Сметы не найдены'),
                                          );
                                        }
                                        return ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(16),
                                          child: ListView(
                                            children: [
                                              for (final objectEntry
                                                  in groupedEstimates
                                                      .entries) ...[
                                                _ObjectGroupHeader(
                                                  name: objectEntry.key,
                                                  total: objectEntry
                                                      .value.values
                                                      .expand((files) => files)
                                                      .fold(
                                                        0.0,
                                                        (sum, file) =>
                                                            sum + file.total,
                                                      ),
                                                  isExpanded: _expandedObjects[
                                                          objectEntry.key] ??
                                                      false,
                                                  onTap: () => setState(() {
                                                    _expandedObjects[objectEntry
                                                            .key] =
                                                        !(_expandedObjects[
                                                                objectEntry
                                                                    .key] ??
                                                            false);
                                                  }),
                                                ),
                                                if (_expandedObjects[
                                                        objectEntry.key] ??
                                                    false)
                                                  for (final contractEntry
                                                      in objectEntry
                                                          .value.entries) ...[
                                                    _ContractGroupHeader(
                                                      number: contractEntry.key,
                                                      total: contractEntry.value
                                                          .fold(
                                                        0.0,
                                                        (sum, file) =>
                                                            sum + file.total,
                                                      ),
                                                      isExpanded: _expandedContracts[
                                                              '${objectEntry.key}_${contractEntry.key}'] ??
                                                          false,
                                                      onTap: () => setState(() {
                                                        _expandedContracts[
                                                                '${objectEntry.key}_${contractEntry.key}'] =
                                                            !(_expandedContracts[
                                                                    '${objectEntry.key}_${contractEntry.key}'] ??
                                                                false);
                                                      }),
                                                      onKs6aTap: () => setState(() {
                                                        _isKs6aMode = true;
                                                        _selectedContractNumber =
                                                            contractEntry.key;
                                                        _selectedContractId = 
                                                            contractEntry.value.firstOrNull?.contractId;
                                                        _selectedEstimateFile =
                                                            null;
                                                      }),
                                                    ),
                                                    if (_expandedContracts[
                                                            '${objectEntry.key}_${contractEntry.key}'] ??
                                                        false)
                                                      ...contractEntry.value
                                                          .map((file) {
                                                        final isSelected =
                                                            _selectedEstimateFile
                                                                        ?.estimateTitle ==
                                                                    file.estimateTitle &&
                                                                _selectedEstimateFile
                                                                        ?.objectId ==
                                                                    file.objectId &&
                                                                _selectedEstimateFile
                                                                        ?.contractId ==
                                                                    file.contractId;

                                                        return _EstimateListTile(
                                                          file: file,
                                                          isSelected:
                                                              isSelected,
                                                          canDelete: canDelete,
                                                          onTap: () {
                                                            setState(() {
                                                              _selectedEstimateFile =
                                                                  file;
                                                              _selectedHistoryEstimate =
                                                                  null;
                                                              _isKs6aMode = false;
                                                              _selectedContractNumber = null;
                                                            });
                                                          },
                                                          onDelete: () =>
                                                              _deleteEstimateFile(
                                                                  file),
                                                        );
                                                      }),
                                                  ],
                                              ],
                                            ],
                                          ),
                                        );
                                      },
                                      loading: () => const Center(
                                        child: CupertinoActivityIndicator(),
                                      ),
                                      error: (e, s) => Center(
                                        child: Text('Ошибка списка: $e'),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                    ),
                  ),
                ),

                // 3. Основная область (Таблица)
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeInOutCubic,
                  left: isSidebarVisible ? 382 : 16,
                  right: 16,
                  top: 16,
                  bottom: 16,
                  child: Container(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: isSidebarVisible
                          ? null
                          : [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 12,
                                offset: const Offset(-4, 0),
                              ),
                            ],
                    ),
                    child: _isKs6aMode
                        ? _buildKs6aPanel(context)
                        : (_selectedEstimateFile == null
                            ? _EmptyDesktopSelection(theme: theme)
                            : _buildDetailPanel(context, _selectedEstimateFile!)),
                  ),
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

  Widget _buildKs6aPanel(BuildContext context) {
    final theme = Theme.of(context);
    final contractId = _selectedContractId;

    if (contractId == null) {
      return const Center(child: Text('Ошибка: ID договора не найден'));
    }

    final ks6aDataAsync = ref.watch(ks6aDataProvider(contractId));

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
                        'Журнал КС-6а',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (_selectedContractNumber != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Договор № $_selectedContractNumber',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                ks6aDataAsync.when(
                  data: (ks6aData) {
                    final hasDraft =
                        ks6aData.periods.any((p) => p.status == Ks6aStatus.draft);
                    return Row(
                      children: [
                        GTPrimaryButton(
                          text: 'Сформировать период',
                          onPressed: () => _onCreatePeriodForKs6a(contractId),
                          icon: CupertinoIcons.add,
                        ),
                        if (hasDraft) ...[
                          const SizedBox(width: 8),
                          GTSecondaryButton(
                            text: 'Обновить',
                            icon: CupertinoIcons.refresh,
                            onPressed: () {
                              final draft = ks6aData.periods.firstWhere(
                                (p) => p.status == Ks6aStatus.draft,
                              );
                              ref
                                  .read(ks6aActionsProvider)
                                  .refreshPeriod(contractId, draft.id);
                            },
                          ),
                          const SizedBox(width: 8),
                          GTPrimaryButton(
                            text: 'Согласовать',
                            icon: CupertinoIcons.check_mark_circled,
                            backgroundColor: Colors.green[700],
                            onPressed: () {
                              final draft = ks6aData.periods.firstWhere(
                                (p) => p.status == Ks6aStatus.draft,
                              );
                              ref
                                  .read(ks6aActionsProvider)
                                  .approvePeriod(contractId, draft.id);
                            },
                          ),
                        ],
                      ],
                    );
                  },
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                ),
                const SizedBox(width: 16),
                GTSecondaryButton(
                  icon: CupertinoIcons.xmark,
                  text: 'Закрыть',
                  onPressed: () => setState(() {
                    _isKs6aMode = false;
                    _selectedContractNumber = null;
                    _selectedContractId = null;
                  }),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Ks6aTableView(contractId: contractId),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _onCreatePeriodForKs6a(String contractId) async {
    final dates = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      helpText: 'Выберите период для КС-6а',
    );

    if (dates != null) {
      try {
        final actions = ref.read(ks6aActionsProvider);
        await actions.createPeriod(
          contractId: contractId,
          startDate: dates.start,
          endDate: dates.end,
        );
        if (mounted) {
          SnackBarUtils.showSuccess(context, 'Черновик периода создан');
        }
      } catch (e) {
        if (mounted) {
          SnackBarUtils.showError(context, 'Ошибка: $e');
        }
      }
    }
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
            selectedId: _selectedHistoryEstimate?.id,
            onRowTap: _viewMode == EstimateViewMode.execution
                ? (estimate) => setState(() {
                      if (_selectedHistoryEstimate?.id == estimate.id) {
                        _selectedHistoryEstimate = null;
                      } else {
                        _selectedHistoryEstimate = estimate;
                      }
                    })
                : null,
            onEdit: (estimate) => openEditDialog(
              context,
              estimate: estimate,
              estimateTitle: file.estimateTitle,
              objectId: file.objectId,
              contractId: file.contractId,
            ),
            onDuplicate: (estimate) => duplicateEstimateItem(context, estimate),
            onDelete: (id) => deleteEstimateItem(context, id),
            contractNumber: file.contractNumber,
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
                  permission: 'create',
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

class _ObjectGroupHeader extends StatelessWidget {
  final String name;
  final double total;
  final bool isExpanded;
  final VoidCallback onTap;

  const _ObjectGroupHeader({
    required this.name,
    required this.total,
    required this.isExpanded,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? Colors.black.withValues(alpha: 0.3) : Colors.grey[200],
          border: Border(
            bottom: BorderSide(
              color: isDark ? Colors.grey[800]! : Colors.grey[300]!,
              width: 0.5,
            ),
          ),
        ),
        child: Row(
          children: [
            Icon(
              isExpanded
                  ? CupertinoIcons.chevron_down
                  : CupertinoIcons.chevron_right,
              size: 14,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                name.toUpperCase(),
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                  color: theme.colorScheme.primary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              formatCurrency(total),
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ContractGroupHeader extends StatelessWidget {
  final String number;
  final double total;
  final bool isExpanded;
  final VoidCallback onTap;
  final VoidCallback onKs6aTap;

  const _ContractGroupHeader({
    required this.number,
    required this.total,
    required this.isExpanded,
    required this.onTap,
    required this.onKs6aTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(top: 8, left: 8, right: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isExpanded
              ? (isDark ? Colors.white10 : Colors.grey[100])
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isExpanded
                ? theme.colorScheme.primary.withValues(alpha: 0.3)
                : (isDark ? Colors.grey[800]! : Colors.grey[300]!),
            width: isExpanded ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isExpanded
                      ? CupertinoIcons.chevron_down
                      : CupertinoIcons.chevron_right,
                  size: 14,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Договор: $number',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Сумма: ${formatCurrency(total)}',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: onKs6aTap,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    'Журнал КС-6а',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EstimateListTile extends StatelessWidget {
  final EstimateFile file;
  final bool isSelected;
  final bool canDelete;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _EstimateListTile({
    required this.file,
    required this.isSelected,
    required this.canDelete,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(
            color: theme.colorScheme.primary.withValues(alpha: 0.3),
            width: 2,
          ),
        ),
      ),
      child: Material(
        color: isSelected
            ? theme.colorScheme.primaryContainer.withValues(alpha: 0.3)
            : Colors.transparent,
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(8),
          bottomRight: Radius.circular(8),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: const BorderRadius.only(
            topRight: Radius.circular(8),
            bottomRight: Radius.circular(8),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        file.estimateTitle,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.w500,
                          fontSize: 13,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (canDelete)
                      IconButton(
                        icon: Icon(CupertinoIcons.trash,
                            size: 16, color: theme.colorScheme.error),
                        onPressed: onDelete,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${file.itemsCount} поз.',
                      style: theme.textTheme.bodySmall,
                    ),
                    Text(
                      formatCurrency(file.total),
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
