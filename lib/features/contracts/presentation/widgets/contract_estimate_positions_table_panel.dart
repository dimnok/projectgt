import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:projectgt/core/di/providers.dart';
import 'package:projectgt/core/widgets/app_snackbar.dart';
import 'package:projectgt/domain/entities/contract.dart';
import 'package:projectgt/domain/entities/estimate.dart';
import 'package:projectgt/data/models/estimate_completion_model.dart';
import 'package:projectgt/features/contractors/presentation/providers/subcontractors_contractor_unit_prices_provider.dart';
import 'package:projectgt/features/contractors/presentation/providers/subcontractors_execution_progress_provider.dart';
import 'package:projectgt/features/contractors/presentation/widgets/subcontractors_estimate_table.dart';
import 'package:projectgt/features/estimates/presentation/providers/estimate_providers.dart';
import 'package:projectgt/features/estimates/presentation/widgets/estimate_edit_dialog.dart';
import 'package:projectgt/features/contracts/presentation/widgets/estimate_position_addendum_history_dialog.dart';
import 'package:projectgt/features/roles/application/permission_service.dart';
import 'package:projectgt/presentation/widgets/cupertino_dialog_widget.dart';

/// Подрежим вкладки «Сметы» на карточке договора: расценки и выполнение.
///
/// Хранится в [contractEstimateEmbeddedTableTabProvider] для связи строки заголовка
/// [ContractDetailsPanel] и [ContractEstimatePositionsTablePanel].
enum ContractEstimateEmbeddedTableTab {
  /// Таблица позиций (как «Расценки» у подрядчиков).
  rates,

  /// План/факт по данным выполнения.
  execution,
}

/// Текущий подрежим таблицы смет для договора [contractId].
final contractEstimateEmbeddedTableTabProvider = StateProvider.autoDispose
    .family<ContractEstimateEmbeddedTableTab, String>(
      (ref, contractId) => ContractEstimateEmbeddedTableTab.rates,
    );

/// Полоса переключения «Расценки / Выполнения» в шапке карточки договора.
class ContractEstimateEmbeddedTabStrip extends ConsumerWidget {
  /// Создаёт переключатель для договора [contractId].
  const ContractEstimateEmbeddedTabStrip({super.key, required this.contractId});

  /// Идентификатор договора (ключ состояния вкладки).
  final String contractId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tab = ref.watch(contractEstimateEmbeddedTableTabProvider(contractId));
    final notifier = ref.read(
      contractEstimateEmbeddedTableTabProvider(contractId).notifier,
    );
    final scheme = Theme.of(context).colorScheme;

    final sepStyle = TextStyle(
      color: scheme.onSurface.withValues(alpha: 0.4),
      fontWeight: FontWeight.w600,
    );

    Widget chip(String label, ContractEstimateEmbeddedTableTab value) =>
        _ModeChip(
          label: label,
          selected: tab == value,
          onTap: () => notifier.state = value,
        );

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: EdgeInsets.zero,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          chip('Расценки', ContractEstimateEmbeddedTableTab.rates),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text('/', style: sepStyle),
          ),
          chip('Выполнения', ContractEstimateEmbeddedTableTab.execution),
        ],
      ),
    );
  }
}

/// Табличное представление позиций смет по одному договору для встроенной
/// карточки договора.
///
/// Визуально и по колонкам совпадает с таблицей модуля «Подрядчики»
/// ([SubcontractorsEstimateTable]). Режим «Выполнения» использует план по полям
/// сметной позиции (цена/количество) и факт из [estimateCompletionByIdsProvider].
///
/// Отделён от [ContractEstimatesSection] для изоляции вёрстки и зависимостей.
class ContractEstimatePositionsTablePanel extends ConsumerStatefulWidget {
  /// Карточка договора (даёт идентификатор загрузки позиций).
  final Contract contract;

  /// По вертикали заполняет доступное ограничение родителя; при `maxHeight ==
  /// ∞` сохраняется прежняя эвристическая высота.
  final bool fillAvailableHeight;

  /// Создаёт панель таблицы смет для [contract].
  const ContractEstimatePositionsTablePanel({
    super.key,
    required this.contract,
    this.fillAvailableHeight = false,
  });

  @override
  ConsumerState<ContractEstimatePositionsTablePanel> createState() =>
      _ContractEstimatePositionsTablePanelState();
}

