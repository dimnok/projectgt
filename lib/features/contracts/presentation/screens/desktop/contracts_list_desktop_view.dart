import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:projectgt/domain/entities/contract.dart';
import 'package:projectgt/features/contracts/presentation/widgets/contract_row_item_desktop.dart';
import 'package:projectgt/features/contracts/presentation/widgets/contract_details_panel.dart';
import 'package:projectgt/features/contracts/presentation/screens/contract_form_screen.dart';
import 'package:projectgt/features/roles/presentation/widgets/permission_guard.dart';
import 'package:projectgt/core/widgets/gt_buttons.dart';

/// Десктопное представление списка договоров.
///
/// Реализует двухпанельный интерфейс: слева список договоров с возможностью поиска
/// и фильтрации, справа — панель с детальной информацией о выбранном договоре.
class ContractsListDesktopView extends ConsumerStatefulWidget {
  /// Список отфильтрованных договоров для отображения.
  final List<Contract> filteredContracts;

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
  final _scrollController = ScrollController();
  String? _selectedContractId;

  @override
  void initState() {
    super.initState();

    // Select first contract by default if list is not empty
    if (widget.filteredContracts.isNotEmpty) {
      _selectedContractId = widget.filteredContracts.first.id;
    }
  }

  @override
  void didUpdateWidget(ContractsListDesktopView oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If list changed and current selection is not in the new list, select first
    if (_selectedContractId != null) {
      final containsSelected = widget.filteredContracts.any(
        (c) => c.id == _selectedContractId,
      );
      if (!containsSelected && widget.filteredContracts.isNotEmpty) {
        _selectedContractId = widget.filteredContracts.first.id;
      }
    } else if (widget.filteredContracts.isNotEmpty) {
      _selectedContractId = widget.filteredContracts.first.id;
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _showContractForm([Contract? contract]) async {
    await showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: ContractFormModal(contract: contract),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final selectedContract = _selectedContractId != null
        ? widget.filteredContracts.firstWhere(
            (c) => c.id == _selectedContractId,
            orElse: () => widget.filteredContracts.isNotEmpty
                ? widget.filteredContracts.first
                : widget
                      .filteredContracts
                      .first, // Should not happen with check above
          )
        : null;

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
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Left Panel - List
              Container(
                width: 350,
                margin: const EdgeInsets.only(right: 16),
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[900] : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? Colors.grey[800]! : Colors.grey[300]!,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: PermissionGuard(
                        module: 'contracts',
                        permission: 'create',
                        child: SizedBox(
                          width: double.infinity,
                          child: GTPrimaryButton(
                            text: 'Добавить договор',
                            icon: CupertinoIcons.plus,
                            onPressed: () => _showContractForm(),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: widget.isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : widget.isError
                          ? Center(child: Text(widget.errorMessage ?? 'Ошибка'))
                          : widget.filteredContracts.isEmpty
                          ? Center(
                              child: Text(
                                'Список договоров пуст',
                                style: theme.textTheme.bodyMedium,
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.all(8),
                              controller: _scrollController,
                              itemCount: widget.filteredContracts.length,
                              itemBuilder: (context, index) {
                                final contract =
                                    widget.filteredContracts[index];
                                return ContractListItemDesktop(
                                  contract: contract,
                                  isSelected:
                                      _selectedContractId == contract.id,
                                  onTap: () {
                                    setState(() {
                                      _selectedContractId = contract.id;
                                    });
                                  },
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
              // Right Panel - Details
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey[900] : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark ? Colors.grey[800]! : Colors.grey[300]!,
                    ),
                  ),
                  child: _selectedContractId != null && selectedContract != null
                      ? ContractDetailsPanel(
                          contract: selectedContract,
                          onEdit: () => _showContractForm(selectedContract),
                        )
                      : Center(
                          child: Text(
                            'Выберите договор из списка',
                            style: theme.textTheme.titleLarge?.copyWith(
                              color: theme.textTheme.bodySmall?.color,
                            ),
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
