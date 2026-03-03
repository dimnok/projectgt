import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:projectgt/core/refresh/refresh_models.dart';
import 'package:projectgt/core/refresh/app_focus_refresh_coordinator.dart';
import 'package:projectgt/features/cash_flow/presentation/state/cash_flow_state.dart';
import 'package:projectgt/presentation/widgets/app_bar_widget.dart';
import 'package:projectgt/presentation/widgets/app_drawer.dart';
import 'package:projectgt/core/widgets/edge_to_edge_scaffold.dart';
import 'desktop/cash_flow_list_desktop_view.dart';

/// Экран модуля Cash Flow (Движение денежных средств).
///
/// Обеспечивает адаптивное отображение списка финансовых операций.
/// На данный момент оптимизирован для десктопной версии.
class CashFlowListScreen extends ConsumerStatefulWidget {
  /// Создаёт экран списка Cash Flow.
  const CashFlowListScreen({super.key});

  @override
  ConsumerState<CashFlowListScreen> createState() => _CashFlowListScreenState();
}

class _CashFlowListScreenState extends ConsumerState<CashFlowListScreen> {
  late final AppFocusRefreshCoordinator _refreshCoordinator;

  @override
  void initState() {
    super.initState();
    _refreshCoordinator = ref.read(appFocusRefreshProvider.notifier);

    // Регистрация цели автоматического обновления для модуля Cash Flow
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _refreshCoordinator.registerTarget(
          RefreshTarget(
            id: 'cash_flow',
            callback: (ref) async {
              // Тихая перезагрузка данных Cash Flow
              await ref.read(cashFlowProvider.notifier).loadAllData(quiet: true);
            },
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _refreshCoordinator.unregisterTarget('cash_flow');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 900;

    return EdgeToEdgeScaffold(
      extendBodyBehindAppBar: false,
      appBar: const AppBarWidget(title: 'Cash Flow', showThemeSwitch: true),
      drawer: const AppDrawer(activeRoute: AppRoute.cashFlow),
      body: isMobile
          ? const Center(
              child: Text('Мобильная версия в разработке (только десктоп)'),
            )
          : const CashFlowListDesktopView(),
    );
  }
}
