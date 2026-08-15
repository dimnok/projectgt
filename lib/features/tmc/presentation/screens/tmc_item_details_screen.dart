import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:projectgt/core/utils/formatters.dart';
import 'package:projectgt/features/roles/application/permission_service.dart';
import 'package:projectgt/features/tmc/domain/entities/tmc_enums.dart';
import 'package:projectgt/features/tmc/domain/entities/tmc_item.dart';
import 'package:projectgt/features/tmc/domain/entities/tmc_operation.dart';
import 'package:projectgt/features/tmc/domain/entities/tmc_unit.dart';
import 'package:projectgt/features/tmc/presentation/state/tmc_providers.dart';
import 'package:projectgt/features/tmc/presentation/utils/tmc_ui_labels.dart';
import 'package:projectgt/features/tmc/presentation/widgets/tmc_item_form_dialog.dart';
import 'package:projectgt/features/tmc/presentation/widgets/tmc_operation_dialog.dart';
import 'package:projectgt/features/tmc/presentation/widgets/tmc_unit_form_dialog.dart';

/// Встроенная карточка позиции ТМЦ (без отдельного экрана).
///
/// Показывается внутри основной области модуля вместо таблицы реестра.
class TmcItemDetailsPanel extends ConsumerWidget {
  /// Id позиции.
  final String itemId;

