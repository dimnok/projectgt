import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:projectgt/core/di/providers.dart';
import 'package:projectgt/core/widgets/gt_dropdown.dart';
import 'package:projectgt/domain/entities/contract.dart';
import 'package:projectgt/features/contractors/presentation/providers/subcontractors_selected_contract_provider.dart';
import 'package:projectgt/features/contractors/presentation/providers/subcontractors_selected_contractor_provider.dart';
import 'package:projectgt/features/contractors/presentation/providers/subcontractors_selected_object_provider.dart';
import 'package:projectgt/features/roles/application/permission_service.dart';

/// Поле выбора договора для фильтрации смет (раздел «Подрядчики»).
///
/// Список договоров ограничен выбранным [subcontractorsSelectedObjectIdProvider].
/// [compact] — одна строка с [GTDropdown] как у [SubcontractorsObjectFilterField].
class SubcontractorsContractFilterField extends ConsumerWidget {
  /// Создаёт поле фильтра.
  const SubcontractorsContractFilterField({
    super.key,
    this.compact = false,
    this.borderSide,
    this.style,
  });

  /// Плотное поле в одну линию с шапкой.
  final bool compact;

  /// Граница поля.
  final BorderSide? borderSide;

  /// Стиль текста значения/подсказки.
  final TextStyle? style;

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

    final objectId = ref.watch(subcontractorsSelectedObjectIdProvider);
    final contractState = ref.watch(contractProvider);
    final items =
        objectId == null || objectId.isEmpty
              ? <Contract>[]
              : contractState.contracts
                    .where((c) => c.objectId == objectId)
                    .toList()
          ..sort(
            (a, b) => a.number.toLowerCase().compareTo(b.number.toLowerCase()),
          );

    final selectedId = ref.watch(subcontractorsSelectedContractIdProvider);
    final Contract? selected = selectedId == null
        ? null
        : items.firstWhereOrNull((c) => c.id == selectedId);

    if (selectedId != null && selected == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(subcontractorsSelectedContractIdProvider.notifier).state =
            null;
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
      prefixIcon: compact ? Icons.assignment_outlined : null,
      prefixIconSize: 18,
      prefixIconConstraints: compact
          ? const BoxConstraints(minWidth: 32, minHeight: 32)
          : null,
      suffixIconConstraints: compact
          ? const BoxConstraints(minWidth: 28, minHeight: 28)
          : null,
      contentPadding: compact
          ? const EdgeInsets.symmetric(horizontal: 4, vertical: 6)
          : null,
      style:
          style ??
          (compact ? theme.textTheme.bodyMedium?.copyWith(fontSize: 14) : null),
      onSelectionChanged: (item) {
        ref.read(subcontractorsSelectedContractIdProvider.notifier).state =
            item?.id;
        ref.read(subcontractorsSelectedContractorIdProvider.notifier).state =
            null;
      },
    );
  }
}
