import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:projectgt/core/widgets/desktop_dialog_content.dart';
import 'package:projectgt/core/widgets/gt_buttons.dart';
import 'package:projectgt/core/widgets/gt_dropdown.dart';
import 'package:projectgt/core/widgets/mobile_bottom_sheet_content.dart';
import 'package:projectgt/domain/entities/contract_document_status.dart';
import 'package:projectgt/features/contracts/presentation/constants/contract_file_dialog_width.dart';
import 'package:projectgt/core/widgets/app_snackbar.dart';
import 'package:projectgt/features/contracts/presentation/providers/contract_files_providers.dart';

/// Диалог выбора нового статуса для нескольких документов договора.
class ContractFilesBulkStatusDialog extends ConsumerStatefulWidget {
  /// Идентификатор договора.
  final String contractId;

  /// Идентификаторы выбранных файлов.
  final List<String> fileIds;

  /// Создаёт диалог.
  const ContractFilesBulkStatusDialog({
    super.key,
    required this.contractId,
    required this.fileIds,
  });

  /// Показывает диалог. Возвращает `true` при успешном применении.
  static Future<bool?> show({
    required BuildContext context,
    required String contractId,
    required List<String> fileIds,
  }) {
    final isDesktop = MediaQuery.sizeOf(context).width >= 900;
    if (isDesktop) {
      return showDialog<bool>(
        context: context,
        barrierColor: Colors.black.withValues(alpha: 0.6),
        builder: (context) => Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: ContractFilesBulkStatusDialog(
            contractId: contractId,
            fileIds: fileIds,
          ),
        ),
      );
    }
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      builder: (context) => ContractFilesBulkStatusDialog(
        contractId: contractId,
        fileIds: fileIds,
      ),
    );
  }

  @override
  ConsumerState<ContractFilesBulkStatusDialog> createState() =>
      _ContractFilesBulkStatusDialogState();
}

class _ContractFilesBulkStatusDialogState
    extends ConsumerState<ContractFilesBulkStatusDialog> {
  ContractDocumentStatus _status = ContractDocumentStatus.draft;
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.sizeOf(context).width >= 900;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    final body = Padding(
      padding: EdgeInsets.only(bottom: bottomInset > 0 ? 8 : 0),
      child: GTEnumDropdown<ContractDocumentStatus>(
        values: ContractDocumentStatus.values,
        selectedValue: _status,
        onChanged: (v) {
          if (v != null) setState(() => _status = v);
        },
        labelText: 'Новый статус',
        hintText: 'Выберите статус',
        allowClear: false,
        enumToString: (e) => e.ruLabel,
      ),
    );

    Future<void> submit() async {
      setState(() => _saving = true);
      try {
        await ref.read(contractFilesProvider(widget.contractId).notifier).bulkUpdateDocumentStatus(
              fileIds: widget.fileIds,
              status: _status,
            );
        if (!context.mounted) return;
        Navigator.of(context).pop(true);
      } catch (e) {
        if (!context.mounted) return;
        AppSnackBar.show(
          context: context,
          message: 'Не удалось применить: $e',
          kind: AppSnackBarKind.error,
        );
        setState(() => _saving = false);
      }
    }

    if (isDesktop) {
      return DesktopDialogContent(
        title: 'Изменить статус',
        width: kContractFileDesktopDialogWidth,
        scrollable: false,
        showDividers: false,
        padding: const EdgeInsets.fromLTRB(32, 0, 32, 24),
        footer: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            GTSecondaryButton(
              text: 'Отмена',
              onPressed: _saving ? null : () => Navigator.of(context).pop(false),
            ),
            const SizedBox(width: 12),
            GTPrimaryButton(
              text: 'Применить',
              isLoading: _saving,
              onPressed: _saving ? null : submit,
            ),
          ],
        ),
        child: body,
      );
    }

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: MobileBottomSheetContent(
        title: 'Изменить статус',
        scrollable: false,
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
        footer: Column(
          children: [
            SizedBox(
              width: double.infinity,
              child: GTPrimaryButton(
                text: 'Применить',
                isLoading: _saving,
                onPressed: _saving ? null : submit,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: GTSecondaryButton(
                text: 'Отмена',
                onPressed: _saving ? null : () => Navigator.of(context).pop(false),
              ),
            ),
          ],
        ),
        child: body,
      ),
    );
  }
}
