import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:projectgt/core/widgets/gt_dropdown.dart';
import 'package:projectgt/features/contractors/domain/entities/contractor.dart';
import 'package:projectgt/features/contractors/presentation/providers/subcontractors_selected_contract_provider.dart';
import 'package:projectgt/features/contractors/presentation/providers/subcontractors_selected_contractor_provider.dart';
import 'package:projectgt/features/contractors/presentation/providers/subcontractors_selected_object_provider.dart';
import 'package:projectgt/features/contractors/presentation/state/contractor_state.dart';
import 'package:projectgt/features/roles/application/permission_service.dart';

/// Выбор подрядчика для отображения его расценок в таблице (раздел «Подрядчики»).
///
/// В списке только [ContractorType.contractor]. Доступно после выбора объекта и договора.
class SubcontractorsContractorFilterField extends ConsumerWidget {
  /// Создаёт поле фильтра.
  const SubcontractorsContractorFilterField({
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
    if (!permissions.can('contractors', 'read')) {
      return Text(
        'Нет доступа',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      );
    }

    final objectId = ref.watch(subcontractorsSelectedObjectIdProvider);
    final contractId = ref.watch(subcontractorsSelectedContractIdProvider);
    final ready =
        objectId != null &&
        objectId.isNotEmpty &&
        contractId != null &&
        contractId.isNotEmpty;

    final contractorState = ref.watch(contractorNotifierProvider);
    final items =
        contractorState.contractors
            .where((c) => c.type == ContractorType.contractor)
            .toList()
          ..sort(
            (a, b) =>
                a.shortName.toLowerCase().compareTo(b.shortName.toLowerCase()),
          );

    final selectedId = ref.watch(subcontractorsSelectedContractorIdProvider);
    final Contractor? selected = selectedId == null
        ? null
        : items.firstWhereOrNull((c) => c.id == selectedId);

    if (selectedId != null && selected == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(subcontractorsSelectedContractorIdProvider.notifier).state =
            null;
      });
    }

    return GTDropdown<Contractor>(
      items: items,
      selectedItem: selected,
      itemDisplayBuilder: (c) =>
          c.shortName.trim().isNotEmpty ? c.shortName : c.fullName,
      labelText: compact ? '' : 'Подрядчик',
      hintText: ready ? 'Подрядчик' : 'Объект и договор',
      allowClear: true,
      readOnly: !ready,
      isDense: true,
      borderRadius: compact ? 20 : 12,
      borderSide: borderSide,
      prefixIcon: compact ? Icons.engineering_outlined : null,
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
      isLoading: contractorState.status == ContractorStatus.loading,
      onSelectionChanged: (item) {
        ref.read(subcontractorsSelectedContractorIdProvider.notifier).state =
            item?.id;
      },
    );
  }
}
