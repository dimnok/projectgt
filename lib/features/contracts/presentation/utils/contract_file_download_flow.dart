import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:projectgt/core/utils/attachment_file_save.dart';
import 'package:projectgt/core/widgets/app_snackbar.dart';
import 'package:projectgt/domain/entities/contract_file.dart';
import 'package:projectgt/features/contracts/presentation/providers/contract_files_providers.dart';

/// Скачивает файл договора из Storage и предлагает сохранить его пользователю.
///
/// Учитывает [contractFileDownloadingIdsProvider]: повторный запуск для того же
/// [file.id] игнорируется.
Future<void> downloadContractFileForUser({
  required BuildContext context,
  required WidgetRef ref,
  required String contractId,
  required ContractFile file,
}) async {
  final dn = ref.read(
    contractFileDownloadingIdsProvider(contractId).notifier,
  );
  if (dn.state.contains(file.id)) return;

  dn.state = {...dn.state, file.id};
  try {
    final bytes = await ref
        .read(contractFilesProvider(contractId).notifier)
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
    final n = ref.read(
      contractFileDownloadingIdsProvider(contractId).notifier,
    );
    n.state = {...n.state}..remove(file.id);
  }
}
