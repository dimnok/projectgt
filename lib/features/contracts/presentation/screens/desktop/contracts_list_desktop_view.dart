import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:projectgt/domain/entities/contract.dart';
import 'package:projectgt/features/contracts/presentation/screens/contract_form_screen.dart';
import 'package:projectgt/features/contracts/presentation/widgets/contract_table_view.dart';
import 'package:projectgt/features/contracts/presentation/widgets/contract_details_panel.dart';
import 'package:projectgt/features/roles/presentation/widgets/permission_guard.dart';
import 'package:projectgt/core/widgets/gt_buttons.dart';
import 'package:projectgt/core/widgets/gt_text_field.dart';

/// Десктопное представление списка договоров.
///
/// Реализует табличный интерфейс для отображения договоров на весь экран.
/// Каждая строка таблицы - это карточка с информацией: номер договора,
/// контрагент, дата окончания, сумма, статус.
class ContractsListDesktopView extends ConsumerStatefulWidget {
  /// Список отфильтрованных договоров для отображения.
  final List<Contract> filteredContracts;

  /// Текущий поисковый запрос.
  final String searchQuery;

  /// Коллбэк для поиска.
  final Function(String) onSearch;

  /// Флаг состояния загрузки данных.
  final bool isLoading;

  /// Флаг наличия ошибки при загрузке данных.
  final bool isError;

  /// Текст ошибки для отображения пользователю.
  final String? errorMessage;

  /// Создает десктопное представление списка договоров.
  const ContractsListDesktopView({
    super.key,
    required this.filteredContracts,
    required this.searchQuery,
    required this.onSearch,
    required this.isLoading,
    required this.isError,
    this.errorMessage,
  });

  @override
  ConsumerState<ContractsListDesktopView> createState() =>
      _ContractsListDesktopViewState();
}

class _ContractsListDesktopViewState
    extends ConsumerState<ContractsListDesktopView> {
  String? _selectedContractId;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.text = widget.searchQuery;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(ContractsListDesktopView oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If current selection is not in the new list, clear selection
    if (_selectedContractId != null) {
      final containsSelected = widget.filteredContracts.any(
        (c) => c.id == _selectedContractId,
      );
      if (!containsSelected) {
        _selectedContractId = null;
      }
    }
    if (widget.searchQuery != _searchController.text) {
      _searchController.text = widget.searchQuery;
    }
  }

  Future<void> _showContractForm([Contract? contract]) async {
    // Используем новый статический метод с анимацией
    await ContractFormModal.show(context, contract: contract);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        decoration: BoxDecoration(
          color: isDark
              ? const Color.fromRGBO(38, 40, 42, 1)
              : const Color.fromRGBO(248, 249, 250, 1),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            // Header with Title and Search and Add button
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[900] : Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
                border: Border(
                  bottom: BorderSide(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.05)
                        : Colors.black.withValues(alpha: 0.05),
                  ),
                ),
              ),
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'РЕЕСТР ДОГОВОРОВ',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Всего: ${widget.filteredContracts.length}',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 48),
                  // Search Field
                  Expanded(
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 400),
                      child: GTTextField(
                        controller: _searchController,
                        hintText: 'Поиск по номеру, контрагенту или объекту...',
                        prefixIcon: Icons.search_rounded,
                        onChanged: widget.onSearch,
                      ),
                    ),
                  ),
                  const SizedBox(width: 24),
                  PermissionGuard(
                    module: 'contracts',
                    permission: 'create',
                    child: GTPrimaryButton(
                      text: 'Новый договор',
                      icon: Icons.add_rounded,
                      onPressed: () => _showContractForm(),
                    ),
                  ),
                ],
              ),
            ),
            // Table
            Expanded(
              child: widget.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : widget.isError
                  ? Center(child: Text(widget.errorMessage ?? 'Ошибка'))
                  : widget.filteredContracts.isEmpty
                  ? Center(
                      child: Text(
                        widget.searchQuery.isEmpty
                            ? 'Список договоров пуст'
                            : 'По вашему запросу ничего не найдено',
                        style: theme.textTheme.bodyMedium,
                      ),
                    )
                  : ContractTableView(
                      contracts: widget.filteredContracts,
                      selectedId: _selectedContractId,
                      onSelect: (contract) {
                        setState(() {
                          _selectedContractId = contract.id;
                        });
                        ContractDetailsPanel.show(
                          context,
                          contract: contract,
                          onEdit: () => _showContractForm(contract),
                        );
                      },
                      onEdit: (contract) {
                        setState(() {
                          _selectedContractId = contract.id;
                        });
                        _showContractForm(contract);
                      },
                      onDelete: (id) {
                        setState(() {
                          widget.filteredContracts.removeWhere(
                            (c) => c.id == id,
                          );
                          if (_selectedContractId == id) {
                            _selectedContractId = null;
                          }
                        });
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
