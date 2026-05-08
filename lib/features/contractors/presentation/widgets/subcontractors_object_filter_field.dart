import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:projectgt/core/di/providers.dart';
import 'package:projectgt/core/widgets/gt_dropdown.dart';
import 'package:projectgt/features/contractors/presentation/providers/subcontractors_selected_contract_provider.dart';
import 'package:projectgt/features/contractors/presentation/providers/subcontractors_selected_contractor_provider.dart';
import 'package:projectgt/features/contractors/presentation/providers/subcontractors_selected_object_provider.dart';
import 'package:projectgt/features/objects/domain/entities/object.dart';
import 'package:projectgt/features/roles/application/permission_service.dart';

/// Поле выбора объекта для фильтрации смет (раздел «Подрядчики»).
///
/// [compact] — одна строка: без [label] над полем, меньше шрифт и отступы.
class SubcontractorsObjectFilterField extends ConsumerWidget {
  /// Создаёт поле фильтра.
  const SubcontractorsObjectFilterField({
    super.key,
    this.compact = false,
    this.borderSide,
    this.style,
  });

  /// Плотное поле в одну линию с шапкой.
  final bool compact;

  /// Граница поля (например как у кнопок в [MobileAtmosphereAppearance]).
  final BorderSide? borderSide;

  /// Стиль текста значения/подсказки.
  final TextStyle? style;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final permissions = ref.watch(permissionServiceProvider);
    if (!permissions.can('objects', 'read')) {
      return Text(
        'Нет доступа к объектам',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      );
    }

    final objectState = ref.watch(objectProvider);
    final objects = objectState.objects;
    final selectedId = ref.watch(subcontractorsSelectedObjectIdProvider);
    final ObjectEntity? selected = selectedId == null
        ? null
        : objects.firstWhereOrNull((o) => o.id == selectedId);

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
      prefixIcon: compact ? Icons.apartment_outlined : null,
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
        ref.read(subcontractorsSelectedObjectIdProvider.notifier).state =
            item?.id;
        ref.read(subcontractorsSelectedContractIdProvider.notifier).state =
            null;
        ref.read(subcontractorsSelectedContractorIdProvider.notifier).state =
            null;
      },
    );
  }
}
