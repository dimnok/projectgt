import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:projectgt/core/di/providers.dart';
import 'package:projectgt/core/utils/supabase_error_message.dart';
import 'package:projectgt/core/widgets/app_snackbar.dart';
import 'package:projectgt/core/widgets/gt_buttons.dart';
import 'package:projectgt/core/widgets/gt_confirmation_dialog.dart';
import 'package:projectgt/core/widgets/gt_text_field.dart';
import 'package:projectgt/features/purchase_requests/domain/entities/purchase_request.dart';
import 'package:projectgt/features/purchase_requests/domain/entities/purchase_request_item.dart';
import 'package:projectgt/features/purchase_requests/domain/entities/purchase_request_settings.dart';
import 'package:projectgt/features/purchase_requests/presentation/state/purchase_request_providers.dart';
import 'package:projectgt/features/purchase_requests/presentation/utils/purchase_request_form_dialog.dart';
import 'package:projectgt/features/purchase_requests/presentation/utils/purchase_request_items_excel_export.dart';
import 'package:projectgt/features/purchase_requests/presentation/utils/purchase_request_module_utils.dart';
import 'package:projectgt/features/purchase_requests/presentation/utils/purchase_request_ui_labels.dart';
import 'package:projectgt/features/purchase_requests/presentation/widgets/purchase_request_actions_bar.dart';
import 'package:projectgt/features/purchase_requests/presentation/widgets/purchase_request_create_dialog.dart';
import 'package:projectgt/features/purchase_requests/presentation/widgets/purchase_request_details_summary.dart';
import 'package:projectgt/features/purchase_requests/presentation/widgets/purchase_request_details_tokens.dart';
import 'package:projectgt/features/purchase_requests/presentation/widgets/purchase_request_history_timeline.dart';
import 'package:projectgt/features/purchase_requests/presentation/widgets/purchase_request_invoices_section.dart';
import 'package:projectgt/features/purchase_requests/presentation/widgets/purchase_request_items_table.dart';
import 'package:projectgt/features/roles/application/permission_service.dart';

/// Панель деталей заявки на закупку (встраивается в текущий экран).
class PurchaseRequestDetailsPanel extends ConsumerWidget {
  /// Создаёт панель.
  const PurchaseRequestDetailsPanel({
    super.key,
    required this.requestId,
    this.onClose,
    this.onDeleted,
    this.showCloseButton = false,
  });

  /// Идентификатор заявки.
  final String requestId;

  /// Закрыть панель и вернуться к списку.
  final VoidCallback? onClose;

  /// Закрыть панель после удаления черновика.
  final VoidCallback? onDeleted;

