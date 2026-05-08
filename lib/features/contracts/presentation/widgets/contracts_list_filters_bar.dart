import 'package:flutter/material.dart';

import 'package:projectgt/core/widgets/gt_dropdown.dart';
import 'package:projectgt/domain/entities/contract.dart';
import 'package:projectgt/features/contracts/presentation/widgets/contract_list_shared.dart';

/// Элемент выпадающего списка «Контрагент»: ид и подпись в UI.
final class ContractsListContractorFilterItem {
  /// Создаёт опцию фильтра по контрагенту.
  const ContractsListContractorFilterItem({
    required this.contractorId,
    required this.label,
  });

  /// Идентификатор контрагента ([Contract.contractorId]).
  final String contractorId;

  /// Текст в списке (имя или запасная подпись).
  final String label;
}

/// Элемент выпадающего списка «Объект»: ид объекта и подпись в UI.
final class ContractsListObjectFilterItem {
  /// Создаёт опцию фильтра по объекту.
  const ContractsListObjectFilterItem({
    required this.objectId,
    required this.label,
  });

  /// Идентификатор объекта ([Contract.objectId]).
  final String objectId;

  /// Текст в списке (имя объекта или запасная подпись).
  final String label;
}

/// Блок фильтров списка договоров: тип договора, контрагент, объект.
///
/// Поля имеют общую фиксированную ширину ([fieldWidth]) и переносятся через [Wrap], без растягивания
/// на всю строку экрана. Варианты контрагентов и объектов собираются из
/// [allContracts], чтобы выпадающие списки не сужались вместе с поиском.
class ContractsListFiltersBar extends StatelessWidget {
  /// Создаёт блок фильтров.
  const ContractsListFiltersBar({
    super.key,
    required this.allContracts,
    required this.selectedKind,
    required this.onKindChanged,
    required this.selectedContractorId,
    required this.onContractorChanged,
    required this.selectedObjectId,
    required this.onObjectChanged,
    this.borderSide,
    this.compact = false,
    this.spacing = 10,
    this.fieldWidth = _defaultFilterFieldWidth,
  });

  /// Одна ширина для всех выпадающих фильтров по умолчанию (логические px).
  static const double _defaultFilterFieldWidth = 232;

  /// Полный список договоров компании для построения списков фильтров.
  final List<Contract> allContracts;

  /// Выбранный [Contract.kind] или `null`.
  final ContractKind? selectedKind;

  /// Изменение фильтра по типу договора.
  final ValueChanged<ContractKind?> onKindChanged;

  /// Выбранный [Contract.contractorId] или `null`.
  final String? selectedContractorId;

  /// Изменение фильтра по контрагенту.
  final ValueChanged<String?> onContractorChanged;

  /// Выбранный [Contract.objectId] или `null`.
  final String? selectedObjectId;

  /// Изменение фильтра по объекту.
  final ValueChanged<String?> onObjectChanged;

  /// Граница полей в стиле шапки атмосферы.
  final BorderSide? borderSide;

  /// Компактные поля без крупной подписи [labelText].
  final bool compact;

  /// Горизонтальный и вертикальный зазор между полями в [Wrap].
  final double spacing;

  /// Общая ширина каждого выпадающего поля (тип, контрагент, объект).
  final double fieldWidth;

  static List<ContractsListContractorFilterItem> _contractorOptionsFrom(
    List<Contract> contracts,
  ) {
    final map = <String, String>{};
    for (final c in contracts) {
      final name = c.contractorName?.trim();
      final label = name != null && name.isNotEmpty
          ? name
          : 'Контрагент ${c.contractorId}';
      map.putIfAbsent(c.contractorId, () => label);
    }
    final items = map.entries
        .map(
          (e) => ContractsListContractorFilterItem(
            contractorId: e.key,
            label: e.value,
          ),
        )
        .toList(growable: false);
    items.sort((a, b) => a.label.toLowerCase().compareTo(b.label.toLowerCase()));
    return items;
  }

