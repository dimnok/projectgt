import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:projectgt/core/utils/attachment_file_save.dart';
import 'package:projectgt/core/utils/formatters.dart';
import 'package:projectgt/core/widgets/app_snackbar.dart';
import 'package:projectgt/domain/entities/ks2_act.dart';
import 'package:projectgt/features/contracts/presentation/providers/contract_ks2_providers.dart';

/// Скачивает сохранённый Excel акта КС-2 из Storage на устройство пользователя.
Future<void> downloadContractKs2ActExcelForUser({
  required BuildContext context,
  required WidgetRef ref,
  required Ks2Act act,
}) async {
  if (act.excelPath == null || act.excelPath!.isEmpty) {
    AppSnackBar.show(
      context: context,
      message: 'Файл акта не найден — сохраните акт заново из формы КС-2',
      kind: AppSnackBarKind.warning,
    );
    return;
  }

  try {
    final repository = ref.read(contractKs2RepositoryProvider);
    final bytes = await repository.downloadActExcel(act.id);
    final fileName = 'КС-2_№${act.number}_${formatRuDate(act.date)}.xlsx';
    await saveFileBytesToUserDevice(fileName: fileName, bytes: bytes);
  } catch (e) {
    if (!context.mounted) return;
    AppSnackBar.show(
      context: context,
      message: 'Не удалось скачать файл: $e',
      kind: AppSnackBarKind.error,
    );
  }
}
