import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:projectgt/core/utils/responsive_utils.dart';
import 'package:projectgt/core/widgets/app_snackbar.dart';
import 'package:projectgt/core/widgets/desktop_dialog_content.dart';
import 'package:projectgt/core/widgets/gt_buttons.dart';
import 'package:projectgt/core/widgets/gt_dropdown.dart';
import 'package:projectgt/core/widgets/gt_text_field.dart';
import 'package:projectgt/core/widgets/mobile_bottom_sheet_content.dart';
import 'package:projectgt/domain/entities/employee.dart';
import 'package:projectgt/features/objects/domain/entities/object.dart';
import 'package:projectgt/features/tmc/domain/entities/tmc_enums.dart';
import 'package:projectgt/core/di/providers.dart';
import 'package:projectgt/features/tmc/domain/entities/tmc_condition.dart';
import 'package:projectgt/features/tmc/domain/entities/tmc_item.dart';
import 'package:projectgt/features/tmc/domain/entities/tmc_unit.dart';
import 'package:projectgt/features/tmc/domain/entities/tmc_warehouse.dart';
import 'package:projectgt/features/tmc/presentation/state/tmc_providers.dart';
import 'package:projectgt/features/tmc/presentation/utils/tmc_ui_labels.dart';
import 'package:projectgt/features/tmc/presentation/widgets/tmc_serial_numbers_editor.dart';
import 'package:projectgt/presentation/state/employee_state.dart' as emp_state;

/// Унифицированный диалог складской операции ТМЦ.
class TmcOperationDialog extends ConsumerStatefulWidget {
  /// Тип операции.
  final TmcOperationType operationType;

  /// Предзаполненная позиция.
  final TmcItem? presetItem;

  /// Предзаполненная единица.
  final TmcUnit? presetUnit;

  /// Создаёт диалог.
  const TmcOperationDialog({
    super.key,
    required this.operationType,
    this.presetItem,
    this.presetUnit,
  });

  /// Показать диалог.
  static Future<void> show(
    BuildContext context, {
    required TmcOperationType operationType,
    TmcItem? item,
    TmcUnit? unit,
  }) {
    final isDesktop = ResponsiveUtils.isDesktop(context);
    final dialog = TmcOperationDialog(
      operationType: operationType,
      presetItem: item,
      presetUnit: unit,
    );
    if (isDesktop) {
      return showDialog<void>(
        context: context,
        builder: (_) => Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(24),
          child: dialog,
        ),
      );
    }
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => dialog,
    );
  }

  @override
  ConsumerState<TmcOperationDialog> createState() => _TmcOperationDialogState();
}

class _TmcOperationDialogState extends ConsumerState<TmcOperationDialog> {
  final _commentController = TextEditingController();
  final _quantityController = TextEditingController(text: '1');
  final _documentController = TextEditingController();
  final _repairReasonController = TextEditingController();
  final _repairOrgController = TextEditingController();
  final _writeOffActController = TextEditingController();
  final _serialNumbersKey = GlobalKey<TmcSerialNumbersEditorState>();

  String? _warehouseId;
  String? _toWarehouseId;
  String? _objectId;
  String? _employeeId;
  String? _conditionId;
  String? _selectedUnitId;
  TmcWriteOffReason _writeOffReason = TmcWriteOffReason.wear;
  bool _saving = false;
  List<TmcUnit> _units = const [];
  bool _unitsLoading = false;

  bool get _isIndividual =>
      widget.presetItem?.accountingType == TmcAccountingType.individual ||
      widget.presetUnit != null;

  bool get _needsUnit =>
      _isIndividual && widget.operationType != TmcOperationType.receipt;

