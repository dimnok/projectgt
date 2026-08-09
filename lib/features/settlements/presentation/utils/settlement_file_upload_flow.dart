import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart' as path_provider;
import 'package:projectgt/core/widgets/app_snackbar.dart';
import 'package:projectgt/core/widgets/desktop_dialog_content.dart';
import 'package:projectgt/core/widgets/gt_buttons.dart';
import 'package:projectgt/core/widgets/gt_text_field.dart';
import 'package:projectgt/features/contracts/presentation/constants/contract_file_dialog_width.dart';
import 'package:projectgt/features/settlements/presentation/state/settlement_files_state.dart';

/// Допустимые расширения вложений к счёту.
const settlementFileAcceptedExtensions = [
  'pdf',
  'doc',
  'docx',
  'xls',
  'xlsx',
  'jpg',
  'jpeg',
  'png',
];

/// Открывает диалог выбора файла и загрузки вложения к счёту.
Future<void> openSettlementFileUploadFlow({
  required BuildContext context,
  required WidgetRef ref,
  required String settlementOperationId,
}) async {
  try {
    final file = await openFile(
      acceptedTypeGroups: [
        const XTypeGroup(
          label: 'Документы',
          extensions: settlementFileAcceptedExtensions,
        ),
      ],
    );

    if (file == null) return;

    final originalFileName = file.name;
    final extension = originalFileName.split('.').last;
    final nameWithoutExtension =
        originalFileName.replaceAll('.$extension', '');

    final nameController = TextEditingController(text: nameWithoutExtension);
    final descriptionController = TextEditingController();

    if (!context.mounted) return;

    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(24),
        child: DesktopDialogContent(
          title: 'Прикрепить файл',
          width: kContractFileDesktopDialogWidth,
          footer: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              GTSecondaryButton(
                text: 'Отмена',
                onPressed: () => Navigator.pop(context),
              ),
              const SizedBox(width: 16),
              GTPrimaryButton(
                text: 'Загрузить',
                onPressed: () {
                  final name = nameController.text.trim();
                  final description = descriptionController.text.trim();
                  Navigator.pop(context, {
                    'name': name.isEmpty ? nameWithoutExtension : name,
                    'description': description,
                  });
                },
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              GTTextField(
                controller: nameController,
                autofocus: true,
                labelText: 'Наименование файла *',
                hintText: 'Введите название',
                suffixText: '.$extension',
              ),
              const SizedBox(height: 20),
              GTTextField(
                controller: descriptionController,
                labelText: 'Краткое описание',
                hintText: 'О чём этот документ...',
                maxLines: 3,
              ),
            ],
          ),
        ),
      ),
    );

    if (result == null) return;

    final finalFileName = '${result['name']}.$extension';
    final description = result['description'];
    final fileBytes = await file.readAsBytes();

    if (!context.mounted) return;

    AppSnackBar.show(
      context: context,
      message: 'Начинаем загрузку файла...',
      kind: AppSnackBarKind.info,
    );

    final tempDir = await path_provider.getTemporaryDirectory();
    final tempFile = File('${tempDir.path}/${file.name}');
    await tempFile.writeAsBytes(fileBytes);

    await ref
        .read(settlementFilesProvider(settlementOperationId).notifier)
        .uploadFile(
          tempFile,
          finalFileName,
          description: description?.isEmpty == true ? null : description,
        );

    if (!context.mounted) return;
    AppSnackBar.show(
      context: context,
      message: 'Файл прикреплён',
      kind: AppSnackBarKind.success,
    );
  } catch (e) {
    if (!context.mounted) return;
    AppSnackBar.show(
      context: context,
      message: 'Ошибка при загрузке: $e',
      kind: AppSnackBarKind.error,
    );
  }
}
