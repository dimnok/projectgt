import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:projectgt/presentation/widgets/app_drawer.dart';
import 'package:projectgt/features/roles/application/permission_service.dart';
import '../widgets/inventory_table_widget.dart';
import '../providers/inventory_provider.dart';
import '../../domain/entities/inventory_item.dart';

/// Экран складского учёта.
class InventoryScreen extends ConsumerWidget {
  /// Создаёт экран складского учёта.
  const InventoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final permissionService = ref.watch(permissionServiceProvider);

    return Scaffold(
      drawer: const AppDrawer(activeRoute: AppRoute.inventory),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 16, 8, 8),
              child: Row(
                children: [
                  Builder(
                    builder: (context) => CupertinoButton(
                      padding: EdgeInsets.zero,
                      child: const Icon(
                        Icons.menu,
                        color: Colors.green,
                      ),
                      onPressed: () {
                        Scaffold.of(context).openDrawer();
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (permissionService.can('inventory', 'create')) ...[
                    Expanded(
                      child: _buildNavigationCard(
                        context: context,
                        theme: theme,
                        icon: Icons.add_box_outlined,
                        title: 'Приход ТМЦ',
                        onTap: () => context.goNamed('inventory_receipt'),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  if (permissionService.can('inventory', 'update')) ...[
                    Expanded(
                      child: _buildNavigationCard(
                        context: context,
                        theme: theme,
                        icon: Icons.swap_horiz_outlined,
                        title: 'Передача / Выдача',
                        onTap: () => context.goNamed('inventory_transfer'),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  if (permissionService.can('inventory', 'update')) ...[
                    Expanded(
                      child: _buildNavigationCard(
                        context: context,
                        theme: theme,
                        icon: Icons.build_outlined,
                        title: 'Поломки / Утраты',
                        onTap: () => context.goNamed('inventory_breakdowns'),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  if (permissionService.can('inventory', 'update')) ...[
                    Expanded(
                      child: _buildNavigationCard(
                        context: context,
                        theme: theme,
                        icon: Icons.checklist_outlined,
                        title: 'Инвентаризация',
                        onTap: () => context.goNamed('inventory_inventory'),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Expanded(
                    child: _buildNavigationCard(
                      context: context,
                      theme: theme,
                      icon: Icons.folder_special_outlined,
                      title: 'Справочник',
                      onTap: () =>
                          context.goNamed('inventory_categories_reference'),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: ref.watch(inventoryItemsProvider).when(
                      data: (items) => InventoryTableWidget(
                        items: _convertItemsToMap(items),
                      ),
                      loading: () => const Center(
                        child: CircularProgressIndicator(),
                      ),
                      error: (error, stack) => Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline,
                              size: 64,
                              color: theme.colorScheme.error,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Ошибка загрузки данных',
                              style: theme.textTheme.titleLarge?.copyWith(
                                color: theme.colorScheme.error,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              error.toString(),
                              style: theme.textTheme.bodyMedium,
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Преобразует список [InventoryItem] в формат для таблицы.
  List<Map<String, dynamic>> _convertItemsToMap(List<InventoryItem> items) {
    return items.map((item) {
      // Определяем название местоположения
      String location = 'Склад';
      if (item.locationType == InventoryLocationType.object) {
        location = item.locationName ?? 'Объект';
      } else if (item.locationType == InventoryLocationType.employee) {
        location = item.responsibleName ?? 'У сотрудника';
      }

      // Преобразуем статус в строку для таблицы
      String statusString = 'new';
      switch (item.status) {
        case InventoryItemStatus.new_:
          statusString = 'new';
          break;
        case InventoryItemStatus.good:
          statusString = 'good';
          break;
        case InventoryItemStatus.broken:
          statusString = 'broken';
          break;
        case InventoryItemStatus.writtenOff:
          statusString = 'written_off';
          break;
        case InventoryItemStatus.repair:
          statusString = 'repair';
          break;
        case InventoryItemStatus.critical:
          statusString = 'critical';
          break;
      }

      return {
        'id': item.id,
        'name': item.name,
        'category': item.categoryName ?? 'Не указана',
        'unit': item.unit,
        'quantity': item.quantity, // Количество из записи
        'serial_number': item.serialNumber,
        'status': statusString,
        'purchase_date': item.purchaseDate,
        'location': location,
      };
    }).toList();
  }

  /// Строит компактную карточку навигации.
  Widget _buildNavigationCard({
    required BuildContext context,
    required ThemeData theme,
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.5)
                : Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.3)
                : Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 1),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Card(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: isDark ? theme.colorScheme.surface : Colors.blue.shade50,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            splashColor: Colors.green.withValues(alpha: 0.1),
            highlightColor: Colors.green.withValues(alpha: 0.05),
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(vertical: 8.0, horizontal: 10.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    icon,
                    size: 16,
                    color: Colors.green,
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      title,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                        letterSpacing: 0.2,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
