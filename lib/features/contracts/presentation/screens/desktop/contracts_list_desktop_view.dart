import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:projectgt/domain/entities/contract.dart';
import 'package:projectgt/features/contracts/presentation/widgets/contract_details_panel.dart';
import 'package:projectgt/features/contracts/presentation/widgets/contract_table_view.dart';

/// Десктопное представление списка договоров (таблица-карточки без отдельной «оболочки»).
///
/// Заголовок и поиск вынесены на экран [ContractsListScreen] в стиле атмосферы.
class ContractsListDesktopView extends ConsumerStatefulWidget {
  /// Отфильтрованный список договоров.
  final List<Contract> filteredContracts;

  /// Загрузка данных.
  final bool isLoading;

  /// Ошибка загрузки.
  final bool isError;

  /// Текст ошибки.
  final String? errorMessage;

  /// Открыть форму редактирования договора.
  final void Function(Contract contract) onEditContract;

  /// Есть ли непустой поисковый запрос (влияет на текст пустого состояния).
  final bool hasActiveSearch;

  /// Создаёт виджет.
  const ContractsListDesktopView({
    super.key,
    required this.filteredContracts,
    required this.isLoading,
    required this.isError,
    this.errorMessage,
    required this.hasActiveSearch,
    required this.onEditContract,
  });

  @override
  ConsumerState<ContractsListDesktopView> createState() =>
      _ContractsListDesktopViewState();
}

class _ContractsListDesktopViewState
    extends ConsumerState<ContractsListDesktopView> {
  String? _selectedContractId;

  @override
  void didUpdateWidget(ContractsListDesktopView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_selectedContractId != null) {
      final containsSelected = widget.filteredContracts.any(
        (c) => c.id == _selectedContractId,
      );
      if (!containsSelected) {
        _selectedContractId = null;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (widget.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (widget.isError) {
      return Center(child: Text(widget.errorMessage ?? 'Ошибка'));
    }
    if (widget.filteredContracts.isEmpty) {
      return Center(
        child: Text(
          widget.hasActiveSearch
              ? 'По вашему запросу ничего не найдено'
              : 'Список договоров пуст',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    return ContractTableView(
      contracts: widget.filteredContracts,
      selectedId: _selectedContractId,
      onSelect: (contract) async {
        setState(() {
          _selectedContractId = contract.id;
        });
        await ContractDetailsPanel.show(
          context,
          contract: contract,
          onEdit: () => widget.onEditContract(contract),
        );
        if (!mounted) return;
        setState(() {
          _selectedContractId = null;
        });
      },
    );
  }
}
