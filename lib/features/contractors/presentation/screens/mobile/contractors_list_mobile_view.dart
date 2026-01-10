import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:projectgt/features/contractors/presentation/state/contractor_state.dart';
import 'package:projectgt/features/contractors/domain/entities/contractor.dart';
import '../../widgets/contractor_row_item_mobile.dart';

/// Мобильное представление списка контрагентов.
///
/// Реализует отображение списка в виде вертикальной ленты карточек
/// с механизмом pull-to-refresh для обновления данных.
class ContractorsListMobileView extends ConsumerStatefulWidget {
  /// Список отфильтрованных контрагентов для отображения.
  final List<Contractor> filteredContractors;

  /// Флаг состояния загрузки данных.
  final bool isLoading;

  /// Создает мобильное представление списка контрагентов.
  const ContractorsListMobileView({
    super.key,
    required this.filteredContractors,
    required this.isLoading,
  });

  @override
  ConsumerState<ContractorsListMobileView> createState() =>
      _ContractorsListMobileViewState();
}

class _ContractorsListMobileViewState
    extends ConsumerState<ContractorsListMobileView> {
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _handleRefresh() async {
    await ref.read(contractorNotifierProvider.notifier).loadContractors();
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: RefreshIndicator(
        onRefresh: _handleRefresh,
        child: widget.isLoading
            ? const Center(child: CircularProgressIndicator())
            : widget.filteredContractors.isEmpty
            ? const Center(child: Text('Контрагенты не найдены'))
            : ListView.builder(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                itemCount: widget.filteredContractors.length,
                itemBuilder: (context, index) {
                  final contractor = widget.filteredContractors[index];
                  return ContractorRowItemMobile(
                    contractor: contractor,
                    onTap: () {
                      context.pushNamed(
                        'contractor_details',
                        pathParameters: {'contractorId': contractor.id},
                      );
                    },
                  );
                },
              ),
      ),
    );
  }
}