class _ContractEstimatePositionsTablePanelState
    extends ConsumerState<ContractEstimatePositionsTablePanel> {
  final Set<String> _selectedIds = {};

  double _embeddedPanelHeight(BuildContext context) =>
      (MediaQuery.sizeOf(context).height * 0.48).clamp(320.0, 640.0);

  Map<String, SubcontractorPricingForEstimate> _mirrorPlanPricing(
    List<Estimate> items,
  ) {
    return {
      for (final e in items)
        e.id: SubcontractorPricingForEstimate(
          unitPrice: e.price,
          contractorQuantity: e.quantity,
        ),
    };
  }

  /// Редактирование позиции в общем диалоге смет (как в модуле смет).
  Future<void> _openEditEstimate(
    BuildContext context,
    Estimate estimate,
  ) async {
    final permissionService = ref.read(permissionServiceProvider);
    if (!permissionService.can('estimates', 'update')) {
      return;
    }

    final raw = estimate.estimateTitle?.trim();
    final title = raw == null || raw.isEmpty ? 'Без названия' : raw;

    await EstimateEditDialog.show(
      context,
      estimate: estimate,
      estimateTitle: title,
      objectId: estimate.objectId,
      contractId: estimate.contractId ?? widget.contract.id,
    );

    if (!context.mounted) return;
    _invalidateContractEstimateLists();
  }

  /// Новая позиция в той же смете, что и строка, по которой открыли меню.
  Future<void> _openAddEstimatePosition(
    BuildContext context,
    Estimate contextRow,
  ) async {
    final permissionService = ref.read(permissionServiceProvider);
    if (!permissionService.can('estimates', 'update')) {
      return;
    }

    final raw = contextRow.estimateTitle?.trim();
    final title = raw == null || raw.isEmpty ? 'Без названия' : raw;

    await EstimateEditDialog.show(
      context,
      estimate: null,
      estimateTitle: title,
      objectId: contextRow.objectId,
      contractId: contextRow.contractId ?? widget.contract.id,
      initialSystem: contextRow.system,
      initialSubsystem: contextRow.subsystem,
    );

    if (!context.mounted) return;
    _invalidateContractEstimateLists();
  }

  Future<void> _openAddendumHistory(Estimate estimate) async {
    final permissionService = ref.read(permissionServiceProvider);
    if (!permissionService.can('estimates', 'read')) {
      return;
    }
    final rawTitle = estimate.estimateTitle?.trim();
    if (rawTitle == null || rawTitle.isEmpty) {
      if (!context.mounted) return;
      AppSnackBar.show(
        context: context,
        message: 'У позиции не указан заголовок сметы',
        kind: AppSnackBarKind.warning,
      );
      return;
    }
    final contractId = estimate.contractId ?? widget.contract.id;
    await EstimatePositionAddendumHistoryDialog.show(
      context,
      contractId: contractId,
      estimateTitle: rawTitle,
      estimateRowId: estimate.id,
      rowSubtitle: estimate.name,
    );
    if (!context.mounted) return;
  }

  /// Удаление позиции после подтверждения (как в модуле смет).
  Future<void> _deleteEstimateItem(BuildContext context, String id) async {
    final permissionService = ref.read(permissionServiceProvider);
    if (!permissionService.can('estimates', 'delete')) {
      return;
    }

    final confirmed = await CupertinoDialogs.showDeleteConfirmDialog<bool>(
      context: context,
      title: 'Удаление позиции',
      message: 'Вы действительно хотите удалить эту позицию?',
      onConfirm: () {},
    );

    if (confirmed == true && mounted) {
      try {
        await ref.read(estimateNotifierProvider.notifier).deleteEstimate(id);
        if (!context.mounted) return;
        _invalidateContractEstimateLists();
        AppSnackBar.show(
          context: context,
          message: 'Позиция удалена',
          kind: AppSnackBarKind.success,
        );
      } catch (e) {
        if (!context.mounted) return;
        AppSnackBar.show(
          context: context,
          message: 'Ошибка удаления: $e',
          kind: AppSnackBarKind.error,
        );
      }
    }
  }

  /// Удаление отмеченных чекбоксами позиций после подтверждения.
  Future<void> _deleteSelectedEstimateItems(BuildContext context) async {
    final permissionService = ref.read(permissionServiceProvider);
    if (!permissionService.can('estimates', 'delete')) {
      return;
    }

    final ids = _selectedIds.toList(growable: false);
    if (ids.isEmpty) return;

    final count = ids.length;
    final confirmed = await CupertinoDialogs.showDeleteConfirmDialog<bool>(
      context: context,
      title: 'Удаление позиций',
      message: count == 1
          ? 'Вы действительно хотите удалить выбранную позицию?'
          : 'Вы действительно хотите удалить выбранные позиции ($count шт.)?',
      onConfirm: () {},
    );

    if (confirmed != true || !mounted) return;

    final notifier = ref.read(estimateNotifierProvider.notifier);
    Object? firstError;
    final deletedIds = <String>[];

    for (final id in ids) {
      try {
        await notifier.deleteEstimate(id);
        deletedIds.add(id);
      } catch (e) {
        firstError ??= e;
      }
    }

    if (!mounted) return;
    _invalidateContractEstimateLists();
    setState(() => _selectedIds.removeAll(deletedIds));

    if (!context.mounted) return;

    if (firstError != null && deletedIds.isEmpty) {
      AppSnackBar.show(
        context: context,
        message: 'Ошибка удаления: $firstError',
        kind: AppSnackBarKind.error,
      );
      return;
    }

    if (firstError != null) {
      AppSnackBar.show(
        context: context,
        message:
            'Удалено позиций: ${deletedIds.length}. Ошибка: $firstError',
        kind: AppSnackBarKind.error,
      );
      return;
    }

    final n = deletedIds.length;
    AppSnackBar.show(
      context: context,
      message: n == 1
          ? 'Позиция удалена'
          : 'Удалено позиций: $n',
      kind: AppSnackBarKind.success,
    );
  }

  Future<void> _toggleVisibleInEstimatesModule(
    BuildContext context,
    Estimate estimate,
  ) async {
    final permissionService = ref.read(permissionServiceProvider);
    if (!permissionService.can('estimates', 'update')) {
      return;
    }
    try {
      await ref.read(estimateNotifierProvider.notifier).updateEstimate(
            estimate.copyWith(
              visibleInEstimatesModule: !estimate.visibleInEstimatesModule,
            ),
          );
      if (!context.mounted) return;
      _invalidateContractEstimateLists();
    } catch (e) {
      if (!context.mounted) return;
      AppSnackBar.show(
        context: context,
        message: 'Не удалось сохранить: $e',
        kind: AppSnackBarKind.error,
      );
    }
  }

  void _invalidateContractEstimateLists() {
    ref.invalidate(contractEstimatesProvider(widget.contract.id));
    ref.invalidate(estimateGroupsProvider);
    ref.invalidate(estimateCompletionByIdsProvider);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final estimatesAsync = ref.watch(
      contractEstimatesProvider(widget.contract.id),
    );
    final tab = ref.watch(
      contractEstimateEmbeddedTableTabProvider(widget.contract.id),
    );

    return estimatesAsync.when(
      loading: () => widget.fillAvailableHeight
          ? const SizedBox.expand(
              child: Center(
                child: Padding(
                  padding: EdgeInsets.all(28),
                  child: CircularProgressIndicator(),
                ),
              ),
            )
          : const Center(
              child: Padding(
                padding: EdgeInsets.all(28),
                child: CircularProgressIndicator(),
              ),
            ),
      error: (err, _) {
        final text = Text(
          'Не удалось загрузить позиции: $err',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(color: scheme.error),
        );
        return widget.fillAvailableHeight
            ? SizedBox.expand(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: text,
                  ),
                ),
              )
            : text;
      },
      data: (items) {
        if (items.isEmpty) {
          final msg = Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
            child: Text(
              'Для этого договора смет пока нет.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onSurface.withValues(alpha: 0.58),
              ),
            ),
          );
          return widget.fillAvailableHeight
              ? SizedBox.expand(child: Center(child: msg))
              : msg;
        }

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          final keepIds = items.map((e) => e.id).toSet();
          if (_selectedIds.difference(keepIds).isEmpty) return;
          setState(() => _selectedIds.retainWhere(keepIds.contains));
        });

        Widget tableBody() => switch (tab) {
          ContractEstimateEmbeddedTableTab.rates => SubcontractorsEstimateTable(
            items: items,
            subcontractorPricingByEstimateId: null,
            executionByEstimateId: null,
            mode: SubcontractorsEstimateTableMode.rates,
            expandSections: false,
            showInEstimatesModuleColumn: true,
            onVisibleInEstimatesModuleTap: (e) =>
                _toggleVisibleInEstimatesModule(context, e),
            selectedEstimateIds: _selectedIds,
            onSelectedEstimateIdsChanged: (ids) => setState(
              () => _selectedIds
                ..clear()
                ..addAll(ids),
            ),
            onEdit: (e) => _openEditEstimate(context, e),
            onDuplicate: (_) {},
            onAddPosition: (row) => _openAddEstimatePosition(context, row),
            onDelete: (id) => _deleteEstimateItem(context, id),
            onDeleteSelected: (ctx) =>
                unawaited(_deleteSelectedEstimateItems(ctx)),
            onEstimateAddendumHistory: _openAddendumHistory,
          ),
          ContractEstimateEmbeddedTableTab.execution =>
            _EmbeddedExecutionModeTable(
              items: items,
              selectedIds: _selectedIds,
              onSelectionChanged: (ids) => setState(
                () => _selectedIds
                  ..clear()
                  ..addAll(ids),
              ),
              onEdit: (e) => _openEditEstimate(context, e),
              onAddPosition: (row) => _openAddEstimatePosition(context, row),
              onDelete: (id) => _deleteEstimateItem(context, id),
              onDeleteSelected: (ctx) =>
                  unawaited(_deleteSelectedEstimateItems(ctx)),
              planPricingOverride: _mirrorPlanPricing(items),
              onEstimateAddendumHistory: _openAddendumHistory,
            ),
        };

        if (widget.fillAvailableHeight) {
          return SizedBox.expand(child: tableBody());
        }

        return SizedBox(
          height: _embeddedPanelHeight(context),
          width: double.infinity,
          child: tableBody(),
        );
      },
    );
  }
}

