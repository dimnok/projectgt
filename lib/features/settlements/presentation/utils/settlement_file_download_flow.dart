import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:projectgt/core/utils/attachment_file_save.dart';
import 'package:projectgt/core/widgets/app_snackbar.dart';
import 'package:projectgt/features/settlements/domain/entities/settlement_file.dart';
import 'package:projectgt/features/settlements/presentation/state/settlement_files_state.dart';

/// Скачивает файл счёта из Storage и сохраняет на устройство пользователя.
Future<void> downloadSettlementFileForUser({
  required BuildContext context,
  required WidgetRef ref,
  required String settlementOperationId,
  required SettlementFile file,
}) async {
  final downloadingNotifier = ref.read(
    settlementFileDownloadingIdsProvider(settlementOperationId).notifier,
  );
  if (downloadingNotifier.state.contains(file.id)) return;

  downloadingNotifier.state = {...downloadingNotifier.state, file.id};
  try {
    final bytes = await ref
        .read(settlementFilesProvider(settlementOperationId).notifier)
        .downloadFile(file.filePath);
    await saveFileBytesToUserDevice(fileName: file.name, bytes: bytes);
  } catch (e) {
    if (!context.mounted) return;
    AppSnackBar.show(
      context: context,
      message: 'Ошибка при скачивании: $e',
      kind: AppSnackBarKind.error,
    );
  } finally {
    final notifier = ref.read(
      settlementFileDownloadingIdsProvider(settlementOperationId).notifier,
    );
    notifier.state = {...notifier.state}..remove(file.id);
  }
}
