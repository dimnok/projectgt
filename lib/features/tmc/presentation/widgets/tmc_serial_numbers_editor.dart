import 'package:flutter/material.dart';
import 'package:projectgt/core/widgets/gt_text_field.dart';
import 'package:projectgt/features/tmc/presentation/utils/tmc_ui_labels.dart';

/// Поля серийных номеров для поступления индивидуальных единиц ТМЦ.
///
/// Количество полей следует за [unitCount]. Значения читаются через [values].
class TmcSerialNumbersEditor extends StatefulWidget {
  /// Сколько экземпляров будет принято (сколько полей S/N показать).
  final int unitCount;

  /// Создаёт редактор серийных номеров.
  const TmcSerialNumbersEditor({super.key, required this.unitCount});

  @override
  State<TmcSerialNumbersEditor> createState() => TmcSerialNumbersEditorState();
}

/// Состояние редактора серийных номеров.
class TmcSerialNumbersEditorState extends State<TmcSerialNumbersEditor> {
  final List<TextEditingController> _controllers = [];

  /// Текущие серийные номера (пустые строки отфильтровываются снаружи при необходимости).
  List<String> get values =>
      _controllers.map((c) => c.text.trim()).toList(growable: false);

  @override
  void initState() {
    super.initState();
    _syncControllers(widget.unitCount);
  }

  @override
  void didUpdateWidget(covariant TmcSerialNumbersEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.unitCount != widget.unitCount) {
      _syncControllers(widget.unitCount);
    }
  }

  void _syncControllers(int count) {
    final safeCount = count.clamp(0, TmcUiLabels.maxSerialFields);
    while (_controllers.length > safeCount) {
      _controllers.removeLast().dispose();
    }
    while (_controllers.length < safeCount) {
      _controllers.add(TextEditingController());
    }
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.unitCount <= 0) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final tooMany = widget.unitCount > TmcUiLabels.maxSerialFields;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          widget.unitCount == 1
              ? 'Серийный номер экземпляра'
              : 'Серийные номера экземпляров',
          style: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          tooMany
              ? 'Показаны поля для первых ${TmcUiLabels.maxSerialFields} единиц. Остальные S/N можно указать позже в карточке.'
              : 'Заводской номер с шильдика инструмента. Можно заполнить позже.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: scheme.onSurface.withValues(alpha: 0.55),
          ),
        ),
        const SizedBox(height: 10),
        for (var i = 0; i < _controllers.length; i++) ...[
          if (i > 0) const SizedBox(height: 8),
          GTTextField(
            controller: _controllers[i],
            labelText: widget.unitCount == 1
                ? 'Серийный номер (S/N)'
                : 'S/N экземпляра ${i + 1}',
            hintText: 'Например: 98452109',
          ),
        ],
      ],
    );
  }
}
