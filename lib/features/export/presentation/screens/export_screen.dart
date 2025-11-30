import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:projectgt/core/utils/responsive_utils.dart';
import 'package:projectgt/presentation/widgets/app_bar_widget.dart';
import '../widgets/export_search_action.dart';
import '../widgets/export_search_filter_chips.dart';
import '../widgets/work_search_date_filter.dart';
import '../widgets/work_search_export_action.dart';
import 'package:projectgt/presentation/widgets/app_drawer.dart';
import 'tabs/export_tab_search.dart';
import 'package:projectgt/features/roles/presentation/widgets/permission_guard.dart';

/// Экран поиска по работам.
class ExportScreen extends ConsumerStatefulWidget {
  /// Создаёт экран поиска.
  const ExportScreen({super.key});

  @override
  ConsumerState<ExportScreen> createState() => _ExportScreenState();
}

class _ExportScreenState extends ConsumerState<ExportScreen> {
  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveUtils.isDesktop(context);

    return Scaffold(
      appBar: AppBarWidget(
        title: 'Поиск по работам',
        actions: [
          // Кнопка поиска показывается только на десктопе
          if (isDesktop) const ExportSearchAction(),
          // Календарь для выбора периода
          const WorkSearchDateRangeAction(),
          // Кнопка экспорта результатов
          const PermissionGuard(
            module: 'export',
            permission: 'export',
            child: WorkSearchExportAction(),
          ),
        ],
      ),
      drawer: const AppDrawer(activeRoute: AppRoute.export),
      body: GestureDetector(
        // Закрываем поле поиска при клике вне его, если запрос пуст
        onTap: () {
          final searchVisible = ref.read(exportSearchVisibleProvider);
          final searchQuery = ref.read(exportSearchQueryProvider);
          // Закрываем только если поле видимо и запрос пуст
          if (searchVisible && searchQuery.trim().isEmpty) {
            ref.read(exportSearchVisibleProvider.notifier).state = false;
          }
        },
        // Позволяем кликам проходить через GestureDetector к дочерним элементам
        behavior: HitTestBehavior.translucent,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Чипы фильтров (показываются только когда есть результаты поиска и это десктоп)
            if (ResponsiveUtils.isDesktop(context))
              const ExportSearchFilterChips(),
            // Контент - таб поиска
            const Expanded(
              child: ExportTabSearch(),
            ),
          ],
        ),
      ),
    );
  }
}
