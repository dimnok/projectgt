import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:projectgt/core/utils/responsive_utils.dart';
import 'package:projectgt/core/utils/snackbar_utils.dart';
import 'package:projectgt/core/widgets/desktop_dialog_content.dart';
import 'package:projectgt/core/widgets/gt_buttons.dart';
import 'package:projectgt/core/widgets/gt_dropdown.dart';
import 'package:projectgt/core/widgets/gt_text_field.dart';
import 'package:projectgt/core/widgets/mobile_bottom_sheet_content.dart';
import 'package:projectgt/features/fot/presentation/services/payroll_payout_excel_import_service.dart';
import 'package:projectgt/features/fot/presentation/utils/payroll_payout_batch_save.dart';
import 'package:projectgt/features/fot/presentation/widgets/payroll_payout_form_modal.dart';
import 'package:projectgt/features/fot/presentation/widgets/payroll_payout_import_preview_dialog.dart';
import 'package:projectgt/presentation/state/employee_state.dart';

/// Диалог импорта выплат из Excel: параметры выплаты и выбор файла.
class PayrollPayoutExcelImportDialog extends ConsumerStatefulWidget {
  /// Создаёт диалог импорта.
  const PayrollPayoutExcelImportDialog({super.key});

  @override
  ConsumerState<PayrollPayoutExcelImportDialog> createState() =>
      _PayrollPayoutExcelImportDialogState();
}

class _PayrollPayoutExcelImportDialogState
    extends ConsumerState<PayrollPayoutExcelImportDialog> {
  final _formKey = GlobalKey<FormState>();
  final _commentController = TextEditingController();
  final _dateController = TextEditingController();

  DateTime? _selectedDate;
  PaymentMethod _selectedMethod = PaymentMethod.values.first;
  PaymentType _selectedType = PaymentType.values.first;
  bool _pickingFile = false;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _updateDateController();
  }

  @override
  void dispose() {
    _commentController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  void _updateDateController() {
    _dateController.text = _selectedDate != null
        ? DateFormat('dd.MM.yyyy').format(_selectedDate!)
        : '';
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 1),
      locale: const Locale('ru'),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _updateDateController();
      });
    }
  }

  Future<void> _pickExcelAndPreview() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDate == null) return;

    setState(() => _pickingFile = true);
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx'],
        withData: true,
      );
      if (result == null || result.files.isEmpty) return;

      final file = result.files.first;
      final bytes = file.bytes;
      if (bytes == null || bytes.isEmpty) {
        if (mounted) {
          SnackBarUtils.showError(context, 'Не удалось прочитать файл');
        }
        return;
      }

      final employees = ref.read(employeeProvider).employees;
      if (employees.isEmpty) {
        if (mounted) {
          SnackBarUtils.showWarning(
            context,
            'Справочник сотрудников пуст — загрузите сотрудников',
          );
        }
        return;
      }

      final parseResult = PayrollPayoutExcelImportService.parseAndMatch(
        bytes,
        employees,
      );

      if (!mounted) return;

      final batchParams = PayrollPayoutBatchParams(
        payoutDate: _selectedDate!,
        method: _selectedMethod.value,
        type: _selectedType.value,
        comment: _commentController.text.trim(),
      );

      final imported = await showDialog<bool>(
        context: context,
        builder: (ctx) => PayrollPayoutImportPreviewDialog(
          parseResult: parseResult,
          batchParams: batchParams,
        ),
      );

      if (imported == true && mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        SnackBarUtils.showError(context, e.toString());
      }
    } finally {
      if (mounted) setState(() => _pickingFile = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDesktop = ResponsiveUtils.isDesktop(context);
    const title = 'Импорт выплат из Excel';

    final content = Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Выберите параметры выплаты, затем файл ведомости (.xlsx). '
            'Ожидаются колонки «ФИО» и «Сумма» (Фамилия Имя Отчество).',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 16),
          GTTextField(
            controller: _dateController,
            labelText: 'Дата выплаты',
            prefixIcon: Icons.event,
            readOnly: true,
            onTap: _pickDate,
            validator: (_) =>
                _selectedDate == null ? 'Выберите дату выплаты' : null,
          ),
          const SizedBox(height: 16),
          GTDropdown<PaymentMethod>(
            items: PaymentMethod.values,
            itemDisplayBuilder: (m) => m.displayName,
            selectedItem: _selectedMethod,
            onSelectionChanged: (m) {
              setState(() => _selectedMethod = m ?? PaymentMethod.values.first);
            },
            labelText: 'Способ выплаты',
            hintText: 'Выберите способ выплаты',
            allowClear: false,
          ),
          const SizedBox(height: 16),
          GTDropdown<PaymentType>(
            items: PaymentType.values,
            itemDisplayBuilder: (t) => t.displayName,
            selectedItem: _selectedType,
            onSelectionChanged: (t) {
              setState(() => _selectedType = t ?? PaymentType.values.first);
            },
            labelText: 'Тип выплаты',
            hintText: 'Выберите тип выплаты',
            allowClear: false,
          ),
          const SizedBox(height: 16),
          GTTextField(
            controller: _commentController,
            labelText: 'Комментарий',
            prefixIcon: Icons.comment_outlined,
            maxLines: 2,
          ),
        ],
      ),
    );

    final footer = Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        GTTextButton(
          text: 'Отмена',
          onPressed: _pickingFile ? null : () => Navigator.pop(context),
        ),
        const SizedBox(width: 8),
        GTPrimaryButton(
          text: 'Выбрать файл',
          icon: Icons.upload_file_outlined,
          isLoading: _pickingFile,
          onPressed: _pickingFile ? null : _pickExcelAndPreview,
        ),
      ],
    );

    if (isDesktop) {
      return Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: DesktopDialogContent(
          title: title,
          footer: footer,
          width: 480,
          child: content,
        ),
      );
    }

    return MobileBottomSheetContent(
      title: title,
      footer: footer,
      child: content,
    );
  }
}
