import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:projectgt/presentation/state/contract_state.dart';
import 'package:projectgt/domain/entities/contract.dart';
import 'package:projectgt/core/di/providers.dart';
import 'package:projectgt/core/refresh/refresh_models.dart';
import 'package:projectgt/core/refresh/app_focus_refresh_coordinator.dart';
import 'package:projectgt/presentation/widgets/app_bar_widget.dart';
import 'package:projectgt/presentation/widgets/app_drawer.dart';
import 'contract_form_screen.dart';
import 'package:projectgt/features/roles/presentation/widgets/permission_guard.dart';
import 'mobile/contracts_list_mobile_view.dart';
import 'desktop/contracts_list_desktop_view.dart';

/// Экран списка договоров с поддержкой поиска, фильтрации и адаптивного отображения.
/// Разделен на мобильную и десктопную версии.
class ContractsListScreen extends ConsumerStatefulWidget {
  /// Создает основной экран списка договоров.
  const ContractsListScreen({super.key});

  @override
  ConsumerState<ContractsListScreen> createState() =>
      _ContractsListScreenState();
}

class _ContractsListScreenState extends ConsumerState<ContractsListScreen> {
  String _searchQuery = '';
  late final AppFocusRefreshCoordinator _refreshCoordinator;

  @override
  void initState() {
    super.initState();
    _refreshCoordinator = ref.read(appFocusRefreshProvider.notifier);

    // Регистрация цели автоматического обновления для модуля договоров
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _refreshCoordinator.registerTarget(
          RefreshTarget(
            id: 'contracts',
            callback: (ref) async {
              // Игнорируем лодинг, чтобы обновление было тихим
              await ref.read(contractProvider.notifier).loadContracts(quiet: true);
            },
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _refreshCoordinator.unregisterTarget('contracts');
    super.dispose();
  }

  void _onSearch(String query) {
    setState(() {
      _searchQuery = query;
    });
  }

  Future<void> _showContractForm([Contract? contract]) async {
    final isDesktop = MediaQuery.of(context).size.width > 800;

    if (isDesktop) {
      await ContractFormModal.show(context, contract: contract);
    } else {
      await showModalBottomSheet(
        context: context,
        useRootNavigator: true,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        useSafeArea: true,
        builder: (context) => ContractFormModal(contract: contract),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = ref.watch(contractProvider);
    final contracts = state.contracts;
    final isLoading = state.status == ContractStatusState.loading;
    final isError = state.status == ContractStatusState.error;
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 900;

    final filteredContracts = List<Contract>.from(
      _searchQuery.isEmpty
          ? contracts
          : contracts
                .where(
                  (c) =>
                      c.number.toLowerCase().contains(
                        _searchQuery.toLowerCase(),
                      ) ||
                      (c.contractorName?.toLowerCase().contains(
                            _searchQuery.toLowerCase(),
                          ) ??
                          false) ||
                      (c.objectName?.toLowerCase().contains(
                            _searchQuery.toLowerCase(),
                          ) ??
                          false),
                )
                .toList(),
    )..sort((a, b) => b.date.compareTo(a.date));

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: const AppBarWidget(title: 'Договоры', showThemeSwitch: true),
      drawer: const AppDrawer(activeRoute: AppRoute.contracts),
      floatingActionButton: isMobile
          ? PermissionGuard(
              module: 'contracts',
              permission: 'create',
              child: FloatingActionButton(
                onPressed: () => _showContractForm(),
                child: const Icon(Icons.add),
              ),
            )
          : null,
      body: isMobile
          ? ContractsListMobileView(
              filteredContracts: filteredContracts,
              searchQuery: _searchQuery,
              isLoading: isLoading,
              isError: isError,
              errorMessage: state.errorMessage,
              onSearch: _onSearch,
            )
          : ContractsListDesktopView(
              filteredContracts: filteredContracts,
              searchQuery: _searchQuery,
              onSearch: _onSearch,
              isLoading: isLoading,
              isError: isError,
              errorMessage: state.errorMessage,
            ),
    );
  }
}
