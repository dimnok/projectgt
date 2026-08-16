import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:projectgt/core/widgets/app_snackbar.dart';
import 'package:projectgt/core/widgets/gt_buttons.dart';
import 'package:projectgt/core/widgets/gt_text_field.dart';
import 'package:projectgt/features/purchase_requests/domain/entities/purchase_request.dart';
import 'package:projectgt/features/purchase_requests/domain/entities/purchase_request_status.dart';
import 'package:projectgt/core/utils/supabase_error_message.dart';
import 'package:projectgt/features/purchase_requests/presentation/utils/purchase_request_form_dialog.dart';
import 'package:projectgt/features/purchase_requests/presentation/utils/purchase_request_invoice_utils.dart';
import 'package:projectgt/features/purchase_requests/presentation/utils/purchase_request_ui_labels.dart';
import 'package:projectgt/features/purchase_requests/presentation/state/purchase_request_providers.dart';
import 'package:projectgt/features/roles/application/permission_service.dart';

/// Доступные действия по заявке для текущего пользователя.
class PurchaseRequestActionSet {
  /// Создаёт набор действий.
  const PurchaseRequestActionSet({
    this.canSubmit = false,
    this.canApprove = false,
    this.canReturn = false,
    this.canSubmitInvoices = false,
    this.canApproveInvoice = false,
    this.canReturnInvoice = false,
    this.canQueuePayment = false,
    this.canMarkPaid = false,
    this.canMarkReceived = false,
    this.canCancel = false,
    this.canEditItems = false,
    this.canEditDraft = false,
    this.canDeleteDraft = false,
  });

  /// Можно отправить заявку.
  final bool canSubmit;

  /// Можно согласовать заявку.
  final bool canApprove;

  /// Можно вернуть на доработку.
  final bool canReturn;

  /// Можно отправить счета на согласование.
  final bool canSubmitInvoices;

  /// Можно согласовать счёт.
  final bool canApproveInvoice;

  /// Можно вернуть счёт на доработку.
  final bool canReturnInvoice;

  /// Можно завести на оплату.
  final bool canQueuePayment;

  /// Можно отметить оплату.
  final bool canMarkPaid;

  /// Можно отметить получение материала.
  final bool canMarkReceived;

  /// Можно отменить заявку.
  final bool canCancel;

  /// Можно редактировать позиции.
  final bool canEditItems;

  /// Можно править свою заявку целиком (шапка и позиции), только черновик.
  final bool canEditDraft;

  /// Можно удалить свою заявку, только черновик.
  final bool canDeleteDraft;

  /// Есть ли хотя бы одно действие в панели.
  bool get hasAny =>
      canSubmit ||
      canApprove ||
      canReturn ||
      canSubmitInvoices ||
      canApproveInvoice ||
      canReturnInvoice ||
      canQueuePayment ||
      canMarkPaid ||
      canMarkReceived ||
      canCancel;
}

