import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:projectgt/core/utils/responsive_utils.dart';
import 'package:projectgt/core/widgets/app_snackbar.dart';
import 'package:projectgt/core/widgets/desktop_dialog_content.dart';
import 'package:projectgt/core/widgets/gt_buttons.dart';
import 'package:projectgt/core/widgets/gt_dropdown.dart';
import 'package:projectgt/core/widgets/gt_text_field.dart';
import 'package:projectgt/core/widgets/mobile_bottom_sheet_content.dart';
import 'package:projectgt/features/company/presentation/providers/company_providers.dart';
import 'package:projectgt/features/tmc/domain/entities/tmc_category.dart';
import 'package:projectgt/features/tmc/domain/entities/tmc_enums.dart';
import 'package:projectgt/features/tmc/domain/entities/tmc_item.dart';
import 'package:projectgt/features/tmc/domain/entities/tmc_warehouse.dart';
import 'package:projectgt/features/tmc/presentation/state/tmc_providers.dart';
import 'package:projectgt/features/tmc/presentation/utils/tmc_ui_labels.dart';

/// Диалог создания / редактирования позиции каталога ТМЦ.
class TmcItemFormDialog extends ConsumerStatefulWidget {
  /// Существующая позиция.
  final TmcItem? item;

  /// Создаёт диалог.
  const TmcItemFormDialog({super.key, this.item});

  /// Показать диалог.
  static Future<void> show(BuildContext context, {TmcItem? item}) {
    final isDesktop = ResponsiveUtils.isDesktop(context);
    if (isDesktop) {
      return showDialog<void>(
        context: context,
        builder: (_) => Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(24),
          child: TmcItemFormDialog(item: item),
        ),
      );
    }
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => TmcItemFormDialog(item: item),
    );
  }

  @override
  ConsumerState<TmcItemFormDialog> createState() => _TmcItemFormDialogState();
}

