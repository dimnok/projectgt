import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:projectgt/core/widgets/app_snackbar.dart';
import 'package:projectgt/core/widgets/gt_buttons.dart';
import 'package:projectgt/core/widgets/gt_text_field.dart';
import 'package:projectgt/features/purchase_requests/domain/entities/purchase_request.dart';
import 'package:projectgt/features/purchase_requests/domain/entities/purchase_request_status.dart';
import 'package:projectgt/core/utils/supabase_error_message.dart';
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
  });

  final bool canSubmit;
  final bool canApprove;
  final bool canReturn;
  final bool canSubmitInvoices;
  final bool canApproveInvoice;
  final bool canReturnInvoice;
  final bool canQueuePayment;
  final bool canMarkPaid;
  final bool canMarkReceived;
  final bool canCancel;
  final bool canEditItems;
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

  return PurchaseRequestActionSet(
    canEditItems: isCreator &&
        (status == PurchaseRequestStatus.draft ||
            status == PurchaseRequestStatus.revision),
    canSubmit: isCreator &&
        permissions.can('purchase_requests', 'create') &&
        (status == PurchaseRequestStatus.draft ||
            status == PurchaseRequestStatus.revision),
    canApprove: isAssignee &&
        permissions.can('purchase_requests', 'approve') &&
        status == PurchaseRequestStatus.approval,
    canReturn: isAssignee &&
        permissions.can('purchase_requests', 'approve') &&
        status == PurchaseRequestStatus.approval,
    canSubmitInvoices: isAssignee &&
        permissions.can('purchase_requests', 'prepare_invoice') &&
        status == PurchaseRequestStatus.invoicePreparation,
    canApproveInvoice: isAssignee &&
        permissions.can('purchase_requests', 'approve_invoice') &&
        status == PurchaseRequestStatus.invoiceApproval,
    canReturnInvoice: isAssignee &&
        permissions.can('purchase_requests', 'approve_invoice') &&
        status == PurchaseRequestStatus.invoiceApproval,
    canQueuePayment: isAssignee &&
        permissions.can('purchase_requests', 'payment') &&
        status == PurchaseRequestStatus.accounting,
    canMarkPaid: isAssignee &&
        permissions.can('purchase_requests', 'payment') &&
        status == PurchaseRequestStatus.paymentQueue,
    canMarkReceived: isAssignee &&
        permissions.can('purchase_requests', 'receive') &&
        status == PurchaseRequestStatus.paid,
    canCancel: (isCreator ||
            permissions.can('purchase_requests', 'view_all')) &&
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

  final String requestId;
  final PurchaseRequest request;
  final PurchaseRequestActionSet actions;

  @override
  ConsumerState<PurchaseRequestActionsBar> createState() =>
      _PurchaseRequestActionsBarState();
}

class _PurchaseRequestActionsBarState
    extends ConsumerState<PurchaseRequestActionsBar> {
  bool _busy = false;

  Future<void> _run(Future<void> action) async {
    setState(() => _busy = true);
    try {
      await action;
      ref.invalidate(purchaseRequestDetailsProvider(widget.requestId));
      ref.invalidate(purchaseRequestHistoryProvider(widget.requestId));
      ref.invalidate(purchaseRequestItemsProvider(widget.requestId));
      ref.invalidate(purchaseRequestListProvider);
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
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: GTTextField(
          controller: controller,
          labelText: 'Комментарий',
          maxLines: 4,
        ),
        actions: [
          GTTextButton(text: 'Отмена', onPressed: () => Navigator.pop(ctx)),
          GTPrimaryButton(
            text: 'OK',
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
          ),
        ],
      ),
    );
    if (required && (result == null || result.isEmpty)) return null;
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final repo = ref.read(purchaseRequestRepositoryProvider);
    final a = widget.actions;
    final itemsAsync = ref.watch(purchaseRequestItemsProvider(widget.requestId));
    final itemsCount = itemsAsync.valueOrNull?.length ?? 0;
    final canSubmitNow = a.canSubmit && itemsCount > 0;

    if (!a.canSubmit &&
        !a.canApprove &&
        !a.canReturn &&
        !a.canSubmitInvoices &&
        !a.canApproveInvoice &&
        !a.canReturnInvoice &&
        !a.canQueuePayment &&
        !a.canMarkPaid &&
        !a.canMarkReceived &&
        !a.canCancel) {
      return Text(
        'Ожидает действия ответственного',
        style: Theme.of(context).textTheme.bodyMedium,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (a.canSubmit && itemsCount == 0)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              'Добавьте хотя бы одну позицию перед отправкой',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.error,
                  ),
            ),
          ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
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
                    if (c == null || c.isEmpty) return;
                    await _run(
                      repo.returnForRevision(widget.requestId, comment: c),
                    );
                  },
          ),
        if (a.canSubmitInvoices)
          GTPrimaryButton(
            text: 'Отправить на согласование',
            isLoading: _busy,
            onPressed: _busy
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
                    if (c == null || c.isEmpty) return;
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
                    if (c == null || c.isEmpty) return;
                    await _run(repo.cancel(widget.requestId, comment: c));
                  },
          ),
      ],
        ),
      ],
    );
  }
}