/// Вычисляет доступные действия.
PurchaseRequestActionSet resolvePurchaseRequestActions({
  required PurchaseRequest request,
  required String? currentUserId,
  required PermissionService permissions,
}) {
  final uid = currentUserId;
  if (uid == null) return const PurchaseRequestActionSet();

  final isCreator = request.createdBy == uid;
  final isAssignee = request.currentAssigneeId == uid;
  final status = request.status;
  final canMutateDraft =
      isCreator &&
      permissions.can('purchase_requests', 'create') &&
      (status == PurchaseRequestStatus.draft ||
          status == PurchaseRequestStatus.revision);
  final canOwnDraft =
      isCreator &&
      permissions.can('purchase_requests', 'create') &&
      status == PurchaseRequestStatus.draft;

  return PurchaseRequestActionSet(
    canEditItems: canMutateDraft,
    canEditDraft: canOwnDraft,
    canDeleteDraft: canOwnDraft,
    canSubmit: canMutateDraft,
    canApprove:
        isAssignee &&
        permissions.can('purchase_requests', 'approve') &&
        status == PurchaseRequestStatus.approval,
    canReturn:
        isAssignee &&
        permissions.can('purchase_requests', 'approve') &&
        status == PurchaseRequestStatus.approval,
    canSubmitInvoices:
        isAssignee &&
        permissions.can('purchase_requests', 'prepare_invoice') &&
        status == PurchaseRequestStatus.invoicePreparation,
    canApproveInvoice:
        isAssignee &&
        permissions.can('purchase_requests', 'approve_invoice') &&
        status == PurchaseRequestStatus.invoiceApproval,
    canReturnInvoice:
        isAssignee &&
        permissions.can('purchase_requests', 'approve_invoice') &&
        status == PurchaseRequestStatus.invoiceApproval,
    canQueuePayment:
        isAssignee &&
        permissions.can('purchase_requests', 'payment') &&
        status == PurchaseRequestStatus.accounting,
    canMarkPaid:
        isAssignee &&
        permissions.can('purchase_requests', 'payment') &&
        status == PurchaseRequestStatus.paymentQueue,
    canMarkReceived:
        isAssignee &&
        permissions.can('purchase_requests', 'receive') &&
        status == PurchaseRequestStatus.paid,
    canCancel:
        (isCreator || permissions.can('purchase_requests', 'view_all')) &&
        status != PurchaseRequestStatus.received &&
        status != PurchaseRequestStatus.cancelled,
  );
}

/// Панель действий в карточке заявки.
class PurchaseRequestActionsBar extends ConsumerStatefulWidget {
  /// Создаёт панель.
  const PurchaseRequestActionsBar({
    super.key,
    required this.requestId,
    required this.request,
    required this.actions,
  });

  /// Идентификатор заявки.
  final String requestId;

  /// Данные заявки.
  final PurchaseRequest request;

  /// Набор доступных действий.
  final PurchaseRequestActionSet actions;

  @override
  ConsumerState<PurchaseRequestActionsBar> createState() =>
      _PurchaseRequestActionsBarState();
}

