import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:projectgt/core/di/providers.dart';
import 'package:projectgt/core/utils/formatters.dart';
import 'package:projectgt/core/widgets/app_snackbar.dart';
import 'package:projectgt/domain/entities/contract_act.dart';
import 'package:projectgt/core/utils/attachment_file_save.dart';

/// Скачивает сохранённый Excel акта КС-2 из Storage на устройство пользователя.
Future<void> downloadContractActExcelForUser({
  required BuildContext context,
  required WidgetRef ref,
  required ContractAct act,
}) async {
  if (!act.hasExcel) {
    AppSnackBar.show(
      context: context,
      message: 'Файл акта не найден — сохраните акт заново из формы КС-2',
      kind: AppSnackBarKind.warning,
    );
    return;
  }

  try {
    final repository = ref.read(contractActRepositoryProvider);
    final bytes = await repository.downloadKs2Excel(act.id);
    if (!context.mounted) return;

    final fileName = 'КС-2_№${act.number}_${formatRuDate(act.actDate)}.xlsx';
    await saveFileBytesToUserDevice(fileName: fileName, bytes: bytes);

    if (!context.mounted) return;
    AppSnackBar.show(
      context: context,
      message: 'Файл КС-2 сохранён',
      kind: AppSnackBarKind.success,
    );
  } catch (e) {
    if (!context.mounted) return;
    AppSnackBar.show(
      context: context,
      message: 'Не удалось скачать файл: $e',
      kind: AppSnackBarKind.error,
    );
  }
}
