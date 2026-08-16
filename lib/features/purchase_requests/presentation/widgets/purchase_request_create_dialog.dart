import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:projectgt/core/di/providers.dart';
import 'package:projectgt/core/utils/responsive_utils.dart';
import 'package:projectgt/core/utils/supabase_error_message.dart';
import 'package:projectgt/core/widgets/app_snackbar.dart';
import 'package:projectgt/core/widgets/desktop_dialog_content.dart';
import 'package:projectgt/core/widgets/gt_buttons.dart';
import 'package:projectgt/core/widgets/gt_dropdown.dart';
import 'package:projectgt/core/widgets/gt_text_field.dart';
import 'package:projectgt/core/widgets/mobile_bottom_sheet_content.dart';
import 'package:projectgt/features/purchase_requests/presentation/state/purchase_request_providers.dart';

/// Ширина десктопного окна создания заявки.
const _kCreateDialogWidth = 980.0;

/// Компактные поля в строках позиций.
const _kItemFieldPadding = EdgeInsets.symmetric(horizontal: 12, vertical: 10);
const _kItemFieldRadius = 10.0;
const _kItemFieldStyle = TextStyle(fontSize: 14);

/// Фиксированные ширины узких колонок (наименование — всё остальное).
const _kUnitColWidth = 80.0;
const _kQtyColWidth = 96.0;
const _kArticleColWidth = 128.0;
const _kRowActionWidth = 36.0;
const _kColGap = 10.0;

/// Позиция в форме создания заявки (до сохранения в БД).
class _PendingPurchaseItem {
  _PendingPurchaseItem({
    required this.name,
    required this.quantity,
    required this.unit,
    this.article,
  });

  final String name;
  final double quantity;
  final String unit;
  final String? article;
}

/// Контроллеры одной строки позиции в форме.
class _PurchaseItemRowControllers {
  _PurchaseItemRowControllers() {
    unitController.text = 'шт';
    qtyController.text = '1';
  }

  final nameController = TextEditingController();
  final unitController = TextEditingController();
  final qtyController = TextEditingController();
  final articleController = TextEditingController();

  void dispose() {
    nameController.dispose();
    unitController.dispose();
    qtyController.dispose();
    articleController.dispose();
  }

  _PendingPurchaseItem? toPending() {
    final name = nameController.text.trim();
    if (name.isEmpty) return null;

    final qty =
        double.tryParse(qtyController.text.replaceAll(',', '.')) ?? 0;
    if (qty <= 0) return null;

    final unit = unitController.text.trim().isEmpty
        ? 'шт'
        : unitController.text.trim();
    final article = articleController.text.trim();

    return _PendingPurchaseItem(
      name: name,
      quantity: qty,
      unit: unit,
      article: article.isEmpty ? null : article,
    );
  }
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
        builder: (_) => const Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.all(24),
          child: PurchaseRequestCreateDialog(),
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
  final List<_PurchaseItemRowControllers> _itemRows = [
    _PurchaseItemRowControllers(),
  ];
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    ref.read(objectProvider.notifier).loadObjects();
  }

  @override
  void dispose() {
    _commentController.dispose();
    for (final row in _itemRows) {
      row.dispose();
    }
    super.dispose();
  }

  void _addItemRow() {
    setState(() => _itemRows.add(_PurchaseItemRowControllers()));
  }

  void _removeItemRow(int index) {
    if (_itemRows.length <= 1) return;
    setState(() {
      _itemRows[index].dispose();
      _itemRows.removeAt(index);
    });
  }

  List<_PendingPurchaseItem> _collectPendingItems() {
    final items = <_PendingPurchaseItem>[];
    for (final row in _itemRows) {
      final item = row.toPending();
      if (item != null) items.add(item);
    }
    return items;
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

    final pendingItems = _collectPendingItems();
    if (pendingItems.isEmpty) {
      AppSnackBar.show(
        context: context,
        message: 'Добавьте хотя бы одну позицию с наименованием',
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

      for (final item in pendingItems) {
        await repo.addItem(
          requestId: id,
          name: item.name,
          quantity: item.quantity,
          unit: item.unit,
          article: item.article,
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

    final content = Column(
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
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: Text(
                'Что нужно закупить',
                style: theme.textTheme.titleSmall,
              ),
            ),
            IconButton(
              tooltip: 'Добавить строку',
              onPressed: _submitting ? null : _addItemRow,
              icon: const Icon(Icons.add_circle_outline),
            ),
          ],
        ),
        const SizedBox(height: 4),
        _PurchaseItemsTableHeader(theme: theme),
        const SizedBox(height: 6),
        for (var i = 0; i < _itemRows.length; i++) ...[
          _PurchaseItemInputRow(
            controllers: _itemRows[i],
            canRemove: _itemRows.length > 1,
            onRemove: () => _removeItemRow(i),
            enabled: !_submitting,
          ),
          if (i < _itemRows.length - 1) const SizedBox(height: 6),
        ],
        const SizedBox(height: 16),
        GTTextField(
          labelText: 'Комментарий',
          controller: _commentController,
          maxLines: 2,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 12,
          ),
        ),
        const SizedBox(height: 20),
        GTPrimaryButton(
          text: 'Создать заявку',
          isLoading: _submitting,
          onPressed: _submitting ? null : _submit,
        ),
      ],
    );

    if (isDesktop) {
      return DesktopDialogContent(
        title: 'Новая заявка',
        width: _kCreateDialogWidth,
        child: content,
      );
    }
    return MobileBottomSheetContent(
      title: 'Новая заявка',
      child: SingleChildScrollView(child: content),
    );
  }
}

