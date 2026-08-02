import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:projectgt/core/common/app_router.dart';
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
import 'package:projectgt/presentation/widgets/app_bar_widget.dart';

/// Карточка позиции каталога ТМЦ.
class TmcItemDetailsScreen extends ConsumerWidget {
  /// Id позиции.
  final String itemId;

  /// Создаёт экран.
  const TmcItemDetailsScreen({super.key, required this.itemId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemAsync = ref.watch(tmcItemProvider(itemId));
    final unitsAsync = ref.watch(tmcItemUnitsProvider(itemId));
    final opsAsync = ref.watch(tmcItemOperationsProvider(itemId));
    final permissions = ref.watch(permissionServiceProvider);
    final canUpdate = permissions.can('tmc', 'update');
    final canViewCost = permissions.can('tmc', 'view_cost');

    return Scaffold(
      appBar: AppBarWidget(
        title: TmcUiLabels.itemCard,
        leading: BackButton(onPressed: () => context.go(AppRoutes.tmc)),
      ),
      body: itemAsync.when(
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
                _QuickActions(
                  item: item,
                  permissions: permissions,
                ),
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
                      _MainTab(item: item, canViewCost: canViewCost, canUpdate: canUpdate),
                      unitsAsync.when(
                        data: (units) => _UnitsTab(
                          units: units,
                          item: item,
                          permissions: permissions,
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
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  final TmcItem item;
  final PermissionService permissions;

  const _QuickActions({
    required this.item,
    required this.permissions,
  });

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
          if (permissions.can('tmc', 'repair'))
            _ActionChip(
              label: TmcUiLabels.actionRepair,
              onTap: () => TmcOperationDialog.show(
                context,
                operationType: TmcOperationType.sendToRepair,
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
        if (canViewCost)
          _InfoRow('Цена', formatCurrency(item.unitPrice)),
        if (canViewCost)
          _InfoRow('Стоимость', formatCurrency(item.totalCost)),
        _InfoRow('Статус', TmcUiLabels.itemStatus(item.status)),
        if (item.description != null)
          _InfoRow('Описание', item.description!),
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
          item.warrantyUntil != null
              ? formatRuDate(item.warrantyUntil!)
              : '—',
        ),
      ],
    );
  }
}

class _UnitsTab extends StatelessWidget {
  final List<TmcUnit> units;
  final TmcItem item;
  final PermissionService permissions;

  const _UnitsTab({
    required this.units,
    required this.item,
    required this.permissions,
  });

  @override
  Widget build(BuildContext context) {
    if (units.isEmpty) {
      return const Center(child: Text('Единиц не найдено'));
    }
    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: units.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final unit = units[index];
        return ListTile(
          title: Text(unit.inventoryNumber),
          subtitle: Text(
            '${TmcUiLabels.unitStatus(unit.status)} · ${unit.warehouseName ?? unit.objectName ?? unit.employeeName ?? '—'}',
          ),
          trailing: permissions.can('tmc', 'issue')
              ? IconButton(
                  icon: const Icon(CupertinoIcons.arrow_right_circle),
                  onPressed: () => TmcOperationDialog.show(
                    context,
                    operationType: TmcOperationType.issue,
                    item: item,
                    unit: unit,
                  ),
                )
              : null,
          onTap: permissions.can('tmc', 'issue')
              ? () => TmcOperationDialog.show(
                    context,
                    operationType: TmcOperationType.issue,
                    item: item,
                    unit: unit,
                  )
              : null,
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
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.55),
                  ),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
