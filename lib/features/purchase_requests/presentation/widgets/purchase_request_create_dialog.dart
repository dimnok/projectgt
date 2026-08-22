import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:projectgt/core/di/providers.dart';
import 'package:projectgt/core/utils/supabase_error_message.dart';
import 'package:projectgt/core/widgets/app_snackbar.dart';
import 'package:projectgt/core/widgets/desktop_dialog_content.dart';
import 'package:projectgt/core/widgets/gt_buttons.dart';
import 'package:projectgt/core/widgets/gt_dropdown.dart';
import 'package:projectgt/core/widgets/gt_text_field.dart';
import 'package:projectgt/core/widgets/mobile_bottom_sheet_content.dart';
import 'package:projectgt/features/employees/presentation/utils/employees_layout_utils.dart';
import 'package:projectgt/features/purchase_requests/domain/entities/purchase_request.dart';
import 'package:projectgt/features/purchase_requests/domain/entities/purchase_request_item.dart';
import 'package:projectgt/features/purchase_requests/domain/repositories/purchase_request_repository.dart';
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

/// Позиция в форме заявки (до сохранения в БД).
class _PendingPurchaseItem {
  _PendingPurchaseItem({
    required this.name,
    required this.quantity,
    required this.unit,
    this.id,
    this.article,
  });

  final String? id;
  final String name;
  final double quantity;
  final String unit;
  final String? article;
}

/// Контроллеры одной строки позиции в форме.
class _PurchaseItemRowControllers {
  _PurchaseItemRowControllers({this.itemId}) {
    unitController.text = 'шт';
    qtyController.text = '1';
  }

  factory _PurchaseItemRowControllers.fromItem(PurchaseRequestItem item) {
    final row = _PurchaseItemRowControllers(itemId: item.id);
    row.nameController.text = item.name;
    row.unitController.text = item.unit;
    row.qtyController.text = _quantityDraftText(item.quantity);
    row.articleController.text = item.article ?? '';
    return row;
  }

  final String? itemId;
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

    final qty = double.tryParse(qtyController.text.replaceAll(',', '.')) ?? 0;
    if (qty <= 0) return null;

    final unit = unitController.text.trim().isEmpty
        ? 'шт'
        : unitController.text.trim();
    final article = articleController.text.trim();

