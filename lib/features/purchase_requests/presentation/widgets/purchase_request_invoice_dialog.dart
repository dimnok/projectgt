import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:projectgt/core/utils/formatters.dart';
import 'package:projectgt/core/utils/responsive_utils.dart';
import 'package:projectgt/core/utils/supabase_error_message.dart';
import 'package:projectgt/core/widgets/app_snackbar.dart';
import 'package:projectgt/core/widgets/desktop_dialog_content.dart';
import 'package:projectgt/core/widgets/gt_buttons.dart';
import 'package:projectgt/core/widgets/gt_dropdown.dart';
import 'package:projectgt/core/widgets/gt_text_field.dart';
import 'package:projectgt/core/widgets/mobile_bottom_sheet_content.dart';
import 'package:projectgt/features/contractors/domain/entities/contractor.dart';
import 'package:projectgt/features/contractors/presentation/state/contractor_state.dart';
import 'package:projectgt/features/purchase_requests/presentation/state/purchase_request_providers.dart';

/// Допустимые расширения файла счёта.
const purchaseRequestInvoiceAcceptedExtensions = [
  'pdf',
  'jpg',
  'jpeg',
  'png',
];

/// Диалог добавления счёта с прикреплением файла.
class PurchaseRequestInvoiceDialog extends ConsumerStatefulWidget {
  /// Создаёт диалог.
  const PurchaseRequestInvoiceDialog({
    super.key,
    required this.requestId,
  });

  /// Идентификатор заявки.
  final String requestId;

  /// Показать диалог добавления счёта.
  static Future<bool?> show(
    BuildContext context, {
    required String requestId,
  }) {
    final isDesktop = ResponsiveUtils.isDesktop(context);
    final child = PurchaseRequestInvoiceDialog(requestId: requestId);

    if (isDesktop) {
      return showDialog<bool?>(
        context: context,
        builder: (_) => Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(24),
          child: child,
        ),
      );
    }

    return showModalBottomSheet<bool?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => child,
    );
  }

  @override
  ConsumerState<PurchaseRequestInvoiceDialog> createState() =>
      _PurchaseRequestInvoiceDialogState();
}

class _PurchaseRequestInvoiceDialogState
    extends ConsumerState<PurchaseRequestInvoiceDialog> {
  Contractor? _supplier;
  final _amountController = TextEditingController();
  final _numberController = TextEditingController();
  final _dateController = TextEditingController();
  final _commentController = TextEditingController();
  XFile? _selectedFile;
  bool _saving = false;

  @override
  void dispose() {
    _amountController.dispose();
    _numberController.dispose();
    _dateController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    final file = await openFile(
      acceptedTypeGroups: const [
        XTypeGroup(
          label: 'Счёт (PDF или изображение)',
          extensions: purchaseRequestInvoiceAcceptedExtensions,
        ),
      ],
    );
    if (!mounted || file == null) return;
    setState(() => _selectedFile = file);
  }

  Future<void> _save() async {
    if (_supplier == null) {
      AppSnackBar.show(
        context: context,
        message: 'Выберите поставщика',
        kind: AppSnackBarKind.error,
      );
      return;
    }

    final amount =
        double.tryParse(_amountController.text.trim().replaceAll(',', '.'));
    if (amount == null || amount <= 0) {
      AppSnackBar.show(
        context: context,
        message: 'Укажите сумму счёта больше нуля',
        kind: AppSnackBarKind.error,
      );
      return;
    }

    if (_selectedFile == null) {
      AppSnackBar.show(
        context: context,
        message: 'Прикрепите файл счёта',
        kind: AppSnackBarKind.error,
      );
      return;
    }

    final dateText = _dateController.text.trim();
    final invoiceDate =
        dateText.isEmpty ? null : parseDate(dateText, 'dd.MM.yyyy');
    if (dateText.isNotEmpty && invoiceDate == null) {
      AppSnackBar.show(
        context: context,
        message: 'Дата счёта: формат dd.MM.yyyy',
        kind: AppSnackBarKind.error,
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final bytes = await _selectedFile!.readAsBytes();
      await ref.read(purchaseRequestRepositoryProvider).createInvoiceWithFile(
            requestId: widget.requestId,
            supplierId: _supplier!.id,
            amount: amount,
            fileBytes: bytes,
            fileName: _selectedFile!.name,
            invoiceNumber: _numberController.text.trim().isEmpty
                ? null
                : _numberController.text.trim(),
            invoiceDate: invoiceDate,
            comment: _commentController.text.trim().isEmpty
                ? null
                : _commentController.text.trim(),
          );
      invalidatePurchaseRequestCaches(ref, widget.requestId);
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;
      AppSnackBar.show(
        context: context,
        message: formatSupabaseErrorMessage(error),
        kind: AppSnackBarKind.error,
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final contractorState = ref.watch(contractorNotifierProvider);
    final suppliers = contractorState.contractors
        .where((c) => c.type == ContractorType.supplier)
        .toList()
      ..sort(
        (a, b) =>
            a.shortName.toLowerCase().compareTo(b.shortName.toLowerCase()),
      );

    final form = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        GTDropdown<Contractor>(
          labelText: 'Поставщик *',
          hintText: 'Выберите поставщика',
          selectedItem: _supplier,
          items: suppliers,
          itemDisplayBuilder: (item) => item.shortName,
          onSelectionChanged: (value) => setState(() => _supplier = value),
        ),
        const SizedBox(height: 16),
        GTTextField(
          controller: _amountController,
          labelText: 'Сумма счёта *',
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
        ),
        const SizedBox(height: 16),
        GTTextField(
          controller: _numberController,
          labelText: 'Номер счёта',
        ),
        const SizedBox(height: 16),
        GTTextField(
          controller: _dateController,
          labelText: 'Дата счёта',
          hintText: 'dd.MM.yyyy',
        ),
        const SizedBox(height: 16),
        GTTextField(
          controller: _commentController,
          labelText: 'Комментарий',
          maxLines: 2,
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: GTSecondaryButton(
                text: _selectedFile == null ? 'Выбрать файл *' : 'Заменить файл',
                icon: Icons.attach_file_rounded,
                onPressed: _saving ? null : _pickFile,
              ),
            ),
          ],
        ),
        if (_selectedFile != null) ...[
          const SizedBox(height: 8),
          Text(
            _selectedFile!.name,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ],
    );

    final footer = Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        GTSecondaryButton(
          text: 'Отмена',
          onPressed: _saving ? null : () => Navigator.pop(context),
        ),
        const SizedBox(width: 12),
        GTPrimaryButton(
          text: 'Сохранить',
          isLoading: _saving,
          onPressed: _saving ? null : _save,
        ),
      ],
    );

    if (ResponsiveUtils.isDesktop(context)) {
      return DesktopDialogContent(
        title: 'Добавить счёт',
        width: 560,
        footer: footer,
        child: form,
      );
    }

    return MobileBottomSheetContent(
      title: 'Добавить счёт',
      footer: footer,
      child: form,
    );
  }
}
