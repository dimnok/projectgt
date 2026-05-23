import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/di/providers.dart';
import '../../../../core/widgets/gt_dropdown.dart';
import '../../../../presentation/state/profile_state.dart';
import '../../../objects/domain/entities/object.dart';
import '../providers/materials_context_providers.dart';
import '../providers/materials_providers.dart';

/// Выпадающий список выбора объекта в модуле «Материалы».
class MaterialsObjectFilterField extends ConsumerWidget {
  /// Создаёт поле выбора объекта.
  const MaterialsObjectFilterField({
    super.key,
    this.compact = false,
    this.borderSide,
  });

  /// Компактный режим (без подписи над полем).
  final bool compact;

  /// Граница поля в стиле шапки атмосферы.
  final BorderSide? borderSide;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final profile = ref.watch(currentUserProfileProvider).profile;
    final allowedObjectIds = profile?.objectIds ?? const <String>[];

    final objectState = ref.watch(objectProvider);
    final objects = (allowedObjectIds.isNotEmpty
            ? objectState.objects
                  .where((o) => allowedObjectIds.contains(o.id))
                  .toList()
            : List<ObjectEntity>.from(objectState.objects))
          ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    final selectedId = ref.watch(selectedMaterialsObjectIdProvider);
    final ObjectEntity? selected = selectedId == null
        ? null
        : objects.firstWhereOrNull((o) => o.id == selectedId);

    if (selectedId != null && selected == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(selectedMaterialsObjectIdProvider.notifier).state = null;
        ref.read(selectedMaterialsContractIdProvider.notifier).state = null;
        ref.read(selectedContractNumberProvider.notifier).state = null;
      });
    }

    return GTDropdown<ObjectEntity>(
      items: objects,
      selectedItem: selected,
      itemDisplayBuilder: (o) => o.name,
      labelText: compact ? '' : 'Объект',
      hintText: 'Объект',
      allowClear: true,
      isDense: true,
      borderRadius: compact ? 20 : 12,
      borderSide: borderSide,
      contentPadding: compact
          ? const EdgeInsets.symmetric(horizontal: 6, vertical: 8)
          : null,
      prefixIcon: compact ? Icons.apartment_outlined : null,
      prefixIconSize: 18,
      prefixIconConstraints: compact
          ? const BoxConstraints(minWidth: 32, minHeight: 32)
          : null,
      suffixIconConstraints: compact
          ? const BoxConstraints(minWidth: 28, minHeight: 28)
          : null,
      style: compact ? theme.textTheme.bodyMedium?.copyWith(fontSize: 14) : null,
      maxDropdownHeight: 280,
      onSelectionChanged: (item) {
        ref.read(selectedMaterialsObjectIdProvider.notifier).state = item?.id;
        ref.read(selectedMaterialsContractIdProvider.notifier).state = null;
        ref.read(selectedContractNumberProvider.notifier).state = null;
      },
    );
  }
}
