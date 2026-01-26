import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../../../domain/entities/estimate.dart';
import '../../../../core/di/providers.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/mobile_bottom_sheet_content.dart';
import '../../../../core/widgets/desktop_dialog_content.dart';
import '../../../../core/widgets/gt_buttons.dart';
import '../../../../core/widgets/gt_text_field.dart';
import '../../../../core/widgets/gt_dropdown.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../features/roles/application/permission_service.dart';
import '../../../../features/company/presentation/providers/company_providers.dart';

/// Диалоговое окно для создания или редактирования позиции сметы.
class EstimateEditDialog extends ConsumerStatefulWidget {
  /// Редактируемая позиция сметы (null при создании новой).
  final Estimate? estimate;

  /// Название сметы, к которой относится позиция.
  final String? estimateTitle;

  /// Идентификатор объекта (для контекста новой позиции).
  final String? objectId;

  /// Идентификатор договора (для контекста новой позиции).
  final String? contractId;

  /// Нужно ли оборачивать в DesktopDialogContent/MobileBottomSheetContent.
  /// По умолчанию true.
  final bool useWrapper;

  /// Создаёт диалог редактирования позиции.
  const EstimateEditDialog({
    super.key,
    this.estimate,
    this.estimateTitle,
    this.objectId,
    this.contractId,
    this.useWrapper = true,
  });

  /// Показывает диалог редактирования/создания позиции.
  ///
  /// Адаптируется под размер экрана (Dialog для Desktop, BottomSheet для Mobile).
  static Future<void> show(
    BuildContext context, {
    Estimate? estimate,
    String? estimateTitle,
    String? objectId,
    String? contractId,
  }) async {
    final isLargeScreen = MediaQuery.of(context).size.width > 900;
    final title = estimate != null ? 'Редактирование позиции' : 'Добавление позиции';

    if (isLargeScreen) {
      await DesktopDialogContent.show(
        context,
        title: title,
        width: 750,
        child: EstimateEditDialog(
          estimate: estimate,
          estimateTitle: estimateTitle,
          objectId: objectId,
          contractId: contractId,
          useWrapper: false,
        ),
      );
    } else {
      await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        backgroundColor: Colors.transparent,
        builder: (context) => EstimateEditDialog(
          estimate: estimate,
          estimateTitle: estimateTitle,
          objectId: objectId,
          contractId: contractId,
        ),
      );
    }
  }

  @override
  ConsumerState<EstimateEditDialog> createState() => _EstimateEditDialogState();
}

class _EstimateEditDialogState extends ConsumerState<EstimateEditDialog> {
  final _formKey = GlobalKey<FormState>();
  final _uuid = const Uuid();

  late TextEditingController _systemController;
  late TextEditingController _subsystemController;
  late TextEditingController _numberController;
  late TextEditingController _nameController;
  late TextEditingController _articleController;
  late TextEditingController _manufacturerController;
  late TextEditingController _unitController;
  late TextEditingController _quantityController;
  late TextEditingController _priceController;

  List<String> _systems = [];
  List<String> _subsystems = [];
  List<String> _units = [];
  bool _systemsLoading = false;
  bool _subsystemsLoading = false;
  bool _unitsLoading = false;

  bool get isEditing => widget.estimate != null;

  @override
  void initState() {
    super.initState();
    _initControllers();
    _loadLookupData();
  }

  void _initControllers() {
    final e = widget.estimate;

    String initialNumber = '';
    if (e != null) {
      initialNumber = e.number;
    } else {
      // При создании новой позиции вычисляем следующий номер через нотификатор
      initialNumber = ref
          .read(estimateNotifierProvider.notifier)
          .calculateNextNumber(
            estimateTitle: widget.estimateTitle,
            objectId: widget.objectId,
            contractId: widget.contractId,
          );
    }

    _systemController = TextEditingController(text: e?.system ?? '');
    _subsystemController = TextEditingController(text: e?.subsystem ?? '');
    _numberController = TextEditingController(text: initialNumber);
    _nameController = TextEditingController(text: e?.name ?? '');
    _articleController = TextEditingController(text: e?.article ?? '');
    _manufacturerController = TextEditingController(
      text: e?.manufacturer ?? '',
    );
    _unitController = TextEditingController(text: e?.unit ?? '');
    _quantityController = TextEditingController(
      text: e?.quantity.toString() ?? '',
    );
    _priceController = TextEditingController(text: e?.price.toString() ?? '');
  }

  // Метод _calculateNextNumber удален, логика перенесена в EstimateNotifier