  static List<ContractsListObjectFilterItem> _objectOptionsFrom(
    List<Contract> contracts,
  ) {
    final map = <String, String>{};
    for (final c in contracts) {
      final name = c.objectName?.trim();
      final label =
          name != null && name.isNotEmpty ? name : 'Объект ${c.objectId}';
      map.putIfAbsent(c.objectId, () => label);
    }
    final items = map.entries
        .map(
          (e) => ContractsListObjectFilterItem(
            objectId: e.key,
            label: e.value,
          ),
        )
        .toList(growable: false);
    items.sort((a, b) => a.label.toLowerCase().compareTo(b.label.toLowerCase()));
    return items;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final contractorItems = _contractorOptionsFrom(allContracts);
    ContractsListContractorFilterItem? selectedContractor;
    if (selectedContractorId != null) {
      for (final item in contractorItems) {
        if (item.contractorId == selectedContractorId) {
          selectedContractor = item;
          break;
        }
      }
    }

    final objectItems = _objectOptionsFrom(allContracts);
    ContractsListObjectFilterItem? selectedObject;
    if (selectedObjectId != null) {
      for (final o in objectItems) {
        if (o.objectId == selectedObjectId) {
          selectedObject = o;
          break;
        }
      }
    }

    final kindField = GTEnumDropdown<ContractKind>(
      values: ContractKind.values,
      selectedValue: selectedKind,
      onChanged: onKindChanged,
      labelText: compact ? '' : ContractListTableHeaders.kind,
      hintText: ContractListTableHeaders.kind,
      enumToString: ContractKindUi.label,
      allowClear: true,
      isDense: true,
      borderRadius: compact ? 20 : 12,
      borderSide: borderSide,
      contentPadding: compact
          ? const EdgeInsets.symmetric(horizontal: 6, vertical: 8)
          : null,
      style: compact
          ? theme.textTheme.bodyMedium?.copyWith(fontSize: 14)
          : null,
    );

    final contractorField = GTDropdown<ContractsListContractorFilterItem>(
      items: contractorItems,
      selectedItem: selectedContractor,
      itemDisplayBuilder: (item) => item.label,
      onSelectionChanged: (item) => onContractorChanged(item?.contractorId),
      labelText: compact ? '' : ContractListTableHeaders.contractor,
      hintText: ContractListTableHeaders.contractor,
      allowClear: true,
      isDense: true,
      borderRadius: compact ? 20 : 12,
      borderSide: borderSide,
      prefixIcon: compact ? Icons.corporate_fare_outlined : null,
      prefixIconSize: 18,
      prefixIconConstraints: compact
          ? const BoxConstraints(minWidth: 32, minHeight: 32)
          : null,
      suffixIconConstraints: compact
          ? const BoxConstraints(minWidth: 28, minHeight: 28)
          : null,
      contentPadding: compact
          ? const EdgeInsets.symmetric(horizontal: 6, vertical: 8)
          : null,
      maxDropdownHeight: 280,
      style: compact
          ? theme.textTheme.bodyMedium?.copyWith(fontSize: 14)
          : null,
    );

    final objectField = GTDropdown<ContractsListObjectFilterItem>(
      items: objectItems,
      selectedItem: selectedObject,
      itemDisplayBuilder: (item) => item.label,
      onSelectionChanged: (item) => onObjectChanged(item?.objectId),
      labelText: compact ? '' : ContractListTableHeaders.object,
      hintText: ContractListTableHeaders.object,
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
          ? const EdgeInsets.symmetric(horizontal: 6, vertical: 8)
          : null,
      maxDropdownHeight: 280,
      style: compact
          ? theme.textTheme.bodyMedium?.copyWith(fontSize: 14)
          : null,
    );

    return Wrap(
      spacing: spacing,
      runSpacing: spacing,
      crossAxisAlignment: WrapCrossAlignment.center,
      alignment: WrapAlignment.start,
      children: [
        SizedBox(width: fieldWidth, child: kindField),
        SizedBox(width: fieldWidth, child: contractorField),
        SizedBox(width: fieldWidth, child: objectField),
      ],
    );
  }
}