    return _PendingPurchaseItem(
      id: itemId,
      name: name,
      quantity: qty,
      unit: unit,
      article: article.isEmpty ? null : article,
    );
  }

  /// Шаг количества для кнопок «−» / «+». Минимум — 1.
  void adjustQuantity(double delta) {
    final current =
        double.tryParse(qtyController.text.replaceAll(',', '.')) ?? 0;
    final next = current + delta;
    final text = _quantityDraftText(next < 1 ? 1 : next);
    qtyController.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

String _quantityDraftText(double quantity) {
  if (quantity == quantity.roundToDouble()) {
    return quantity.round().toString();
  }
  return quantity.toString();
}

/// Диалог создания или редактирования черновика заявки.
class PurchaseRequestCreateDialog extends ConsumerStatefulWidget {
  /// Создаёт диалог.
  const PurchaseRequestCreateDialog({
    super.key,
    this.request,
    this.initialItems,
    this.isDesktopSurface = false,
  });

  /// Заявка для режима редактирования.
  final PurchaseRequest? request;

  /// Текущие позиции заявки (режим редактирования).
  final List<PurchaseRequestItem>? initialItems;

  /// `true` — центрированный desktop-диалог, `false` — лист снизу на телефоне.
  ///
  /// Задаётся в [show], чтобы вёрстка не зависела от [MediaQuery] внутри окна.
  final bool isDesktopSurface;

  /// Показать диалог. Возвращает id созданной или сохранённой заявки.
  static Future<String?> show(
    BuildContext context, {
    PurchaseRequest? request,
    List<PurchaseRequestItem>? initialItems,
  }) {
    final useDesktop = EmployeesLayoutUtils.useEmployeesDesktopModal(context);
    final dialog = PurchaseRequestCreateDialog(
      request: request,
      initialItems: initialItems,
      isDesktopSurface: useDesktop,
    );
    if (useDesktop) {
      return showDialog<String?>(
        context: context,
        builder: (_) => Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(24),
          child: dialog,
        ),
      );
    }

    final screenWidth = MediaQuery.sizeOf(context).width;
    return showModalBottomSheet<String?>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      enableDrag: true,
      constraints: BoxConstraints(maxWidth: screenWidth),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => dialog,
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

  bool get _isEdit => widget.request != null;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(objectProvider.notifier).loadObjects();
    });
    final request = widget.request;
    if (request == null) return;

    _objectId = request.objectId;
    _commentController.text = request.comment ?? '';
    final items = widget.initialItems ?? const <PurchaseRequestItem>[];
    if (items.isEmpty) return;

    for (final row in _itemRows) {
      row.dispose();
    }
    _itemRows
      ..clear()
      ..addAll(items.map(_PurchaseItemRowControllers.fromItem));
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
      final comment = _commentController.text.trim().isEmpty
          ? null
          : _commentController.text.trim();
      final id = _isEdit
          ? await _saveExisting(
              repo: repo,
              objectId: _objectId!,
              comment: comment,
              pendingItems: pendingItems,
            )
          : await _createNew(
              repo: repo,
              objectId: _objectId!,
              comment: comment,
              pendingItems: pendingItems,
            );

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

  Future<String> _createNew({
    required PurchaseRequestRepository repo,
    required String objectId,
    required String? comment,
    required List<_PendingPurchaseItem> pendingItems,
  }) async {
    final id = await repo.createDraft(objectId: objectId, comment: comment);
    for (final item in pendingItems) {
      await repo.addItem(
        requestId: id,
        name: item.name,
        quantity: item.quantity,
        unit: item.unit,
        article: item.article,
      );
    }
    return id;
  }

  Future<String> _saveExisting({
    required PurchaseRequestRepository repo,
    required String objectId,
    required String? comment,
    required List<_PendingPurchaseItem> pendingItems,
  }) async {
    final request = widget.request!;
    await repo.updateHeader(
      requestId: request.id,
      objectId: objectId,
      comment: comment,
    );

    final existingById = {
      for (final item in widget.initialItems ?? const <PurchaseRequestItem>[])
        item.id: item,
    };
    final keptIds = <String>{};

    for (final item in pendingItems) {
      final existingId = item.id;
      if (existingId != null && existingById.containsKey(existingId)) {
        keptIds.add(existingId);
        final original = existingById[existingId]!;
        await repo.updateItem(
          original.copyWith(
            name: item.name,
            quantity: item.quantity,
            unit: item.unit,
            article: item.article,
          ),
        );
      } else {
        await repo.addItem(
          requestId: request.id,
          name: item.name,
          quantity: item.quantity,
          unit: item.unit,
          article: item.article,
        );
      }
    }

    for (final existingId in existingById.keys) {
      if (!keptIds.contains(existingId)) {
        await repo.deleteItem(existingId);
      }
    }

    return request.id;
  }

  @override
  Widget build(BuildContext context) {
    final objectState = ref.watch(objectProvider);
    final objects = objectState.objects;
    final isDesktop = widget.isDesktopSurface;
    final theme = Theme.of(context);

    final objectField = GTDropdown<String>(
      labelText: 'Объект',
      hintText: 'Выберите объект',
      items: objects.map((o) => o.id).toList(),
      selectedItem: _objectId,
      itemDisplayBuilder: (id) {
        for (final obj in objects) {
          if (obj.id == id) return obj.name;
        }
        return id;
      },
      onSelectionChanged: (v) => setState(() => _objectId = v),
    );

    final submitButton = GTPrimaryButton(
      text: _isEdit ? 'Сохранить' : 'Создать заявку',
      isLoading: _submitting,
      onPressed: _submitting ? null : _submit,
    );

    final title = _isEdit ? 'Редактировать заявку' : 'Новая заявка';
    if (isDesktop) {
      return DesktopDialogContent(
        title: title,
        width: _kCreateDialogWidth,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            objectField,
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
            submitButton,
          ],
        ),
      );
    }

    return MobileBottomSheetContent(
      title: title,
      footer: submitButton,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          objectField,
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Что нужно закупить',
                  style: theme.textTheme.titleSmall,
                ),
              ),
              _MobileCircleIconButton(
                icon: Icons.add_rounded,
                tooltip: 'Добавить позицию',
                onPressed: _submitting ? null : _addItemRow,
              ),
            ],
          ),
          const SizedBox(height: 8),
          for (var i = 0; i < _itemRows.length; i++) ...[
            if (i > 0) ...[
              const SizedBox(height: 12),
              Divider(
                height: 1,
                thickness: 1,
                color: theme.colorScheme.outline.withValues(alpha: 0.12),
              ),
              const SizedBox(height: 16),
            ],
            _PurchaseItemMobileCard(
              index: i,
              controllers: _itemRows[i],
              canRemove: _itemRows.length > 1,
              onRemove: () => _removeItemRow(i),
              enabled: !_submitting,
            ),
          ],
          const SizedBox(height: 16),
          GTTextField(
            labelText: 'Комментарий',
            controller: _commentController,
            hintText: 'Необязательно',
            maxLines: 2,
            enabled: !_submitting,
          ),
        ],
      ),
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

