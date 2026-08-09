import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:projectgt/core/widgets/app_snackbar.dart';
import 'package:projectgt/core/widgets/gt_buttons.dart';
import 'package:projectgt/core/widgets/gt_confirmation_dialog.dart';
import 'package:projectgt/features/roles/presentation/widgets/permission_guard.dart';
import 'package:projectgt/features/settlements/domain/entities/settlement_file.dart';
import 'package:projectgt/features/settlements/presentation/state/settlement_files_state.dart';
import 'package:projectgt/features/settlements/presentation/utils/settlement_file_download_flow.dart';
import 'package:projectgt/features/settlements/presentation/utils/settlement_file_upload_flow.dart';

/// Блок вложений к счёту в деталях взаиморасчёта.
class SettlementFilesSection extends ConsumerWidget {
  /// Идентификатор счёта.
  final String settlementOperationId;

  /// Компактный режим (мобильный bottom sheet).
  final bool compact;

  /// Создаёт секцию файлов.
  const SettlementFilesSection({
    super.key,
    required this.settlementOperationId,
    this.compact = false,
  });

  Future<void> _handleDelete(
    BuildContext context,
    WidgetRef ref,
    SettlementFile file,
  ) async {
    final confirmed = await GTConfirmationDialog.show(
      context: context,
      title: 'Удалить файл?',
      message:
          'Файл будет удалён из списка и из хранилища без возможности восстановления.',
      emphasisText: file.name,
      detail: file.description,
      confirmText: 'Удалить',
      cancelText: 'Отмена',
      type: GTConfirmationType.danger,
    );

    if (confirmed != true || !context.mounted) return;

    final success = await ref
        .read(settlementFilesProvider(settlementOperationId).notifier)
        .deleteFile(file.id, file.filePath);

    if (!context.mounted) return;
    AppSnackBar.show(
      context: context,
      message: success ? 'Файл удалён' : 'Не удалось удалить файл',
      kind: success ? AppSnackBarKind.success : AppSnackBarKind.error,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final state = ref.watch(settlementFilesProvider(settlementOperationId));
    final downloadingIds =
        ref.watch(settlementFileDownloadingIdsProvider(settlementOperationId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Документы',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            if (state.isLoading)
              const Padding(
                padding: EdgeInsets.only(right: 8),
                child: CupertinoActivityIndicator(radius: 8),
              ),
            PermissionGuard(
              module: 'settlements',
              permission: 'update',
              child: GTTextButton(
                text: 'Прикрепить',
                onPressed: state.isLoading
                    ? null
                    : () => openSettlementFileUploadFlow(
                          context: context,
                          ref: ref,
                          settlementOperationId: settlementOperationId,
                        ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (state.error != null && state.files.isEmpty)
          Text(
            state.error!,
            style: theme.textTheme.bodyMedium?.copyWith(color: scheme.error),
          )
        else if (state.isLoading && state.files.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: CupertinoActivityIndicator()),
          )
        else if (state.files.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: scheme.outline.withValues(alpha: 0.22)),
              color: scheme.surfaceContainerHighest.withValues(alpha: 0.35),
            ),
            child: Text(
              'К этому счёту пока не прикреплены файлы',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onSurface.withValues(alpha: 0.55),
              ),
            ),
          )
        else if (compact)
          ...state.files.map(
            (file) => _SettlementFileMobileCard(
              file: file,
              isDownloading: downloadingIds.contains(file.id),
              onDownload: () => downloadSettlementFileForUser(
                context: context,
                ref: ref,
                settlementOperationId: settlementOperationId,
                file: file,
              ),
              onDelete: () => _handleDelete(context, ref, file),
            ),
          )
        else
          Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: scheme.outline.withValues(alpha: 0.22),
              ),
              color: scheme.surfaceContainerHighest.withValues(alpha: 0.35),
            ),
            child: Column(
              children: [
                for (var i = 0; i < state.files.length; i++) ...[
                  _SettlementFileDesktopRow(
                    file: state.files[i],
                    isDownloading: downloadingIds.contains(state.files[i].id),
                    onDownload: () => downloadSettlementFileForUser(
                      context: context,
                      ref: ref,
                      settlementOperationId: settlementOperationId,
                      file: state.files[i],
                    ),
                    onDelete: () =>
                        _handleDelete(context, ref, state.files[i]),
                  ),
                  if (i < state.files.length - 1)
                    Divider(
                      height: 1,
                      thickness: 0.5,
                      color: scheme.outline.withValues(alpha: 0.12),
                    ),
                ],
              ],
            ),
          ),
      ],
    );
  }
}

class _SettlementFileDesktopRow extends StatelessWidget {
  final SettlementFile file;
  final bool isDownloading;
  final VoidCallback onDownload;
  final VoidCallback onDelete;

  const _SettlementFileDesktopRow({
    required this.file,
    required this.isDownloading,
    required this.onDownload,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      child: Row(
        children: [
          Icon(
            _fileIcon(file.name),
            size: 18,
            color: scheme.primary.withValues(alpha: 0.8),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  file.name,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    height: 1.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (file.description != null &&
                    file.description!.isNotEmpty)
                  Text(
                    file.description!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurface.withValues(alpha: 0.6),
                      height: 1.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          _FileActionButton(
            onPressed: isDownloading ? null : onDownload,
            child: isDownloading
                ? CupertinoActivityIndicator(
                    radius: 6,
                    color: scheme.primary.withValues(alpha: 0.85),
                  )
                : Icon(
                    CupertinoIcons.cloud_download,
                    size: 18,
                    color: scheme.primary.withValues(alpha: 0.85),
                  ),
          ),
          PermissionGuard(
            module: 'settlements',
            permission: 'update',
            child: _FileActionButton(
              onPressed: onDelete,
              child: const Icon(
                CupertinoIcons.trash,
                size: 18,
                color: Colors.red,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FileActionButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget child;

  const _FileActionButton({
    required this.onPressed,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 32,
      height: 32,
      child: IconButton(
        padding: EdgeInsets.zero,
        visualDensity: VisualDensity.compact,
        constraints: const BoxConstraints.tightFor(width: 32, height: 32),
        onPressed: onPressed,
        icon: child,
      ),
    );
  }
}

class _SettlementFileMobileCard extends StatelessWidget {
  final SettlementFile file;
  final bool isDownloading;
  final VoidCallback onDownload;
  final VoidCallback onDelete;

  const _SettlementFileMobileCard({
    required this.file,
    required this.isDownloading,
    required this.onDownload,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.outline.withValues(alpha: 0.28)),
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _fileIcon(file.name),
                size: 18,
                color: scheme.primary.withValues(alpha: 0.8),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  file.name,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          if (file.description != null && file.description!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              file.description!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurface.withValues(alpha: 0.65),
                height: 1.2,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              GTTextButton(
                text: isDownloading ? 'Скачивание…' : 'Скачать',
                onPressed: isDownloading ? null : onDownload,
              ),
              PermissionGuard(
                module: 'settlements',
                permission: 'update',
                child: GTTextButton(
                  text: 'Удалить',
                  onPressed: onDelete,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

IconData _fileIcon(String fileName) {
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
