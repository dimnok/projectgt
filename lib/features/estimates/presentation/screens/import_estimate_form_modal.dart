import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:projectgt/core/di/providers.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:excel/excel.dart' as excel;
import 'dart:typed_data';
import 'package:projectgt/data/models/estimate_model.dart';
import 'package:projectgt/data/services/excel_estimate_service.dart';
import 'package:intl/intl.dart';
import 'package:file_saver/file_saver.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io';
import 'package:path_provider/path_provider.dart' as path_provider;
import 'package:share_plus/share_plus.dart';
import 'package:projectgt/core/utils/snackbar_utils.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/mobile_bottom_sheet_content.dart';
import '../../../../core/widgets/desktop_dialog_content.dart';
import '../../../../core/widgets/gt_buttons.dart';

/// Модальное окно для импорта сметы из Excel файла.
class ImportEstimateFormModal extends ConsumerStatefulWidget {
  /// Коллбек, вызываемый при успешном импорте.
  final VoidCallback onSuccess;

  /// Коллбек, вызываемый при отмене или закрытии окна.
  final VoidCallback onCancel;

  /// Создаёт модальное окно импорта сметы.
  const ImportEstimateFormModal({
    super.key,
    required this.onSuccess,
    required this.onCancel,
  });

  /// Показывает модальное окно импорта.
  ///
  /// Адаптируется под размер экрана (Dialog для Desktop, BottomSheet для Mobile).
  static void show(BuildContext context, WidgetRef ref,
      {required VoidCallback onSuccess}) {
    final isLargeScreen = MediaQuery.of(context).size.width > 900;

    if (isLargeScreen) {
      showDialog(
        context: context,
        builder: (context) => Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(24),
          child: ImportEstimateFormModal(
            onSuccess: onSuccess,
            onCancel: () => context.pop(),
          ),
        ),
      );
    } else {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        backgroundColor: Colors.transparent,
        builder: (context) => ImportEstimateFormModal(
          onSuccess: onSuccess,
          onCancel: () => context.pop(),
        ),
      );
    }
  }

  @override
  ConsumerState<ImportEstimateFormModal> createState() =>
      _ImportEstimateFormModalState();
}

