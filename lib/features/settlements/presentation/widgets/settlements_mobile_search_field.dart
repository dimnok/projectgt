import 'package:flutter/material.dart';
import 'package:projectgt/core/widgets/gt_text_field.dart';

/// Компактное поле поиска в шапке мобильного реестра взаиморасчётов.
class SettlementsMobileSearchField extends StatefulWidget {
  /// Текущий текст поиска.
  final String searchQuery;

  /// Колбэк при изменении поиска.
  final ValueChanged<String> onSearchChanged;

  /// Создаёт поле поиска.
  const SettlementsMobileSearchField({
    super.key,
    required this.searchQuery,
    required this.onSearchChanged,
  });

  @override
  State<SettlementsMobileSearchField> createState() =>
      _SettlementsMobileSearchFieldState();
}

class _SettlementsMobileSearchFieldState
    extends State<SettlementsMobileSearchField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.searchQuery);
    _controller.addListener(() => setState(() {}));
  }

  @override
  void didUpdateWidget(covariant SettlementsMobileSearchField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.searchQuery != _controller.text &&
        widget.searchQuery != oldWidget.searchQuery) {
      _controller.text = widget.searchQuery;
      _controller.selection = TextSelection.collapsed(
        offset: _controller.text.length,
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _clear() {
    _controller.clear();
    widget.onSearchChanged('');
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final hasText = _controller.text.isNotEmpty;

    return GTTextField(
      controller: _controller,
      hintText: 'Поиск',
      prefixIcon: Icons.search_rounded,
      prefixIconSize: 22,
      borderRadius: 22,
      textCapitalization: TextCapitalization.none,
      onChanged: widget.onSearchChanged,
      style: TextStyle(
        color: scheme.onSurface,
        fontSize: 15,
        fontWeight: FontWeight.w400,
      ),
      contentPadding: const EdgeInsets.fromLTRB(0, 10, 8, 10),
      prefixIconConstraints: const BoxConstraints(
        minWidth: 44,
        minHeight: 40,
      ),
      suffixIconConstraints: const BoxConstraints(
        minWidth: 40,
        minHeight: 40,
      ),
      suffixIcon: hasText
          ? IconButton(
              onPressed: _clear,
              padding: EdgeInsets.zero,
              visualDensity: VisualDensity.compact,
              icon: Icon(
                Icons.close_rounded,
                size: 20,
                color: scheme.onSurfaceVariant,
              ),
              tooltip: 'Очистить',
            )
          : null,
    );
  }
}
