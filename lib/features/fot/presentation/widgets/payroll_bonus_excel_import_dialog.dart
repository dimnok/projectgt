import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:projectgt/core/di/providers.dart';
import 'package:projectgt/core/utils/formatters.dart';
import 'package:projectgt/core/utils/responsive_utils.dart';
import 'package:projectgt/core/utils/snackbar_utils.dart';
import 'package:projectgt/core/widgets/desktop_dialog_content.dart';
import 'package:projectgt/core/widgets/gt_buttons.dart';
import 'package:projectgt/core/widgets/gt_dropdown.dart';
import 'package:projectgt/core/widgets/gt_text_field.dart';
import 'package:projectgt/core/widgets/mobile_bottom_sheet_content.dart';
import 'package:projectgt/features/fot/presentation/providers/payroll_filter_providers.dart';
import 'package:projectgt/features/fot/presentation/services/payroll_payout_excel_import_service.dart';
import 'package:projectgt/features/fot/presentation/utils/payroll_bonus_batch_save.dart';
import 'package:projectgt/features/fot/presentation/widgets/payroll_payout_import_preview_dialog.dart';
import 'package:projectgt/features/objects/domain/entities/object.dart';
import 'package:projectgt/presentation/state/employee_state.dart';

/// Диалог импорта премий из Excel: параметры премии и выбор файла.
class PayrollBonusExcelImportDialog extends ConsumerStatefulWidget {
  /// Создаёт диалог импорта.
  const PayrollBonusExcelImportDialog({super.key});

  @override
  ConsumerState<PayrollBonusExcelImportDialog> createState() =>
      _PayrollBonusExcelImportDialogState();
}

class _PayrollBonusExcelImportDialogState
    extends ConsumerState<PayrollBonusExcelImportDialog> {
  final _formKey = GlobalKey<FormState>();
  final _commentController = TextEditingController();
  final _dateController = TextEditingController();

  DateTime? _selectedDate;
  ObjectEntity? _selectedObject;
  bool _pickingFile = false;

  @override
  void initState() {
    super.initState();
    final filter = ref.read(payrollFilterProvider);
    final now = DateTime.now();
    if (filter.selectedYear == now.year && filter.selectedMonth == now.month) {
      _selectedDate = now;
    } else {
      _selectedDate = DateTime(filter.selectedYear, filter.selectedMonth, 1);
    }
    _updateDateController();

    final selectedIds = filter.selectedObjectIds;
    if (selectedIds.length == 1) {
      _selectedObject = ref
          .read(objectProvider)
          .objects
          .where((o) => o.id == selectedIds.first)
          .firstOrNull;
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  void _updateDateController() {
    _dateController.text =
        _selectedDate != null ? formatRuDate(_selectedDate!) : '';
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: DateTime(now.year - 2),
      lastDate: DateTime(now.year + 2),
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
    if (_selectedDate == null || _selectedObject == null) return;

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

      final batchParams = PayrollBonusBatchParams(
        date: _selectedDate!,
        objectId: _selectedObject!.id,
        reason: _commentController.text.trim(),
      );

      final imported = await showDialog<bool>(
        context: context,
        builder: (ctx) => PayrollPayoutImportPreviewDialog(
          parseResult: parseResult,
          onImport: (entries) => savePayrollBonusBatch(
            ref: ref,
            params: batchParams,
            entries: entries,
          ),
          createActionLabel: 'Создать премии',
          successMessage: (count) => 'Создано премий: $count',
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
    const title = 'Импорт премий из Excel';

    final objects = List<ObjectEntity>.from(ref.watch(objectProvider).objects)
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

    final content = Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Укажите дату, объект и примечание, затем файл ведомости (.xlsx). '
            'Ожидаются колонки «ФИО» и «Сумма» (Фамилия Имя Отчество).',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 16),
          GTTextField(
            controller: _dateController,
            labelText: 'Дата',
            prefixIcon: Icons.event,
            readOnly: true,
            onTap: _pickDate,
            validator: (_) =>
                _selectedDate == null ? 'Выберите дату' : null,
          ),
          const SizedBox(height: 16),
          GTDropdown<ObjectEntity>(
            items: objects,
            itemDisplayBuilder: (o) => o.name,
            selectedItem: _selectedObject,
            onSelectionChanged: (object) {
              setState(() => _selectedObject = object);
            },
            labelText: 'Объект',
            hintText: objects.isEmpty
                ? 'Нет доступных объектов'
                : 'Выберите объект',
            allowClear: false,
            validator: (_) =>
                _selectedObject == null ? 'Выберите объект' : null,
          ),
          const SizedBox(height: 16),
          GTTextField(
            controller: _commentController,
            labelText: 'Примечание',
            prefixIcon: Icons.comment_outlined,
            hintText: 'Причина или комментарий',
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