  /// Создаёт карточку позиции.
  const TmcItemDetailsPanel({super.key, required this.itemId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemAsync = ref.watch(tmcItemProvider(itemId));
    final unitsAsync = ref.watch(tmcItemUnitsProvider(itemId));
    final opsAsync = ref.watch(tmcItemOperationsProvider(itemId));
    final permissions = ref.watch(permissionServiceProvider);
    final canUpdate = permissions.can('tmc', 'update');
    final canViewCost = permissions.can('tmc', 'view_cost');

    return itemAsync.when(
      loading: () => const Center(child: CupertinoActivityIndicator()),
      error: (e, _) => Center(child: Text(e.toString())),
      data: (item) {
        if (item == null) {
          return const Center(child: Text('Позиция не найдена'));
        }
        return DefaultTabController(
          length: 4,
          child: Column(
            children: [
              _QuickActions(item: item, permissions: permissions),
              const TabBar(
                tabs: [
                  Tab(text: TmcUiLabels.sectionMain),
                  Tab(text: TmcUiLabels.sectionUnits),
                  Tab(text: TmcUiLabels.sectionPurchase),
                  Tab(text: TmcUiLabels.sectionHistory),
                ],
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    _MainTab(
                      item: item,
                      canViewCost: canViewCost,
                      canUpdate: canUpdate,
                    ),
                    unitsAsync.when(
                      data: (units) => _UnitsTab(
                        units: units,
                        item: item,
                        permissions: permissions,
                        canUpdate: canUpdate,
                      ),
                      loading: () =>
                          const Center(child: CupertinoActivityIndicator()),
                      error: (e, _) => Center(child: Text(e.toString())),
                    ),
                    _PurchaseTab(item: item, canViewCost: canViewCost),
                    opsAsync.when(
                      data: (ops) => _HistoryTab(operations: ops),
                      loading: () =>
                          const Center(child: CupertinoActivityIndicator()),
                      error: (e, _) => Center(child: Text(e.toString())),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _QuickActions extends StatelessWidget {
  final TmcItem item;
  final PermissionService permissions;

  const _QuickActions({required this.item, required this.permissions});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          if (permissions.can('tmc', 'create'))
            _ActionChip(
              label: TmcUiLabels.actionReceipt,
              onTap: () => TmcOperationDialog.show(
                context,
                operationType: TmcOperationType.receipt,
                item: item,
              ),
            ),
          if (permissions.can('tmc', 'issue'))
            _ActionChip(
              label: TmcUiLabels.actionIssue,
              onTap: () => TmcOperationDialog.show(
                context,
                operationType: TmcOperationType.issue,
                item: item,
              ),
            ),
          if (permissions.can('tmc', 'issue'))
            _ActionChip(
              label: TmcUiLabels.actionReturn,
              onTap: () => TmcOperationDialog.show(
                context,
                operationType: TmcOperationType.returnFromEmployee,
                item: item,
              ),
            ),
          if (permissions.can('tmc', 'move'))
            _ActionChip(
              label: TmcUiLabels.actionMove,
              onTap: () => TmcOperationDialog.show(
                context,
                operationType: TmcOperationType.moveBetweenWarehouses,
                item: item,
              ),
            ),
          if (permissions.can('tmc', 'move'))
            _ActionChip(
              label: TmcUiLabels.actionMoveToObject,
              onTap: () => TmcOperationDialog.show(
                context,
                operationType: TmcOperationType.transferToObject,
                item: item,
              ),
            ),
          if (permissions.can('tmc', 'repair'))
            _ActionChip(
              label: TmcUiLabels.actionRepair,
              onTap: () => TmcOperationDialog.show(
                context,
                operationType: TmcOperationType.sendToRepair,
                item: item,
              ),
            ),
          if (permissions.can('tmc', 'repair'))
            _ActionChip(
              label: TmcUiLabels.actionReturnFromRepair,
              onTap: () => TmcOperationDialog.show(
                context,
                operationType: TmcOperationType.returnFromRepair,
                item: item,
              ),
            ),
          if (permissions.can('tmc', 'write_off'))
            _ActionChip(
              label: TmcUiLabels.actionWriteOff,
              onTap: () => TmcOperationDialog.show(
                context,
                operationType: TmcOperationType.writeOff,
                item: item,
              ),
            ),
          if (permissions.can('tmc', 'update'))
            _ActionChip(
              label: TmcUiLabels.actionChangeCondition,
              onTap: () => TmcOperationDialog.show(
                context,
                operationType: TmcOperationType.changeCondition,
                item: item,
              ),
            ),
        ],
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _ActionChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ActionChip(label: Text(label), onPressed: onTap),
    );
  }
}

class _MainTab extends StatelessWidget {
  final TmcItem item;
  final bool canViewCost;
  final bool canUpdate;

  const _MainTab({
    required this.item,
    required this.canViewCost,
    required this.canUpdate,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _InfoRow('Наименование', item.name),
        _InfoRow('Категория', item.categoryName ?? '—'),
        _InfoRow('Тип учёта', TmcUiLabels.accountingType(item.accountingType)),
        _InfoRow('Артикул', item.sku ?? '—'),
        _InfoRow('Ед. изм.', item.unitOfMeasure),
        _InfoRow('Всего', formatQuantity(item.quantity)),
        _InfoRow('На складе', formatQuantity(item.qtyInStock)),
        _InfoRow('Выдано', formatQuantity(item.qtyIssued)),
        _InfoRow('На объекте', formatQuantity(item.qtyOnObject)),
        _InfoRow(
          'Где лежит',
          item.locationSummary?.isNotEmpty == true
              ? item.locationSummary!
              : '—',
        ),
        if (canViewCost) _InfoRow('Цена', formatCurrency(item.unitPrice)),
        if (canViewCost) _InfoRow('Стоимость', formatCurrency(item.totalCost)),
        _InfoRow('Статус', TmcUiLabels.itemStatus(item.status)),
        if (item.description != null) _InfoRow('Описание', item.description!),
        if (canUpdate)
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: OutlinedButton(
              onPressed: () => TmcItemFormDialog.show(context, item: item),
              child: const Text('Редактировать'),
            ),
          ),
      ],
    );
  }
}

class _PurchaseTab extends StatelessWidget {
  final TmcItem item;
  final bool canViewCost;

  const _PurchaseTab({required this.item, required this.canViewCost});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _InfoRow('Поставщик', item.supplierName ?? '—'),
        _InfoRow(
          'Дата поставки',
          item.deliveryDate != null ? formatRuDate(item.deliveryDate!) : '—',
        ),
        _InfoRow(
          'Дата приёмки',
          item.acceptanceDate != null
              ? formatRuDate(item.acceptanceDate!)
              : '—',
        ),
        _InfoRow('Документ', item.documentNumber ?? '—'),
        if (canViewCost) _InfoRow('Цена', formatCurrency(item.unitPrice)),
        _InfoRow(
          'Гарантия до',
          item.warrantyUntil != null ? formatRuDate(item.warrantyUntil!) : '—',
        ),
      ],
    );
  }
}

class _UnitsTab extends StatelessWidget {
  final List<TmcUnit> units;
  final TmcItem item;
  final PermissionService permissions;
  final bool canUpdate;

  const _UnitsTab({
    required this.units,
    required this.item,
    required this.permissions,
    required this.canUpdate,
  });

  @override
  Widget build(BuildContext context) {
    if (units.isEmpty) {
      return const Center(child: Text('Конкретных единиц не найдено'));
    }

    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final canIssue = permissions.can('tmc', 'issue');
    final canMove = permissions.can('tmc', 'move');
    final canRepair = permissions.can('tmc', 'repair');
    final canWriteOff = permissions.can('tmc', 'write_off');

    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: units.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final unit = units[index];
        final isStock = unit.status == TmcUnitStatus.inStock;
        final isIssued = unit.status == TmcUnitStatus.issued;
        final isInRepair = unit.status == TmcUnitStatus.inRepair;
        final hasSn = unit.serialNumber?.trim().isNotEmpty == true;

        final locationText =
            unit.warehouseName ??
            unit.objectName ??
            (unit.employeeName != null
                ? 'Сотрудник: ${unit.employeeName}'
                : '—');

        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: canUpdate
                ? () => TmcUnitFormDialog.show(context, unit: unit)
                : null,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Иконка
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: scheme.surfaceContainerHighest.withValues(
                        alpha: 0.5,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      CupertinoIcons.tag,
                      size: 18,
                      color: scheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Описание единицы (Инвентарный № + Серийный №)
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Инв. № ${unit.inventoryNumber}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 3),
                        if (hasSn)
                          Text(
                            'S/N: ${unit.serialNumber!.trim()}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: scheme.onSurface,
                            ),
                          )
                        else
                          Text(
                            canUpdate
                                ? 'Серийный номер не указан — нажмите, чтобы добавить'
                                : 'Серийный номер не указан',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: scheme.onSurface.withValues(alpha: 0.45),
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        const SizedBox(height: 2),
                        Text(
                          '${TmcUiLabels.unitStatus(unit.status)} · $locationText',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: scheme.onSurface.withValues(alpha: 0.65),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Кнопки действий над конкретным экземпляром
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (canUpdate)
                        Tooltip(
                          message: hasSn
                              ? 'Изменить серийный номер'
                              : 'Указать серийный номер',
                          child: IconButton(
                            icon: const Icon(CupertinoIcons.pencil, size: 18),
                            onPressed: () =>
                                TmcUnitFormDialog.show(context, unit: unit),
                          ),
                        ),
                      if (canIssue && isStock)
                        Tooltip(
                          message: 'Выдать этот инструмент',
                          child: IconButton(
                            icon: const Icon(
                              CupertinoIcons.arrow_up_right_circle,
                              size: 20,
                            ),
                            onPressed: () => TmcOperationDialog.show(
                              context,
                              operationType: TmcOperationType.issue,
                              item: item,
                              unit: unit,
                            ),
                          ),
                        ),
                      if (canIssue && isIssued)
                        Tooltip(
                          message: 'Принять возврат',
                          child: IconButton(
                            icon: const Icon(
                              CupertinoIcons.arrow_down_left_circle,
                              size: 20,
                            ),
                            onPressed: () => TmcOperationDialog.show(
                              context,
                              operationType:
                                  TmcOperationType.returnFromEmployee,
                              item: item,
                              unit: unit,
                            ),
                          ),
                        ),
                      if (canMove && isStock)
                        Tooltip(
                          message: 'Переместить между складами',
                          child: IconButton(
                            icon: const Icon(
                              CupertinoIcons.arrow_2_circlepath,
                              size: 20,
                            ),
                            onPressed: () => TmcOperationDialog.show(
                              context,
                              operationType:
                                  TmcOperationType.moveBetweenWarehouses,
                              item: item,
                              unit: unit,
                            ),
                          ),
                        ),
                      if (canMove && isStock)
                        Tooltip(
                          message: TmcUiLabels.actionMoveToObject,
                          child: IconButton(
                            icon: const Icon(
                              CupertinoIcons.location,
                              size: 18,
                            ),
                            onPressed: () => TmcOperationDialog.show(
                              context,
                              operationType: TmcOperationType.transferToObject,
                              item: item,
                              unit: unit,
                            ),
                          ),
                        ),
                      if (canRepair && !isInRepair)
                        Tooltip(
                          message: 'В ремонт',
                          child: IconButton(
                            icon: const Icon(CupertinoIcons.wrench, size: 18),
                            onPressed: () => TmcOperationDialog.show(
                              context,
                              operationType: TmcOperationType.sendToRepair,
                              item: item,
                              unit: unit,
                            ),
                          ),
                        ),
                      if (canRepair && isInRepair)
                        Tooltip(
                          message: TmcUiLabels.actionReturnFromRepair,
                          child: IconButton(
                            icon: const Icon(
                              CupertinoIcons.arrow_uturn_left,
                              size: 18,
                            ),
                            onPressed: () => TmcOperationDialog.show(
                              context,
                              operationType: TmcOperationType.returnFromRepair,
                              item: item,
                              unit: unit,
                            ),
                          ),
                        ),
                      if (canWriteOff)
                        Tooltip(
                          message: 'Списать',
                          child: IconButton(
                            icon: const Icon(CupertinoIcons.trash, size: 18),
                            onPressed: () => TmcOperationDialog.show(
                              context,
                              operationType: TmcOperationType.writeOff,
                              item: item,
                              unit: unit,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _HistoryTab extends StatelessWidget {
  final List<TmcOperation> operations;

  const _HistoryTab({required this.operations});

  @override
  Widget build(BuildContext context) {
    if (operations.isEmpty) {
      return const Center(child: Text(TmcUiLabels.emptyOperations));
    }
    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: operations.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final op = operations[index];
        return ListTile(
          title: Text(TmcUiLabels.operationType(op.operationType)),
          subtitle: Text(formatRuDateTime(op.operatedAt)),
        );
      },
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.55),
              ),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
