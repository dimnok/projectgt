import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:projectgt/core/widgets/app_snackbar.dart';
import 'package:projectgt/core/widgets/desktop_dialog_content.dart';
import 'package:projectgt/core/widgets/gt_buttons.dart';
import 'package:projectgt/core/widgets/gt_dropdown.dart';
import 'package:projectgt/core/widgets/gt_text_field.dart';
import 'package:projectgt/domain/entities/contract_document_status.dart';
import 'package:projectgt/core/widgets/mobile_bottom_sheet_content.dart';
import 'package:projectgt/domain/entities/contract_file.dart';
import 'package:projectgt/features/contracts/presentation/constants/contract_file_dialog_width.dart';
import 'package:projectgt/features/contracts/presentation/providers/contract_files_providers.dart';

/// Делит полное имя файла на часть для ввода и суффикс с точкой (например `.pdf`).
({String base, String extensionDot}) _splitDisplayName(String fullName) {
  final t = fullName.trim();
  final dot = t.lastIndexOf('.');
  if (dot <= 0 || dot >= t.length - 1) {
    return (base: t, extensionDot: '');
  }
  return (base: t.substring(0, dot), extensionDot: t.substring(dot));
}

/// Диалог редактирования отображаемого имени и примечания к файлу договора.
///
/// Показывается по центру на десктопе и снизу листом на мобильных. Расширение
/// отображается отдельно в поле ввода ([GTTextField.suffixText]), как при загрузке;
/// физический файл в хранилище не переименовывается.
class ContractFileEditDialog extends ConsumerStatefulWidget {
  /// Идентификатор договора (для провайдера списка файлов).
  final String contractId;

  /// Редактируемый файл.
  final ContractFile file;

  /// Создаёт диалог.
  const ContractFileEditDialog({
    super.key,
    required this.contractId,
    required this.file,
  });

  /// Показывает диалог. Возвращает `true`, если пользователь сохранил изменения.
  static Future<bool?> show({
    required BuildContext context,
    required String contractId,
    required ContractFile file,
  }) {
    final isDesktop = MediaQuery.sizeOf(context).width >= 900;
    if (isDesktop) {
      return showDialog<bool>(
        context: context,
        barrierColor: Colors.black.withValues(alpha: 0.6),
        builder: (context) => Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: ContractFileEditDialog(
            contractId: contractId,
            file: file,
          ),
        ),
      );
    }
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      builder: (context) => ContractFileEditDialog(
        contractId: contractId,
        file: file,
      ),
    );
  }

  @override
  ConsumerState<ContractFileEditDialog> createState() =>
      _ContractFileEditDialogState();
}

class _ContractFileEditDialogState extends ConsumerState<ContractFileEditDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _versionController;
  late ContractDocumentStatus _documentStatus;
  late bool _isAmendment;
  /// Суффикс с точкой (например `.xlsx`); пусто, если в исходном имени не было расширения.
  late final String _extensionDot;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final parts = _splitDisplayName(widget.file.name);
    _extensionDot = parts.extensionDot;
    _nameController = TextEditingController(text: parts.base);
    _descriptionController = TextEditingController(
      text: widget.file.description ?? '',
    );
    _versionController = TextEditingController(
      text: widget.file.documentVersion.toString(),
    );
    _documentStatus = widget.file.documentStatus;
    _isAmendment = widget.file.isAmendment;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _versionController.dispose();
    super.dispose();
  }

  String? _validateName(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Введите наименование файла';
    return null;
  }

  String _composeFullFileName() {
    final base = _nameController.text.trim();
    return _extensionDot.isEmpty ? base : '$base$_extensionDot';
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final desc = _descriptionController.text.trim();
      final versionParsed = int.tryParse(_versionController.text.trim());
      if (versionParsed == null || versionParsed < 1) {
        if (!mounted) return;
        AppSnackBar.show(
          context: context,
          message: 'Версия — целое число не меньше 1',
          kind: AppSnackBarKind.error,
        );
        setState(() => _saving = false);
        return;
      }
      await ref
          .read(contractFilesProvider(widget.contractId).notifier)
          .updateFileMetadata(
            fileId: widget.file.id,
            name: _composeFullFileName(),
            description: desc.isEmpty ? null : desc,
            documentStatus: _documentStatus,
            documentVersion: versionParsed,
            isAmendment: _isAmendment,
          );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      AppSnackBar.show(
        context: context,
        message: 'Не удалось сохранить: $e',
        kind: AppSnackBarKind.error,
      );
      setState(() => _saving = false);
    }
  }

  Widget _formBody(ThemeData theme) {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GTTextField(
            controller: _nameController,
            labelText: 'Наименование файла',
            hintText: 'Введите название',
            suffixText: _extensionDot.isEmpty ? null : _extensionDot,
            enabled: !_saving,
            textInputAction: TextInputAction.next,
            helperText: _extensionDot.isEmpty
                ? null
                : 'Расширение справа не меняется.',
            validator: _validateName,
          ),
          const SizedBox(height: 16),
          GTTextField(
            controller: _descriptionController,
            labelText: 'Примечание',
            hintText: 'Необязательно',
            enabled: !_saving,
            maxLines: 4,
            keyboardType: TextInputType.multiline,
            textInputAction: TextInputAction.newline,
          ),
          const SizedBox(height: 16),
          GTEnumDropdown<ContractDocumentStatus>(
            values: ContractDocumentStatus.values,
            selectedValue: _documentStatus,
            onChanged: (v) {
              if (v != null) setState(() => _documentStatus = v);
            },
            labelText: 'Статус',
            hintText: 'Выберите статус',
            allowClear: false,
            enumToString: (e) => e.ruLabel,
            readOnly: _saving,
          ),
          const SizedBox(height: 16),
          GTTextField(
            controller: _versionController,
            labelText: 'Версия (номер)',
            hintText: '1',
            enabled: !_saving,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.done,
          ),
          const SizedBox(height: 12),
          InkWell(
            onTap: _saving ? null : () => setState(() => _isAmendment = !_isAmendment),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  SizedBox(
                    height: 32,
                    child: Switch.adaptive(
                      value: _isAmendment,
                      onChanged: _saving
                          ? null
                          : (v) => setState(() => _isAmendment = v),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Новая редакция (пометка «изм.»)',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.85),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDesktop = MediaQuery.sizeOf(context).width >= 900;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    final scrollableForm = SingleChildScrollView(
      padding: EdgeInsets.only(bottom: bottomInset > 0 ? 8 : 0),
      child: _formBody(theme),
    );

    if (isDesktop) {
      return DesktopDialogContent(
        title: 'Редактирование',
        width: kContractFileDesktopDialogWidth,
        scrollable: true,
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
              text: 'Сохранить',
              isLoading: _saving,
              onPressed: _submit,
            ),
          ],
        ),
        child: scrollableForm,
      );
    }

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: MobileBottomSheetContent(
        title: 'Редактирование',
        scrollable: false,
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
        footer: Column(
          children: [
            SizedBox(
              width: double.infinity,
              child: GTPrimaryButton(
                text: 'Сохранить',
                isLoading: _saving,
                onPressed: _submit,
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
        child: scrollableForm,
      ),
    );
  }
}
