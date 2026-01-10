import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:projectgt/features/contractors/presentation/state/contractor_state.dart';
import 'package:projectgt/presentation/widgets/app_bar_widget.dart';
import 'package:projectgt/presentation/widgets/app_drawer.dart';
import 'contractor_form_screen.dart';
import 'mobile/contractor_details_mobile_view.dart';
import 'package:projectgt/features/contractors/presentation/widgets/contractor_details_panel.dart';

/// Экран подробной информации о контрагенте (заказчик, подрядчик, поставщик).
///
/// Управляет загрузкой данных и переключает представления в зависимости от размера экрана.
/// Адаптируется под desktop и mobile, интегрирован с провайдером состояния [contractorNotifierProvider].
class ContractorDetailsScreen extends ConsumerStatefulWidget {
  /// Идентификатор контрагента для отображения.
  final String contractorId;

  /// Показывать ли AppBar и Drawer (по умолчанию true).
  final bool showAppBar;

  /// Создаёт экран деталей для контрагента.
  const ContractorDetailsScreen({
    super.key,
    required this.contractorId,
    this.showAppBar = true,
  });

  @override
  ConsumerState<ContractorDetailsScreen> createState() =>
      _ContractorDetailsScreenState();
}

class _ContractorDetailsScreenState
    extends ConsumerState<ContractorDetailsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(contractorNotifierProvider.notifier)
          .getContractor(widget.contractorId);
    });
  }

  @override
  void didUpdateWidget(covariant ContractorDetailsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.contractorId != widget.contractorId) {
      Future.microtask(() {
        ref
            .read(contractorNotifierProvider.notifier)
            .getContractor(widget.contractorId);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = ref.watch(contractorNotifierProvider);
    final contractor = state.contractor;
    final isLoading =
        contractor == null && state.status == ContractorStatus.loading;
    final isDesktop = MediaQuery.of(context).size.width >= 900;

    if (isLoading) {
      return Scaffold(
        appBar: widget.showAppBar
            ? const AppBarWidget(title: 'Информация о контрагенте')
            : null,
        drawer: widget.showAppBar
            ? const AppDrawer(activeRoute: AppRoute.contractors)
            : null,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (state.status == ContractorStatus.error || contractor == null) {
      return Scaffold(
        appBar: widget.showAppBar
            ? const AppBarWidget(title: 'Информация о контрагенте')
            : null,
        drawer: widget.showAppBar
            ? const AppDrawer(activeRoute: AppRoute.contractors)
            : null,
        body: Center(
          child: Text(
            state.errorMessage ?? 'Контрагент не найден',
            style: theme.textTheme.bodyLarge,
          ),
        ),
      );
    }

    if (isDesktop) {
      return Scaffold(
        backgroundColor: theme.colorScheme.surface,
        body: ContractorDetailsPanel(
          contractor: contractor,
          onEdit: () {
            showDialog(
              context: context,
              builder: (context) => Dialog(
                backgroundColor: Colors.transparent,
                child: ContractorFormScreen(contractorId: contractor.id),
              ),
            );
          },
        ),
      );
    }

    return ContractorDetailsMobileView(
      contractor: contractor,
      showAppBar: widget.showAppBar,
    );
  }
}