class _TmcItemFormDialogState extends ConsumerState<TmcItemFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _skuController;
  late final TextEditingController _unitOfMeasureController;
  late final TextEditingController _unitPriceController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _quantityController;

  TmcAccountingType _accountingType = TmcAccountingType.individual;
  String? _categoryId;
  bool _saving = false;
  bool _receiveOnCreate = false;
  String? _warehouseId;

  @override
  void initState() {
    super.initState();
    final item = widget.item;
    _nameController = TextEditingController(text: item?.name ?? '');
    _skuController = TextEditingController(text: item?.sku ?? '');
    _unitOfMeasureController = TextEditingController(
      text: item?.unitOfMeasure ?? 'шт',
    );
    _unitPriceController = TextEditingController(
      text: item != null ? item.unitPrice.toString() : '0',
    );
    _descriptionController = TextEditingController(text: item?.description ?? '');
    _quantityController = TextEditingController(text: '1');
    _accountingType = item?.accountingType ?? TmcAccountingType.individual;
    _categoryId = item?.categoryId;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _skuController.dispose();
    _unitOfMeasureController.dispose();
    _unitPriceController.dispose();
    _descriptionController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    final companyId = ref.read(activeCompanyIdProvider) ?? '';
    final repo = ref.read(tmcRepositoryProvider);

    final unitPrice =
        double.tryParse(_unitPriceController.text.replaceAll(',', '.')) ?? 0;

    final isCreate = widget.item == null;
    final shouldReceive = isCreate &&
        _receiveOnCreate &&
        double.tryParse(_quantityController.text.replaceAll(',', '.')) != null &&
        (double.tryParse(_quantityController.text.replaceAll(',', '.')) ?? 0) > 0 &&
        _warehouseId != null &&
        _warehouseId!.isNotEmpty;

    try {
      if (isCreate) {
        final baseItem = TmcItem(
          id: '',
          companyId: companyId,
          name: _nameController.text.trim(),
          categoryId: _categoryId,
          accountingType: _accountingType,
          sku: _skuController.text.trim().isEmpty
              ? null
              : _skuController.text.trim(),
          unitOfMeasure: _unitOfMeasureController.text.trim(),
          unitPrice: unitPrice,
          quantity: 0,
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
        );

        if (shouldReceive) {
          final qty = double.tryParse(
                  _quantityController.text.replaceAll(',', '.')) ??
              1;
          await repo.createItemWithReceipt(
            item: baseItem,
            receiveQuantity: qty,
            warehouseId: _warehouseId,
            unitPrice: unitPrice,
          );
        } else {
          await repo.createItem(baseItem);
        }
      } else {
        await repo.updateItem(
          widget.item!.copyWith(
            name: _nameController.text.trim(),
            categoryId: _categoryId,
            accountingType: _accountingType,
            sku: _skuController.text.trim().isEmpty
                ? null
                : _skuController.text.trim(),
            unitOfMeasure: _unitOfMeasureController.text.trim(),
            unitPrice: unitPrice,
            description: _descriptionController.text.trim().isEmpty
                ? null
                : _descriptionController.text.trim(),
          ),
        );
      }

      ref.invalidate(tmcItemsListProvider);
      ref.invalidate(tmcDashboardProvider);
      if (shouldReceive) {
        ref.invalidate(tmcOperationsProvider);
      }
      if (!mounted) return;
      Navigator.of(context).pop();
      AppSnackBar.show(
        context: context,
        message: shouldReceive ? 'Позиция создана и принята на склад' : 'Сохранено',
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
    final categoriesAsync = ref.watch(tmcCategoriesProvider);
    final warehousesAsync = ref.watch(tmcWarehousesProvider);
    final isDesktop = ResponsiveUtils.isDesktop(context);
    final isCreate = widget.item == null;
    final title = isCreate ? TmcUiLabels.newItem : TmcUiLabels.editItem;

    // Автовыбор основного склада при первой загрузке
    warehousesAsync.whenData((warehouses) {
      if (_warehouseId == null && _receiveOnCreate) {
        final main =
            warehouses.where((w) => w.isMain && !w.isArchived).firstOrNull;
        if (main != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(() => _warehouseId = main.id);
          });
        }
      }
    });

    final form = Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GTTextField(
            controller: _nameController,
            labelText: 'Наименование',
            validator: (v) =>
                v == null || v.trim().isEmpty ? 'Укажите наименование' : null,
          ),
          const SizedBox(height: 12),
          categoriesAsync.when(
            data: (categories) {
              TmcCategory? selected;
              for (final c in categories) {
                if (c.id == _categoryId) selected = c;
              }
              return GTDropdown<TmcCategory>(
                labelText: 'Категория',
                hintText: 'Выберите категорию',
                items: categories,
                selectedItem: selected,
                itemDisplayBuilder: (c) => c.name,
                onSelectionChanged: (c) =>
                    setState(() => _categoryId = c?.id),
                allowClear: true,
              );
            },
            loading: () => const LinearProgressIndicator(),
            error: (e, _) => Text(e.toString()),
          ),
          const SizedBox(height: 12),
          GTEnumDropdown<TmcAccountingType>(
            labelText: 'Тип учёта',
            hintText: 'Выберите тип',
            values: TmcAccountingType.values,
            selectedValue: _accountingType,
            enumToString: TmcUiLabels.accountingType,
            onChanged: (v) {
              if (v != null) setState(() => _accountingType = v);
            },
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: GTTextField(
                  controller: _skuController,
                  labelText: 'Артикул',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GTTextField(
                  controller: _unitOfMeasureController,
                  labelText: 'Ед. изм.',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          GTTextField(
            controller: _unitPriceController,
            labelText: 'Цена за единицу',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
          if (widget.item != null) ...[
            const SizedBox(height: 8),
            Text(
              'Количество меняется только через операции (поступление, выдача и т.д.). '
              'Сейчас: ${widget.item!.quantity}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
          const SizedBox(height: 12),
          GTTextField(
            controller: _descriptionController,
            labelText: 'Описание',
            maxLines: 3,
          ),
          if (isCreate) ...[
            const SizedBox(height: 16),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              title: const Text('Принять на склад'),
              subtitle: const Text(
                'Сразу провести поступление на основной склад',
                style: TextStyle(fontSize: 12),
              ),
              value: _receiveOnCreate,
              onChanged: (v) => setState(() {
                _receiveOnCreate = v;
                if (!v) _warehouseId = null;
              }),
            ),
            if (_receiveOnCreate) ...[
              const SizedBox(height: 8),
              warehousesAsync.when(
                data: (warehouses) {
                  final active =
                      warehouses.where((w) => !w.isArchived).toList();
                  TmcWarehouse? selected;
                  for (final w in active) {
                    if (w.id == _warehouseId) selected = w;
                  }
                  return GTDropdown<TmcWarehouse>(
                    labelText: 'Склад',
                    hintText: 'Выберите склад',
                    items: active,
                    selectedItem: selected,
                    itemDisplayBuilder: (w) =>
                        w.isMain ? '${w.name} (основной)' : w.name,
                    onSelectionChanged: (w) =>
                        setState(() => _warehouseId = w?.id),
                    allowClear: false,
                  );
                },
                loading: () => const LinearProgressIndicator(),
                error: (e, _) => Text(e.toString()),
              ),
              const SizedBox(height: 12),
              GTTextField(
                controller: _quantityController,
                labelText: 'Количество',
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                validator: (v) {
                  if (!_receiveOnCreate) return null;
                  final n = double.tryParse(
                      (v ?? '').replaceAll(',', '.'));
                  if (n == null || n <= 0) return 'Укажите количество больше 0';
                  return null;
                },
              ),
            ],
          ],
        ],
      ),
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
            text: 'Сохранить',
            onPressed: _saving ? null : _save,
            isLoading: _saving,
          ),
        ),
      ],
    );

    if (isDesktop) {
      return DesktopDialogContent(
        title: title,
        footer: footer,
        child: form,
      );
    }

    return MobileBottomSheetContent(
      title: title,
      footer: footer,
      child: form,
    );
  }
}
