import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:projectgt/core/utils/formatters.dart';
import 'package:projectgt/core/utils/responsive_utils.dart';
import 'package:projectgt/core/widgets/app_snackbar.dart';
import 'package:projectgt/core/widgets/desktop_dialog_content.dart';
import 'package:projectgt/core/widgets/gt_buttons.dart';
import 'package:projectgt/core/widgets/gt_text_field.dart';
import 'package:projectgt/core/widgets/mobile_bottom_sheet_content.dart';
import 'package:projectgt/features/tmc/domain/entities/tmc_unit.dart';
import 'package:projectgt/features/tmc/presentation/state/tmc_providers.dart';

/// Диалог редактирования единицы ТМЦ (серийный номер, инвентарный номер, штрихкод и т.д.).
class TmcUnitFormDialog extends ConsumerStatefulWidget {
  /// Единица для редактирования.
  final TmcUnit unit;

  /// Создаёт диалог.
  const TmcUnitFormDialog({super.key, required this.unit});

  /// Показать диалог.
  static Future<void> show(BuildContext context, {required TmcUnit unit}) {
    final isDesktop = ResponsiveUtils.isDesktop(context);
    if (isDesktop) {
      return showDialog<void>(
        context: context,
        builder: (_) => Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(24),
          child: TmcUnitFormDialog(unit: unit),
        ),
      );
    }
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => TmcUnitFormDialog(unit: unit),
    );
  }

  @override
  ConsumerState<TmcUnitFormDialog> createState() => _TmcUnitFormDialogState();
}

class _TmcUnitFormDialogState extends ConsumerState<TmcUnitFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _inventoryNumberController;
  late final TextEditingController _serialNumberController;
  late final TextEditingController _barcodeController;
  late final TextEditingController _commentController;
  DateTime? _warrantyUntil;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final unit = widget.unit;
    _inventoryNumberController = TextEditingController(
      text: unit.inventoryNumber,
    );
    _serialNumberController = TextEditingController(
      text: unit.serialNumber ?? '',
    );
    _barcodeController = TextEditingController(text: unit.barcode ?? '');
    _commentController = TextEditingController(text: unit.comment ?? '');
    _warrantyUntil = unit.warrantyUntil;
  }

  @override
  void dispose() {
    _inventoryNumberController.dispose();
    _serialNumberController.dispose();
    _barcodeController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    final repo = ref.read(tmcRepositoryProvider);

    try {
      final updated = widget.unit.copyWith(
        inventoryNumber: _inventoryNumberController.text.trim(),
        serialNumber: _serialNumberController.text.trim().isEmpty
            ? null
            : _serialNumberController.text.trim(),
        barcode: _barcodeController.text.trim().isEmpty
            ? null
            : _barcodeController.text.trim(),
        warrantyUntil: _warrantyUntil,
        comment: _commentController.text.trim().isEmpty
            ? null
            : _commentController.text.trim(),
      );

      await repo.updateUnit(updated);

      ref.invalidate(tmcItemUnitsProvider(widget.unit.itemId));
      ref.invalidate(tmcItemProvider(widget.unit.itemId));
      ref.read(tmcItemsListProvider.notifier).load();

      if (!mounted) return;
      Navigator.of(context).pop();
      AppSnackBar.show(
        context: context,
        message: 'Данные единицы обновлены',
        kind: AppSnackBarKind.success,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      AppSnackBar.show(
        context: context,
        message: 'Не удалось сохранить: $e',
        kind: AppSnackBarKind.error,
      );
    }
  }

  Future<void> _pickWarrantyDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _warrantyUntil ?? now.add(const Duration(days: 365)),
      firstDate: DateTime(2000),
      lastDate: DateTime(2040),
    );
    if (picked != null) {
      setState(() => _warrantyUntil = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveUtils.isDesktop(context);
    final theme = Theme.of(context);

    final title = 'Редактирование экземпляра: ${widget.unit.inventoryNumber}';

    final form = Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.unit.itemName != null) ...[
            Text(
              widget.unit.itemName!,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
          ],
          GTTextField(
            controller: _inventoryNumberController,
            labelText: 'Инвентарный номер *',
            validator: (v) => v == null || v.trim().isEmpty
                ? 'Укажите инвентарный номер'
                : null,
          ),
          const SizedBox(height: 12),
          GTTextField(
            controller: _serialNumberController,
            labelText: 'Серийный номер (S/N с шильдика инструмента)',
            hintText: 'Например: 98452109',
          ),
          const SizedBox(height: 12),
          GTTextField(
            controller: _barcodeController,
            labelText: 'Штрихкод / QR-код',
            hintText: 'Опционально',
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: GTTextField(
                  readOnly: true,
                  onTap: _pickWarrantyDate,
                  labelText: 'Гарантия до',
                  hintText: _warrantyUntil != null
                      ? formatRuDate(_warrantyUntil!)
                      : 'Не указана',
                  suffixIcon: const Icon(
                    Icons.calendar_today_outlined,
                    size: 16,
                  ),
                ),
              ),
              if (_warrantyUntil != null) ...[
                const SizedBox(width: 8),
                IconButton(
                  tooltip: 'Очистить дату',
                  icon: const Icon(Icons.clear, size: 18),
                  onPressed: () => setState(() => _warrantyUntil = null),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          GTTextField(
            controller: _commentController,
            labelText: 'Комментарий / примечание',
            maxLines: 2,
          ),
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
      return DesktopDialogContent(title: title, footer: footer, child: form);
    }
    return MobileBottomSheetContent(title: title, footer: footer, child: form);
  }
}
