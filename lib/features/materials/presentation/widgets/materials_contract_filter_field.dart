import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/di/providers.dart';
import '../../../../core/widgets/gt_dropdown.dart';
import '../../../../domain/entities/contract.dart';
import '../../../roles/application/permission_service.dart';
import '../providers/materials_context_providers.dart';
import '../providers/materials_providers.dart';

/// Выпадающий список выбора договора в модуле «Материалы».
///
/// Список ограничен [selectedMaterialsObjectIdProvider] и активными договорами.
class MaterialsContractFilterField extends ConsumerWidget {
  /// Создаёт поле выбора договора.
  const MaterialsContractFilterField({
    super.key,
    this.compact = false,
    this.borderSide,
  });

  /// Компактный режим.
  final bool compact;

  /// Граница поля в стиле шапки атмосферы.
  final BorderSide? borderSide;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final permissions = ref.watch(permissionServiceProvider);
    if (!permissions.can('contracts', 'read')) {
      return Text(
        'Нет доступа к договорам',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      );
    }

    final objectId = ref.watch(selectedMaterialsObjectIdProvider);
    final contractState = ref.watch(contractProvider);
    final items = objectId == null || objectId.isEmpty
        ? <Contract>[]
        : contractState.contracts
              .where(
                (c) => c.objectId == objectId && isMaterialsActiveContract(c),
              )
              .toList()
          ..sort(
            (a, b) => a.number.toLowerCase().compareTo(b.number.toLowerCase()),
          );

    final selectedId = ref.watch(selectedMaterialsContractIdProvider);
    final Contract? selected = selectedId == null
        ? null
        : items.firstWhereOrNull((c) => c.id == selectedId);

    if (selectedId != null && selected == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(selectedMaterialsContractIdProvider.notifier).state = null;
        ref.read(selectedContractNumberProvider.notifier).state = null;
      });
    }

    final noObject = objectId == null || objectId.isEmpty;

    return GTDropdown<Contract>(
      items: items,
      selectedItem: selected,
      itemDisplayBuilder: (c) => c.number,
      labelText: compact ? '' : 'Договор',
      hintText: noObject ? 'Сначала объект' : 'Договор',
      allowClear: true,
      readOnly: noObject,
      isDense: true,
      borderRadius: compact ? 20 : 12,
      borderSide: borderSide,
      contentPadding: compact
          ? const EdgeInsets.symmetric(horizontal: 6, vertical: 8)
          : null,
      maxDropdownHeight: 280,
      prefixIcon: compact ? Icons.assignment_outlined : null,
      prefixIconSize: 18,
      prefixIconConstraints: compact
          ? const BoxConstraints(minWidth: 32, minHeight: 32)
          : null,
      suffixIconConstraints: compact
          ? const BoxConstraints(minWidth: 28, minHeight: 28)
          : null,
      style: compact ? theme.textTheme.bodyMedium?.copyWith(fontSize: 14) : null,
      onSelectionChanged: (contract) {
        ref.read(selectedMaterialsContractIdProvider.notifier).state =
            contract?.id;
        ref.read(selectedContractNumberProvider.notifier).state =
            contract?.number;
      },
    );
  }
}
