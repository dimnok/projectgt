import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:projectgt/core/widgets/gt_buttons.dart';
import 'package:projectgt/core/widgets/gt_text_field.dart';
import 'package:projectgt/features/purchase_requests/domain/entities/purchase_request_status.dart';
import 'package:projectgt/features/purchase_requests/presentation/state/purchase_request_providers.dart';
import 'package:projectgt/features/purchase_requests/presentation/widgets/purchase_request_details_panel.dart';
import 'package:projectgt/features/purchase_requests/presentation/widgets/purchase_requests_table.dart';

/// Десктопное представление реестра заявок на закупку.
///
/// Двухпанельная компоновка по образцу Cash Flow:
/// слева — поиск, фильтры и действия; справа — таблица или детали заявки.
class PurchaseRequestsListDesktopView extends ConsumerStatefulWidget {
  /// Создаёт десктопный вид.
  const PurchaseRequestsListDesktopView({
    super.key,
    required this.canCreate,
    required this.isOwner,
    required this.selectedRequestId,
    required this.onSelectRequest,
    required this.onCloseDetails,
    required this.onCreate,
    required this.onSettings,
  });

  /// Можно создавать заявки.
  final bool canCreate;

  /// Владелец компании (доступ к настройкам).
  final bool isOwner;

  /// Выбранная заявка.
  final String? selectedRequestId;

  /// Выбрать заявку.
  final ValueChanged<String> onSelectRequest;

  /// Закрыть карточку заявки.
  final VoidCallback onCloseDetails;

  /// Создать заявку.
  final VoidCallback onCreate;

  /// Открыть настройки согласующих.
  final VoidCallback onSettings;

  @override
  ConsumerState<PurchaseRequestsListDesktopView> createState() =>
      _PurchaseRequestsListDesktopViewState();
}

class _PurchaseRequestsListDesktopViewState
    extends ConsumerState<PurchaseRequestsListDesktopView> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final listState = ref.watch(purchaseRequestListProvider);
    final listNotifier = ref.read(purchaseRequestListProvider.notifier);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Container(
        decoration: BoxDecoration(
          color: isDark
              ? const Color.fromRGBO(38, 40, 42, 1)
              : const Color.fromRGBO(248, 249, 250, 1),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              _PurchaseRequestsSidebar(
                searchController: _searchController,
                canCreate: widget.canCreate,
                isOwner: widget.isOwner,
                filter: listState.filter,
                onFilterChanged: listNotifier.setFilter,
                onSearchChanged: listNotifier.setSearchQuery,
                onCreate: widget.onCreate,
                onSettings: widget.onSettings,
              ),
              Expanded(
                child: _PurchaseRequestsContentPanel(
                  listState: listState,
                  selectedRequestId: widget.selectedRequestId,
                  onSelectRequest: widget.onSelectRequest,
                  onCloseDetails: widget.onCloseDetails,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Левая панель: поиск, фильтры и действия.
class _PurchaseRequestsSidebar extends StatelessWidget {
  const _PurchaseRequestsSidebar({
    required this.searchController,
    required this.canCreate,
    required this.isOwner,
    required this.filter,
    required this.onFilterChanged,
    required this.onSearchChanged,
    required this.onCreate,
    required this.onSettings,
  });

  final TextEditingController searchController;
  final bool canCreate;
  final bool isOwner;
  final PurchaseRequestListFilter filter;
  final ValueChanged<PurchaseRequestListFilter> onFilterChanged;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onCreate;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: 300,
      margin: const EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[900] : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.grey[800]! : Colors.grey[300]!,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                GTTextField(
                  controller: searchController,
                  hintText: 'Поиск заявок...',
                  prefixIcon: CupertinoIcons.search,
                  onChanged: onSearchChanged,
                ),
                if (canCreate) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: GTPrimaryButton(
                      text: 'Новая заявка',
                      icon: CupertinoIcons.plus,
                      onPressed: onCreate,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: PurchaseRequestListFilter.values.map((f) {
                final selected = f == filter;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _FilterTile(
                    label: f.label,
                    selected: selected,
                    isDark: isDark,
                    onTap: () => onFilterChanged(f),
                  ),
                );
              }).toList(),
            ),
          ),
          if (isOwner) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: GTSecondaryButton(
                  text: 'Настройки',
                  icon: CupertinoIcons.gear,
                  onPressed: onSettings,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Правая панель: таблица или детали заявки.
class _PurchaseRequestsContentPanel extends StatelessWidget {
  const _PurchaseRequestsContentPanel({
    required this.listState,
    required this.selectedRequestId,
    required this.onSelectRequest,
    required this.onCloseDetails,
  });

  final PurchaseRequestListState listState;
  final String? selectedRequestId;
  final ValueChanged<String> onSelectRequest;
  final VoidCallback onCloseDetails;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[900] : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.grey[800]! : Colors.grey[300]!,
        ),
      ),
      child: listState.error != null
          ? Center(child: Text(listState.error!))
          : selectedRequestId != null
              ? PurchaseRequestDetailsPanel(
                  key: ValueKey(selectedRequestId),
                  requestId: selectedRequestId!,
                  showCloseButton: true,
                  onClose: onCloseDetails,
                )
              : PurchaseRequestsTable(
                  items: listState.items,
                  isLoading: listState.isLoading,
                  selectedId: selectedRequestId,
                  onRowTap: (item) => onSelectRequest(item.id),
                ),
    );
  }
}

class _FilterTile extends StatelessWidget {
  const _FilterTile({
    required this.label,
    required this.selected,
    required this.isDark,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: selected
                ? (isDark ? Colors.grey[800] : Colors.grey[100])
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected
                  ? (isDark ? Colors.white24 : Colors.black12)
                  : Colors.transparent,
            ),
          ),
          child: Row(
            children: [
              Icon(
                selected
                    ? CupertinoIcons.checkmark_circle_fill
                    : CupertinoIcons.circle,
                size: 18,
                color: selected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurface.withValues(alpha: 0.4),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ),
              if (selected)
                Icon(
                  CupertinoIcons.chevron_right,
                  size: 14,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