/// Позиция на телефоне: те же поля, что на desktop, столбиком.
class _PurchaseItemMobileCard extends StatelessWidget {
  const _PurchaseItemMobileCard({
    required this.index,
    required this.controllers,
    required this.canRemove,
    required this.onRemove,
    required this.enabled,
  });

  final int index;
  final _PurchaseItemRowControllers controllers;
  final bool canRemove;
  final VoidCallback onRemove;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Semantics(
      container: true,
      label: 'Позиция ${index + 1}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (canRemove) ...[
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Позиция ${index + 1}',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(
                        alpha: 0.45,
                      ),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                _MobileCircleIconButton(
                  icon: Icons.delete_outline_rounded,
                  tooltip: 'Удалить позицию',
                  color: theme.colorScheme.error,
                  onPressed: enabled ? onRemove : null,
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
          GTTextField(
            controller: controllers.nameController,
            labelText: 'Наименование',
            enabled: enabled,
            textCapitalization: TextCapitalization.sentences,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    _MobileCircleIconButton(
                      icon: Icons.remove_rounded,
                      tooltip: 'Меньше',
                      borderRadius: 16,
                      onPressed: enabled
                          ? () => _stepQuantity(controllers, -1)
                          : null,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: GTTextField(
                        controller: controllers.qtyController,
                        labelText: 'Кол-во',
                        enabled: enabled,
                        textAlign: TextAlign.center,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                        ],
                        textInputAction: TextInputAction.next,
                      ),
                    ),
                    const SizedBox(width: 8),
                    _MobileCircleIconButton(
                      icon: Icons.add_rounded,
                      tooltip: 'Больше',
                      borderRadius: 16,
                      onPressed: enabled
                          ? () => _stepQuantity(controllers, 1)
                          : null,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GTTextField(
                  controller: controllers.unitController,
                  labelText: 'Ед. изм.',
                  enabled: enabled,
                  textAlign: TextAlign.center,
                  textInputAction: TextInputAction.next,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          GTTextField(
            controller: controllers.articleController,
            labelText: 'Артикул',
            hintText: 'Необязательно',
            enabled: enabled,
            textInputAction: TextInputAction.next,
          ),
        ],
      ),
    );
  }
}

void _stepQuantity(_PurchaseItemRowControllers controllers, double delta) {
  HapticFeedback.selectionClick();
  controllers.adjustQuantity(delta);
}

/// Кнопка 44×44 для телефона: круг (добавить / удалить) или квадрат со
/// скруглением как у [GTTextField] (шаг количества).
class _MobileCircleIconButton extends StatelessWidget {
  const _MobileCircleIconButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.color,
    this.borderRadius,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final Color? color;

  /// Если задан — квадрат с этим радиусом; иначе круг.
  final double? borderRadius;

  static const _size = 44.0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final enabled = onPressed != null;
    final fg = (color ?? theme.colorScheme.onSurface).withValues(
      alpha: enabled ? 1 : 0.32,
    );
    final border = theme.colorScheme.outline.withValues(
      alpha: theme.brightness == Brightness.dark ? 0.15 : 0.3,
    );
    final radius = borderRadius;
    final shape = radius == null
        ? const CircleBorder()
        : RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius));

    return Semantics(
      button: true,
      enabled: enabled,
      label: tooltip,
      child: Tooltip(
        message: tooltip,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onPressed,
            customBorder: shape,
            child: Ink(
              width: _size,
              height: _size,
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                shape: radius == null ? BoxShape.circle : BoxShape.rectangle,
                borderRadius: radius == null
                    ? null
                    : BorderRadius.circular(radius),
                border: Border.all(color: border, width: 1.2),
              ),
              child: Icon(icon, size: 22, color: fg),
            ),
          ),
        ),
      ),
    );
  }
}
