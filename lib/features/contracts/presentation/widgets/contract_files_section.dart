import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:file_saver/file_saver.dart';
import 'dart:typed_data';
import 'package:projectgt/domain/entities/contract.dart';
import 'package:projectgt/domain/entities/contract_file.dart';
import 'package:projectgt/features/roles/presentation/widgets/permission_guard.dart';
import 'package:projectgt/features/contracts/presentation/providers/contract_files_providers.dart';
import 'package:projectgt/core/utils/snackbar_utils.dart';
import 'package:projectgt/core/widgets/desktop_dialog_content.dart';
import 'package:projectgt/core/widgets/gt_buttons.dart';
import 'contract_list_shared.dart';

/// Раздел управления файлами договора.
///
/// Предоставляет интерфейс для просмотра списка прикрепленных файлов,
/// их загрузки, скачивания и удаления.
class ContractFilesSection extends ConsumerWidget {
  /// Договор, к которому относятся файлы.
  final Contract contract;

  /// Создает раздел файлов договора.
  const ContractFilesSection({super.key, required this.contract});

  Future<void> _handleUpload(BuildContext context, WidgetRef ref) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        final originalFileName = result.files.single.name;
        final extension = originalFileName.split('.').last;
        final nameWithoutExtension = originalFileName.replaceAll(
          '.$extension',
          '',
        );

        final controller = TextEditingController(text: nameWithoutExtension);

        if (!context.mounted) return;

