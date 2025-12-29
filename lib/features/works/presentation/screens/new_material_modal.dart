import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:projectgt/core/di/providers.dart';
import 'package:projectgt/core/utils/responsive_utils.dart';
import 'package:projectgt/domain/entities/estimate.dart';
import 'package:projectgt/core/widgets/app_snackbar.dart';
import 'package:projectgt/core/widgets/desktop_dialog_content.dart';
import 'package:projectgt/core/widgets/gt_buttons.dart';
import 'package:projectgt/core/widgets/gt_dropdown.dart';
import 'package:projectgt/core/widgets/mobile_bottom_sheet_content.dart';

/// Модалка "Новый материал"
///
/// Добавляет новую позицию сметы (материал) в общий список для текущего объекта и выбранных
/// системы/подсистемы. После сохранения закрывается и возвращает карту с полями
/// { 'name': <String>, 'unit': <String> } для последующего авто-выбора в родительской модалке.
class NewMaterialModal extends ConsumerStatefulWidget {
  /// Идентификатор объекта.
  final String objectId;

  /// Выбранная система.
  final String system;

  /// Выбранная подсистема.
  final String subsystem;

  /// Контроллер прокрутки, передаваемый внешней оберткой (для единого поведения кнопок).
  final ScrollController? scrollController;

  /// Создаёт модальное окно добавления нового материала.
  ///
  /// Требует идентификатор объекта [objectId], выбранные [system] и [subsystem].
  /// Опционально принимает внешний [scrollController] для синхронизации прокрутки.
  const NewMaterialModal({
    super.key,
    required this.objectId,
    required this.system,
    required this.subsystem,
    this.scrollController,
  });

  @override
  ConsumerState<NewMaterialModal> createState() => _NewMaterialModalState();
}

