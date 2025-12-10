import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:projectgt/presentation/widgets/app_bar_widget.dart';
import 'package:projectgt/presentation/widgets/app_drawer.dart';
import 'package:projectgt/core/utils/responsive_utils.dart';
import 'package:projectgt/features/procurement/presentation/screens/procurement_list_desktop_screen.dart';
import 'package:projectgt/features/procurement/presentation/controllers/procurement_controller.dart';

/// Главный экран списка заявок на закупку.
///
/// Адаптируется под размер экрана:
/// - На Desktop отображает [ProcurementListDesktopScreen].
/// - На Mobile отображает заглушку (в разработке).
class ProcurementListScreen extends ConsumerStatefulWidget {
  /// Создаёт экран списка заявок.
  const ProcurementListScreen({super.key});

  @override
  ConsumerState<ProcurementListScreen> createState() =>
      _ProcurementListScreenState();
}

class _ProcurementListScreenState extends ConsumerState<ProcurementListScreen> {
  bool _isSettingsVisible = false;

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveUtils.isDesktop(context);
    final applicationsAsync = ref.watch(procurementControllerProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBarWidget(
        title: 'Заявки на закупку',
        actions: [
          IconButton(
            icon: Icon(
              _isSettingsVisible
                  ? CupertinoIcons.xmark
                  : CupertinoIcons.settings,
            ),
            tooltip: _isSettingsVisible
                ? 'Закрыть настройки'
                : 'Настройки согласования',
            onPressed: () => setState(() {
              _isSettingsVisible = !_isSettingsVisible;
            }),
          ),
        ],
      ),
      drawer: const AppDrawer(activeRoute: AppRoute.procurement),
      body: isDesktop
          ? applicationsAsync.when(
              data: (applications) => ProcurementListDesktopScreen(
                applications: applications,
                isLoading: false,
                isSettingsVisible: _isSettingsVisible,
              ),
              loading: () => ProcurementListDesktopScreen(
                applications: const [],
                isLoading: true,
                isSettingsVisible: _isSettingsVisible,
              ),
              error: (error, stack) => Center(
                child: Text('Ошибка загрузки: $error'),
              ),
            )
          : const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(CupertinoIcons.cart, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'Мобильная версия в разработке',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
    );
  }
}