/// Подрежим выполнение: свой [Consumer] только здесь подписывает провайдер
/// выполнения и не дергает RPC на вкладке «Расценки».
class _EmbeddedExecutionModeTable extends ConsumerWidget {
  const _EmbeddedExecutionModeTable({
    required this.items,
    required this.selectedIds,
    required this.onSelectionChanged,
    required this.onEdit,
    required this.onAddPosition,
    required this.onDelete,
    required this.onDeleteSelected,
    required this.planPricingOverride,
    this.onEstimateAddendumHistory,
  });

  final List<Estimate> items;
  final Set<String> selectedIds;
  final ValueChanged<Set<String>> onSelectionChanged;
  final void Function(Estimate estimate) onEdit;
  final void Function(Estimate contextRow) onAddPosition;
  final void Function(String id) onDelete;
  final void Function(BuildContext context) onDeleteSelected;
  final Map<String, SubcontractorPricingForEstimate> planPricingOverride;
  final void Function(Estimate estimate)? onEstimateAddendumHistory;

  Map<String, SubcontractorExecutionProgress> _fromCompletionModels(
    List<EstimateCompletionModel> rows,
  ) {
    final out = <String, SubcontractorExecutionProgress>{};
    for (final c in rows) {
      final id = c.estimateId;
      if (id.isEmpty) continue;
      out[id] = SubcontractorExecutionProgress(
        completedQuantity: c.completedQuantity,
        rowsCount: 0,
      );
    }
    return out;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ids = items.map((e) => e.id).toList(growable: false);
    final completionAsync = ref.watch(
      estimateCompletionByIdsProvider(EstimateIds(ids)),
    );

    return completionAsync.when(
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: CircularProgressIndicator(),
        ),
      ),
      error: (err, _) => Center(
        child: Text('Ошибка выполнения: $err', textAlign: TextAlign.center),
      ),
      data: (completionRows) {
        return SubcontractorsEstimateTable(
          items: items,
          subcontractorPricingByEstimateId: planPricingOverride,
          executionByEstimateId: _fromCompletionModels(completionRows),
          mode: SubcontractorsEstimateTableMode.execution,
          expandSections: false,
          selectedEstimateIds: selectedIds,
          onSelectedEstimateIdsChanged: onSelectionChanged,
          onEdit: onEdit,
          onAddPosition: onAddPosition,
          onDuplicate: (_) {},
          onDelete: onDelete,
          onDeleteSelected: onDeleteSelected,
          onEstimateAddendumHistory: onEstimateAddendumHistory,
        );
      },
    );
  }
}

/// Кнопка переключения режима таблицы (аналог текстовых вкладок в «Подрядчики»).
class _ModeChip extends StatelessWidget {
  const _ModeChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final base = scheme.onSurfaceVariant;
    final active = scheme.primary;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              width: selected ? 2 : 1,
              color: selected ? active : base.withValues(alpha: 0.15),
            ),
          ),
        ),
        child: Text(
          label,
          style: theme.textTheme.labelLarge?.copyWith(
            fontSize: 13,
            letterSpacing: 0.08,
            fontWeight: FontWeight.w600,
            color: selected ? active : base,
          ),
        ),
      ),
    );
  }
}
