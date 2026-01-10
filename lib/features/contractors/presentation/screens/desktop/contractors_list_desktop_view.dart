import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:projectgt/features/contractors/domain/entities/contractor.dart';
import 'package:projectgt/features/roles/presentation/widgets/permission_guard.dart';
import 'package:projectgt/core/widgets/gt_buttons.dart';
import '../../widgets/contractor_list_item_desktop.dart';
import '../../widgets/contractor_details_panel.dart';
import '../contractor_form_screen.dart';

/// Десктопная версия экрана списка контрагентов.
///
/// Реализует двухпанельный интерфейс: список слева и детализация справа.
class ContractorsListDesktopView extends ConsumerStatefulWidget {
  /// Отфильтрованный список контрагентов для отображения.
  final List<Contractor> filteredContractors;

  /// Флаг состояния загрузки данных.
  final bool isLoading;

  /// Создает десктопную версию списка контрагентов.
  const ContractorsListDesktopView({
    super.key,
    required this.filteredContractors,
    required this.isLoading,
  });

  @override
  ConsumerState<ContractorsListDesktopView> createState() =>
      _ContractorsListDesktopViewState();
}

class _ContractorsListDesktopViewState
    extends ConsumerState<ContractorsListDesktopView> {
  final _scrollController = ScrollController();
  String? _selectedContractorId;

  @override
  void initState() {
    super.initState();
    if (widget.filteredContractors.isNotEmpty) {
      _selectedContractorId = widget.filteredContractors.first.id;
    }
  }

  @override
  void didUpdateWidget(ContractorsListDesktopView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_selectedContractorId != null) {
      final containsSelected = widget.filteredContractors.any(
        (c) => c.id == _selectedContractorId,
      );
      if (!containsSelected && widget.filteredContractors.isNotEmpty) {
        _selectedContractorId = widget.filteredContractors.first.id;
      }
    } else if (widget.filteredContractors.isNotEmpty) {
      _selectedContractorId = widget.filteredContractors.first.id;
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _showContractorForm([String? contractorId]) async {
    await showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: ContractorFormScreen(contractorId: contractorId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final selectedContractor = _selectedContractorId != null
        ? widget.filteredContractors.firstWhere(
            (c) => c.id == _selectedContractorId,
            orElse: () => widget.filteredContractors.first,
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
              // Left Panel
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
                        module: 'contractors',
                        permission: 'create',
                        child: SizedBox(
                          width: double.infinity,
                          child: GTPrimaryButton(
                            text: 'Добавить контрагента',
                            icon: CupertinoIcons.plus,
                            onPressed: () => _showContractorForm(),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: widget.isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : widget.filteredContractors.isEmpty
                          ? const Center(child: Text('Контрагенты не найдены'))
                          : ListView.builder(
                              padding: const EdgeInsets.all(8),
                              controller: _scrollController,
                              itemCount: widget.filteredContractors.length,
                              itemBuilder: (context, index) {
                                final contractor =
                                    widget.filteredContractors[index];
                                return ContractorListItemDesktop(
                                  contractor: contractor,
                                  isSelected:
                                      _selectedContractorId == contractor.id,
                                  onTap: () {
                                    setState(() {
                                      _selectedContractorId = contractor.id;
                                    });
                                  },
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
              // Right Panel
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey[900] : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark ? Colors.grey[800]! : Colors.grey[300]!,
                    ),
                  ),
                  child:
                      _selectedContractorId != null &&
                          selectedContractor != null
                      ? ContractorDetailsPanel(
                          contractor: selectedContractor,
                          onEdit: () =>
                              _showContractorForm(selectedContractor.id),
                        )
                      : Center(
                          child: Text(
                            'Выберите контрагента из списка',
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