class _PurchaseRequestActionsBarState
    extends ConsumerState<PurchaseRequestActionsBar> {
  bool _busy = false;

  Future<void> _run(Future<void> action) async {
    if (!mounted) return;
    setState(() => _busy = true);
    try {
      await action;
      invalidatePurchaseRequestCaches(ref, widget.requestId);
    } catch (e) {
      if (mounted) {
        AppSnackBar.show(
          context: context,
          message: formatSupabaseErrorMessage(e),
          kind: AppSnackBarKind.error,
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<String?> _promptComment({
    required String title,
    bool required = false,
  }) async {
    final controller = TextEditingController();
    try {
      final result = await showPurchaseRequestFormDialog<String>(
        context: context,
        title: title,
        bodyBuilder: (_) => GTTextField(
          controller: controller,
          labelText: 'Комментарий',
          maxLines: 4,
        ),
        footerBuilder: (dialogContext) => Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            GTTextButton(
              text: 'Отмена',
              onPressed: () => Navigator.pop(dialogContext),
            ),
            const SizedBox(width: 8),
            GTPrimaryButton(
              text: 'OK',
              onPressed: () =>
                  Navigator.pop(dialogContext, controller.text.trim()),
            ),
          ],
        ),
      );
      if (required && (result == null || result.isEmpty)) return null;
      return result;
    } finally {
      controller.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    final repo = ref.read(purchaseRequestRepositoryProvider);
    final a = widget.actions;
    final itemsAsync = ref.watch(
      purchaseRequestItemsProvider(widget.requestId),
    );
    final invoicesAsync = ref.watch(
      purchaseRequestInvoicesProvider(widget.requestId),
    );
    final itemsReady = itemsAsync.hasValue;
    final invoicesReady = invoicesAsync.hasValue;
    final itemsCount = itemsAsync.valueOrNull?.length ?? 0;
    final invoices = invoicesAsync.valueOrNull ?? const [];
    final canSubmitNow = a.canSubmit && itemsReady && itemsCount > 0;
    final canSubmitInvoicesNow =
        a.canSubmitInvoices &&
        invoicesReady &&
        purchaseRequestInvoicesReadyForSubmit(invoices);

    if (!a.hasAny) {
      return Text(
        PurchaseRequestUiLabels.idleActionsMessage(widget.request.status),
        style: Theme.of(context).textTheme.bodyMedium,
      );
    }

    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (a.canSubmit && itemsReady && itemsCount == 0)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  size: 16,
                  color: theme.colorScheme.error,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Добавьте хотя бы одну позицию перед отправкой',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.error,
                    ),
                  ),
                ),
              ],
            ),
          ),
        if (a.canSubmitInvoices &&
            invoicesReady &&
            !purchaseRequestInvoicesReadyForSubmit(invoices))
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  size: 16,
                  color: theme.colorScheme.error,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    invoices.isEmpty
                        ? 'Добавьте счёт с файлом в секции «Счета»'
                        : 'Для каждого счёта нужен прикреплённый файл',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.error,
                    ),
                  ),
                ),
              ],
            ),
          ),
        Align(
          alignment: Alignment.centerRight,
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.end,
            children: [
              if (a.canSubmit)
                GTPrimaryButton(
                  text: widget.request.status == PurchaseRequestStatus.revision
                      ? 'Отправить повторно'
                      : 'Отправить',
                  isLoading: _busy,
                  onPressed: !canSubmitNow || _busy
                      ? null
                      : () => _run(repo.submit(widget.requestId)),
                ),
              if (a.canApprove)
                GTPrimaryButton(
                  text: 'Согласовать',
                  isLoading: _busy,
                  onPressed: _busy
                      ? null
                      : () => _run(repo.approve(widget.requestId)),
                ),
              if (a.canReturn)
                GTSecondaryButton(
                  text: 'Вернуть',
                  onPressed: _busy
                      ? null
                      : () async {
                          final c = await _promptComment(
                            title: 'Причина возврата',
                            required: true,
                          );
                          if (!mounted || c == null || c.isEmpty) return;
                          await _run(
                            repo.returnForRevision(
                              widget.requestId,
                              comment: c,
                            ),
                          );
                        },
                ),
              if (a.canSubmitInvoices)
                GTPrimaryButton(
                  text: 'Отправить на согласование',
                  isLoading: _busy,
                  onPressed: !canSubmitInvoicesNow || _busy
                      ? null
                      : () => _run(repo.submitInvoices(widget.requestId)),
                ),
              if (a.canApproveInvoice)
                GTPrimaryButton(
                  text: 'Согласовать счет',
                  isLoading: _busy,
                  onPressed: _busy
                      ? null
                      : () => _run(repo.approveInvoice(widget.requestId)),
                ),
              if (a.canReturnInvoice)
                GTSecondaryButton(
                  text: 'Вернуть счет',
                  onPressed: _busy
                      ? null
                      : () async {
                          final c = await _promptComment(
                            title: 'Причина возврата счета',
                            required: true,
                          );
                          if (!mounted || c == null || c.isEmpty) return;
                          await _run(
                            repo.returnInvoice(widget.requestId, comment: c),
                          );
                        },
                ),
              if (a.canQueuePayment)
                GTPrimaryButton(
                  text: 'Заведено на оплату',
                  isLoading: _busy,
                  onPressed: _busy
                      ? null
                      : () => _run(repo.queuePayment(widget.requestId)),
                ),
              if (a.canMarkPaid)
                GTPrimaryButton(
                  text: 'Оплачено',
                  isLoading: _busy,
                  onPressed: _busy
                      ? null
                      : () => _run(repo.markPaid(widget.requestId)),
                ),
              if (a.canMarkReceived)
                GTPrimaryButton(
                  text: 'Материал получен',
                  isLoading: _busy,
                  onPressed: _busy
                      ? null
                      : () => _run(repo.markReceived(widget.requestId)),
                ),
              if (a.canCancel)
                GTSecondaryButton(
                  text: 'Отменить',
                  onPressed: _busy
                      ? null
                      : () async {
                          final c = await _promptComment(
                            title: 'Причина отмены',
                            required: true,
                          );
                          if (!mounted || c == null || c.isEmpty) return;
                          await _run(repo.cancel(widget.requestId, comment: c));
                        },
                ),
            ],
          ),
        ),
      ],
    );
  }
}
