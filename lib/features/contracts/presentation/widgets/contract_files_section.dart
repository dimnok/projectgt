import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:projectgt/domain/entities/contract.dart';
import 'package:projectgt/domain/entities/contract_file.dart';
import 'package:projectgt/features/roles/presentation/widgets/permission_guard.dart';
import 'package:projectgt/features/contracts/presentation/providers/contract_files_providers.dart';
import 'package:projectgt/features/contracts/presentation/utils/contract_document_upload_flow.dart';
import 'package:projectgt/features/contracts/presentation/utils/contract_file_download_flow.dart';
import 'package:projectgt/core/utils/formatters.dart';
import 'package:projectgt/core/widgets/app_snackbar.dart';
import 'package:projectgt/core/widgets/gt_confirmation_dialog.dart';
import 'package:projectgt/features/contracts/presentation/widgets/contract_file_edit_dialog.dart';
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

  Future<void> _handleDelete(
    BuildContext context,
    WidgetRef ref,
    ContractFile file,
  ) async {
    // Используем addPostFrameCallback для предотвращения MouseTracker error на десктопе
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!context.mounted) return;
      final confirmed = await GTConfirmationDialog.show(
        context: context,
        title: 'Удаление файла',
        message:
            'Файл будет удалён из списка и из хранилища без возможности восстановления. Продолжить?',
        emphasisText: file.name,
        detail: file.description,
        confirmText: 'Удалить',
        cancelText: 'Отмена',
        type: GTConfirmationType.danger,
      );

      if (confirmed == true) {
        try {
          await ref
              .read(contractFilesProvider(contract.id).notifier)
              .deleteFile(file.id, file.filePath);
          if (!context.mounted) return;
          AppSnackBar.show(
            context: context,
            message: 'Файл удален',
            kind: AppSnackBarKind.success,
          );
        } catch (e) {
          if (!context.mounted) return;
          AppSnackBar.show(
            context: context,
            message: 'Ошибка при удалении: $e',
            kind: AppSnackBarKind.error,
          );
        }
      }
    });
  }

  Future<void> _handleEdit(
    BuildContext context,
    WidgetRef ref,
    ContractFile file,
  ) async {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!context.mounted) return;
      final saved = await ContractFileEditDialog.show(
        context: context,
        contractId: contract.id,
        file: file,
      );
      if (!context.mounted) return;
      if (saved == true) {
        AppSnackBar.show(
          context: context,
          message: 'Изменения сохранены',
          kind: AppSnackBarKind.success,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final state = ref.watch(contractFilesProvider(contract.id));
    final downloadingIds =
        ref.watch(contractFileDownloadingIdsProvider(contract.id));

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
                    : () => openContractDocumentUploadFlow(
                          context: context,
                          ref: ref,
                          contract: contract,
                        ),
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
        ...state.files.map(
          (file) => _buildFileRow(
            context,
            ref,
            file,
            theme,
            downloadingIds,
          ),
        ),
      ],
    );
  }

  Widget _buildFileRow(
    BuildContext context,
    WidgetRef ref,
    ContractFile file,
    ThemeData theme,
    Set<String> downloadingIds,
  ) {
    final fileSizeFormatted = formatFileSizeBytes(file.size);

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
                    Text(
                      'Загрузка: ${formatRuDateTime(file.createdAt)}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.45,
                        ),
                        fontSize: 10.5,
                        height: 1.25,
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
                    onPressed: downloadingIds.contains(file.id)
                        ? null
                        : () => downloadContractFileForUser(
                              context: context,
                              ref: ref,
                              contractId: contract.id,
                              file: file,
                            ),
                    child: downloadingIds.contains(file.id)
                        ? Padding(
                            padding: const EdgeInsets.all(2),
                            child: CupertinoActivityIndicator(
                              radius: 7,
                              color: theme.colorScheme.primary
                                  .withValues(alpha: 0.85),
                            ),
                          )
                        : Icon(
                            CupertinoIcons.cloud_download,
                            size: 20,
                            color: theme.colorScheme.primary
                                .withValues(alpha: 0.85),
                          ),
                  ),
                  PermissionGuard(
                    module: 'contracts',
                    permission: 'update',
                    child: CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: () => _handleEdit(context, ref, file),
                      child: Icon(
                        CupertinoIcons.pencil,
                        size: 20,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.75),
                      ),
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
        return CupertinoIcons.photo;
      default:
        return CupertinoIcons.doc;
    }
  }
}
