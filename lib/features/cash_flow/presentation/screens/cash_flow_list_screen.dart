import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
