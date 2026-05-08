import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:projectgt/core/widgets/gt_text_field.dart';
import 'package:projectgt/core/widgets/mobile_atmosphere_backdrop.dart';
import 'package:projectgt/features/contractors/presentation/providers/subcontractors_estimate_name_search_provider.dart';

/// Строка поиска позиций сметы по наименованию для раздела «Подрядчики».
class SubcontractorsEstimateNameSearchField extends ConsumerStatefulWidget {
  /// Внешние отступы поля.
  final EdgeInsetsGeometry padding;

  /// Создаёт строку поиска позиций по наименованию.
  const SubcontractorsEstimateNameSearchField({
    super.key,
    this.padding = EdgeInsets.zero,
  });

  @override
  ConsumerState<SubcontractorsEstimateNameSearchField> createState() =>
      _SubcontractorsEstimateNameSearchFieldState();
}

class _SubcontractorsEstimateNameSearchFieldState
    extends ConsumerState<SubcontractorsEstimateNameSearchField> {
  final _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller.text = ref.read(subcontractorsEstimateNameSearchProvider);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _clearSearch() {
    _controller.clear();
    ref.read(subcontractorsEstimateNameSearchProvider.notifier).state = '';
  }

  @override
  Widget build(BuildContext context) {
    final appearance = MobileAtmosphereAppearance.of(context);
    final scheme = appearance.scheme;
    final textStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      color: scheme.onSurface,
    );

    ref.listen<String>(subcontractorsEstimateNameSearchProvider, (
      previous,
      next,
    ) {
      if (_controller.text == next) return;
      _controller.value = TextEditingValue(
        text: next,
        selection: TextSelection.collapsed(offset: next.length),
      );
    });

    final query = ref.watch(subcontractorsEstimateNameSearchProvider);

    return Padding(
      padding: widget.padding,
      child: Semantics(
        label: 'Поиск позиций по наименованию',
        textField: true,
        child: SizedBox(
          height: 44,
          child: GTTextField(
            controller: _controller,
            hintText: 'Поиск по наименованию...',
            prefixIcon: Icons.search_rounded,
            prefixIconColor: scheme.onSurfaceVariant,
            prefixIconSize: 18,
            prefixIconConstraints: const BoxConstraints(
              minWidth: 38,
              minHeight: 38,
            ),
            style: textStyle,
            fillColor: appearance.chromeFill,
            borderSide: BorderSide(color: appearance.chromeBorder),
            focusedBorderSide: BorderSide(
              color: scheme.primary.withValues(alpha: 0.65),
              width: 1.2,
            ),
            borderRadius: 22,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 4,
              vertical: 11,
            ),
            textInputAction: TextInputAction.search,
            onChanged: (value) {
              ref
                      .read(subcontractorsEstimateNameSearchProvider.notifier)
                      .state =
                  value;
            },
            suffixIcon: query.trim().isEmpty
                ? null
                : IconButton(
                    tooltip: 'Очистить поиск',
                    color: scheme.onSurfaceVariant,
                    icon: const Icon(Icons.close_rounded, size: 18),
                    onPressed: _clearSearch,
                  ),
            suffixIconConstraints: const BoxConstraints(
              minWidth: 38,
              minHeight: 38,
            ),
          ),
        ),
      ),
    );
  }
}
