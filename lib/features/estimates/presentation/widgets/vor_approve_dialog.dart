import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../../../core/widgets/desktop_dialog_content.dart';
import '../../../../core/widgets/gt_buttons.dart';
import '../../../../domain/entities/vor.dart';

/// Диалог подтверждения подписания ВОР.
///
/// Предупреждает о заморозке данных и предлагает загрузить подписанный PDF.
class VorApproveDialog extends StatefulWidget {
  /// Ведомость ВОР для подписания.
  final Vor vor;

  /// Создает экземпляр [VorApproveDialog].
  const VorApproveDialog({super.key, required this.vor});

  /// Отображает диалог подтверждения.
  ///
  /// Возвращает `true`, если пользователь подтвердил подписание.
  static Future<bool?> show(BuildContext context, Vor vor) {
    return showGeneralDialog<bool>(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'Подписание ВОР',
      barrierColor: Colors.black.withValues(alpha: 0.75),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) {
        return Center(
          child: Dialog(
            backgroundColor: Colors.transparent,
            elevation: 0,
            child: DesktopDialogContent(
              title: 'Подтверждение подписания',
              width: 500,
              child: VorApproveDialog(vor: vor),
            ),
          ),
        );
      },
    );
  }

  @override
  State<VorApproveDialog> createState() => _VorApproveDialogState();
}

class _VorApproveDialogState extends State<VorApproveDialog> {
  PlatformFile? _selectedFile;
  final bool _isUploading = false;

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result != null) {
      setState(() {
        _selectedFile = result.files.first;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Предупреждение
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.errorContainer.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: theme.colorScheme.error.withValues(alpha: 0.2),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                CupertinoIcons.exclamationmark_triangle_fill,
                color: theme.colorScheme.error,
                size: 24,
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Внимание! Данные будут заморожены',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'После смены статуса на «Подписан» объемы работ за данный период будут зафиксированы. '
                      'Редактирование и удаление ведомости станет невозможным.',
                      style: TextStyle(fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Секция загрузки файла
        const Text(
          'Загрузить подписанный документ (необязательно)',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        ),
        const SizedBox(height: 12),
        InkWell(
          onTap: _isUploading ? null : _pickFile,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(
                color: theme.colorScheme.outline.withValues(alpha: 0.2),
                style: BorderStyle.solid,
              ),
              borderRadius: BorderRadius.circular(12),
              color: theme.colorScheme.surfaceContainerHighest.withValues(
                alpha: 0.05,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _selectedFile != null
                      ? CupertinoIcons.doc_checkmark_fill
                      : CupertinoIcons.cloud_upload,
                  color: _selectedFile != null
                      ? Colors.green
                      : theme.colorScheme.primary,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    _selectedFile?.name ?? 'Выберите файл в формате PDF',
                    style: TextStyle(
                      fontSize: 13,
                      color: _selectedFile != null
                          ? theme.colorScheme.onSurface
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (_selectedFile != null)
                  IconButton(
                    icon: const Icon(
                      CupertinoIcons.xmark_circle_fill,
                      size: 20,
                    ),
                    onPressed: () => setState(() => _selectedFile = null),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 32),

        // Кнопки действий
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            GTTextButton(
              text: 'Отмена',
              onPressed: () => Navigator.of(context).pop(false),
            ),
            const SizedBox(width: 12),
            GTPrimaryButton(
              text: 'Подтвердить и подписать',
              onPressed: () {
                // В будущем здесь будет логика загрузки файла в Storage
                Navigator.of(context).pop(true);
              },
            ),
          ],
        ),
      ],
    );
  }
}