class _ImportEstimateFormModalState
    extends ConsumerState<ImportEstimateFormModal> {
  String? selectedObjectId;
  String? selectedContractId;
  String? estimateName;
  PlatformFile? pickedFile;
  final formKey = GlobalKey<FormState>();
  bool isLoading = false;
  late final TextEditingController _objectController;
  late final TextEditingController _contractController;
  late final TextEditingController _estimateNameController;

  List<String> _existingEstimateTitles = [];
  List<String> _filteredEstimateTitles = [];
  bool _loadingEstimateTitles = false;

  bool _showPreview = false;
  ExcelPreviewResult? _previewData;
  ExcelValidationResult? _validationResult;
  int _currentStep = 0;
  bool _isImporting = false;
  int _importedRows = 0;
  int _totalRows = 0;
  String _importStatus = '';
  bool _validationPassed = false;

  final NumberFormat moneyFormat = NumberFormat.currency(
    locale: 'ru_RU',
    symbol: '₽',
    decimalDigits: 2,
  );

  @override
  void initState() {
    super.initState();
    _objectController = TextEditingController();
    _contractController = TextEditingController();
    _estimateNameController = TextEditingController();
    _loadExistingEstimateTitles();
  }

  @override
  void dispose() {
    _objectController.dispose();
    _contractController.dispose();
    _estimateNameController.dispose();
    super.dispose();
  }

  Future<void> _loadExistingEstimateTitles() async {
    setState(() => _loadingEstimateTitles = true);
    try {
      final estimates = ref.read(estimateNotifierProvider).estimates;
      final titles = <String>{};
      for (final estimate in estimates) {
        if (estimate.estimateTitle != null &&
            estimate.estimateTitle!.isNotEmpty) {
          titles.add(estimate.estimateTitle!);
        }
      }
      setState(() {
        _existingEstimateTitles = titles.toList()..sort();
        _filteredEstimateTitles = _existingEstimateTitles;
        _loadingEstimateTitles = false;
      });
    } catch (e) {
      setState(() => _loadingEstimateTitles = false);
    }
  }

  void _updateFilteredEstimates() {
    final estimates = ref.read(estimateNotifierProvider).estimates;
    if (selectedObjectId == null) {
      _filteredEstimateTitles = _existingEstimateTitles;
      return;
    }
    final filteredTitles = <String>{};
    for (final estimate in estimates) {
      if (estimate.estimateTitle != null &&
          estimate.estimateTitle!.isNotEmpty &&
          estimate.objectId == selectedObjectId &&
          (selectedContractId == null ||
              estimate.contractId == selectedContractId)) {
        filteredTitles.add(estimate.estimateTitle!);
      }
    }
    _filteredEstimateTitles = filteredTitles.toList()..sort();
  }

  List<String> _getFilteredContracts(String pattern) {
    final contractState = ref.read(contractProvider);
    final searchPattern = pattern.toLowerCase().trim();

    return contractState.contracts
        .where((c) {
          // Если выбран объект, показываем только его договоры
          if (selectedObjectId != null && c.objectId != selectedObjectId) {
            return false;
          }
          return c.number.toLowerCase().contains(searchPattern);
        })
        .map((c) => c.number)
        .toSet()
        .toList();
  }

  void _resetContractSelection() {
    selectedContractId = null;
    _contractController.text = '';
  }

  void _updateEstimateInfo(String title) {
    final estimates = ref.read(estimateNotifierProvider).estimates;
    final selectedEstimate = estimates.firstWhere(
      (e) => e.estimateTitle == title,
      orElse: () => estimates.first,
    );
    final objectId = selectedEstimate.objectId;
    final contractId = selectedEstimate.contractId;

    setState(() {
      if (objectId != null) {
        final objects = ref.read(objectProvider).objects;
        final selectedObject = objects.firstWhere(
          (o) => o.id == objectId,
          orElse: () => objects.first,
        );
        selectedObjectId = objectId;
        _objectController.text = selectedObject.name;
      }

      if (contractId != null) {
        final contracts = ref.read(contractProvider).contracts;
        final selectedContract = contracts.firstWhere(
          (c) => c.id == contractId,
          orElse: () => contracts.first,
        );
        selectedContractId = contractId;
        _contractController.text = selectedContract.number;
      }

      _updateFilteredEstimates();
    });
  }

  Future<void> _downloadTemplate() async {
    try {
      setState(() => isLoading = true);
      final bytes = await ExcelEstimateService.loadTemplateFromFileSystem();

      if (kIsWeb) {
        await FileSaver.instance.saveFile(
          name: 'estimate_template.xlsx',
          bytes: bytes,
          mimeType: MimeType.microsoftExcel,
        );
      } else {
        final directory = await path_provider.getTemporaryDirectory();
        final path = '${directory.path}/estimate_template.xlsx';
        final file = File(path);
        await file.writeAsBytes(bytes);
        await SharePlus.instance.share(
          ShareParams(
            files: [XFile(path)],
            text: 'Шаблон сметы для заполнения',
          ),
        );
      }
      if (!mounted) return;
      SnackBarUtils.showSuccess(context, 'Шаблон сметы успешно скачан');
    } catch (e) {
      if (!mounted) return;
      SnackBarUtils.showError(context, 'Ошибка при скачивании шаблона: $e');
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _pickExcelFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx'],
        withData: true,
      );

      if (result != null && result.files.single.bytes != null) {
        setState(() {
          pickedFile = result.files.single;
          _showPreview = false;
          _previewData = null;
          _validationResult = null;
          _validationPassed = false;
        });
        await _validateFile();
      }
    } catch (e) {
      if (!mounted) return;
      SnackBarUtils.showError(context, 'Ошибка при выборе файла: $e');
    }
  }

  Future<void> _validateFile() async {
    if (pickedFile?.bytes == null) return;
    setState(() => isLoading = true);
    try {
      final bytes = Uint8List.fromList(pickedFile!.bytes!);
      final validationResult = ExcelEstimateService.validateExcelFile(bytes);
      final previewData = ExcelEstimateService.preparePreview(bytes);
      setState(() {
        _validationResult = validationResult;
        _previewData = previewData;
        _showPreview = true;
        _validationPassed = validationResult.isValid;
        _totalRows = previewData.rowCount;
      });
    } catch (e) {
      if (!mounted) return;
      SnackBarUtils.showError(context, 'Ошибка при обработке файла: $e');
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _importExcelData() async {
    if (!formKey.currentState!.validate() || pickedFile?.bytes == null) return;
    if (!_validationPassed &&
        _validationResult != null &&
        _validationResult!.errors.isNotEmpty) {
      SnackBarUtils.showError(
          context, 'Невозможно импортировать файл с ошибками структуры');
      return;
    }

    final userId = ref.read(supabaseClientProvider).auth.currentUser?.id;
    if (userId == null) {
      SnackBarUtils.showError(context, 'Не удалось определить пользователя');
      return;
    }

    final estimateTitle = _estimateNameController.text.trim();
    final isExistingEstimate = _filteredEstimateTitles.contains(estimateTitle);

    setState(() {
      _isImporting = true;
      _importedRows = 0;
      _importStatus = isExistingEstimate
          ? 'Добавление позиций в существующую смету...'
          : 'Начало импорта новой сметы...';
    });

    try {
      final bytes = Uint8List.fromList(pickedFile!.bytes!);
      final excelFile = excel.Excel.decodeBytes(bytes);
      final sheet = excelFile.tables[excelFile.tables.keys.first]!;
      final rows = sheet.rows.skip(1).toList();
      final estimateRepo = ref.read(estimateRepositoryProvider);

      _totalRows = rows.length;
      int successCount = 0;

      for (int i = 0; i < rows.length; i++) {
        if (!mounted) break;
        try {
          setState(() {
            _importedRows = i;
            _importStatus = 'Импорт строки ${i + 1} из $_totalRows...';
          });

          final row = rows[i];
          final modelData = ExcelEstimateService.rowToEstimateModel(
            row,
            selectedObjectId,
            selectedContractId,
            estimateTitle,
          );

          if (modelData != null) {
            final model = EstimateModel(
              system: modelData['system'],
              subsystem: modelData['subsystem'],
              number: modelData['number'],
              name: modelData['name'],
              article: modelData['article'],
              manufacturer: modelData['manufacturer'],
              unit: modelData['unit'],
              quantity: modelData['quantity'],
              price: modelData['price'],
              total: modelData['total'],
              objectId: modelData['objectId'],
              contractId: modelData['contractId'],
              estimateTitle: modelData['estimateTitle'],
            );

            await estimateRepo.createEstimate(model.toDomain());
            successCount++;
          }
        } catch (_) {}
      }

      setState(() => _importStatus = 'Сохранение файла...');
      final supabase = ref.read(supabaseClientProvider);
      final fileName = 'estimate_${DateTime.now().millisecondsSinceEpoch}.xlsx';
      await supabase.storage.from('estimates').uploadBinary(fileName, bytes);

      final completionMessage = isExistingEstimate
          ? 'Добавлено $successCount позиций в смету "$estimateTitle"'
          : 'Создана новая смета с $successCount позициями';

      setState(() => _importStatus = 'Импорт завершен успешно!');
      widget.onSuccess();

      if (!mounted) return;
      SnackBarUtils.showSuccess(context, completionMessage);
    } catch (e) {
      if (!mounted) return;
      setState(() => _importStatus = 'Ошибка импорта: $e');
      SnackBarUtils.showError(context, 'Ошибка импорта: $e');
    } finally {
      if (mounted) setState(() => _isImporting = false);
    }
  }

  Widget _buildStepIndicator(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        children: [
          _buildStepItem(theme, 0, 'Файл'),
          _buildStepDivider(theme, 0),
          _buildStepItem(theme, 1, 'Параметры'),
          _buildStepDivider(theme, 1),
          _buildStepItem(theme, 2, 'Импорт'),
        ],
      ),
    );
  }

  Widget _buildStepItem(ThemeData theme, int step, String label) {
    final isActive = _currentStep == step;
    final isCompleted = _currentStep > step;
    final color = isActive || isCompleted
        ? theme.colorScheme.primary
        : theme.colorScheme.outline.withValues(alpha: 0.5);

    return Expanded(
      child: Column(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isActive ? theme.colorScheme.primary : Colors.transparent,
              border: Border.all(
                color: color,
                width: 2,
              ),
            ),
            child: isCompleted
                ? Icon(CupertinoIcons.checkmark_alt,
                    size: 16, color: theme.colorScheme.primary)
                : isActive
                    ? Center(
                        child: Text(
                          '${step + 1}',
                          style: TextStyle(
                            color: theme.colorScheme.onPrimary,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      )
                    : Center(
                        child: Text(
                          '${step + 1}',
                          style: TextStyle(
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.5),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: isActive
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurface.withValues(alpha: 0.5),
              fontWeight: isActive ? FontWeight.bold : null,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildStepDivider(ThemeData theme, int step) {
    final isCompleted = _currentStep > step;
    return Container(
      width: 20,
      height: 2,
      color: isCompleted
          ? theme.colorScheme.primary
          : theme.colorScheme.outline.withValues(alpha: 0.2),
    );
  }

  Widget _buildStepContent(ThemeData theme) {
    switch (_currentStep) {
      case 0:
        return _buildFileStep(theme);
      case 1:
        return _buildParamsStep(theme);
      case 2:
        return _buildImportStep(theme);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildFileStep(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: GTPrimaryButton(
                text: pickedFile == null ? 'Выбрать файл' : 'Изменить файл',
                icon: CupertinoIcons.arrow_up_doc,
                onPressed: isLoading ? null : _pickExcelFile,
              ),
            ),
            const SizedBox(width: 16),
            IconButton(
              tooltip: 'Скачать шаблон Excel',
              icon: const Icon(CupertinoIcons.arrow_down_doc),
              onPressed: isLoading ? null : _downloadTemplate,
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (pickedFile != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Text('Файл: ${pickedFile!.name}',
                style: theme.textTheme.bodyMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
          ),
        if (_showPreview && _validationResult != null) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _validationResult!.isValid
                  ? theme.colorScheme.primaryContainer.withValues(alpha: 0.2)
                  : theme.colorScheme.errorContainer.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _validationResult!.isValid
                    ? theme.colorScheme.primary.withValues(alpha: 0.5)
                    : theme.colorScheme.error.withValues(alpha: 0.5),
              ),
            ),
            child: Text(
              _validationResult!.isValid
                  ? 'Файл прошел проверку'
                  : 'Исправьте ошибки в файле',
              style: TextStyle(
                color: _validationResult!.isValid
                    ? theme.colorScheme.primary
                    : theme.colorScheme.error,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (_validationResult!.errors.isNotEmpty) ...[
            Text('Ошибки:',
                style: TextStyle(
                    color: theme.colorScheme.error,
                    fontWeight: FontWeight.bold)),
            ...buildErrorsList(_validationResult!.errors),
            const SizedBox(height: 8),
          ],
          if (_validationResult!.isValid) ...[
            Text('Строк: ${_previewData?.rowCount ?? 0}'),
            Text(
                'Сумма: ${moneyFormat.format(_previewData?.totalAmount ?? 0)}'),
            const SizedBox(height: 16),
            const Text('Системы в смете:',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            if (_previewData?.systems.isNotEmpty ?? false)
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _previewData!.systems
                    .map((s) => Chip(
                          label: Text(s, style: const TextStyle(fontSize: 12)),
                          backgroundColor:
                              theme.colorScheme.surfaceContainerHighest,
                          side: BorderSide.none,
                          padding: EdgeInsets.zero,
                          visualDensity: VisualDensity.compact,
                        ))
                    .toList(),
              )
            else
              Text('Системы не найдены',
                  style: TextStyle(color: theme.colorScheme.outline)),
          ],
        ],
      ],
    );
  }

  Widget _buildParamsStep(ThemeData theme) {
    return _buildDataForm();
  }

  Widget _buildImportStep(ThemeData theme) {
    return Column(
      children: [
        if (_isImporting) ...[
          LinearProgressIndicator(
            value: _totalRows > 0 ? _importedRows / _totalRows : 0,
          ),
          const SizedBox(height: 16),
          Text(_importStatus),
        ] else ...[
          Text(_importStatus.isEmpty ? 'Готово к импорту' : _importStatus),
        ],
      ],
    );
  }

  List<Widget> buildErrorsList(List<String> messages) {
    return messages
        .map((message) => Padding(
              padding: const EdgeInsets.only(left: 8.0, top: 4.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('• '),
                  Expanded(child: Text(message)),
                ],
              ),
            ))
        .toList();
  }

  Widget _buildDataForm() {
    final objectState = ref.watch(objectProvider);
    final contractState = ref.watch(contractProvider);

    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TypeAheadField<String>(
            controller: _objectController,
            suggestionsCallback: (pattern) => objectState.objects
                .where(
                    (o) => o.name.toLowerCase().contains(pattern.toLowerCase()))
                .map((o) => o.name)
                .toList(),
            itemBuilder: (context, suggestion) =>
                ListTile(title: Text(suggestion)),
            onSelected: (suggestion) {
              final obj =
                  objectState.objects.firstWhere((o) => o.name == suggestion);
              setState(() {
                if (selectedObjectId != obj.id) _resetContractSelection();
                selectedObjectId = obj.id;
                _objectController.text = obj.name;
                _updateFilteredEstimates();
              });
            },
            builder: (context, controller, focusNode) => TextFormField(
              controller: controller,
              focusNode: focusNode,
              decoration: const InputDecoration(
                labelText: 'Объект *',
                hintText: 'Выберите объект',
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
                  selectedObjectId == null ? 'Выберите объект' : null,
            ),
          ),
          const SizedBox(height: 16),
          TypeAheadField<String>(
            key: ValueKey('contract_$selectedObjectId'),
            controller: _contractController,
            suggestionsCallback: (pattern) => _getFilteredContracts(pattern),
            itemBuilder: (context, suggestion) {
              // Ищем договор, соответствующий номеру и выбранному объекту
              final contract = contractState.contracts.firstWhere(
                (c) =>
                    c.number == suggestion &&
                    (selectedObjectId == null ||
                        c.objectId == selectedObjectId),
                orElse: () => contractState.contracts
                    .firstWhere((c) => c.number == suggestion),
              );
              return ListTile(
                title: Text(suggestion),
                subtitle: Text(contract.contractorName ?? "Без контрагента"),
              );
            },
            onSelected: (suggestion) {
              final contract = contractState.contracts.firstWhere(
                (c) =>
                    c.number == suggestion &&
                    (selectedObjectId == null ||
                        c.objectId == selectedObjectId),
                orElse: () => contractState.contracts
                    .firstWhere((c) => c.number == suggestion),
              );
              setState(() {
                selectedContractId = contract.id;
                _contractController.text = contract.number;
                _updateFilteredEstimates();
              });
            },
            builder: (context, controller, focusNode) => TextFormField(
              controller: controller,
              focusNode: focusNode,
              decoration: InputDecoration(
                labelText: 'Договор *',
                hintText: selectedObjectId == null
                    ? 'Сначала выберите объект'
                    : 'Выберите договор',
                border: const OutlineInputBorder(),
                enabled: selectedObjectId != null,
              ),
              validator: (v) =>
                  selectedContractId == null ? 'Выберите договор' : null,
            ),
          ),
          const SizedBox(height: 16),
          TypeAheadField<String>(
            controller: _estimateNameController,
            suggestionsCallback: (pattern) => _filteredEstimateTitles
                .where((t) => t.toLowerCase().contains(pattern.toLowerCase()))
                .toList(),
            itemBuilder: (context, suggestion) =>
                ListTile(title: Text(suggestion)),
            onSelected: (suggestion) {
              setState(() => _estimateNameController.text = suggestion);
              _updateEstimateInfo(suggestion);
            },
            builder: (context, controller, focusNode) => TextFormField(
              controller: controller,
              focusNode: focusNode,
              decoration: InputDecoration(
                labelText: 'Название сметы *',
                hintText: 'Выберите или введите новую',
                border: const OutlineInputBorder(),
                suffixIcon: _loadingEstimateTitles
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: Padding(
                          padding: EdgeInsets.all(8.0),
                          child: CupertinoActivityIndicator(),
                        ),
                      )
                    : null,
              ),
              validator: (v) =>
                  (v == null || v.isEmpty) ? 'Введите название' : null,
            ),
          ),
        ],
      ),
    );
  }

  void _goNext() {
    if (_currentStep == 0) {
      if (pickedFile == null ||
          !_validationPassed ||
          _validationResult == null ||
          !_validationResult!.isValid) {
        SnackBarUtils.showError(context, 'Выберите корректный файл');
        return;
      }
      setState(() => _currentStep = 1);
    } else if (_currentStep == 1) {
      if (!formKey.currentState!.validate()) return;
      estimateName = _estimateNameController.text.trim();
      setState(() => _currentStep = 2);
      _importExcelData();
    }
  }

  void _goBack() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    } else {
      widget.onCancel();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLargeScreen = MediaQuery.of(context).size.width > 900;
    final theme = Theme.of(context);

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildStepIndicator(theme),
        _buildStepContent(theme),
      ],
    );

    // Actions
    final actions = Row(
      children: [
        if (_currentStep > 0)
          Expanded(
            child: GTSecondaryButton(
              text: 'Назад',
              onPressed: _isImporting ? null : _goBack,
            ),
          ),
        if (_currentStep > 0) const SizedBox(width: 16),
        Expanded(
          child: _currentStep < 2
              ? GTPrimaryButton(
                  text: _currentStep == 1 ? 'Импортировать' : 'Продолжить',
                  onPressed: isLoading ? null : _goNext,
                )
              : const SizedBox.shrink(), // На шаге импорта кнопка не нужна
        ),
      ],
    );

    if (isLargeScreen) {
      return DesktopDialogContent(
        title: 'Импорт сметы',
        width: 750,
        footer: actions,
        onClose: widget.onCancel,
        child: content,
      );
    }

    return MobileBottomSheetContent(
      title: 'Импорт сметы',
      footer: actions,
      child: content,
    );
  }
}