        final newName = await showDialog<String>(
          context: context,
          builder: (context) => Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.all(24),
            child: DesktopDialogContent(
              title: 'Загрузка файла',
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
                      final text = controller.text.trim();
                      Navigator.pop(
                        context,
                        text.isEmpty ? nameWithoutExtension : text,
                      );
                    },
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Укажите название для загружаемого файла:'),
                  const SizedBox(height: 16),
                  TextField(
                    controller: controller,
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: 'Название файла',
                      suffixText: '.$extension',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );

        if (newName == null) return;

        final file = File(result.files.single.path!);
        final finalFileName = '$newName.$extension';

        await ref
            .read(contractFilesProvider(contract.id).notifier)
            .uploadFile(file, finalFileName);

        if (!context.mounted) return;
        SnackBarUtils.showSuccess(context, 'Файл успешно загружен');
      }
    } catch (e) {
      if (!context.mounted) return;
      SnackBarUtils.showError(context, 'Ошибка при загрузке: $e');
    }
  }

  Future<void> _handleDownload(
    BuildContext context,
    WidgetRef ref,
    ContractFile file,
  ) async {
    try {
      final bytes = await ref
          .read(contractFilesProvider(contract.id).notifier)
          .downloadFile(file.filePath);

      final extension = file.name.split('.').last;
      final nameWithoutExtension = file.name.replaceAll('.$extension', '');

      await FileSaver.instance.saveAs(
        name: nameWithoutExtension,
        bytes: Uint8List.fromList(bytes),
        ext: extension,
        mimeType: _getMimeType(extension),
      );
    } catch (e) {
      if (!context.mounted) return;
      SnackBarUtils.showError(context, 'Ошибка при скачивании файла: $e');
    }
  }

  MimeType _getMimeType(String extension) {
    switch (extension.toLowerCase()) {
      case 'pdf':
        return MimeType.pdf;
      case 'doc':
      case 'docx':
        return MimeType.microsoftWord;
      case 'xls':
      case 'xlsx':
        return MimeType.microsoftExcel;
      case 'jpg':
      case 'jpeg':
        return MimeType.jpeg;
      case 'png':
        return MimeType.png;
      default:
        return MimeType.other;
    }
  }

  Future<void> _handleDelete(
    BuildContext context,
    WidgetRef ref,
    ContractFile file,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(24),
        child: DesktopDialogContent(
          title: 'Удаление файла',
          footer: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              GTSecondaryButton(
                text: 'Отмена',
                onPressed: () => Navigator.pop(context, false),
              ),
              const SizedBox(width: 16),
              GTPrimaryButton(
                text: 'Удалить',
                onPressed: () => Navigator.pop(context, true),
                backgroundColor: Colors.red,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Вы уверены, что хотите удалить файл "${file.name}"?'),
              const SizedBox(height: 8),
              const Text(
                'Это действие нельзя будет отменить.',
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    );

    if (confirmed == true) {
      try {
        await ref
            .read(contractFilesProvider(contract.id).notifier)
            .deleteFile(file.id, file.filePath);
        if (!context.mounted) return;
        SnackBarUtils.showSuccess(context, 'Файл удален');
      } catch (e) {
        if (!context.mounted) return;
        SnackBarUtils.showError(context, 'Ошибка при удалении: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final state = ref.watch(contractFilesProvider(contract.id));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Expanded(
              child: ContractSectionTitle(title: 'Файлы договора'),
            ),
            if (state.isLoading)
              const Padding(
                padding: EdgeInsets.only(right: 8.0),
                child: CupertinoActivityIndicator(radius: 8),
              ),
            PermissionGuard(
              module: 'contracts',
              permission: 'update',
              child: CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: state.isLoading
                    ? null
                    : () => _handleUpload(context, ref),
                child: const Icon(CupertinoIcons.plus_circle, size: 20),
              ),
            ),
          ],
        ),
        if (state.errorMessage != null)
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              state.errorMessage!,
              style: TextStyle(color: theme.colorScheme.error, fontSize: 12),
            ),
          ),
        const SizedBox(height: 8),
        if (state.files.isEmpty && !state.isLoading)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: Text(
                'Нет прикрепленных файлов',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                ),
              ),
            ),
          ),
        ...state.files.map((file) => _buildFileRow(context, ref, file, theme)),
      ],
    );
  }

  Widget _buildFileRow(
    BuildContext context,
    WidgetRef ref,
    ContractFile file,
    ThemeData theme,
  ) {
    final fileSizeFormatted = _formatFileSize(file.size);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          child: Row(
            children: [
              Icon(
                _getFileIcon(file.name),
                size: 20,
                color: theme.colorScheme.primary.withValues(alpha: 0.7),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      file.name,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      fileSizeFormatted,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.5,
                        ),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () => _handleDownload(context, ref, file),
                    child: const Icon(
                      CupertinoIcons.cloud_download,
                      size: 20,
                      color: Colors.blue,
                    ),
                  ),
                  PermissionGuard(
                    module: 'contracts',
                    permission: 'update',
                    child: CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: () => _handleDelete(context, ref, file),
                      child: const Icon(
                        CupertinoIcons.trash,
                        size: 20,
                        color: Colors.red,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Divider(
          height: 1,
          thickness: 0.5,
          indent: 44,
          endIndent: 12,
          color: theme.colorScheme.outline.withValues(alpha: 0.08),
        ),
      ],
    );
  }

  String _formatFileSize(int bytes) {
    if (bytes <= 0) return "0 B";
    const suffixes = ["B", "KB", "MB", "GB", "TB"];
    var i = (math.log(bytes) / math.log(1024)).floor();
    return '${(bytes / math.pow(1024, i)).toStringAsFixed(1)} ${suffixes[i]}';
  }

  IconData _getFileIcon(String fileName) {
    final ext = fileName.split('.').last.toLowerCase();
    switch (ext) {
      case 'pdf':
        return CupertinoIcons.doc_text_fill;
      case 'doc':
      case 'docx':
        return CupertinoIcons.doc_text;
      case 'xls':
      case 'xlsx':
        return CupertinoIcons.table;
      case 'jpg':
      case 'jpeg':
      case 'png':
        return CupertinoIcons.photo;
      default:
        return CupertinoIcons.doc;
    }
  }
}
