import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/providers.dart';
import '../../../../core/utils/snackbar_utils.dart';
import '../../../../core/widgets/desktop_dialog_content.dart';
import '../../../../core/widgets/gt_buttons.dart';
import '../../../../core/widgets/mobile_bottom_sheet_content.dart';
import '../../../../domain/entities/estimate_bulk_update.dart';
import '../services/estimate_bulk_update_excel_service.dart';

/// Модальное окно безопасного массового обновления сметы из Excel.
class ImportEstimateBulkUpdateModal extends ConsumerStatefulWidget {
  /// Название сметы.
  final String estimateTitle;

  /// Идентификатор договора.
  final String contractId;

  /// Идентификатор объекта.
  final String? objectId;

  /// Коллбек после успешного применения.
  final VoidCallback onSuccess;

  /// Коллбек закрытия.
  final VoidCallback onCancel;

  /// Нужно ли оборачивать в стандартный wrapper.
  final bool useWrapper;

  /// Создаёт модальное окно массового обновления.
  const ImportEstimateBulkUpdateModal({
    super.key,
    required this.estimateTitle,
    required this.contractId,
    required this.objectId,
    required this.onSuccess,
    required this.onCancel,
    this.useWrapper = true,
  });

  /// Открывает модальное окно массового обновления.
  static void show(
    BuildContext context, {
    required String estimateTitle,
    required String contractId,
    String? objectId,
    required VoidCallback onSuccess,
  }) {
    final isLargeScreen = MediaQuery.of(context).size.width > 900;
    if (isLargeScreen) {
      DesktopDialogContent.show(
        context,
        title: 'Обновление сметы из Excel',
        width: 820,
        onClose: () => Navigator.of(context).pop(),
        child: ImportEstimateBulkUpdateModal(
          estimateTitle: estimateTitle,
          contractId: contractId,
          objectId: objectId,
          onSuccess: onSuccess,
          onCancel: () => Navigator.of(context).pop(),
          useWrapper: false,
        ),
      );
    } else {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        backgroundColor: Colors.transparent,
        builder: (context) => ImportEstimateBulkUpdateModal(
          estimateTitle: estimateTitle,
          contractId: contractId,
          objectId: objectId,
          onSuccess: onSuccess,
          onCancel: () => context.pop(),
        ),
      );
    }
  }

  @override
  ConsumerState<ImportEstimateBulkUpdateModal> createState() =>
      _ImportEstimateBulkUpdateModalState();
}

