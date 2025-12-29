import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// Виджет текстового поля для поиска позиций сметы.
class EstimateSearchField extends StatefulWidget {
  /// Создает экземпляр [EstimateSearchField].
  const EstimateSearchField({
    super.key,
    required this.onChanged,
    this.hintText = 'Поиск по наименованию...',
  });

  /// Обратный вызов при изменении текста поиска.
  final ValueChanged<String> onChanged;

  /// Текст подсказки (placeholder).
  final String hintText;

  @override
  State<EstimateSearchField> createState() => _EstimateSearchFieldState();
}

class _EstimateSearchFieldState extends State<EstimateSearchField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return SizedBox(
      width: 300,
      height: 32,
      child: CupertinoSearchTextField(
        controller: _controller,
        onChanged: widget.onChanged,
        placeholder: widget.hintText,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurface,
        ),
        placeholderStyle: TextStyle(
          color: theme.colorScheme.outline,
        ),
        decoration: BoxDecoration(
          color: isDark
              ? theme.colorScheme.surfaceContainerHighest
              : theme.colorScheme.onSurface.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(9),
          border: Border.all(
            color: isDark
                ? Colors.transparent
                : theme.colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
        itemColor: theme.colorScheme.outline,
      ),
    );
  }
}

