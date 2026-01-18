import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:projectgt/core/widgets/desktop_dialog_content.dart';
import 'package:projectgt/core/widgets/mobile_bottom_sheet_content.dart';
import 'package:projectgt/core/widgets/gt_buttons.dart';
import 'package:projectgt/core/widgets/gt_text_field.dart';
import 'package:projectgt/core/widgets/app_snackbar.dart';
import 'package:projectgt/features/company/domain/entities/company_document.dart';
import 'package:projectgt/features/company/presentation/providers/company_providers.dart';
import 'package:projectgt/core/utils/formatters.dart';

/// Диалоговое окно для добавления или редактирования документа.
class CompanyDocumentEditDialog extends ConsumerStatefulWidget {
  /// Идентификатор компании.
  final String companyId;

  /// Редактируемый документ (null при создании нового).
  final CompanyDocument? document;

  /// Создаёт диалог.
  const CompanyDocumentEditDialog({
    super.key,
    required this.companyId,
    this.document,
  });

  /// Показывает диалог адаптивно (Dialog на Desktop, BottomSheet на Mobile).
  static void show(BuildContext context, String companyId,
      {CompanyDocument? document}) {
    final isDesktop = MediaQuery.of(context).size.width >= 800;

    if (isDesktop) {
      showDialog(
        context: context,
        builder: (context) => Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(24),
          child: CompanyDocumentEditDialog(
            companyId: companyId,
            document: document,
          ),
        ),
      );
    } else {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        backgroundColor: Colors.transparent,
        builder: (context) => CompanyDocumentEditDialog(
          companyId: companyId,
          document: document,
        ),
      );
    }
  }

  @override
  ConsumerState<CompanyDocumentEditDialog> createState() =>
      _CompanyDocumentEditDialogState();
}

class _CompanyDocumentEditDialogState
    extends ConsumerState<CompanyDocumentEditDialog> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  late TextEditingController _titleController;
  late TextEditingController _numberController;
  late TextEditingController _typeController;
  DateTime? _issueDate;

  @override
  void initState() {
    super.initState();
    final d = widget.document;
    _titleController = TextEditingController(text: d?.title);
    _numberController = TextEditingController(text: d?.number);
    _typeController = TextEditingController(text: d?.type);
    _issueDate = d?.issueDate;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _numberController.dispose();
    _typeController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _issueDate ?? DateTime.now(),
      firstDate: DateTime(1990),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => _issueDate = picked);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final repo = ref.read(companyRepositoryProvider);

      if (widget.document != null) {
        final updated = widget.document!.copyWith(
          title: _titleController.text,
          number: _numberController.text,
          type: _typeController.text,
          issueDate: _issueDate,
        );
        await repo.updateDocument(updated);
      } else {
        final newDoc = CompanyDocument(
          id: '',
          companyId: widget.companyId,
          title: _titleController.text,
          number: _numberController.text,
          type: _typeController.text,
          issueDate: _issueDate,
        );
        await repo.addDocument(newDoc);
      }

      ref.invalidate(companyDocumentsProvider);

      if (mounted) {
        Navigator.of(context).pop();
        AppSnackBar.show(
          context: context,
          message: 'Документ сохранен',
          kind: AppSnackBarKind.success,
        );
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.show(
          context: context,
          message: 'Ошибка при сохранении: $e',
          kind: AppSnackBarKind.error,
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 800;
    final title = widget.document == null
        ? 'Добавление документа'
        : 'Редактирование документа';

    final content = Form(
      key: _formKey,
      child: Column(
        children: [
          GTTextField(
            controller: _titleController,
            labelText: 'Название документа',
            prefixIcon: CupertinoIcons.doc_text,
            enabled: !_isLoading,
            validator: (v) =>
                v == null || v.isEmpty ? 'Введите название' : null,
          ),
          const SizedBox(height: 16),
          GTTextField(
            controller: _numberController,
            labelText: 'Номер документа',
            prefixIcon: CupertinoIcons.number,
            enabled: !_isLoading,
          ),
          const SizedBox(height: 16),
          GTTextField(
            controller: _typeController,
            labelText: 'Тип (Лицензия, СРО и т.д.)',
            prefixIcon: CupertinoIcons.tag,
            enabled: !_isLoading,
          ),
          const SizedBox(height: 16),
          InkWell(
            onTap: _isLoading ? null : _selectDate,
            borderRadius: BorderRadius.circular(16),
            child: InputDecorator(
              decoration: InputDecoration(
                labelText: 'Дата выдачи',
                prefixIcon: const Icon(CupertinoIcons.calendar, size: 20),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(
                _issueDate == null ? 'Не выбрана' : formatRuDate(_issueDate!),
              ),
            ),
          ),
        ],
      ),
    );

    if (isDesktop) {
      return DesktopDialogContent(
        title: title,
        footer: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            GTSecondaryButton(
              text: 'Отмена',
              onPressed: () => Navigator.pop(context),
            ),
            const SizedBox(width: 16),
            GTPrimaryButton(
              text: 'Сохранить',
              isLoading: _isLoading,
              onPressed: _save,
            ),
          ],
        ),
        child: content,
      );
    } else {
      return MobileBottomSheetContent(
        title: title,
        footer: GTPrimaryButton(
          text: 'Сохранить',
          isLoading: _isLoading,
          onPressed: _save,
        ),
        child: content,
      );
    }
  }
}

