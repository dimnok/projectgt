import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:projectgt/presentation/widgets/app_bar_widget.dart';
import 'package:projectgt/presentation/widgets/app_drawer.dart';
import 'package:projectgt/features/contractors/presentation/state/contractor_state.dart';
import 'package:projectgt/features/roles/presentation/widgets/permission_guard.dart';
import 'contractor_form_screen.dart';
import 'mobile/contractors_list_mobile_view.dart';
import 'desktop/contractors_list_desktop_view.dart';

/// Экран списка контрагентов (заказчики, подрядчики, поставщики).
/// Разделен на мобильную и десктопную версии.
class ContractorsListScreen extends ConsumerStatefulWidget {
  /// Создает экран списка контрагентов.
  const ContractorsListScreen({super.key});

  @override
  ConsumerState<ContractorsListScreen> createState() =>
      _ContractorsListScreenState();
}

class _ContractorsListScreenState extends ConsumerState<ContractorsListScreen> {
  Future<void> _showContractorForm() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const ContractorFormScreen(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = ref.watch(contractorNotifierProvider);
    final contractors = ref.watch(filteredContractorsProvider);
    final isLoading = state.status == ContractorStatus.loading;
    final isDesktop = MediaQuery.of(context).size.width >= 900;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: const AppBarWidget(title: 'Контрагенты', showThemeSwitch: true),
      drawer: const AppDrawer(activeRoute: AppRoute.contractors),
      floatingActionButton: isDesktop
          ? null
          : PermissionGuard(
              module: 'contractors',
              permission: 'create',
              child: FloatingActionButton(
                onPressed: _showContractorForm,
                tooltip: 'Добавить контрагента',
                child: const Icon(Icons.add),
              ),
            ),
      body: SafeArea(
        child: isDesktop
            ? ContractorsListDesktopView(
                filteredContractors: contractors,
                isLoading: isLoading,
              )
            : Column(
                children: [
                  ContractorsListMobileView(
                    filteredContractors: contractors,
                    isLoading: isLoading,
                  ),
                ],
              ),
      ),
    );
  }
}
