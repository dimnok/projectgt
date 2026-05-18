import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_selector/file_selector.dart';
import 'package:path_provider/path_provider.dart' as path_provider;

import 'package:projectgt/domain/entities/contract.dart';
import 'package:projectgt/features/contracts/presentation/providers/contract_files_providers.dart';
import 'package:projectgt/core/widgets/app_snackbar.dart';
import 'package:projectgt/features/contracts/presentation/constants/contract_file_dialog_width.dart';
import 'package:projectgt/core/widgets/desktop_dialog_content.dart';
import 'package:projectgt/core/widgets/gt_buttons.dart';
import 'package:projectgt/core/widgets/gt_text_field.dart';

/// Открывает диалог выбора файла и загрузки документа для договора.
Future<void> openContractDocumentUploadFlow({
  required BuildContext context,
  required WidgetRef ref,
  required Contract contract,
}) async {
  try {
    final XFile? file = await openFile(
      acceptedTypeGroups: [
        const XTypeGroup(
          label: 'Документы',
          extensions: ['pdf', 'doc', 'docx', 'xls', 'xlsx', 'jpg', 'jpeg', 'png'],
        ),
      ],
    );

    if (file != null) {
      final originalFileName = file.name;
      final extension = originalFileName.split('.').last;
      final nameWithoutExtension = originalFileName.replaceAll('.$extension', '');

      final nameController = TextEditingController(text: nameWithoutExtension);
      final descriptionController = TextEditingController();

      if (!context.mounted) return;

      final result = await showDialog<Map<String, String>>(
        context: context,
        builder: (context) => Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(24),
          child: DesktopDialogContent(
            title: 'Загрузка документа',
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
                  hintText: 'О чем этот документ...',
                  maxLines: 3,
                ),
              ],
            ),
          ),
        ),
      );

      if (result == null) {
        return;
      }

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
          .read(contractFilesProvider(contract.id).notifier)
          .uploadFile(tempFile, finalFileName, description: description);

      if (!context.mounted) return;
      AppSnackBar.show(
        context: context,
        message: 'Документ успешно загружен',
        kind: AppSnackBarKind.success,
      );
    }
  } catch (e) {
    if (!context.mounted) return;
    AppSnackBar.show(
      context: context,
      message: 'Ошибка при загрузке: $e',
      kind: AppSnackBarKind.error,
    );
  }
}