  @override
  void dispose() {
    _systemController.dispose();
    _subsystemController.dispose();
    _numberController.dispose();
    _nameController.dispose();
    _articleController.dispose();
    _manufacturerController.dispose();
    _unitController.dispose();
    _quantityController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _loadLookupData() async {
    setState(() {
      _systemsLoading = true;
      _subsystemsLoading = true;
      _unitsLoading = true;
    });

    try {
      final estimateRepo = ref.read(estimateRepositoryProvider);
      final systems = await estimateRepo.getSystems(
        estimateTitle: widget.estimateTitle,
      );
      final subsystems = await estimateRepo.getSubsystems(
        estimateTitle: widget.estimateTitle,
      );
      final units = await estimateRepo.getUnits(
        estimateTitle: widget.estimateTitle,
      );

      if (!mounted) return;

      setState(() {
        _systems = systems;
        _subsystems = subsystems;
        _units = units;
        _systemsLoading = false;
        _subsystemsLoading = false;
        _unitsLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _systemsLoading = false;
        _subsystemsLoading = false;
        _unitsLoading = false;
      });
    }
  }

  Future<void> _save() async {
    if (_formKey.currentState!.validate()) {
      final quantity = parseAmount(_quantityController.text) ?? 0.0;
      final price = parseAmount(_priceController.text) ?? 0.0;

      String? objectId = widget.estimate?.objectId ?? widget.objectId;
      String? contractId = widget.estimate?.contractId ?? widget.contractId;

      if (!isEditing && objectId == null) {
        final state = ref.read(estimateNotifierProvider);
        final currentItems = state.estimates
            .where((e) => e.estimateTitle == widget.estimateTitle)
            .toList();
        if (currentItems.isNotEmpty) {
          objectId = currentItems.first.objectId;
          contractId = currentItems.first.contractId;
        }
      }

      final activeCompanyId = ref.read(activeCompanyIdProvider);
      if (activeCompanyId == null) {
        AppSnackBar.show(
          context: context,
          message: 'Компания не выбрана',
          kind: AppSnackBarKind.error,
        );
        return;
      }

      final updatedEstimate = Estimate(
        id: isEditing ? widget.estimate!.id : _uuid.v4(),
        companyId: widget.estimate?.companyId ?? activeCompanyId,
        system: _systemController.text,
        subsystem: _subsystemController.text,
        number: _numberController.text,
        name: _nameController.text,
        article: _articleController.text.trim(),
        manufacturer: _manufacturerController.text.trim(),
        unit: _unitController.text,
        quantity: quantity,
        price: price,
        total: quantity * price,
        estimateTitle: widget.estimateTitle,
        objectId: objectId,
        contractId: contractId,
      );

      final notifier = ref.read(estimateNotifierProvider.notifier);

      try {
        if (isEditing) {
          await notifier.updateEstimate(updatedEstimate);

          if (!mounted) return;

          AppSnackBar.show(
            context: context,
            message: 'Позиция успешно обновлена',
            kind: AppSnackBarKind.success,
          );
        } else {
          await notifier.addEstimate(updatedEstimate);

          if (!mounted) return;

          AppSnackBar.show(
            context: context,
            message: 'Позиция успешно добавлена',
            kind: AppSnackBarKind.success,
          );
        }

        if (!mounted) return;
        context.pop();
      } catch (e) {
        if (!mounted) return;
        AppSnackBar.show(
          context: context,
          message: 'Ошибка сохранения: $e',
          kind: AppSnackBarKind.error,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLargeScreen = MediaQuery.of(context).size.width > 900;
    final title = isEditing ? 'Редактирование позиции' : 'Добавление позиции';
    final theme = Theme.of(context);

    final permissionService = ref.watch(permissionServiceProvider);
    final canEdit = permissionService.can('estimates', 'update');

    final formContent = Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: _buildFormFields(theme, canEdit),
      ),
    );

    final footer = Row(
      children: [
        Expanded(
          child: GTSecondaryButton(
            text: 'Отмена',
            onPressed: () => context.pop(),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: GTPrimaryButton(
            text: isEditing ? 'Сохранить' : 'Добавить',
            onPressed: canEdit ? _save : null,
          ),
        ),
      ],
    );

    if (!widget.useWrapper) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          formContent,
          const SizedBox(height: 24),
          footer,
        ],
      );
    }

    if (isLargeScreen) {
      return DesktopDialogContent(
        title: title,
        width: 750,
        footer: footer,
        child: formContent,
      );
    }

    return MobileBottomSheetContent(
      title: title,
      footer: Row(
        children: [
          Expanded(
            child: GTSecondaryButton(
              text: 'Отмена',
              onPressed: () => context.pop(),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: GTPrimaryButton(
              text: isEditing ? 'Сохранить' : 'Добавить',
              onPressed: canEdit ? _save : null,
            ),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: _buildFormFields(theme, canEdit),
        ),
      ),
    );
  }

  List<Widget> _buildFormFields(ThemeData theme, bool canEdit) {
    return [
      Text(
        'Основная информация',
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
        ),
      ),
      const SizedBox(height: 16),
      GTStringDropdown(
        items: _systems,
        labelText: 'Система *',
        hintText: 'Выберите или введите систему',
        selectedItem: _systemController.text,
        isLoading: _systemsLoading,
        showAddNewOption: true,
        onSelectionChanged: canEdit
            ? (val) => setState(() => _systemController.text = val ?? '')
            : null,
        validator: (v) =>
            v == null || v.trim().isEmpty ? 'Обязательное поле' : null,
      ),
      const SizedBox(height: 16),
      GTStringDropdown(
        items: _subsystems,
        labelText: 'Подсистема *',
        hintText: 'Выберите или введите подсистему',
        selectedItem: _subsystemController.text,
        isLoading: _subsystemsLoading,
        showAddNewOption: true,
        onSelectionChanged: canEdit
            ? (val) => setState(() => _subsystemController.text = val ?? '')
            : null,
        validator: (v) =>
            v == null || v.trim().isEmpty ? 'Обязательное поле' : null,
      ),
      const SizedBox(height: 16),
      GTTextField(
        controller: _numberController,
        labelText: 'Номер *',
        hintText: 'Введите порядковый номер',
        readOnly: !canEdit,
        validator: (v) =>
            v == null || v.trim().isEmpty ? 'Обязательное поле' : null,
      ),
      const SizedBox(height: 16),
      GTTextField(
        controller: _nameController,
        labelText: 'Наименование *',
        hintText: 'Введите наименование позиции',
        readOnly: !canEdit,
        validator: (v) =>
            v == null || v.trim().isEmpty ? 'Обязательное поле' : null,
        maxLines: null,
      ),
      const SizedBox(height: 24),
      Text(
        'Техническая информация',
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
        ),
      ),
      const SizedBox(height: 16),
      LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 500;
          if (isWide) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: GTTextField(
                    controller: _articleController,
                    labelText: 'Артикул',
                    hintText: 'Введите артикул',
                    readOnly: !canEdit,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: GTTextField(
                    controller: _manufacturerController,
                    labelText: 'Производитель',
                    hintText: 'Введите производителя',
                    readOnly: !canEdit,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: GTStringDropdown(
                    items: _units,
                    labelText: 'Ед. измерения *',
                    hintText: 'Выберите или введите',
                    selectedItem: _unitController.text,
                    isLoading: _unitsLoading,
                    showAddNewOption: true,
                    onSelectionChanged: canEdit
                        ? (val) =>
                            setState(() => _unitController.text = val ?? '')
                        : null,
                    validator: (v) => v == null || v.trim().isEmpty
                        ? 'Обязательное поле'
                        : null,
                  ),
                ),
              ],
            );
          }
          return Column(
            children: [
              GTTextField(
                controller: _articleController,
                labelText: 'Артикул',
                hintText: 'Введите артикул',
                readOnly: !canEdit,
              ),
              const SizedBox(height: 16),
              GTTextField(
                controller: _manufacturerController,
                labelText: 'Производитель',
                hintText: 'Введите производителя',
                readOnly: !canEdit,
              ),
              const SizedBox(height: 16),
              GTStringDropdown(
                items: _units,
                labelText: 'Ед. измерения *',
                hintText: 'Выберите или введите единицу измерения',
                selectedItem: _unitController.text,
                isLoading: _unitsLoading,
                showAddNewOption: true,
                onSelectionChanged: canEdit
                    ? (val) => setState(() => _unitController.text = val ?? '')
                    : null,
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Обязательное поле' : null,
              ),
            ],
          );
        },
      ),
      const SizedBox(height: 24),
      Text(
        'Ценовая информация',
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
        ),
      ),
      const SizedBox(height: 16),
      LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 500;
          if (isWide) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: GTTextField(
                    controller: _quantityController,
                    labelText: 'Количество',
                    hintText: 'Введите количество',
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [quantityFormatter()],
                    validator: _numberValidator,
                    readOnly: !canEdit,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: GTTextField(
                    controller: _priceController,
                    labelText: 'Цена за единицу',
                    hintText: 'Введите цену',
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [amountFormatter()],
                    validator: _numberValidator,
                    readOnly: !canEdit,
                  ),
                ),
              ],
            );
          }
          return Column(
            children: [
              GTTextField(
                controller: _quantityController,
                labelText: 'Количество',
                hintText: 'Введите количество',
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [quantityFormatter()],
                validator: _numberValidator,
                readOnly: !canEdit,
              ),
              const SizedBox(height: 16),
              GTTextField(
                controller: _priceController,
                labelText: 'Цена за единицу',
                hintText: 'Введите цену',
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [amountFormatter()],
                validator: _numberValidator,
                readOnly: !canEdit,
              ),
            ],
          );
        },
      ),
    ];
  }

  String? _numberValidator(String? v) {
    if (v == null || v.trim().isEmpty) return null;
    if (parseAmount(v) == null) {
      return 'Введите число';
    }
    return null;
  }
}
