import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';

import '../../../../domain/entities/estimate.dart';
import '../../../../core/di/providers.dart';
import '../../../../core/widgets/mobile_bottom_sheet_content.dart';
import '../../../../core/widgets/desktop_dialog_content.dart';
import '../../../../core/widgets/gt_buttons.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../providers/estimate_providers.dart';

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

  /// Создаёт диалог редактирования позиции.
  const EstimateEditDialog({
    super.key,
    this.estimate,
    this.estimateTitle,
    this.objectId,
    this.contractId,
  });

  /// Показывает диалог редактирования/создания позиции.
  ///
  /// Адаптируется под размер экрана (Dialog для Desktop, BottomSheet для Mobile).
  static void show(BuildContext context,
      {Estimate? estimate,
      String? estimateTitle,
      String? objectId,
      String? contractId}) {
    final isLargeScreen = MediaQuery.of(context).size.width > 900;

    if (isLargeScreen) {
      showDialog(
        context: context,
        builder: (context) => Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(24),
          child: EstimateEditDialog(
            estimate: estimate,
            estimateTitle: estimateTitle,
            objectId: objectId,
            contractId: contractId,
          ),
        ),
      );
    } else {
      showModalBottomSheet(
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
      // При создании новой позиции вычисляем следующий номер
      initialNumber = _calculateNextNumber();
    }

    _systemController = TextEditingController(text: e?.system ?? '');
    _subsystemController = TextEditingController(text: e?.subsystem ?? '');
    _numberController = TextEditingController(text: initialNumber);
    _nameController = TextEditingController(text: e?.name ?? '');
    _articleController = TextEditingController(text: e?.article ?? '');
    _manufacturerController =
        TextEditingController(text: e?.manufacturer ?? '');
    _unitController = TextEditingController(text: e?.unit ?? '');
    _quantityController =
        TextEditingController(text: e?.quantity.toString() ?? '');
    _priceController = TextEditingController(text: e?.price.toString() ?? '');
  }

  String _calculateNextNumber() {
    try {
      List<Estimate> currentContextEstimates = [];

      // 1. Пытаемся получить актуальные данные из estimateItemsProvider
      // Это основной источник данных для экрана сметы
      if (widget.estimateTitle != null) {
        final args = EstimateDetailArgs(
          estimateTitle: widget.estimateTitle!,
          objectId: widget.objectId,
          contractId: widget.contractId,
        );
        // Используем read для получения текущего значения без подписки (так как мы в initState)
        final asyncValue = ref.read(estimateItemsProvider(args));
        currentContextEstimates = asyncValue.valueOrNull ?? [];
      }

      // 2. Если данных нет (например, провайдер не был инициализирован или пуст),
      // пробуем fallback на estimateNotifierProvider
      if (currentContextEstimates.isEmpty) {
        final allEstimates = ref.read(estimateNotifierProvider).estimates;
        currentContextEstimates = allEstimates.where((est) {
          bool matches = true;
          if (widget.estimateTitle != null) {
            matches = matches && est.estimateTitle == widget.estimateTitle;
          }
          if (widget.objectId != null) {
            matches = matches && est.objectId == widget.objectId;
          }
          if (widget.contractId != null) {
            matches = matches && est.contractId == widget.contractId;
          }
          return matches;
        }).toList();
      }

      if (currentContextEstimates.isEmpty) return '1';

      int maxNumber = 0;
      bool hasDPrefix = false;

      // Анализируем номера на наличие префикса "д-"
      for (final est in currentContextEstimates) {
        final numStr = est.number.trim();
        // Проверяем формат "д-<число>" (регистронезависимо, допускаем D латинскую)
        // Пример: д-1, Д-5, d-10
        final match = RegExp(r'^[дДdD]\s*-\s*(\d+)$').firstMatch(numStr);
        if (match != null) {
          hasDPrefix = true;
          final num = int.tryParse(match.group(1) ?? '0') ?? 0;
          if (num > maxNumber) {
            maxNumber = num;
          }
        }
      }

      // Если нашли номера с префиксом "д-", генерируем следующий в том же формате
      if (hasDPrefix) {
        return 'д-${maxNumber + 1}';
      }

      // Если префикса "д-" не было, ищем максимум среди обычных целых чисел
      maxNumber = 0;
      for (final est in currentContextEstimates) {
        final numStr = est.number.trim();
        if (RegExp(r'^\d+$').hasMatch(numStr)) {
          final num = int.tryParse(numStr);
          if (num != null && num > maxNumber) {
            maxNumber = num;
          }
        }
      }

      return (maxNumber + 1).toString();
    } catch (e) {
      debugPrint('Error calculating next number: $e');
      return '';
    }
  }

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
      final systems =
          await estimateRepo.getSystems(estimateTitle: widget.estimateTitle);
      final subsystems =
          await estimateRepo.getSubsystems(estimateTitle: widget.estimateTitle);
      final units =
          await estimateRepo.getUnits(estimateTitle: widget.estimateTitle);

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
      final quantity =
          double.tryParse(_quantityController.text.replaceAll(',', '.')) ?? 0.0;
      final price =
          double.tryParse(_priceController.text.replaceAll(',', '.')) ?? 0.0;

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

      final updatedEstimate = Estimate(
        id: isEditing ? widget.estimate!.id : _uuid.v4(),
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

          // Проверяем ошибку, так как updateEstimate не пробрасывает её
          final error = ref.read(estimateNotifierProvider).error;
          if (error != null) {
            AppSnackBar.show(
              context: context,
              message: 'Ошибка обновления: $error',
              kind: AppSnackBarKind.error,
            );
            return;
          }

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

    if (isLargeScreen) {
      return DesktopDialogContent(
        title: title,
        width: 750,
        footer: Row(
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
                onPressed: _save,
              ),
            ),
          ],
        ),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: _buildFormFields(theme),
          ),
        ),
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
              onPressed: _save,
            ),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: _buildFormFields(theme),
        ),
      ),
    );
  }

  List<Widget> _buildFormFields(ThemeData theme) {
    return [
      Text(
        'Основная информация',
        style:
            theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 16),
      _buildTypeAhead(
        controller: _systemController,
        label: 'Система *',
        hint: 'Выберите или введите систему',
        items: _systems,
        isLoading: _systemsLoading,
        required: true,
      ),
      const SizedBox(height: 16),
      _buildTypeAhead(
        controller: _subsystemController,
        label: 'Подсистема *',
        hint: 'Выберите или введите подсистему',
        items: _subsystems,
        isLoading: _subsystemsLoading,
        required: true,
      ),
      const SizedBox(height: 16),
      TextFormField(
        controller: _numberController,
        decoration: const InputDecoration(
          labelText: 'Номер *',
          hintText: 'Введите порядковый номер',
          border: OutlineInputBorder(),
        ),
        validator: (v) =>
            v == null || v.trim().isEmpty ? 'Обязательное поле' : null,
      ),
      const SizedBox(height: 16),
      TextFormField(
        controller: _nameController,
        decoration: const InputDecoration(
          labelText: 'Наименование *',
          hintText: 'Введите наименование позиции',
          border: OutlineInputBorder(),
        ),
        validator: (v) =>
            v == null || v.trim().isEmpty ? 'Обязательное поле' : null,
        maxLines: null,
      ),
      const SizedBox(height: 24),
      Text(
        'Техническая информация',
        style:
            theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 16),
      TextFormField(
        controller: _articleController,
        decoration: const InputDecoration(
          labelText: 'Артикул',
          hintText: 'Введите артикул',
          border: OutlineInputBorder(),
        ),
      ),
      const SizedBox(height: 16),
      TextFormField(
        controller: _manufacturerController,
        decoration: const InputDecoration(
          labelText: 'Производитель',
          hintText: 'Введите производителя',
          border: OutlineInputBorder(),
        ),
      ),
      const SizedBox(height: 16),
      _buildTypeAhead(
        controller: _unitController,
        label: 'Единица измерения *',
        hint: 'Выберите или введите единицу измерения',
        items: _units,
        isLoading: _unitsLoading,
        required: true,
      ),
      const SizedBox(height: 24),
      Text(
        'Ценовая информация',
        style:
            theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 16),
      TextFormField(
        controller: _quantityController,
        decoration: const InputDecoration(
          labelText: 'Количество',
          hintText: 'Введите количество',
          border: OutlineInputBorder(),
        ),
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        validator: _numberValidator,
      ),
      const SizedBox(height: 16),
      TextFormField(
        controller: _priceController,
        decoration: const InputDecoration(
          labelText: 'Цена за единицу',
          hintText: 'Введите цену',
          border: OutlineInputBorder(),
        ),
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        validator: _numberValidator,
      ),
    ];
  }

  Widget _buildTypeAhead({
    required TextEditingController controller,
    required String label,
    required String hint,
    required List<String> items,
    required bool isLoading,
    bool required = false,
  }) {
    if (isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(child: CupertinoActivityIndicator()),
      );
    }
    return TypeAheadField<String>(
      controller: controller,
      suggestionsCallback: (pattern) {
        return items
            .where((s) => s.toLowerCase().contains(pattern.toLowerCase()))
            .toList();
      },
      builder: (context, controller, focusNode) {
        return TextFormField(
          controller: controller,
          focusNode: focusNode,
          decoration: InputDecoration(
            labelText: label,
            hintText: hint,
            border: const OutlineInputBorder(),
          ),
          validator: required
              ? (v) =>
                  v == null || v.trim().isEmpty ? 'Обязательное поле' : null
              : null,
        );
      },
      itemBuilder: (context, suggestion) {
        return ListTile(
          title: Text(suggestion),
        );
      },
      onSelected: (suggestion) {
        setState(() {
          controller.text = suggestion;
        });
      },
      emptyBuilder: (context) {
        final input = controller.text.trim();
        if (input.isEmpty) return const SizedBox();
        return ListTile(
          title: Text('Добавить: "$input"'),
          onTap: () {
            setState(() {
              controller.text = input;
            });
            FocusScope.of(context).unfocus();
          },
        );
      },
    );
  }

  String? _numberValidator(String? v) {
    if (v == null || v.trim().isEmpty) return null;
    try {
      double.parse(v.replaceAll(',', '.'));
    } catch (e) {
      return 'Введите число';
    }
    return null;
  }
}
