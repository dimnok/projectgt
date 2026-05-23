import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../company/presentation/providers/company_providers.dart';
import '../providers/materials_context_providers.dart';
import '../providers/materials_providers.dart';
import 'materials_contract_filter_field.dart';
import 'materials_list_chrome.dart';
import 'materials_object_filter_field.dart';

/// Полоса фильтров экрана материалов: объект и договор.
class MaterialsListFiltersBar extends ConsumerWidget {
  /// Создаёт полосу фильтров.
  const MaterialsListFiltersBar({
    super.key,
    required this.borderSide,
    this.compact = true,
    this.spacing = 10,
  });

  /// Граница полей в стиле шапки атмосферы.
  final BorderSide borderSide;

  /// Компактные поля без крупной подписи.
  final bool compact;

  /// Зазор между полями в [Wrap].
  final double spacing;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<String?>(activeCompanyIdProvider, (previous, next) {
      if (previous != null && previous != next) {
        ref.read(selectedMaterialsObjectIdProvider.notifier).state = null;
        ref.read(selectedMaterialsContractIdProvider.notifier).state = null;
        ref.read(selectedContractNumberProvider.notifier).state = null;
      }
    });

    return Wrap(
      spacing: spacing,
      runSpacing: spacing,
      crossAxisAlignment: WrapCrossAlignment.center,
      alignment: WrapAlignment.start,
      children: [
        SizedBox(
          width: MaterialsListScreenChrome.filterFieldWidth,
          child: MaterialsObjectFilterField(
            compact: compact,
            borderSide: borderSide,
          ),
        ),
        SizedBox(
          width: MaterialsListScreenChrome.filterFieldWidth,
          child: MaterialsContractFilterField(
            compact: compact,
            borderSide: borderSide,
          ),
        ),
      ],
    );
  }
}
