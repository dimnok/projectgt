import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:projectgt/core/di/providers.dart';
import 'package:projectgt/core/utils/modal_utils.dart';
import 'package:projectgt/domain/entities/estimate.dart';
import 'package:projectgt/core/widgets/gt_dropdown.dart';

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

      if (!mounted) return;
      Navigator.pop(context, {
        'name': estimate.name,
        'unit': estimate.unit,
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Не удалось сохранить материал: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AnimatedPadding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      child: Material(
        color: theme.colorScheme.surface,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Заголовок в едином стиле
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                border: Border(
                  bottom: BorderSide(
                    color: theme.colorScheme.outline.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
              ),
              child: ModalUtils.buildModalHeader(
                title: 'Новый материал',
                onClose: () => Navigator.pop(context),
                theme: theme,
              ),
            ),

            // Контент (shrink-wrap)
            Padding(
              padding: const EdgeInsets.fromLTRB(24.0, 24.0, 24.0, 0.0),
              child: Center(
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
                            validator: (v) => v == null || v.isEmpty
                                ? 'Выберите смету'
                                : null,
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
                          validator: (v) => v == null || v.isEmpty
                              ? 'Обязательное поле'
                              : null,
                          onSelectionChanged: (value) {
                            setState(() => _unit = value);
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Кнопки действия внизу
            Padding(
              padding: EdgeInsets.fromLTRB(
                24.0,
                16.0,
                24.0,
                24.0 + MediaQuery.of(context).viewPadding.bottom,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed:
                          _isSaving ? null : () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(44),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      child: const Text('Отмена'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isSaving
                          ? null
                          : () {
                              if (_formKey.currentState?.validate() ?? false) {
                                _save();
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(44),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CupertinoActivityIndicator(radius: 10),
                            )
                          : const Text('Сохранить'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