  /// Показать кнопку «назад» в шапке панели.
  final bool showCloseButton;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requestAsync = ref.watch(purchaseRequestDetailsProvider(requestId));
    final itemsAsync = ref.watch(purchaseRequestItemsProvider(requestId));
    final historyAsync = ref.watch(purchaseRequestHistoryProvider(requestId));
    final permissions = ref.watch(permissionServiceProvider);
    final uid = ref.watch(supabaseClientProvider).auth.currentUser?.id;
    final settings = ref.watch(purchaseRequestSettingsProvider).valueOrNull;
    final theme = Theme.of(context);

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: ColoredBox(
        color: PurchaseRequestDetailsTokens.pageBackground(theme),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(
              context,
              ref,
              theme,
              requestAsync,
              itemsAsync,
              uid,
              permissions,
              settings,
            ),
            Expanded(
              child: requestAsync.when(
                loading: () =>
                    const Center(child: CupertinoActivityIndicator()),
                error: (e, _) => Center(child: Text('$e')),
                data: (request) {
                  if (request == null) {
                    return const Center(child: Text('Заявка не найдена'));
                  }

                  final actions = resolvePurchaseRequestActions(
                    request: request,
                    currentUserId: uid,
                    permissions: permissions,
                    settings: settings,
                  );
                  final statusColor = PurchaseRequestUiLabels.statusColor(
                    theme,
                    request.status,
                  );

                  final reworkNote = latestPurchaseRequestReworkComment(
                    historyAsync.valueOrNull ?? const [],
                  );

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: ListView(
                          padding: const EdgeInsets.fromLTRB(
                            PurchaseRequestDetailsTokens.pagePadding,
                            16,
                            PurchaseRequestDetailsTokens.pagePadding,
                            16,
                          ),
                          children: [
                            itemsAsync.maybeWhen(
                              data: (items) => PurchaseRequestDetailsSummary(
                                request: request,
                                statusColor: statusColor,
                                itemsCount: items.length,
                                reworkNote: reworkNote,
                              ),
                              orElse: () => PurchaseRequestDetailsSummary(
                                request: request,
                                statusColor: statusColor,
                                reworkNote: reworkNote,
                              ),
                            ),
                            const SizedBox(
                              height: PurchaseRequestDetailsTokens.sectionGap,
                            ),
                            _DetailSection(
                              title: 'Позиции',
                              trailing: _ItemsSectionTrailing(
                                requestNumber: request.number,
                                items: itemsAsync.valueOrNull ?? const [],
                                canEdit: actions.canEditItems,
                                onAdd: () => _addItem(context, ref),
                              ),
                              child: itemsAsync.when(
                                loading: () => const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 32),
                                  child: Center(
                                    child: CupertinoActivityIndicator(),
                                  ),
                                ),
                                error: (e, _) => _SectionMessage(text: '$e'),
                                data: (items) {
                                  if (items.isEmpty) {
                                    return _SectionMessage(
                                      icon: Icons.inventory_2_outlined,
                                      text: actions.canEditItems
                                          ? 'Добавьте позиции — что нужно закупить'
                                          : 'Нет позиций',
                                    );
                                  }

                                  return PurchaseRequestItemsTable(
                                    items: items,
                                    canEdit: actions.canEditItems,
                                    onDelete: actions.canEditItems
                                        ? (itemId) async {
                                            try {
                                              await ref
                                                  .read(
                                                    purchaseRequestRepositoryProvider,
                                                  )
                                                  .deleteItem(itemId);
                                              invalidatePurchaseRequestCaches(
                                                ref,
                                                requestId,
                                              );
                                            } catch (e) {
                                              if (!context.mounted) return;
                                              AppSnackBar.show(
                                                context: context,
                                                message:
                                                    formatSupabaseErrorMessage(
                                                      e,
                                                    ),
                                                kind: AppSnackBarKind.error,
                                              );
                                            }
                                          }
                                        : null,
                                  );
                                },
                              ),
                            ),
                            if (PurchaseRequestInvoicesSection.shouldShow(
                              request.status,
                            )) ...[
                              const SizedBox(
                                height: PurchaseRequestDetailsTokens.sectionGap,
                              ),
                              PurchaseRequestInvoicesSection(
                                requestId: requestId,
                                canManage: actions.canSubmitInvoices,
                              ),
                            ],
                            const SizedBox(
                              height: PurchaseRequestDetailsTokens.sectionGap,
                            ),
                            _DetailSection(
                              title: 'История',
                              child: historyAsync.when(
                                loading: () => const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 32),
                                  child: Center(
                                    child: CupertinoActivityIndicator(),
                                  ),
                                ),
                                error: (e, _) => _SectionMessage(text: '$e'),
                                data: (entries) =>
                                    PurchaseRequestHistoryTimeline(
                                      entries: entries,
                                    ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      _ActionsFooter(
                        child: PurchaseRequestActionsBar(
                          requestId: requestId,
                          request: request,
                          actions: actions,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    WidgetRef ref,
    ThemeData theme,
    AsyncValue<PurchaseRequest?> requestAsync,
    AsyncValue<List<PurchaseRequestItem>> itemsAsync,
    String? uid,
    PermissionService permissions,
    PurchaseRequestSettings? settings,
  ) {
    final hasBack = showCloseButton && onClose != null;

    return DecoratedBox(
      decoration: PurchaseRequestDetailsTokens.headerDecoration(theme),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          hasBack ? 4 : PurchaseRequestDetailsTokens.pagePadding,
          10,
          PurchaseRequestDetailsTokens.pagePadding,
          14,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (hasBack)
              IconButton(
                tooltip: 'К списку',
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: onClose,
              ),
            Expanded(
              child: requestAsync.when(
                loading: () => _HeaderContent(number: 'Заявка', theme: theme),
                error: (_, __) =>
                    _HeaderContent(number: 'Заявка', theme: theme),
                data: (request) {
                  if (request == null) {
                    return _HeaderContent(number: 'Заявка', theme: theme);
                  }

                  return _HeaderContent(
                    number: request.number,
                    objectName: request.objectName,
                    initiator: request.initiatorLabel,
                    theme: theme,
                  );
                },
              ),
            ),
            requestAsync.maybeWhen(
              data: (request) {
                if (request == null) return const SizedBox.shrink();
                final actions = resolvePurchaseRequestActions(
                  request: request,
                  currentUserId: uid,
                  permissions: permissions,
                  settings: settings,
                );
                if (!actions.canEditDraft && !actions.canDeleteDraft) {
                  return const SizedBox.shrink();
                }
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (actions.canEditDraft)
                      IconButton(
                        tooltip: 'Редактировать',
                        icon: const Icon(Icons.edit_outlined),
                        onPressed: () => _editDraft(
                          context,
                          ref,
                          request,
                          itemsAsync.valueOrNull ?? const [],
                        ),
                      ),
                    if (actions.canDeleteDraft)
                      IconButton(
                        tooltip: 'Удалить',
                        icon: const Icon(Icons.delete_outline_rounded),
                        onPressed: () => _deleteDraft(context, ref, request),
                      ),
                  ],
                );
              },
              orElse: () => const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _editDraft(
    BuildContext context,
    WidgetRef ref,
    PurchaseRequest request,
    List<PurchaseRequestItem> items,
  ) async {
    final id = await PurchaseRequestCreateDialog.show(
      context,
      request: request,
      initialItems: items,
    );
    if (id == null || !context.mounted) return;
    invalidatePurchaseRequestCaches(ref, requestId);
  }

  Future<void> _deleteDraft(
    BuildContext context,
    WidgetRef ref,
    PurchaseRequest request,
  ) async {
    final confirmed = await GTConfirmationDialog.show(
      context: context,
      title: 'Удалить заявку',
      message: 'Черновик будет удалён без возможности восстановления.',
      emphasisText: request.number,
      confirmText: 'Удалить',
      cancelText: 'Отмена',
      type: GTConfirmationType.danger,
    );
    if (confirmed != true || !context.mounted) return;

    try {
      await ref.read(purchaseRequestRepositoryProvider).deleteDraft(request.id);
      invalidatePurchaseRequestCaches(ref, requestId);
      onDeleted?.call();
    } catch (e) {
      if (!context.mounted) return;
      AppSnackBar.show(
        context: context,
        message: formatSupabaseErrorMessage(e),
        kind: AppSnackBarKind.error,
      );
    }
  }

  Future<void> _addItem(BuildContext context, WidgetRef ref) async {
    final nameController = TextEditingController();
    final qtyController = TextEditingController(text: '1');
    final unitController = TextEditingController(text: 'шт');
    final articleController = TextEditingController();

    try {
      final confirmed = await showPurchaseRequestFormDialog<bool>(
        context: context,
        title: 'Позиция',
        bodyBuilder: (_) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            GTTextField(controller: nameController, labelText: 'Наименование'),
            const SizedBox(height: 12),
            GTTextField(controller: qtyController, labelText: 'Количество'),
            const SizedBox(height: 12),
            GTTextField(controller: unitController, labelText: 'Ед. изм.'),
            const SizedBox(height: 12),
            GTTextField(controller: articleController, labelText: 'Артикул'),
          ],
        ),
        footerBuilder: (dialogContext) => Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            GTTextButton(
              text: 'Отмена',
              onPressed: () => Navigator.pop(dialogContext, false),
            ),
            const SizedBox(width: 8),
            GTPrimaryButton(
              text: 'Добавить',
              onPressed: () => Navigator.pop(dialogContext, true),
            ),
          ],
        ),
      );

      if (confirmed != true || !context.mounted) return;

      final name = nameController.text.trim();
      final qty = double.tryParse(qtyController.text.replaceAll(',', '.')) ?? 0;
      if (name.isEmpty || qty <= 0) return;

      final unit = unitController.text.trim().isEmpty
          ? 'шт'
          : unitController.text.trim();
      final article = articleController.text.trim();

      await ref
          .read(purchaseRequestRepositoryProvider)
          .addItem(
            requestId: requestId,
            name: name,
            quantity: qty,
            unit: unit,
            article: article.isEmpty ? null : article,
          );
      invalidatePurchaseRequestCaches(ref, requestId);
    } catch (e) {
      if (context.mounted) {
        AppSnackBar.show(
          context: context,
          message: formatSupabaseErrorMessage(e),
          kind: AppSnackBarKind.error,
        );
      }
    } finally {
      nameController.dispose();
      qtyController.dispose();
      unitController.dispose();
      articleController.dispose();
    }
  }
}

class _HeaderContent extends StatelessWidget {
  const _HeaderContent({
    required this.number,
    required this.theme,
    this.objectName,
    this.initiator,
  });

  final String number;
  final ThemeData theme;
  final String? objectName;
  final String? initiator;

  @override
  Widget build(BuildContext context) {
    final muted = PurchaseRequestDetailsTokens.mutedText(theme);
    final meta = <String>[
      if ((objectName ?? '').trim().isNotEmpty) objectName!.trim(),
      if ((initiator ?? '').trim().isNotEmpty) initiator!.trim(),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          number,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
            height: 1.1,
          ),
        ),
        if (meta.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(
            meta.join(' · '),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              color: muted,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }
}

/// Кнопки секции позиций: Excel (если есть строки) и «Добавить».
class _ItemsSectionTrailing extends StatelessWidget {
  const _ItemsSectionTrailing({
    required this.requestNumber,
    required this.items,
    required this.canEdit,
    required this.onAdd,
  });

  final String requestNumber;
  final List<PurchaseRequestItem> items;
  final bool canEdit;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final showExcel = items.isNotEmpty;
    if (!showExcel && !canEdit) return const SizedBox.shrink();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showExcel)
          _ItemsExcelButton(requestNumber: requestNumber, items: items),
        if (showExcel && canEdit) const SizedBox(width: 4),
        if (canEdit)
          GTTextButton(
            text: 'Добавить',
            icon: Icons.add_rounded,
            dense: true,
            onPressed: onAdd,
          ),
      ],
    );
  }
}

