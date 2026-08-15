import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:projectgt/core/di/providers.dart';
import 'package:projectgt/core/utils/formatters.dart';
import 'package:projectgt/core/utils/responsive_utils.dart';
import 'package:projectgt/core/utils/supabase_error_message.dart';
import 'package:projectgt/core/widgets/app_snackbar.dart';
import 'package:projectgt/core/widgets/desktop_dialog_content.dart';
import 'package:projectgt/core/widgets/gt_buttons.dart';
import 'package:projectgt/core/widgets/gt_dropdown.dart';
import 'package:projectgt/core/widgets/gt_text_field.dart';
import 'package:projectgt/core/widgets/mobile_bottom_sheet_content.dart';
import 'package:projectgt/features/purchase_requests/presentation/state/purchase_request_providers.dart';

/// Позиция в форме создания заявки (до сохранения в БД).
class _PendingPurchaseItem {
  _PendingPurchaseItem({
    required this.name,
    required this.quantity,
    required this.unit,
  });

  final String name;
  final double quantity;
  final String unit;
}

/// Диалог создания новой заявки (черновик).
class PurchaseRequestCreateDialog extends ConsumerStatefulWidget {
  /// Создаёт диалог.
  const PurchaseRequestCreateDialog({super.key});

  /// Показать диалог. Возвращает id созданной заявки.
  static Future<String?> show(BuildContext context) {
    final isDesktop = ResponsiveUtils.isDesktop(context);
    if (isDesktop) {
      return showDialog<String?>(
        context: context,
        builder: (_) => Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(24),
          child: const PurchaseRequestCreateDialog(),
        ),
      );
    }
    return showModalBottomSheet<String?>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const PurchaseRequestCreateDialog(),
    );
  }

  @override
  ConsumerState<PurchaseRequestCreateDialog> createState() =>
      _PurchaseRequestCreateDialogState();
}

class _PurchaseRequestCreateDialogState
    extends ConsumerState<PurchaseRequestCreateDialog> {
  String? _objectId;
  final _commentController = TextEditingController();
  final _itemNameController = TextEditingController();
  final _itemQtyController = TextEditingController(text: '1');
  final _itemUnitController = TextEditingController(text: 'шт');
  final List<_PendingPurchaseItem> _pendingItems = [];
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    ref.read(objectProvider.notifier).loadObjects();
  }

  @override
  void dispose() {
    _commentController.dispose();
    _itemNameController.dispose();
    _itemQtyController.dispose();
    _itemUnitController.dispose();
    super.dispose();
  }

  void _addPendingItem() {
    final name = _itemNameController.text.trim();
    final qty =
        double.tryParse(_itemQtyController.text.replaceAll(',', '.')) ?? 0;
    final unit = _itemUnitController.text.trim().isEmpty
        ? 'шт'
        : _itemUnitController.text.trim();

    if (name.isEmpty) {
      AppSnackBar.show(
        context: context,
        message: 'Укажите наименование',
        kind: AppSnackBarKind.error,
      );
      return;
    }
    if (qty <= 0) {
      AppSnackBar.show(
        context: context,
        message: 'Укажите количество',
        kind: AppSnackBarKind.error,
      );
      return;
    }

    setState(() {
      _pendingItems.add(
        _PendingPurchaseItem(name: name, quantity: qty, unit: unit),
      );
      _itemNameController.clear();
      _itemQtyController.text = '1';
      _itemUnitController.text = 'шт';
    });
  }

  void _removePendingItem(int index) {
    setState(() => _pendingItems.removeAt(index));
  }

  Future<void> _submit() async {
    if (_objectId == null) {
      AppSnackBar.show(
        context: context,
        message: 'Выберите объект',
        kind: AppSnackBarKind.error,
      );
      return;
    }
    if (_pendingItems.isEmpty) {
      AppSnackBar.show(
        context: context,
        message: 'Добавьте хотя бы одну позицию',
        kind: AppSnackBarKind.error,
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      final repo = ref.read(purchaseRequestRepositoryProvider);
      final id = await repo.createDraft(
        objectId: _objectId!,
        comment: _commentController.text.trim().isEmpty
            ? null
            : _commentController.text.trim(),
      );

      for (final item in _pendingItems) {
        await repo.addItem(
          requestId: id,
          name: item.name,
          quantity: item.quantity,
          unit: item.unit,
        );
      }

      if (!mounted) return;
      Navigator.of(context).pop(id);
    } catch (e) {
      if (!mounted) return;
      AppSnackBar.show(
        context: context,
        message: formatSupabaseErrorMessage(e),
        kind: AppSnackBarKind.error,
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final objectState = ref.watch(objectProvider);
    final objects = objectState.objects;
    final isDesktop = ResponsiveUtils.isDesktop(context);
    final theme = Theme.of(context);

    final content = SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GTDropdown<String>(
            labelText: 'Объект',
            hintText: 'Выберите объект',
            items: objects.map((o) => o.id).toList(),
            selectedItem: _objectId,
            itemDisplayBuilder: (id) {
              final obj = objects.firstWhere((o) => o.id == id);
              return obj.name;
            },
            onSelectionChanged: (v) => setState(() => _objectId = v),
          ),
          const SizedBox(height: 16),
          Text('Что нужно закупить', style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          GTTextField(
            labelText: 'Наименование',
            controller: _itemNameController,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: GTTextField(
                  labelText: 'Количество',
                  controller: _itemQtyController,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: GTTextField(
                  labelText: 'Ед. изм.',
                  controller: _itemUnitController,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          GTSecondaryButton(
            text: '+ Добавить в список',
            onPressed: _submitting ? null : _addPendingItem,
          ),
          if (_pendingItems.isNotEmpty) ...[
            const SizedBox(height: 12),
            for (var i = 0; i < _pendingItems.length; i++)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(_pendingItems[i].name),
                subtitle: Text(
                  '${formatQuantity(_pendingItems[i].quantity)} '
                  '${_pendingItems[i].unit}',
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: _submitting ? null : () => _removePendingItem(i),
                ),
              ),
          ],
          const SizedBox(height: 12),
          GTTextField(
            labelText: 'Комментарий',
            controller: _commentController,
            maxLines: 2,
          ),
          const SizedBox(height: 20),
          GTPrimaryButton(
            text: 'Создать заявку',
            isLoading: _submitting,
            onPressed: _submitting ? null : _submit,
          ),
        ],
      ),
    );

    if (isDesktop) {
      return DesktopDialogContent(
        title: 'Новая заявка',
        child: content,
      );
    }
    return MobileBottomSheetContent(
      title: 'Новая заявка',
      child: content,
    );
  }
}
