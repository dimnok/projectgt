import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:file_saver/file_saver.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:projectgt/domain/entities/estimate.dart';
import 'package:projectgt/features/company/presentation/providers/company_providers.dart';
import 'package:projectgt/features/estimates/presentation/providers/estimate_providers.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/di/providers.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/snackbar_utils.dart';
import '../../../../core/widgets/desktop_dialog_content.dart';
import '../../../../core/widgets/gt_buttons.dart';
import '../../../../core/widgets/gt_text_field.dart';
import '../../../../core/widgets/mobile_bottom_sheet_content.dart';
import 'package:projectgt/features/roles/presentation/widgets/permission_guard.dart';
import '../services/estimate_addendum_excel_service.dart';

/// Наименование служебной позиции при создании пустой сметы из окна LC / ДС.
///
/// Строка удаляется из [estimates] после успешного импорта ДС; в ревизиях
/// [source_estimate_id] обнуляется по правилу `ON DELETE SET NULL`.
const String kEstimateAddendumPlaceholderRowName =
    'Служебная строка (удалится после импорта ДС)';

/// Модальное окно импорта LC / ДС.
///
/// Новый поток существует параллельно старому импорту сметы и не подменяет его.
///
/// Если [estimateTitle] пустой, пользователь может нажать «Новая смета»:
/// создаётся смета с одной служебной строкой, она удаляется после успешного
/// импорта ДС.
class ImportEstimateAddendumModal extends ConsumerStatefulWidget {
  /// Название сметы (может быть пустым — тогда нужна «Новая смета»).
  final String estimateTitle;

  /// Идентификатор договора.
  final String contractId;

  /// Идентификатор объекта.
  final String? objectId;

  /// Коллбек после успешного импорта.
  final VoidCallback onSuccess;

  /// Коллбек при закрытии.
  final VoidCallback onCancel;

  /// Нужно ли оборачивать в стандартный wrapper.
  final bool useWrapper;

  /// Создаёт модальное окно импорта LC / ДС.
  const ImportEstimateAddendumModal({
    super.key,
    required this.estimateTitle,
    required this.contractId,
    required this.objectId,
    required this.onSuccess,
    required this.onCancel,
    this.useWrapper = true,
  });

