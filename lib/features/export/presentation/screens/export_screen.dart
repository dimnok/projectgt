import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:projectgt/presentation/widgets/app_bar_widget.dart';
import '../widgets/export_date_filter.dart';
import '../widgets/export_filters_action.dart';
import '../widgets/export_excel_action.dart';
import 'package:projectgt/presentation/widgets/app_drawer.dart';
import 'tabs/export_tab_reports.dart';
import 'tabs/export_tab_search.dart';

/// Основной экран модуля выгрузки.
class ExportScreen extends ConsumerStatefulWidget {
  /// Создаёт экран выгрузки.
  const ExportScreen({super.key});

  @override
  ConsumerState<ExportScreen> createState() => _ExportScreenState();
}

class _ExportScreenState extends ConsumerState<ExportScreen> {
  /// Индекс выбранного таба.
  int _selectedTabIndex = 0;

  /// Список табов.
  final List<Tab> _tabs = const [
    Tab(text: 'Выгрузка'),
    Tab(text: 'Поиск'),
  ];

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: const AppBarWidget(
        title: 'Выгрузка данных',
        actions: [
          ExportDateRangeAction(),
          ExportFiltersAction(),
          ExportExcelAction()
        ],
      ),
      drawer: const AppDrawer(activeRoute: AppRoute.export),
      body: _selectedTabIndex == 1
          ? // Таб "Поиск" - отображается полностью сам по себе с собственными табами
          ExportTabSearch(
              onSwitchToReports: () {
                setState(() {
                  _selectedTabIndex = 0;
                });
              },
            )
          : // Таб "Выгрузка"
          Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Табы
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24.0, vertical: 4.0),
                  child: DefaultTabController(
                    length: _tabs.length,
                    initialIndex: _selectedTabIndex,
                    child: Builder(
                      builder: (context) {
                        final TabController tabController =
                            DefaultTabController.of(context);
                        tabController.addListener(() {
                          if (tabController.indexIsChanging) {
                            setState(() {
                              _selectedTabIndex = tabController.index;
                            });
                          }
                        });
                        return TabBar(
                          tabs: _tabs,
                          controller: tabController,
                          labelColor: theme.colorScheme.primary,
                          unselectedLabelColor: theme.colorScheme.outline,
                          indicatorColor: theme.colorScheme.primary,
                        );
                      },
                    ),
                  ),
                ),

                // Контент таба "Выгрузка"
                const Expanded(
                  child: ExportTabReports(),
                ),
              ],
            ),
    );
  }
}
