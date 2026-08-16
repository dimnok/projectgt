import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:projectgt/core/utils/attachment_file_save.dart';
import 'package:projectgt/core/utils/supabase_error_message.dart';
import 'package:projectgt/core/widgets/app_snackbar.dart';
import 'package:projectgt/core/widgets/attachment_file_preview.dart';
import 'package:projectgt/features/purchase_requests/domain/entities/purchase_request_file.dart';
import 'package:projectgt/features/purchase_requests/presentation/state/purchase_request_providers.dart';
import 'package:projectgt/features/purchase_requests/presentation/utils/purchase_request_invoice_utils.dart';

Future<void> _runInvoiceFileAction({
  required BuildContext context,
  required WidgetRef ref,
  required String requestId,
  required PurchaseRequestFile file,
  required Future<void> Function(List<int> bytes) action,
}) async {
  final busy = ref.read(
    purchaseRequestInvoiceFileBusyIdsProvider(requestId).notifier,
  );
  if (busy.state.contains(file.id)) return;

  busy.state = {...busy.state, file.id};
  try {
    final bytes = await ref
        .read(purchaseRequestRepositoryProvider)
        .downloadInvoiceFile(file.storagePath);
    busy.state = {...busy.state}..remove(file.id);
    await action(bytes);
  } catch (error) {
    if (!context.mounted) return;
    AppSnackBar.show(
      context: context,
      message: formatSupabaseErrorMessage(error),
      kind: AppSnackBarKind.error,
    );
  } finally {
    final notifier = ref.read(
      purchaseRequestInvoiceFileBusyIdsProvider(requestId).notifier,
    );
    notifier.state = {...notifier.state}..remove(file.id);
  }
}

/// Скачивает файл счёта на устройство пользователя.
Future<void> downloadPurchaseRequestInvoiceFile({
  required BuildContext context,
  required WidgetRef ref,
  required String requestId,
  required PurchaseRequestFile file,
}) {
  return _runInvoiceFileAction(
    context: context,
    ref: ref,
    requestId: requestId,
    file: file,
    action: (bytes) =>
        saveFileBytesToUserDevice(fileName: file.fileName, bytes: bytes),
  );
}

/// Открывает просмотр файла счёта (PDF или изображение).
Future<void> previewPurchaseRequestInvoiceFile({
  required BuildContext context,
  required WidgetRef ref,
  required String requestId,
  required PurchaseRequestFile file,
}) {
  if (!isPurchaseRequestInvoiceFilePreviewable(file)) {
    AppSnackBar.show(
      context: context,
      message: 'Этот формат нельзя открыть в приложении. Скачайте файл.',
      kind: AppSnackBarKind.error,
    );
    return Future.value();
  }

  return _runInvoiceFileAction(
    context: context,
    ref: ref,
    requestId: requestId,
    file: file,
    action: (bytes) async {
      if (!context.mounted) return;
      await openAttachmentFilePreview(
        context: context,
        fileName: file.fileName,
        mimeType: file.mimeType,
        bytes: bytes,
      );
    },
  );
}