  /// Открывает модальное окно импорта LC / ДС.
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
        title: 'LC / Доп. соглашение',
        width: 780,
        onClose: () => Navigator.of(context).pop(),
        child: ImportEstimateAddendumModal(
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
        builder: (context) => ImportEstimateAddendumModal(
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
  ConsumerState<ImportEstimateAddendumModal> createState() =>
      _ImportEstimateAddendumModalState();
}

class _ImportEstimateAddendumModalState
    extends ConsumerState<ImportEstimateAddendumModal> {
  PlatformFile? _pickedFile;
  EstimateAddendumExcelValidationResult? _validationResult;
  EstimateAddendumExcelPreviewResult? _previewResult;

  bool _isDownloading = false;
  bool _isExportingWithAddenda = false;
  bool _isValidating = false;
  bool _isImporting = false;
  bool _isCreatingShellEstimate = false;
  int _currentStep = 0;
  String _importStatus = '';

  late final TextEditingController _descriptionController;
  late String _activeEstimateTitle;

  /// Строка [estimates], создаваемая кнопкой «Новая смета»; удаляется после импорта ДС.
  String? _placeholderEstimateRowId;
  DateTime _effectiveFrom = DateTime(
    DateTime.now().year,
    DateTime.now().month,
    DateTime.now().day,
  );

  @override
  void initState() {
    super.initState();
    _activeEstimateTitle = widget.estimateTitle;
    _descriptionController = TextEditingController();
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickEffectiveFromDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _effectiveFrom,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked == null || !mounted) return;
    setState(() {
      _effectiveFrom = DateTime(picked.year, picked.month, picked.day);
    });
  }

  Future<String?> _promptNewEstimateTitle() async {
    final controller = TextEditingController();
    try {
      return await showDialog<String>(
        context: context,
        builder: (ctx) {
          final theme = Theme.of(ctx);
          final scheme = theme.colorScheme;
          final radius = BorderRadius.circular(16);
          return Semantics(
            namesRoute: true,
            label: 'Новая смета',
            child: Dialog(
              insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
              clipBehavior: Clip.antiAlias,
              shape: RoundedRectangleBorder(
                borderRadius: radius,
                side: BorderSide(color: scheme.outline.withValues(alpha: 0.22)),
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Новая смета',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Укажите название сметы по договору. Будет создана одна '
                        'служебная строка — она исчезнет после успешного импорта ДС.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurface.withValues(alpha: 0.72),
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 18),
                      GTTextField(
                        controller: controller,
                        labelText: 'Название сметы',
                        autofocus: true,
                        onSubmitted: (v) {
                          final t = v.trim();
                          if (t.isNotEmpty) Navigator.of(ctx).pop(t);
                        },
                      ),
                      const SizedBox(height: 22),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          GTTextButton(
                            text: 'Отмена',
                            onPressed: () => Navigator.of(ctx).pop(),
                          ),
                          const SizedBox(width: 16),
                          GTPrimaryButton(
                            text: 'Создать',
                            onPressed: () {
                              final t = controller.text.trim();
                              if (t.isEmpty) return;
                              Navigator.of(ctx).pop(t);
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      );
    } finally {
      controller.dispose();
    }
  }

  Future<void> _createNewEmptyEstimateForAddendum() async {
    if (_isCreatingShellEstimate) return;
    final title = await _promptNewEstimateTitle();
    if (!mounted) return;
    final trimmed = title?.trim() ?? '';
    if (trimmed.isEmpty) return;

    setState(() => _isCreatingShellEstimate = true);
    try {
      final companyId = ref.read(activeCompanyIdProvider);
      if (companyId == null || companyId.isEmpty) {
        if (mounted) {
          SnackBarUtils.showError(context, 'Компания не выбрана');
        }
        return;
      }

      final repository = ref.read(estimateRepositoryProvider);
      final prev = _placeholderEstimateRowId;
      if (prev != null && prev.isNotEmpty) {
        try {
          await repository.deleteEstimate(prev);
        } catch (_) {}
      }

      final notifier = ref.read(estimateNotifierProvider.notifier);
      final nextNumber = notifier.calculateNextNumber(
        estimateTitle: trimmed,
        objectId: widget.objectId,
        contractId: widget.contractId,
      );
      final id = const Uuid().v4();
      final shell = Estimate(
        id: id,
        companyId: companyId,
        system: '-',
        subsystem: '-',
        number: nextNumber,
        name: kEstimateAddendumPlaceholderRowName,
        article: '',
        manufacturer: '',
        unit: 'усл. ед.',
        quantity: 0,
        price: 0,
        total: 0,
        objectId: widget.objectId,
        contractId: widget.contractId,
        estimateTitle: trimmed,
        visibleInEstimatesModule: false,
      );
      await notifier.addEstimate(shell);

      if (!mounted) return;
      setState(() {
        _activeEstimateTitle = trimmed;
        _placeholderEstimateRowId = id;
        _pickedFile = null;
        _validationResult = null;
        _previewResult = null;
        _currentStep = 0;
      });
      ref.invalidate(contractEstimateFilesProvider(widget.contractId));
      ref.invalidate(contractEstimatesProvider(widget.contractId));
      ref.invalidate(estimateGroupsProvider);
      SnackBarUtils.showSuccess(
        context,
        'Создана смета «$trimmed». Скачайте шаблон и загрузите файл ДС.',
      );
    } catch (e) {
      if (mounted) {
        SnackBarUtils.showError(context, 'Не удалось создать смету: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isCreatingShellEstimate = false);
      }
    }
  }

  Future<void> _downloadTemplate() async {
    if (_activeEstimateTitle.trim().isEmpty) {
      SnackBarUtils.showError(
        context,
        'Сначала создайте смету (кнопка «Новая смета»)',
      );
      return;
    }
    setState(() => _isDownloading = true);
    try {
      final repository = ref.read(estimateRepositoryProvider);

      // Вызываем метод репозитория, который теперь возвращает Map с байтами
      final result = await repository.getAddendumTemplateFile(
        estimateTitle: _activeEstimateTitle,
        contractId: widget.contractId,
        objectId: widget.objectId,
      );

      final bytes = result['bytes'] as Uint8List;
      final fileName = result['filename'] as String;

      if (kIsWeb) {
        await FileSaver.instance.saveFile(
          name: fileName.replaceAll('.xlsx', ''),
          bytes: bytes,
          mimeType: MimeType.microsoftExcel,
        );
      } else {
        final outputPath = await FilePicker.saveFile(
          dialogTitle: 'Сохранить шаблон LC / ДС',
          fileName: fileName,
          type: FileType.custom,
          allowedExtensions: ['xlsx'],
          bytes: bytes,
        );

        if (outputPath == null) return;
      }

      if (!mounted) return;
      SnackBarUtils.showSuccess(
        context,
        'Excel-шаблон LC / ДС успешно подготовлен на сервере',
      );
    } catch (error) {
      if (!mounted) return;
      SnackBarUtils.showError(
        context,
        'Ошибка при подготовке шаблона LC / ДС: $error',
      );
    } finally {
      if (mounted) {
        setState(() => _isDownloading = false);
      }
    }
  }

  Future<void> _exportWithAddendaColumns() async {
    if (_activeEstimateTitle.trim().isEmpty) {
      SnackBarUtils.showError(
        context,
        'Сначала создайте смету (кнопка «Новая смета»)',
      );
      return;
    }
    setState(() => _isExportingWithAddenda = true);
    try {
      final repository = ref.read(estimateRepositoryProvider);
      final result = await repository.exportContractEstimateWithAddendaExcel(
        estimateTitle: _activeEstimateTitle,
        contractId: widget.contractId,
        objectId: widget.objectId,
      );

      final bytes = result['bytes'] as Uint8List;
      final fileName = result['filename'] as String;

      if (kIsWeb) {
        await FileSaver.instance.saveFile(
          name: fileName.replaceAll('.xlsx', ''),
          bytes: bytes,
          mimeType: MimeType.microsoftExcel,
        );
      } else {
        final outputPath = await FilePicker.saveFile(
          dialogTitle: 'Сохранить смету с колонками ДС',
          fileName: fileName,
          type: FileType.custom,
          allowedExtensions: ['xlsx'],
          bytes: bytes,
        );

        if (outputPath == null) return;
      }

      if (!mounted) return;
      SnackBarUtils.showSuccess(
        context,
        'Excel со сметой и колонками ДС сохранён',
      );
    } catch (error) {
      if (!mounted) return;
      SnackBarUtils.showError(
        context,
        'Ошибка при выгрузке сметы с ДС: $error',
      );
    } finally {
      if (mounted) {
        setState(() => _isExportingWithAddenda = false);
      }
    }
  }

  Future<void> _pickExcelFile() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx'],
        withData: true,
      );

      if (result == null || result.files.single.bytes == null) return;

      setState(() {
        _pickedFile = result.files.single;
        _validationResult = null;
        _previewResult = null;
        _currentStep = 0;
      });

      await _validatePickedFile();
    } catch (error) {
      if (!mounted) return;
      SnackBarUtils.showError(context, 'Ошибка выбора файла: $error');
    }
  }

  Future<void> _validatePickedFile() async {
    final bytes = _pickedFile?.bytes;
    if (bytes == null) return;

    setState(() => _isValidating = true);
    try {
      final fileBytes = Uint8List.fromList(bytes);
      final validation = EstimateAddendumExcelService.validateExcelFile(
        fileBytes,
      );
      final preview = EstimateAddendumExcelService.preparePreview(fileBytes);

      setState(() {
        _validationResult = validation;
        _previewResult = preview;
      });
    } finally {
      if (mounted) {
        setState(() => _isValidating = false);
      }
    }
  }

  Future<void> _importDraft() async {
    final bytes = _pickedFile?.bytes;
    final validation = _validationResult;
    if (bytes == null || validation == null || !validation.isValid) {
      SnackBarUtils.showError(
        context,
        'Сначала выберите корректный Excel-файл LC / ДС',
      );
      return;
    }

    setState(() {
      _isImporting = true;
      _importStatus = 'Сохранение ДС...';
    });

    try {
      final fileBytes = Uint8List.fromList(bytes);
      final rows = EstimateAddendumExcelService.parseImportRows(fileBytes);
      if (rows.isEmpty) {
        throw Exception('В файле нет валидных строк для импорта');
      }

      final repository = ref.read(estimateRepositoryProvider);
      final description = _descriptionController.text.trim();
      final result = await repository.createEstimateRevisionDraft(
        estimateTitle: _activeEstimateTitle,
        contractId: widget.contractId,
        objectId: widget.objectId,
        fileName: _pickedFile!.name,
        fileBytes: fileBytes,
        rows: rows,
        effectiveFrom: _effectiveFrom,
        userDescription: description.isEmpty ? null : description,
      );

      final placeholderId = _placeholderEstimateRowId;
      if (placeholderId != null && placeholderId.isNotEmpty) {
        try {
          await repository.deleteEstimate(placeholderId);
        } catch (e) {
          if (mounted) {
            SnackBarUtils.showError(
              context,
              'ДС сохранено; служебную строку удалите вручную: $e',
            );
          }
        }
        if (mounted) {
          setState(() => _placeholderEstimateRowId = null);
        }
      }

      if (!mounted) return;

      final baseNote = result.baseRevisionCreated
          ? ' Базовая ревизия «Основная» создана автоматически.'
          : '';
      SnackBarUtils.showSuccess(
        context,
        'ДС сохранено: ${result.revisionLabel} (${result.itemsCount} строк).$baseNote',
      );
      widget.onSuccess();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _importStatus = 'Ошибка импорта: $error';
      });
      SnackBarUtils.showError(context, 'Ошибка импорта LC / ДС: $error');
    } finally {
      if (mounted) {
        setState(() => _isImporting = false);
      }
    }
  }

  void _goNext() {
    if (_currentStep == 0) {
      if (_activeEstimateTitle.trim().isEmpty) {
        SnackBarUtils.showError(
          context,
          'Сначала создайте смету (кнопка «Новая смета»)',
        );
        return;
      }
      if (_pickedFile == null ||
          _validationResult == null ||
          !_validationResult!.isValid) {
        SnackBarUtils.showError(
          context,
          'Для продолжения нужен корректный Excel-файл LC / ДС',
        );
        return;
      }

      setState(() => _currentStep = 1);
      return;
    }

    if (_currentStep == 1) {
      setState(() => _currentStep = 2);
      _importDraft();
    }
  }

  void _goBack() {
    if (_currentStep == 0) {
      widget.onCancel();
      return;
    }

    setState(() => _currentStep -= 1);
  }

  @override
  Widget build(BuildContext context) {
    final isLargeScreen = MediaQuery.of(context).size.width > 900;
    final theme = Theme.of(context);

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildInfoBanner(theme),
        const SizedBox(height: 20),
        _buildStepIndicator(theme),
        const SizedBox(height: 24),
        _buildStepContent(theme),
      ],
    );

    final actions = Row(
      children: [
        Expanded(
          child: GTSecondaryButton(
            text: _currentStep == 0 ? 'Закрыть' : 'Назад',
            onPressed: _isImporting ? null : _goBack,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _currentStep < 2
              ? GTPrimaryButton(
                  text: _currentStep == 1 ? 'Сохранить ДС' : 'Продолжить',
                  onPressed:
                      (_isDownloading ||
                          _isValidating ||
                          _isImporting ||
                          _isExportingWithAddenda ||
                          _isCreatingShellEstimate)
                      ? null
                      : _goNext,
                )
              : const SizedBox.shrink(),
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
        title: 'LC / Доп. соглашение',
        width: 780,
        footer: actions,
        onClose: widget.onCancel,
        child: content,
      );
    }

    return MobileBottomSheetContent(
      title: 'LC / Доп. соглашение',
      footer: actions,
      child: content,
    );
  }

  Widget _buildInfoBanner(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.2),
        ),
      ),
      child: Text(
        'ДС сохраняется как согласованная ревизия. Чтобы изменения попали в основную смету и ВОР, нажмите «Применить к смете» в списке ДС.',
        style: theme.textTheme.bodyMedium,
      ),
    );
  }

  Widget _buildStepIndicator(ThemeData theme) {
    return Row(
      children: [
        _buildStepItem(theme, 0, 'Файл'),
        _buildStepDivider(theme, 0),
        _buildStepItem(theme, 1, 'Проверка'),
        _buildStepDivider(theme, 1),
        _buildStepItem(theme, 2, 'Сохранение'),
      ],
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
              border: Border.all(color: color, width: 2),
            ),
            child: isCompleted
                ? Icon(
                    CupertinoIcons.checkmark_alt,
                    size: 16,
                    color: theme.colorScheme.primary,
                  )
                : Center(
                    child: Text(
                      '${step + 1}',
                      style: TextStyle(
                        color: isActive
                            ? theme.colorScheme.onPrimary
                            : theme.colorScheme.onSurface.withValues(
                                alpha: 0.6,
                              ),
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
                  : theme.colorScheme.onSurface.withValues(alpha: 0.6),
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
        return _buildCheckStep(theme);
      case 2:
        return _buildImportStep(theme);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildFileStep(ThemeData theme) {
    final hasTitle = _activeEstimateTitle.trim().isNotEmpty;
    final canDownload =
        hasTitle &&
        !_isDownloading &&
        !_isExportingWithAddenda &&
        !_isValidating &&
        !_isImporting;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          hasTitle
              ? 'Смета: $_activeEstimateTitle'
              : 'Смета: не выбрана — нажмите «Новая смета»',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        PermissionGuard(
          module: 'estimates',
          permission: 'import',
          child: GTSecondaryButton(
            text: 'Новая смета',
            icon: CupertinoIcons.add_circled,
            isLoading: _isCreatingShellEstimate,
            onPressed: (_isImporting || _isValidating)
                ? null
                : _createNewEmptyEstimateForAddendum,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: GTSecondaryButton(
                text: 'Скачать Excel',
                icon: CupertinoIcons.arrow_down_doc,
                onPressed: !canDownload ? null : _downloadTemplate,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: GTPrimaryButton(
                text: _pickedFile == null ? 'Выбрать файл' : 'Изменить файл',
                icon: CupertinoIcons.arrow_up_doc,
                onPressed: _isValidating ? null : _pickExcelFile,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        PermissionGuard(
          module: 'estimates',
          permission: 'read',
          child: GTSecondaryButton(
            text: 'Скачать смету с колонками ДС',
            icon: CupertinoIcons.doc_text,
            onPressed: !canDownload ? null : _exportWithAddendaColumns,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Дата действия ДС',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Text(
                formatRuDate(_effectiveFrom),
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            GTSecondaryButton(
              text: 'Изменить',
              icon: CupertinoIcons.calendar,
              onPressed: _pickEffectiveFromDate,
            ),
          ],
        ),
        const SizedBox(height: 16),
        GTTextField(
          controller: _descriptionController,
          labelText: 'Краткое описание ДС (необязательно)',
          maxLines: 3,
        ),
        const SizedBox(height: 16),
        Text(
          'В выгруженном Excel у существующих позиций будет `ID позиции`, а у новых строк оставьте это поле пустым.',
          style: theme.textTheme.bodyMedium,
        ),
        if (_pickedFile != null) ...[
          const SizedBox(height: 16),
          Text(
            'Файл: ${_pickedFile!.name}',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildCheckStep(ThemeData theme) {
    final validation = _validationResult;
    final preview = _previewResult;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (validation == null)
          const Text('Сначала выберите Excel-файл')
        else ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: validation.isValid
                  ? theme.colorScheme.primaryContainer.withValues(alpha: 0.2)
                  : theme.colorScheme.errorContainer.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: validation.isValid
                    ? theme.colorScheme.primary.withValues(alpha: 0.4)
                    : theme.colorScheme.error.withValues(alpha: 0.4),
              ),
            ),
            child: Text(
              validation.isValid
                  ? 'Файл LC / ДС прошёл проверку'
                  : 'В файле LC / ДС есть ошибки структуры',
              style: TextStyle(
                color: validation.isValid
                    ? theme.colorScheme.primary
                    : theme.colorScheme.error,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (preview != null) ...[
            Text('Строк в файле: ${preview.rowCount}'),
            Text('Существующие позиции: ${preview.existingRowsCount}'),
            Text('Новые позиции: ${preview.newRowsCount}'),
            Text('Сумма: ${formatCurrency(preview.totalAmount)}'),
            const SizedBox(height: 16),
          ],
          if (validation.errors.isNotEmpty) ...[
            Text(
              'Ошибки:',
              style: theme.textTheme.titleSmall?.copyWith(
                color: theme.colorScheme.error,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            ...validation.errors.map(
              (error) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text('• $error'),
              ),
            ),
            const SizedBox(height: 12),
          ],
          if (validation.warnings.isNotEmpty) ...[
            Text(
              'Предупреждения:',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            ...validation.warnings.map(
              (warning) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text('• $warning'),
              ),
            ),
          ],
        ],
      ],
    );
  }

  Widget _buildImportStep(ThemeData theme) {
    return Column(
      children: [
        if (_isImporting) ...[
          const CupertinoActivityIndicator(),
          const SizedBox(height: 16),
          Text(
            _importStatus.isEmpty ? 'Сохраняем ДС...' : _importStatus,
            textAlign: TextAlign.center,
          ),
        ] else
          Text(
            _importStatus.isEmpty ? 'Сохранение ДС' : _importStatus,
            textAlign: TextAlign.center,
          ),
      ],
    );
  }
}