/// Общая разметка колонок строки позиции.
class _PurchaseItemRowLayout extends StatelessWidget {
  const _PurchaseItemRowLayout({
    required this.name,
    required this.unit,
    required this.qty,
    required this.article,
    required this.action,
  });

  final Widget name;
  final Widget unit;
  final Widget qty;
  final Widget article;
  final Widget action;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(child: name),
        const SizedBox(width: _kColGap),
        SizedBox(width: _kUnitColWidth, child: unit),
        const SizedBox(width: _kColGap),
        SizedBox(width: _kQtyColWidth, child: qty),
        const SizedBox(width: _kColGap),
        SizedBox(width: _kArticleColWidth, child: article),
        const SizedBox(width: _kColGap),
        SizedBox(width: _kRowActionWidth, child: action),
      ],
    );
  }
}

/// Компактное поле строки позиции.
class _ItemRowField extends StatelessWidget {
  const _ItemRowField({
    required this.controller,
    required this.hintText,
    this.enabled = true,
    this.keyboardType,
    this.inputFormatters,
    this.textAlign = TextAlign.start,
  });

  final TextEditingController controller;
  final String hintText;
  final bool enabled;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final TextAlign textAlign;

  @override
  Widget build(BuildContext context) {
    return GTTextField(
      controller: controller,
      hintText: hintText,
      enabled: enabled,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      textAlign: textAlign,
      borderRadius: _kItemFieldRadius,
      contentPadding: _kItemFieldPadding,
      style: _kItemFieldStyle,
    );
  }
}

/// Заголовки колонок позиций.
class _PurchaseItemsTableHeader extends StatelessWidget {
  const _PurchaseItemsTableHeader({required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return _PurchaseItemRowLayout(
      name: _headerCell('Наименование'),
      unit: _headerCell('Ед. изм.'),
      qty: _headerCell('Кол-во'),
      article: _headerCell('Артикул'),
      action: const SizedBox.shrink(),
    );
  }

  Widget _headerCell(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 2, bottom: 2),
      child: Text(
        text,
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// Одна строка ввода позиции.
class _PurchaseItemInputRow extends StatelessWidget {
  const _PurchaseItemInputRow({
    required this.controllers,
    required this.canRemove,
    required this.onRemove,
    required this.enabled,
  });

  final _PurchaseItemRowControllers controllers;
  final bool canRemove;
  final VoidCallback onRemove;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return _PurchaseItemRowLayout(
      name: _ItemRowField(
        controller: controllers.nameController,
        hintText: 'Наименование',
        enabled: enabled,
      ),
      unit: _ItemRowField(
        controller: controllers.unitController,
        hintText: 'шт',
        enabled: enabled,
        textAlign: TextAlign.center,
      ),
      qty: _ItemRowField(
        controller: controllers.qtyController,
        hintText: '1',
        enabled: enabled,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
        ],
        textAlign: TextAlign.center,
      ),
      article: _ItemRowField(
        controller: controllers.articleController,
        hintText: 'Артикул',
        enabled: enabled,
      ),
      action: canRemove
          ? IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints.tightFor(width: 32, height: 32),
              tooltip: 'Удалить строку',
              onPressed: enabled ? onRemove : null,
              icon: Icon(
                Icons.remove_circle_outline,
                size: 20,
                color: theme.colorScheme.error,
              ),
            )
          : const SizedBox.shrink(),
    );
  }
}