/// Кнопка выгрузки позиций заявки в Excel на устройство пользователя.
class _ItemsExcelButton extends StatefulWidget {
  const _ItemsExcelButton({
    required this.requestNumber,
    required this.items,
  });

  final String requestNumber;
  final List<PurchaseRequestItem> items;

  @override
  State<_ItemsExcelButton> createState() => _ItemsExcelButtonState();
}

class _ItemsExcelButtonState extends State<_ItemsExcelButton> {
  bool _busy = false;

  Future<void> _export() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await exportPurchaseRequestItemsToDevice(
        context: context,
        requestNumber: widget.requestNumber,
        items: widget.items,
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Скачать позиции в Excel',
      child: GTTextButton(
        text: 'Excel',
        icon: Icons.download_outlined,
        dense: true,
        onPressed: _busy ? null : () => unawaited(_export()),
      ),
    );
  }
}

class _DetailSection extends StatelessWidget {
  const _DetailSection({
    required this.title,
    required this.child,
    this.trailing,
  });

  final String title;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = PurchaseRequestDetailsTokens.mutedText(theme);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text(
              title.toUpperCase(),
              style: theme.textTheme.labelMedium?.copyWith(
                color: muted,
                fontWeight: FontWeight.w700,
                letterSpacing: 1,
              ),
            ),
            const Spacer(),
            if (trailing != null) trailing!,
          ],
        ),
        const SizedBox(height: PurchaseRequestDetailsTokens.sectionTitleGap),
        child,
      ],
    );
  }
}

class _ActionsFooter extends StatelessWidget {
  const _ActionsFooter({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DecoratedBox(
      decoration: PurchaseRequestDetailsTokens.footerDecoration(theme),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            PurchaseRequestDetailsTokens.pagePadding,
            12,
            PurchaseRequestDetailsTokens.pagePadding,
            12,
          ),
          child: child,
        ),
      ),
    );
  }
}

class _SectionMessage extends StatelessWidget {
  const _SectionMessage({required this.text, this.icon});

  final String text;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = PurchaseRequestDetailsTokens.mutedText(theme);

    return DecoratedBox(
      decoration: PurchaseRequestDetailsTokens.cardDecoration(theme),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
        child: Column(
          children: [
            if (icon != null) ...[
              Icon(icon, size: 28, color: muted),
              const SizedBox(height: 10),
            ],
            Text(
              text,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(color: muted),
            ),
          ],
        ),
      ),
    );
  }
}
