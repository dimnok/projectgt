import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:projectgt/core/utils/formatters.dart';
import 'package:projectgt/core/utils/supabase_error_message.dart';
import 'package:projectgt/core/widgets/app_snackbar.dart';
import 'package:projectgt/core/widgets/gt_buttons.dart';
import 'package:projectgt/features/purchase_requests/domain/entities/purchase_request_invoice.dart';
import 'package:projectgt/features/purchase_requests/domain/entities/purchase_request_status.dart';
import 'package:projectgt/features/purchase_requests/presentation/state/purchase_request_providers.dart';
import 'package:projectgt/features/purchase_requests/presentation/utils/purchase_request_invoice_file_flow.dart';
import 'package:projectgt/features/purchase_requests/presentation/utils/purchase_request_invoice_utils.dart';
import 'package:projectgt/features/purchase_requests/presentation/widgets/purchase_request_details_tokens.dart';
import 'package:projectgt/features/purchase_requests/presentation/widgets/purchase_request_invoice_dialog.dart';

/// Секция счетов в панели деталей заявки.
class PurchaseRequestInvoicesSection extends ConsumerWidget {
  /// Создаёт секцию.
  const PurchaseRequestInvoicesSection({
    super.key,
    required this.requestId,
    required this.canManage,
  });

  /// Заявка.
  final String requestId;

  /// Можно добавлять и удалять счета.
  final bool canManage;

  /// Показывать секцию для статуса.
  static bool shouldShow(PurchaseRequestStatus status) {
    return switch (status) {
      PurchaseRequestStatus.invoicePreparation ||
      PurchaseRequestStatus.invoiceApproval ||
      PurchaseRequestStatus.accounting ||
      PurchaseRequestStatus.paymentQueue ||
      PurchaseRequestStatus.paid ||
      PurchaseRequestStatus.received =>
        true,
      _ => false,
    };
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final invoicesAsync = ref.watch(purchaseRequestInvoicesProvider(requestId));
    final theme = Theme.of(context);
    final muted = PurchaseRequestDetailsTokens.mutedText(theme);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text(
              'СЧЕТА',
              style: theme.textTheme.labelMedium?.copyWith(
                color: muted,
                fontWeight: FontWeight.w700,
                letterSpacing: 1,
              ),
            ),
            const Spacer(),
            if (canManage)
              GTTextButton(
                text: 'Добавить',
                icon: Icons.add_rounded,
                dense: true,
                onPressed: () async {
                  await PurchaseRequestInvoiceDialog.show(
                    context,
                    requestId: requestId,
                  );
                },
              ),
          ],
        ),
        const SizedBox(height: PurchaseRequestDetailsTokens.sectionTitleGap),
        invoicesAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (error, _) => _EmptyBox(
            text: formatSupabaseErrorMessage(error),
          ),
          data: (invoices) {
            if (invoices.isEmpty) {
              return _EmptyBox(
                text: canManage
                    ? 'Добавьте счёт поставщика и прикрепите файл'
                    : 'Счета не добавлены',
              );
            }

            return Column(
              children: [
                for (final invoice in invoices) ...[
                  _InvoiceCard(
                    requestId: requestId,
                    invoice: invoice,
                    onDelete: canManage
                        ? () => _deleteInvoice(context, ref, invoice.id)
                        : null,
                  ),
                  const SizedBox(height: 8),
                ],
              ],
            );
          },
        ),
      ],
    );
  }

  Future<void> _deleteInvoice(
    BuildContext context,
    WidgetRef ref,
    String invoiceId,
  ) async {
    try {
      await ref.read(purchaseRequestRepositoryProvider).deleteInvoice(invoiceId);
      invalidatePurchaseRequestCaches(ref, requestId);
    } catch (error) {
      if (!context.mounted) return;
      AppSnackBar.show(
        context: context,
        message: formatSupabaseErrorMessage(error),
        kind: AppSnackBarKind.error,
      );
    }
  }
}

class _InvoiceCard extends ConsumerWidget {
  const _InvoiceCard({
    required this.requestId,
    required this.invoice,
    this.onDelete,
  });

  final String requestId;
  final PurchaseRequestInvoice invoice;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final muted = PurchaseRequestDetailsTokens.mutedText(theme);
    final file = invoice.invoiceFile;
    final fileName = file?.fileName;
    final busyIds = ref.watch(
      purchaseRequestInvoiceFileBusyIdsProvider(requestId),
    );
    final isBusy = file != null && busyIds.contains(file.id);
    final canPreview =
        file != null && isPurchaseRequestInvoiceFilePreviewable(file);

    return DecoratedBox(
      decoration: PurchaseRequestDetailsTokens.cardDecoration(theme),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              invoice.hasInvoiceFile
                  ? Icons.check_circle_outline_rounded
                  : Icons.error_outline_rounded,
              size: 20,
              color: invoice.hasInvoiceFile
                  ? theme.colorScheme.primary
                  : theme.colorScheme.error,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    invoice.supplierName ?? 'Поставщик',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    formatCurrency(invoice.amount),
                    style: theme.textTheme.bodyMedium,
                  ),
                  if ((invoice.invoiceNumber ?? '').isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      '№ ${invoice.invoiceNumber}',
                      style: theme.textTheme.bodySmall?.copyWith(color: muted),
                    ),
                  ],
                  if (invoice.invoiceDate != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      formatRuDate(invoice.invoiceDate!),
                      style: theme.textTheme.bodySmall?.copyWith(color: muted),
                    ),
                  ],
                  const SizedBox(height: 4),
                  Text(
                    fileName ?? 'Файл не прикреплён',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: invoice.hasInvoiceFile
                          ? muted
                          : theme.colorScheme.error,
                    ),
                  ),
                ],
              ),
            ),
            if (file != null) ...[
              if (isBusy)
                const Padding(
                  padding: EdgeInsets.all(12),
                  child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CupertinoActivityIndicator(radius: 8),
                  ),
                )
              else ...[
                if (canPreview)
                  IconButton(
                    tooltip: 'Просмотреть счёт',
                    icon: const Icon(Icons.visibility_outlined),
                    onPressed: () => previewPurchaseRequestInvoiceFile(
                      context: context,
                      ref: ref,
                      requestId: requestId,
                      file: file,
                    ),
                  ),
                IconButton(
                  tooltip: 'Скачать счёт',
                  icon: const Icon(Icons.download_outlined),
                  onPressed: () => downloadPurchaseRequestInvoiceFile(
                    context: context,
                    ref: ref,
                    requestId: requestId,
                    file: file,
                  ),
                ),
              ],
            ],
            if (onDelete != null)
              IconButton(
                tooltip: 'Удалить счёт',
                icon: const Icon(Icons.delete_outline_rounded),
                onPressed: onDelete,
              ),
          ],
        ),
      ),
    );
  }
}

class _EmptyBox extends StatelessWidget {
  const _EmptyBox({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = PurchaseRequestDetailsTokens.mutedText(theme);

    return DecoratedBox(
      decoration: PurchaseRequestDetailsTokens.cardDecoration(theme),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(color: muted),
        ),
      ),
    );
  }
}