class _NewMaterialModalState extends ConsumerState<NewMaterialModal> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _articleController = TextEditingController();
  final _manufacturerController = TextEditingController();
  String? _unit;
  String? _selectedEstimateTitle;
  List<String> _availableEstimateTitles = [];

  bool _isSaving = false;

  // Базовый набор единиц измерения
  static const List<String> _units = <String>[
    'шт',
    'м',
    'кг',
    'л',
    'м²',
    'м³',
    'компл.'
  ];

  @override
  void initState() {
    super.initState();
    final all = ref.read(estimateNotifierProvider).estimates;
    _availableEstimateTitles = all
        .where((e) =>
            e.objectId == widget.objectId &&
            e.system == widget.system &&
            e.subsystem == widget.subsystem &&
            (e.estimateTitle != null && e.estimateTitle!.trim().isNotEmpty))
        .map((e) => e.estimateTitle!)
        .toSet()
        .toList()
      ..sort();
    if (_availableEstimateTitles.isNotEmpty) {
      _selectedEstimateTitle = _availableEstimateTitles.first;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _articleController.dispose();
    _manufacturerController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _isSaving = true);

    try {
      // Ищем любую запись выбранной сметы для наследования contractId
      final all = ref.read(estimateNotifierProvider).estimates;
      final sample = all.firstWhere(
        (e) =>
            e.objectId == widget.objectId &&
            e.system == widget.system &&
            e.subsystem == widget.subsystem &&
            e.estimateTitle == _selectedEstimateTitle,
        orElse: () => all.isNotEmpty ? all.first : all.first,
      );

      // Генерируем следующий номер в формате "д-<N>" для выбранной сметы
      String generateNextNumber() {
        int maxNum = 0;
        for (final e in all) {
          if (e.objectId == widget.objectId &&
              e.system == widget.system &&
              e.subsystem == widget.subsystem &&
              e.estimateTitle == _selectedEstimateTitle) {
            // ignore: deprecated_member_use
            final match = RegExp(r'^д-(\d+)$', caseSensitive: false)
                .firstMatch(e.number.trim());
            if (match != null) {
              final n = int.tryParse(match.group(1) ?? '0') ?? 0;
              if (n > maxNum) maxNum = n;
            }
          }
        }
        return 'д-${maxNum + 1}';
      }

      final nextNumber = generateNextNumber();

      final estimate = Estimate(
        id: '',
        system: widget.system,
        subsystem: widget.subsystem,
        number: nextNumber,
        name: _nameController.text.trim(),
        article: _articleController.text.trim(),
        manufacturer: _manufacturerController.text.trim(),
        unit: _unit!.trim(),
        quantity: 0,
        price: 0,
        total: 0,
        objectId: widget.objectId,
        contractId: sample.contractId,
        estimateTitle: _selectedEstimateTitle,
      );

      await ref.read(estimateNotifierProvider.notifier).addEstimate(estimate);

      // Если провайдер вернул ошибку (например, нет прав на insert в сметы) — явно бросаем,
      // чтобы модалка не закрывалась молча.
      final error = ref.read(estimateNotifierProvider).error;
      if (error != null) {
        throw Exception(error);
      }

      if (!mounted) return;
      // Показываем поверх модалок, закрепляем сверху
      AppSnackBar.show(
        context: context,
        message: 'Материал добавлен',
        position: AppSnackBarPosition.top,
        kind: AppSnackBarKind.success,
      );
      Navigator.pop(context, {
        'name': estimate.name,
        'unit': estimate.unit,
      });
    } catch (e) {
      if (!mounted) return;
      final raw = e.toString();
      final isPermissionError = raw.contains('permission') ||
          raw.contains('row-level security') ||
          raw.contains('42501');
      final message = isPermissionError
          ? 'Нет доступа к добавлению материалов в смету. Обратитесь к администратору.'
          : 'Не удалось сохранить материал. Попробуйте ещё раз или обратитесь к администратору.';
      // Показываем поверх модалок, закрепляем сверху
      AppSnackBar.show(
        context: context,
        message: message,
        position: AppSnackBarPosition.top,
        kind: AppSnackBarKind.error,
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveUtils.isDesktop(context);

    Widget buildFormContent() {
      return Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 700),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_availableEstimateTitles.isNotEmpty) ...[
                  GTStringDropdown(
                    items: _availableEstimateTitles,
                    selectedItem: _selectedEstimateTitle,
                    labelText: 'Смета *',
                    hintText: 'Выберите смету',
                    allowCustomInput: false,
                    allowClear: false,
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Выберите смету' : null,
                    onSelectionChanged: (v) {
                      setState(() => _selectedEstimateTitle = v);
                    },
                  ),
                  const SizedBox(height: 12),
                ],
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Наименование *',
                  ),
                  validator: (v) => v == null || v.trim().isEmpty
                      ? 'Обязательное поле'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _articleController,
                  decoration: const InputDecoration(
                    labelText: 'Артикул',
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _manufacturerController,
                  decoration: const InputDecoration(
                    labelText: 'Производитель',
                  ),
                ),
                const SizedBox(height: 12),
                GTStringDropdown(
                  items: _units,
                  selectedItem: _unit,
                  labelText: 'Единица измерения *',
                  hintText: 'Выберите единицу измерения',
                  allowCustomInput: false,
                  allowClear: true,
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Обязательное поле' : null,
                  onSelectionChanged: (value) {
                    setState(() => _unit = value);
                  },
                ),
              ],
            ),
          ),
        ),
      );
    }

    Widget buildFooterButtons() {
      return Row(
        children: [
          Expanded(
            child: GTSecondaryButton(
              text: 'Отмена',
              onPressed: _isSaving ? null : () => Navigator.pop(context),
              isLoading: false,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: GTPrimaryButton(
              text: 'Сохранить',
              onPressed: _isSaving ? null : _save,
              isLoading: _isSaving,
            ),
          ),
        ],
      );
    }

    if (isDesktop) {
      return DesktopDialogContent(
        title: 'Новый материал',
        onClose: _isSaving ? null : () => Navigator.pop(context),
        footer: buildFooterButtons(),
        child: buildFormContent(),
      );
    }

    return MobileBottomSheetContent(
      title: 'Новый материал',
      footer: buildFooterButtons(),
      child: buildFormContent(),
    );
  }
}