  @override
  void initState() {
    super.initState();
    _selectedUnitId = widget.presetUnit?.id;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(objectProvider.notifier).loadObjects();
      ref.read(emp_state.employeeProvider.notifier).getEmployees();
      _loadUnitsIfNeeded();
    });
    _applyUnitDefaults(widget.presetUnit);
  }

  void _applyUnitDefaults(TmcUnit? unit) {
    if (unit == null) return;
    _warehouseId ??= unit.warehouseId;
    _objectId ??= unit.objectId;
    _employeeId ??= unit.employeeId;
    _conditionId ??= unit.conditionId;
  }

  Future<void> _loadUnitsIfNeeded() async {
    final itemId = widget.presetItem?.id;
    if (!_needsUnit || itemId == null || widget.presetUnit != null) return;
    setState(() => _unitsLoading = true);
    try {
      final units = await ref
          .read(tmcRepositoryProvider)
          .listUnits(itemId: itemId);
      if (!mounted) return;
      setState(() {
        _units = units
            .where((u) => u.status != TmcUnitStatus.writtenOff)
            .toList();
        _unitsLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _unitsLoading = false);
      AppSnackBar.show(
        context: context,
        message: 'Не удалось загрузить единицы: $e',
        kind: AppSnackBarKind.error,
      );
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    _quantityController.dispose();
    _documentController.dispose();
    _repairReasonController.dispose();
    _repairOrgController.dispose();
    _writeOffActController.dispose();
    super.dispose();
  }

  TmcUnit? get _activeUnit {
    if (widget.presetUnit != null) return widget.presetUnit;
    for (final u in _units) {
      if (u.id == _selectedUnitId) return u;
    }
    return null;
  }

  String? _validate() {
    if (widget.presetItem == null && widget.presetUnit == null) {
      return 'Не указана позиция ТМЦ';
    }
    if (_needsUnit && (_selectedUnitId == null || _selectedUnitId!.isEmpty)) {
      return 'Выберите единицу имущества (инвентарный номер)';
    }

    final type = widget.operationType;
    switch (type) {
      case TmcOperationType.receipt:
        if (_warehouseId == null) return 'Выберите склад поступления';
      case TmcOperationType.issue:
        if (_warehouseId == null && !_isIndividual) {
          return 'Выберите склад выдачи';
        }
        if (_employeeId == null) return 'Выберите сотрудника';
      case TmcOperationType.returnFromEmployee:
        if (_employeeId == null && _activeUnit?.employeeId == null) {
          return 'Укажите сотрудника';
        }
        if (_warehouseId == null) return 'Выберите склад возврата';
      case TmcOperationType.transferToObject:
        if (_objectId == null) return 'Выберите объект';
        if (_warehouseId == null && !_isIndividual) {
          return 'Выберите склад';
        }
      case TmcOperationType.moveBetweenWarehouses:
        if (_warehouseId == null || _toWarehouseId == null) {
          return 'Укажите оба склада';
        }
        if (_warehouseId == _toWarehouseId) {
          return 'Склады «откуда» и «куда» должны отличаться';
        }
      case TmcOperationType.changeCondition:
        if (_conditionId == null) return 'Выберите новое состояние';
      case TmcOperationType.sendToRepair:
        if (_repairReasonController.text.trim().isEmpty) {
          return 'Укажите причину ремонта';
        }
      case TmcOperationType.writeOff:
        if (!_isIndividual && _warehouseId == null) {
          return 'Выберите склад списания';
        }
      default:
        break;
    }
    return null;
  }

  Map<String, dynamic> _buildPayload() {
    final itemId = widget.presetItem?.id ?? widget.presetUnit?.itemId;
    if (itemId == null || itemId.isEmpty) {
      throw StateError('Не указана позиция ТМЦ');
    }

    final unit = _activeUnit;
    final qty =
        (_isIndividual && widget.operationType != TmcOperationType.receipt)
        ? 1.0
        : (TmcUiLabels.parseQuantity(_quantityController.text) ?? 1);

    // Исходная локация из единицы (для индивидуальных операций)
    final fromType = unit?.locationType.dbValue;
    final fromWarehouse = unit?.warehouseId ?? _warehouseId;
    final fromObject = unit?.objectId;
    final fromEmployee = unit?.employeeId ?? _employeeId;
    final fromNote = unit?.locationNote;

    final serialNumbers =
        widget.operationType == TmcOperationType.receipt && _isIndividual
        ? TmcUiLabels.nonEmptySerials(_serialNumbersKey.currentState?.values)
        : const <String>[];

    final payload = <String, dynamic>{
      'operation_type': widget.operationType.dbValue,
      'operated_at': DateTime.now().toUtc().toIso8601String(),
      'document_number': _documentController.text.trim().isEmpty
          ? null
          : _documentController.text.trim(),
      'comment': _commentController.text.trim().isEmpty
          ? null
          : _commentController.text.trim(),
      'object_id': _objectId,
      'items': [
        {
          'item_id': itemId,
          if (_selectedUnitId != null) 'unit_id': _selectedUnitId,
          'quantity': qty,
          if (_conditionId != null) 'condition_id': _conditionId,
          if (serialNumbers.isNotEmpty) 'serial_numbers': serialNumbers,
          if (serialNumbers.isNotEmpty) 'serial_number': serialNumbers.first,
        },
      ],
    };

    switch (widget.operationType) {
      case TmcOperationType.receipt:
        payload['to_location_type'] = TmcLocationType.warehouse.dbValue;
        payload['to_warehouse_id'] = _warehouseId;
        break;
      case TmcOperationType.issue:
        payload['from_location_type'] =
            fromType ?? TmcLocationType.warehouse.dbValue;
        payload['from_warehouse_id'] = fromWarehouse;
        payload['from_object_id'] = fromObject;
        payload['from_employee_id'] = fromEmployee;
        payload['from_location_note'] = fromNote;
        payload['to_location_type'] = TmcLocationType.employee.dbValue;
        payload['to_employee_id'] = _employeeId;
        payload['object_id'] = _objectId;
        break;
      case TmcOperationType.returnFromEmployee:
        payload['from_location_type'] =
            fromType ?? TmcLocationType.employee.dbValue;
        payload['from_employee_id'] = fromEmployee ?? _employeeId;
        payload['to_location_type'] = TmcLocationType.warehouse.dbValue;
        payload['to_warehouse_id'] = _warehouseId;
        break;
      case TmcOperationType.transferToObject:
        payload['from_location_type'] =
            fromType ?? TmcLocationType.warehouse.dbValue;
        payload['from_warehouse_id'] = fromWarehouse;
        payload['from_object_id'] = fromObject;
        payload['from_employee_id'] = fromEmployee;
        payload['to_location_type'] = TmcLocationType.object.dbValue;
        payload['to_object_id'] = _objectId;
        break;
      case TmcOperationType.moveBetweenWarehouses:
        payload['from_location_type'] = TmcLocationType.warehouse.dbValue;
        payload['from_warehouse_id'] = _warehouseId;
        payload['to_location_type'] = TmcLocationType.warehouse.dbValue;
        payload['to_warehouse_id'] = _toWarehouseId;
        break;
      case TmcOperationType.changeCondition:
        payload['condition_id'] = _conditionId;
        // Для RPC индивидуальной смены состояния unit_id обязателен
        break;
      case TmcOperationType.sendToRepair:
        payload['from_location_type'] =
            fromType ?? TmcLocationType.warehouse.dbValue;
        payload['from_warehouse_id'] = fromWarehouse;
        payload['from_object_id'] = fromObject;
        payload['from_employee_id'] = fromEmployee;
        payload['from_location_note'] = fromNote;
        payload['to_location_type'] = TmcLocationType.repairOrg.dbValue;
        payload['to_location_note'] = _repairOrgController.text.trim().isEmpty
            ? 'Ремонт'
            : _repairOrgController.text.trim();
        payload['repair'] = {
          'reason': _repairReasonController.text.trim(),
          'repair_org_name': _repairOrgController.text.trim().isEmpty
              ? null
              : _repairOrgController.text.trim(),
        };
        break;
      case TmcOperationType.writeOff:
        payload['from_location_type'] =
            fromType ?? TmcLocationType.warehouse.dbValue;
        payload['from_warehouse_id'] = fromWarehouse ?? _warehouseId;
        payload['from_object_id'] = fromObject;
        payload['from_employee_id'] = fromEmployee;
        payload['from_location_note'] = fromNote;
        // без to_location — имущество списывается
        payload['write_off'] = {
          'reason': _writeOffReason.dbValue,
          'act_number': _writeOffActController.text.trim().isEmpty
              ? null
              : _writeOffActController.text.trim(),
        };
        break;
      default:
        break;
    }

    return payload;
  }

  Future<void> _submit() async {
    final error = _validate();
    if (error != null) {
      AppSnackBar.show(
        context: context,
        message: error,
        kind: AppSnackBarKind.error,
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final payload = _buildPayload();
      await ref.read(tmcRepositoryProvider).postOperation(payload);
      ref.invalidate(tmcItemsListProvider);
      ref.invalidate(tmcDashboardProvider);
      ref.invalidate(tmcOperationsProvider);
      final itemId = widget.presetItem?.id ?? widget.presetUnit?.itemId;
      if (itemId != null) {
        ref.invalidate(tmcItemProvider(itemId));
        ref.invalidate(tmcItemUnitsProvider(itemId));
        ref.invalidate(tmcItemOperationsProvider(itemId));
      }
      if (!mounted) return;
      Navigator.of(context).pop();
      AppSnackBar.show(
        context: context,
        message: 'Операция проведена',
        kind: AppSnackBarKind.success,
      );
    } catch (e) {
      if (!mounted) return;
      AppSnackBar.show(
        context: context,
        message: e.toString(),
        kind: AppSnackBarKind.error,
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final warehousesAsync = ref.watch(tmcWarehousesProvider);
    final conditionsAsync = ref.watch(tmcConditionsProvider);
    final objectState = ref.watch(objectProvider);
    final employeeState = ref.watch(emp_state.employeeProvider);
    final isDesktop = ResponsiveUtils.isDesktop(context);

    final title =
        '${TmcUiLabels.operation}: ${TmcUiLabels.operationType(widget.operationType)}';
    final itemName =
        widget.presetItem?.name ?? widget.presetUnit?.itemName ?? '';

    final form = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (itemName.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              itemName,
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ),
        if (widget.presetUnit != null) ...[
          Text(
            TmcUiLabels.unitLabel(
              widget.presetUnit!,
              includeStatus: false,
              includeLocation: false,
            ),
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
        ],
        if (_needsUnit && widget.presetUnit == null) ...[
          const SizedBox(height: 12),
          if (_unitsLoading)
            const LinearProgressIndicator()
          else
            GTDropdown<TmcUnit>(
              labelText: 'Конкретный инструмент (инв. / серийный №)',
              hintText: 'Выберите экземпляр',
              items: _units,
              selectedItem: _activeUnit,
              itemDisplayBuilder: TmcUiLabels.unitLabel,
              onSelectionChanged: (u) {
                setState(() {
                  _selectedUnitId = u?.id;
                  _applyUnitDefaults(u);
                });
              },
              allowClear: false,
            ),
        ],
        if (!_isIndividual ||
            widget.operationType == TmcOperationType.receipt) ...[
          const SizedBox(height: 12),
          GTTextField(
            controller: _quantityController,
            labelText: 'Количество',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (_) => setState(() {}),
          ),
          if (_isIndividual &&
              widget.operationType == TmcOperationType.receipt) ...[
            const SizedBox(height: 12),
            TmcSerialNumbersEditor(
              key: _serialNumbersKey,
              unitCount: TmcUiLabels.receiptUnitCount(_quantityController.text),
            ),
          ],
        ],
        const SizedBox(height: 12),
        GTTextField(
          controller: _documentController,
          labelText: 'Номер документа',
        ),
        const SizedBox(height: 12),
        _buildContextFields(
          warehousesAsync: warehousesAsync,
          conditionsAsync: conditionsAsync,
          objects: objectState.objects,
          employees: employeeState.employees,
        ),
        const SizedBox(height: 12),
        GTTextField(
          controller: _commentController,
          labelText: 'Комментарий',
          maxLines: 2,
        ),
      ],
    );

    final footer = Row(
      children: [
        Expanded(
          child: GTSecondaryButton(
            text: 'Отмена',
            onPressed: _saving ? null : () => Navigator.of(context).pop(),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: GTPrimaryButton(
            text: 'Провести',
            onPressed: _saving ? null : _submit,
            isLoading: _saving,
          ),
        ),
      ],
    );

    if (isDesktop) {
      return DesktopDialogContent(title: title, footer: footer, child: form);
    }
    return MobileBottomSheetContent(title: title, footer: footer, child: form);
  }

  Widget _buildContextFields({
    required AsyncValue<List<TmcWarehouse>> warehousesAsync,
    required AsyncValue<List<TmcCondition>> conditionsAsync,
    required List<ObjectEntity> objects,
    required List<Employee> employees,
  }) {
    final type = widget.operationType;

    if (type == TmcOperationType.sendToRepair) {
      return Column(
        children: [
          GTTextField(
            controller: _repairReasonController,
            labelText: 'Причина ремонта',
          ),
          const SizedBox(height: 12),
          GTTextField(
            controller: _repairOrgController,
            labelText: 'Организация ремонта',
          ),
        ],
      );
    }

    if (type == TmcOperationType.writeOff) {
      return Column(
        children: [
          GTEnumDropdown<TmcWriteOffReason>(
            labelText: 'Причина списания',
            hintText: 'Выберите причину',
            values: TmcWriteOffReason.values,
            selectedValue: _writeOffReason,
            enumToString: TmcUiLabels.writeOffReason,
            onChanged: (v) {
              if (v != null) setState(() => _writeOffReason = v);
            },
          ),
          const SizedBox(height: 12),
          GTTextField(
            controller: _writeOffActController,
            labelText: 'Номер акта',
          ),
          if (!_isIndividual) ...[
            const SizedBox(height: 12),
            warehousesAsync.when(
              data: (warehouses) {
                TmcWarehouse? selected;
                for (final w in warehouses) {
                  if (w.id == _warehouseId) selected = w;
                }
                return GTDropdown<TmcWarehouse>(
                  labelText: 'Склад (откуда)',
                  hintText: 'Выберите склад',
                  items: warehouses,
                  selectedItem: selected,
                  itemDisplayBuilder: (w) => w.name,
                  onSelectionChanged: (w) =>
                      setState(() => _warehouseId = w?.id),
                  allowClear: true,
                );
              },
              loading: () => const LinearProgressIndicator(),
              error: (e, _) => Text(e.toString()),
            ),
          ],
        ],
      );
    }

    final needsWarehouse =
        type == TmcOperationType.receipt ||
        type == TmcOperationType.issue ||
        type == TmcOperationType.returnFromEmployee ||
        type == TmcOperationType.transferToObject ||
        type == TmcOperationType.moveBetweenWarehouses;

    final needsEmployee =
        type == TmcOperationType.issue ||
        type == TmcOperationType.returnFromEmployee;

    final needsObject =
        type == TmcOperationType.transferToObject ||
        type == TmcOperationType.issue;

    final needsCondition = type == TmcOperationType.changeCondition;

    return Column(
      children: [
        if (needsWarehouse)
          warehousesAsync.when(
            data: (warehouses) {
              TmcWarehouse? selected;
              for (final w in warehouses) {
                if (w.id == _warehouseId) selected = w;
              }
              return GTDropdown<TmcWarehouse>(
                labelText: type == TmcOperationType.moveBetweenWarehouses
                    ? 'Склад (откуда)'
                    : 'Склад',
                hintText: 'Выберите склад',
                items: warehouses,
                selectedItem: selected,
                itemDisplayBuilder: (w) => w.name,
                onSelectionChanged: (w) => setState(() => _warehouseId = w?.id),
                allowClear: true,
              );
            },
            loading: () => const LinearProgressIndicator(),
            error: (e, _) => Text(e.toString()),
          ),
        if (type == TmcOperationType.moveBetweenWarehouses) ...[
          const SizedBox(height: 12),
          warehousesAsync.when(
            data: (warehouses) {
              TmcWarehouse? selected;
              for (final w in warehouses) {
                if (w.id == _toWarehouseId) selected = w;
              }
              return GTDropdown<TmcWarehouse>(
                labelText: 'Склад (куда)',
                hintText: 'Выберите склад',
                items: warehouses,
                selectedItem: selected,
                itemDisplayBuilder: (w) => w.name,
                onSelectionChanged: (w) =>
                    setState(() => _toWarehouseId = w?.id),
                allowClear: true,
              );
            },
            loading: () => const LinearProgressIndicator(),
            error: (e, _) => Text(e.toString()),
          ),
        ],
        if (needsEmployee) ...[
          const SizedBox(height: 12),
          _EmployeeDropdown(
            employees: employees,
            employeeId: _employeeId,
            onChanged: (id) => setState(() => _employeeId = id),
          ),
        ],
        if (needsObject) ...[
          const SizedBox(height: 12),
          _ObjectDropdown(
            objects: objects,
            objectId: _objectId,
            onChanged: (id) => setState(() => _objectId = id),
          ),
        ],
        if (needsCondition) ...[
          const SizedBox(height: 12),
          conditionsAsync.when(
            data: (conditions) {
              TmcCondition? selected;
              for (final c in conditions) {
                if (c.id == _conditionId) selected = c;
              }
              return GTDropdown<TmcCondition>(
                labelText: 'Состояние',
                hintText: 'Выберите состояние',
                items: conditions,
                selectedItem: selected,
                itemDisplayBuilder: (c) => c.name,
                onSelectionChanged: (c) => setState(() => _conditionId = c?.id),
                allowClear: true,
              );
            },
            loading: () => const LinearProgressIndicator(),
            error: (e, _) => Text(e.toString()),
          ),
        ],
      ],
    );
  }
}

class _EmployeeDropdown extends StatelessWidget {
  final List<Employee> employees;
  final String? employeeId;
  final ValueChanged<String?> onChanged;

  const _EmployeeDropdown({
    required this.employees,
    required this.employeeId,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    Employee? selected;
    for (final e in employees) {
      if (e.id == employeeId) selected = e;
    }
    return GTDropdown<Employee>(
      labelText: 'Сотрудник',
      hintText: 'Выберите сотрудника',
      items: employees,
      selectedItem: selected,
      itemDisplayBuilder: (e) => e.fullName,
      onSelectionChanged: (e) => onChanged(e?.id),
      allowClear: true,
    );
  }
}

class _ObjectDropdown extends StatelessWidget {
  final List<ObjectEntity> objects;
  final String? objectId;
  final ValueChanged<String?> onChanged;

  const _ObjectDropdown({
    required this.objects,
    required this.objectId,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    ObjectEntity? selected;
    for (final o in objects) {
      if (o.id == objectId) selected = o;
    }
    return GTDropdown<ObjectEntity>(
      labelText: 'Объект',
      hintText: 'Выберите объект',
      items: objects,
      selectedItem: selected,
      itemDisplayBuilder: (o) => o.name,
      onSelectionChanged: (o) => onChanged(o?.id),
      allowClear: true,
    );
  }
}