class _ImportEstimateBulkUpdateModalState
    extends ConsumerState<ImportEstimateBulkUpdateModal> {
  PlatformFile? _pickedFile;
  List<EstimateBulkUpdateImportRow> _rows = const [];
  EstimateBulkUpdateResult? _preview;
  bool _isDownloading = false;
  bool _isPreviewing = false;
  bool _isApplying = false;

  bool get _canApply {
    final preview = _preview;
    if (preview == null) return false;
    final hasInvalidRows = preview.items.any(
      (item) => item.action == 'invalid',
    );
    return preview.summary.conflicts == 0 &&
        !hasInvalidRows &&
        preview.summary.updated + preview.summary.inserted > 0;
  }

  Future<void> _downloadTemplate() async {
    setState(() => _isDownloading = true);
    try {
      final repository = ref.read(estimateRepositoryProvider);
      final result = await repository.getBulkUpdateTemplateFile(
        estimateTitle: widget.estimateTitle,
        contractId: widget.contractId,
        objectId: widget.objectId,
      );
      await EstimateBulkUpdateExcelService.saveToDevice(
        result['bytes'] as Uint8List,
        fileName: result['filename'] as String,
      );

      if (!mounted) return;
      SnackBarUtils.showSuccess(
        context,
        'Файл для обновления сметы сформирован',
      );
    } catch (e) {
      if (!mounted) return;
      SnackBarUtils.showError(context, 'Ошибка выгрузки файла: $e');
    } finally {
      if (mounted) setState(() => _isDownloading = false);
    }
  }

  Future<void> _pickFileAndPreview() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['xlsx'],
        withData: true,
      );
      if (result == null || result.files.single.bytes == null) return;

      setState(() {
        _pickedFile = result.files.single;
        _preview = null;
        _rows = const [];
        _isPreviewing = true;
      });

      final bytes = Uint8List.fromList(result.files.single.bytes!);
      final rows = EstimateBulkUpdateExcelService.parseRows(bytes);
      if (rows.isEmpty) {
        throw Exception('Файл не содержит строк для обновления');
      }

      final repository = ref.read(estimateRepositoryProvider);
      final preview = await repository.previewBulkUpdate(
        estimateTitle: widget.estimateTitle,
        contractId: widget.contractId,
        objectId: widget.objectId,
        rows: rows,
        sourceFileName: result.files.single.name,
      );

      if (!mounted) return;
      setState(() {
        _rows = rows;
        _preview = preview;
      });
    } catch (e) {
      if (!mounted) return;
      SnackBarUtils.showError(context, 'Ошибка проверки файла: $e');
    } finally {
      if (mounted) setState(() => _isPreviewing = false);
    }
  }

  Future<void> _apply() async {
    if (!_canApply || _rows.isEmpty) return;

    setState(() => _isApplying = true);
    try {
      final repository = ref.read(estimateRepositoryProvider);
      final result = await repository.applyBulkUpdate(
        estimateTitle: widget.estimateTitle,
        contractId: widget.contractId,
        objectId: widget.objectId,
        rows: _rows,
        sourceFileName: _pickedFile?.name,
      );

      if (!mounted) return;
      setState(() => _preview = result);

      if (!result.applied) {
        SnackBarUtils.showWarning(
          context,
          result.message ?? 'Обновление не применено',
        );
        return;
      }

      SnackBarUtils.showSuccess(
        context,
        'Смета обновлена: ${result.summary.updated} обновлено, ${result.summary.inserted} добавлено',
      );
      widget.onSuccess();
    } catch (e) {
      if (!mounted) return;
      SnackBarUtils.showError(context, 'Ошибка применения обновления: $e');
    } finally {
      if (mounted) setState(() => _isApplying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLargeScreen = MediaQuery.of(context).size.width > 900;
    final theme = Theme.of(context);

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildInfo(theme),
        const SizedBox(height: 16),
        _buildFileActions(),
        const SizedBox(height: 16),
        _buildPreview(theme),
      ],
    );

    final actions = Row(
      children: [
        Expanded(
          child: GTSecondaryButton(
            text: 'Закрыть',
            onPressed: _isApplying ? null : widget.onCancel,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: GTPrimaryButton(
            text: _isApplying ? 'Применение...' : 'Применить',
            onPressed: _isApplying || !_canApply ? null : _apply,
          ),
        ),
      ],
    );

    if (!widget.useWrapper) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [content, const SizedBox(height: 24), actions],
      );
    }

    if (isLargeScreen) {
      return DesktopDialogContent(
        title: 'Обновление сметы из Excel',
        width: 820,
        footer: actions,
        onClose: widget.onCancel,
        child: content,
      );
    }

    return MobileBottomSheetContent(
      title: 'Обновление сметы из Excel',
      footer: actions,
      child: content,
    );
  }

  Widget _buildInfo(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.18),
        ),
      ),
      child: const Text(
        'Скачайте файл, измените строки и загрузите обратно. '
        'Существующие строки обновляются по ID, новые добавляются только при пустом ID. '
        'Удаление отсутствующих строк не выполняется.',
      ),
    );
  }

  Widget _buildFileActions() {
    return Row(
      children: [
        Expanded(
          child: GTSecondaryButton(
            text: _isDownloading ? 'Формирование...' : 'Скачать Excel',
            icon: CupertinoIcons.arrow_down_doc,
            onPressed: _isDownloading || _isPreviewing || _isApplying
                ? null
                : _downloadTemplate,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: GTPrimaryButton(
            text: _isPreviewing ? 'Проверка...' : 'Загрузить и проверить',
            icon: CupertinoIcons.arrow_up_doc,
            onPressed: _isDownloading || _isPreviewing || _isApplying
                ? null
                : _pickFileAndPreview,
          ),
        ),
      ],
    );
  }

  Widget _buildPreview(ThemeData theme) {
    final preview = _preview;
    if (_isPreviewing) {
      return const Center(child: CupertinoActivityIndicator());
    }
    if (preview == null) {
      return Text(
        'Файл еще не выбран.',
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      );
    }

    final summary = preview.summary;
    final problemItems = preview.items
        .where((item) => item.status == 'conflict' || item.action == 'invalid')
        .take(8)
        .toList();
    final warnings = preview.items
        .where(
          (item) =>
              item.action == 'update' && item.message.contains('фактические'),
        )
        .take(6)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _StatChip(label: 'Всего', value: summary.total),
            _StatChip(label: 'Обновить', value: summary.updated),
            _StatChip(label: 'Добавить', value: summary.inserted),
            _StatChip(label: 'Пропустить', value: summary.skipped),
            _StatChip(
              label: 'Конфликты',
              value: summary.conflicts,
              isError: summary.conflicts > 0,
            ),
          ],
        ),
        if (warnings.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text('Предупреждения', style: theme.textTheme.titleSmall),
          const SizedBox(height: 6),
          for (final item in warnings)
            Text('Строка ${item.rowNo}: ${item.message}'),
        ],
        if (problemItems.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text('Проблемные строки', style: theme.textTheme.titleSmall),
          const SizedBox(height: 6),
          for (final item in problemItems)
            Text('Строка ${item.rowNo}: ${item.message}'),
        ],
        if (!_canApply && summary.conflicts == 0)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(
              'Нет изменений для применения.',
              style: theme.textTheme.bodyMedium,
            ),
          ),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.label,
    required this.value,
    this.isError = false,
  });

  final String label;
  final int value;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = isError ? theme.colorScheme.error : theme.colorScheme.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text('$label: $value'),
    );
  }
}
