import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:projectgt/presentation/state/contract_state.dart';
import 'package:projectgt/domain/entities/contract.dart';
import 'package:projectgt/core/di/providers.dart';
import 'package:projectgt/presentation/widgets/app_bar_widget.dart';
import 'package:projectgt/presentation/widgets/app_drawer.dart';
import 'contract_form_screen.dart';
import 'package:projectgt/core/utils/snackbar_utils.dart';
import 'package:intl/intl.dart';
import 'package:projectgt/presentation/widgets/app_badge.dart';
import 'package:go_router/go_router.dart';

/// Экран списка договоров с поддержкой поиска, фильтрации и адаптивного отображения.
///
/// - На десктопе реализован мастер-детейл паттерн (список + детали).
/// - На мобильных поиск открывается жестом вниз, поддерживается pull-to-refresh.
/// - Использует Riverpod для управления состоянием и загрузкой данных.
/// - Все действия (создание, редактирование, удаление) реализованы через модальные окна.
/// - Поддерживает строгий минимализм, адаптивность, доступность (Semantics, alt text, фокусировка).
class ContractsListScreen extends ConsumerStatefulWidget {
  /// Создаёт экран списка договоров.
  const ContractsListScreen({super.key});

  @override
  ConsumerState<ContractsListScreen> createState() => _ContractsListScreenState();
}

/// Состояние экрана ContractsListScreen.
///
/// Управляет поиском, фильтрацией, выбором договора, обработкой событий pull-to-refresh.
/// Реализует адаптивное поведение для мобильных и десктопных устройств.
class _ContractsListScreenState extends ConsumerState<ContractsListScreen> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  bool _isSearchVisible = false;
  Contract? selectedContract;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (_isMobileDevice() && _scrollController.position.pixels < -50) {
      if (!_isSearchVisible) {
        setState(() {
          _isSearchVisible = true;
        });
      }
    } else if (_scrollController.position.pixels > 0 && _isSearchVisible && _isMobileDevice()) {
      setState(() {
        _isSearchVisible = false;
      });
    }
  }

  /// Проверяет, является ли устройство мобильным (ширина экрана < 600).
  bool _isMobileDevice() {
    final width = MediaQuery.of(context).size.width;
    return width < 600;
  }

  /// Фильтрует список договоров по строке поиска [query].
  void _filterContracts(String query) {
    setState(() {});
  }

  /// Обрабатывает pull-to-refresh.
  ///
  /// Если поиск скрыт — открывает поиск, иначе обновляет список договоров.
  Future<void> _handleRefresh() async {
    if (!_isSearchVisible) {
      setState(() {
        _isSearchVisible = true;
      });
      // Жёстко блокируем обновление: возвращаем задержку, чтобы RefreshIndicator не показывал бесконечный лоадер
      return Future.delayed(const Duration(milliseconds: 500));
    }
    await ref.read(contractProvider.notifier).loadContracts();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = ref.watch(contractProvider);
    final isDesktop = MediaQuery.of(context).size.width >= 900;
    final contracts = state.contracts;
    final isLoading = state.status == ContractStatusState.loading;
    final isError = state.status == ContractStatusState.error;
    final searchQuery = _searchController.text;
    final filteredContracts = List<Contract>.from(
      searchQuery.isEmpty
        ? contracts
        : contracts.where((c) =>
            c.number.toLowerCase().contains(searchQuery.toLowerCase()) ||
            (c.contractorName?.toLowerCase().contains(searchQuery.toLowerCase()) ?? false) ||
            (c.objectName?.toLowerCase().contains(searchQuery.toLowerCase()) ?? false)
          ).toList()
    )..sort((a, b) => b.date.compareTo(a.date));

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBarWidget(
        title: 'Договоры',
        actions: [
          if (isDesktop && selectedContract != null) ...[
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.amber),
              tooltip: 'Редактировать',
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height - MediaQuery.of(context).padding.top - kToolbarHeight,
                  ),
                  builder: (context) {
                    final theme = Theme.of(context);
                    final isDesktop = MediaQuery.of(context).size.width >= 900;
                    Widget modalContent = Container(
                      margin: isDesktop ? const EdgeInsets.only(top: 48) : null,
                      clipBehavior: Clip.antiAlias,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(46),
                            blurRadius: 24,
                            offset: const Offset(0, -8),
                          ),
                        ],
                        border: Border.all(
                          color: theme.colorScheme.outline.withAlpha(30),
                          width: 1.5,
                        ),
                      ),
                      child: DraggableScrollableSheet(
                        initialChildSize: 1.0,
                        minChildSize: 0.5,
                        maxChildSize: 1.0,
                        expand: false,
                        builder: (context, scrollController) => SingleChildScrollView(
                          controller: scrollController,
                          child: Padding(
                            padding: EdgeInsets.only(
                              bottom: MediaQuery.of(context).viewInsets.bottom,
                            ),
                            child: ContractFormModal(contract: selectedContract!),
                          ),
                        ),
                      ),
                    );
                    if (isDesktop) {
                      return Align(
                        alignment: Alignment.topCenter,
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width * 0.5,
                          ),
                          child: modalContent,
                        ),
                      );
                    } else {
                      return modalContent;
                    }
                  },
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              tooltip: 'Удалить',
              onPressed: () async {
                if (selectedContract == null) return;
                final ctx = context;
                final confirmed = await showDialog<bool>(
                  context: ctx,
                  builder: (ctx2) => AlertDialog(
                    title: const Text('Удалить договор?'),
                    content: const Text('Вы уверены, что хотите удалить этот договор?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(ctx2).pop(false),
                        child: const Text('Отмена'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(ctx2).pop(true),
                        child: const Text('Удалить', style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                );
                if (!ctx.mounted) return;
                if (confirmed == true) {
                  try {
                    await ref.read(contractProvider.notifier).deleteContract(selectedContract!.id);
                    if (!ctx.mounted) return;
                    setState(() {
                      selectedContract = null;
                    });
                    SnackBarUtils.showError(ctx, 'Договор удалён');
                  } catch (e) {
                    if (!ctx.mounted) return;
                    SnackBarUtils.showError(ctx, 'Ошибка удаления: ${e.toString()}');
                  }
                }
              },
            ),
          ],
        ],
      ),
      drawer: const AppDrawer(activeRoute: AppRoute.contracts),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height - MediaQuery.of(context).padding.top - kToolbarHeight,
            ),
            builder: (context) {
              final theme = Theme.of(context);
              final isDesktop = MediaQuery.of(context).size.width >= 900;
              Widget modalContent = Container(
                margin: isDesktop ? const EdgeInsets.only(top: 48) : null,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(46),
                      blurRadius: 24,
                      offset: const Offset(0, -8),
                    ),
                  ],
                  border: Border.all(
                    color: theme.colorScheme.outline.withAlpha(30),
                    width: 1.5,
                  ),
                ),
                child: DraggableScrollableSheet(
                  initialChildSize: 1.0,
                  minChildSize: 0.5,
                  maxChildSize: 1.0,
                  expand: false,
                  builder: (context, scrollController) => SingleChildScrollView(
                    controller: scrollController,
                    child: Padding(
                      padding: EdgeInsets.only(
                        bottom: MediaQuery.of(context).viewInsets.bottom,
                      ),
                      child: const ContractFormModal(),
                    ),
                  ),
                ),
              );
              if (isDesktop) {
                return Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.5,
                    ),
                    child: modalContent,
                  ),
                );
              } else {
                return modalContent;
              }
            },
          );
        },
        child: const Icon(Icons.add),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (isDesktop) {
            return Row(
              children: [
                // Список договоров (мастер)
                SizedBox(
                  width: 570,
                  child: Column(
                    children: [
                      // Поиск
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        height: 80,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: TextField(
                            controller: _searchController,
                            decoration: InputDecoration(
                              labelText: 'Поиск договоров',
                              prefixIcon: const Icon(Icons.search),
                              suffixIcon: _searchController.text.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear),
                                      onPressed: () {
                                        _searchController.clear();
                                        _filterContracts('');
                                      },
                                    )
                                  : null,
                            ),
                            onChanged: _filterContracts,
                          ),
                        ),
                      ),
                      Expanded(
                        child: RefreshIndicator(
                          onRefresh: _handleRefresh,
                          child: isLoading
                              ? const Center(child: CircularProgressIndicator())
                              : isError
                                  ? Center(child: Text(state.errorMessage ?? 'Ошибка'))
                                  : filteredContracts.isEmpty
                                      ? Center(
                                          child: Text(
                                            searchQuery.isEmpty
                                                ? 'Список договоров пуст'
                                                : 'Договоры не найдены',
                                            style: theme.textTheme.bodyLarge,
                                          ),
                                        )
                                      : ListView.builder(
                                          controller: _scrollController,
                                          physics: const AlwaysScrollableScrollPhysics(),
                                          itemCount: filteredContracts.length,
                                          itemBuilder: (context, index) {
                                            final contract = filteredContracts[index];
                                            final isSelected = selectedContract?.id == contract.id;
                                            return Card(
                                              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                              elevation: 0,
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(12),
                                                side: BorderSide(
                                                  color: isSelected
                                                      ? Colors.green
                                                      : theme.colorScheme.outline.withValues(alpha: 0.1),
                                                  width: isSelected ? 2 : 1,
                                                ),
                                              ),
                                              child: InkWell(
                                                onTap: () {
                                                  setState(() {
                                                    selectedContract = contract;
                                                  });
                                                },
                                                borderRadius: BorderRadius.circular(12),
                                                child: Padding(
                                                  padding: const EdgeInsets.all(16.0),
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Row(
                                                        children: [
                                                          Expanded(
                                                            child: Text(
                                                              '№ ${contract.number}',
                                                              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                                                              maxLines: 1,
                                                              overflow: TextOverflow.ellipsis,
                                                            ),
                                                          ),
                                                          const SizedBox(width: 8),
                                                          AppBadge(
                                                            text: _getContractStatusInfo(contract.status).$1,
                                                            color: _getContractStatusInfo(contract.status).$2,
                                                          ),
                                                        ],
                                                      ),
                                                      const SizedBox(height: 4),
                                                      Text(
                                                        _formatDate(contract.date),
                                                        style: theme.textTheme.bodyMedium,
                                                      ),
                                                      const SizedBox(height: 4),
                                                      Text(
                                                        contract.contractorName ?? '-',
                                                        style: theme.textTheme.bodyMedium,
                                                      ),
                                                      Text(
                                                        contract.objectName ?? '-',
                                                        style: theme.textTheme.bodyMedium,
                                                      ),
                                                      Text(
                                                        _formatAmount(contract.amount),
                                                        style: theme.textTheme.bodyMedium,
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Детали договора (детейл)
                Expanded(
                  child: selectedContract == null
                      ? Center(
                          child: Text(
                            'Выберите договор из списка',
                            style: theme.textTheme.bodyLarge,
                          ),
                        )
                      : ContractDetailsPanel(contract: selectedContract!),
                ),
              ],
            );
          } else {
            // Мобильный режим
            return Column(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  height: _isSearchVisible ? 80 : 0,
                  child: _isSearchVisible
                      ? Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: TextField(
                            controller: _searchController,
                            decoration: InputDecoration(
                              labelText: 'Поиск договоров',
                              prefixIcon: const Icon(Icons.search),
                              suffixIcon: _searchController.text.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear),
                                      onPressed: () {
                                        _searchController.clear();
                                        _filterContracts('');
                                      },
                                    )
                                  : null,
                            ),
                            onChanged: _filterContracts,
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
                if (_isMobileDevice() && !_isSearchVisible)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Center(
                      child: Text(
                        "↓ Потяните вниз для поиска ↓",
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withAlpha(120),
                        ),
                      ),
                    ),
                  ),
                if (_isMobileDevice() && _isSearchVisible)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Center(
                      child: Text(
                        "↓ Потяните ещё раз для обновления списка ↓",
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withAlpha(120),
                        ),
                      ),
                    ),
                  ),
                Expanded(
                  child: !_isSearchVisible
                      ? NotificationListener<ScrollNotification>(
                          onNotification: (notification) {
                            if (notification is OverscrollNotification && notification.overscroll < 0) {
                              setState(() {
                                _isSearchVisible = true;
                              });
                            }
                            return false;
                          },
                          child: isLoading
                              ? const Center(child: CircularProgressIndicator())
                              : isError
                                  ? Center(child: Text(state.errorMessage ?? 'Ошибка'))
                                  : filteredContracts.isEmpty
                                      ? Center(
                                          child: Text(
                                            searchQuery.isEmpty
                                                ? 'Список договоров пуст'
                                                : 'Договоры не найдены',
                                            style: theme.textTheme.bodyLarge,
                                          ),
                                        )
                                      : ListView.builder(
                                          controller: _scrollController,
                                          physics: const AlwaysScrollableScrollPhysics(),
                                          itemCount: filteredContracts.length,
                                          itemBuilder: (context, index) {
                                            final contract = filteredContracts[index];
                                            return Card(
                                              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                              elevation: 0,
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(12),
                                                side: BorderSide(
                                                  color: theme.colorScheme.outline.withValues(alpha: 0.1),
                                                  width: 1,
                                                ),
                                              ),
                                              child: InkWell(
                                                onTap: () {
                                                  Navigator.of(context).push(
                                                    MaterialPageRoute(
                                                      builder: (context) => ContractDetailsPanel(contract: contract),
                                                    ),
                                                  );
                                                },
                                                borderRadius: BorderRadius.circular(12),
                                                child: Padding(
                                                  padding: const EdgeInsets.all(16.0),
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Row(
                                                        children: [
                                                          Expanded(
                                                            child: Text(
                                                              '№ ${contract.number}',
                                                              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                                                              maxLines: 1,
                                                              overflow: TextOverflow.ellipsis,
                                                            ),
                                                          ),
                                                          const SizedBox(width: 8),
                                                          AppBadge(
                                                            text: _getContractStatusInfo(contract.status).$1,
                                                            color: _getContractStatusInfo(contract.status).$2,
                                                          ),
                                                        ],
                                                      ),
                                                      const SizedBox(height: 4),
                                                      Text(
                                                        _formatDate(contract.date),
                                                        style: theme.textTheme.bodyMedium,
                                                      ),
                                                      const SizedBox(height: 4),
                                                      Text(
                                                        contract.contractorName ?? '-',
                                                        style: theme.textTheme.bodyMedium,
                                                      ),
                                                      Text(
                                                        contract.objectName ?? '-',
                                                        style: theme.textTheme.bodyMedium,
                                                      ),
                                                      Text(
                                                        _formatAmount(contract.amount),
                                                        style: theme.textTheme.bodyMedium,
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                        )
                      : RefreshIndicator(
                          onRefresh: _handleRefresh,
                          child: isLoading
                              ? const Center(child: CircularProgressIndicator())
                              : isError
                                  ? Center(child: Text(state.errorMessage ?? 'Ошибка'))
                                  : filteredContracts.isEmpty
                                      ? Center(
                                          child: Text(
                                            searchQuery.isEmpty
                                                ? 'Список договоров пуст'
                                                : 'Договоры не найдены',
                                            style: theme.textTheme.bodyLarge,
                                          ),
                                        )
                                      : ListView.builder(
                                          controller: _scrollController,
                                          physics: const AlwaysScrollableScrollPhysics(),
                                          itemCount: filteredContracts.length,
                                          itemBuilder: (context, index) {
                                            final contract = filteredContracts[index];
                                            return Card(
                                              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                              elevation: 0,
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(12),
                                                side: BorderSide(
                                                  color: theme.colorScheme.outline.withValues(alpha: 0.1),
                                                  width: 1,
                                                ),
                                              ),
                                              child: InkWell(
                                                onTap: () {
                                                  Navigator.of(context).push(
                                                    MaterialPageRoute(
                                                      builder: (context) => ContractDetailsPanel(contract: contract),
                                                    ),
                                                  );
                                                },
                                                borderRadius: BorderRadius.circular(12),
                                                child: Padding(
                                                  padding: const EdgeInsets.all(16.0),
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Row(
                                                        children: [
                                                          Expanded(
                                                            child: Text(
                                                              '№ ${contract.number}',
                                                              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                                                              maxLines: 1,
                                                              overflow: TextOverflow.ellipsis,
                                                            ),
                                                          ),
                                                          const SizedBox(width: 8),
                                                          AppBadge(
                                                            text: _getContractStatusInfo(contract.status).$1,
                                                            color: _getContractStatusInfo(contract.status).$2,
                                                          ),
                                                        ],
                                                      ),
                                                      const SizedBox(height: 4),
                                                      Text(
                                                        _formatDate(contract.date),
                                                        style: theme.textTheme.bodyMedium,
                                                      ),
                                                      const SizedBox(height: 4),
                                                      Text(
                                                        contract.contractorName ?? '-',
                                                        style: theme.textTheme.bodyMedium,
                                                      ),
                                                      Text(
                                                        contract.objectName ?? '-',
                                                        style: theme.textTheme.bodyMedium,
                                                      ),
                                                      Text(
                                                        _formatAmount(contract.amount),
                                                        style: theme.textTheme.bodyMedium,
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                        ),
                ),
              ],
            );
          }
        },
      ),
    );
  }

  String _formatAmount(num amount) {
    final formatter = NumberFormat('###,##0.00', 'ru_RU');
    return formatter.format(amount);
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }
}

/// Панель деталей договора с табами: основное, связи, история.
///
/// Используется как часть мастер-детейл интерфейса на десктопе и как отдельный экран на мобильных.
/// Позволяет просматривать подробную информацию, связанные объекты и историю изменений.
class ContractDetailsPanel extends ConsumerStatefulWidget {
  /// Данные договора для отображения.
  final Contract contract;
  /// Создаёт панель деталей для [contract].
  const ContractDetailsPanel({super.key, required this.contract});

  @override
  ConsumerState<ContractDetailsPanel> createState() => _ContractDetailsPanelState();
}

/// Состояние панели деталей договора.
///
/// Управляет табами, загрузкой связанных данных, отображением секций.
class _ContractDetailsPanelState extends ConsumerState<ContractDetailsPanel> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final contract = widget.contract;
    // Получаем списки контрагентов и объектов
    final contractors = ref.watch(contractorProvider).contractors;
    final objects = ref.watch(objectProvider).objects;
    // Ищем контрагента и объект по id
    final contractor = contractors.where((c) => c.id == contract.contractorId).isNotEmpty
      ? contractors.firstWhere((c) => c.id == contract.contractorId)
      : null;
    final object = objects.where((o) => o.id == contract.objectId).isNotEmpty
      ? objects.firstWhere((o) => o.id == contract.objectId)
      : null;
    final contractorDisplay = contractor != null
      ? (contractor.shortName.isNotEmpty ? contractor.shortName : contractor.fullName)
      : contract.contractorId;
    final objectDisplay = object != null ? object.name : contract.objectId;
    final (statusText, statusColor) = _getContractStatusInfo(contract.status);

    final isMobile = MediaQuery.of(context).size.width < 900;
    final content = Column(
      children: [
        // Шапка
        Container(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.shadow.withAlpha(20),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 36,
                backgroundColor: theme.colorScheme.primary.withAlpha(20),
                child: Icon(Icons.description_rounded, size: 40, color: theme.colorScheme.primary),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text('№${contract.number}', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(width: 12),
                        AppBadge(
                          text: statusText,
                          color: statusColor,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text('Сумма: ${_formatAmount(contract.amount)} ₽', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Text('от ${_formatDate(contract.date)}', style: theme.textTheme.bodyMedium),
                  ],
                ),
              ),
            ],
          ),
        ),
        // TabBar
        TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Основное'),
            Tab(text: 'Связи'),
            Tab(text: 'История'),
          ],
        ),
        // TabBarView
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              // Основное
              ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildSection('Данные договора', [
                    _buildInfoItem('Номер', contract.number),
                    _buildInfoItem('Дата', _formatDate(contract.date)),
                    if (contract.endDate != null)
                      _buildInfoItem('Дата окончания', _formatDate(contract.endDate!)),
                    _buildInfoItem('Статус', _statusText(contract.status)),
                    _buildInfoItem('Сумма', _formatAmount(contract.amount)),
                  ]),
                ],
              ),
              // Связи
              ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildSection('Связанные объекты', [
                    _buildInfoItem('Контрагент', contractorDisplay),
                    _buildInfoItem('Объект', objectDisplay),
                  ]),
                ],
              ),
              // История
              ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildSection('История', [
                    if (contract.createdAt != null)
                      _buildInfoItem('Создан', _formatDateTime(contract.createdAt!)),
                    if (contract.updatedAt != null)
                      _buildInfoItem('Обновлён', _formatDateTime(contract.updatedAt!)),
                  ]),
                ],
              ),
            ],
          ),
        ),
      ],
    );

    if (isMobile) {
      return Scaffold(
        backgroundColor: theme.colorScheme.surface,
        appBar: AppBar(
          title: const Text('Детали договора'),
          backgroundColor: theme.colorScheme.surface,
          elevation: 0,
          iconTheme: IconThemeData(color: theme.colorScheme.onSurface),
          actions: [
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.amber),
              tooltip: 'Редактировать',
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height - MediaQuery.of(context).padding.top - kToolbarHeight,
                  ),
                  builder: (context) {
                    final theme = Theme.of(context);
                    final isDesktop = MediaQuery.of(context).size.width >= 900;
                    Widget modalContent = Container(
                      margin: isDesktop ? const EdgeInsets.only(top: 48) : null,
                      clipBehavior: Clip.antiAlias,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(46),
                            blurRadius: 24,
                            offset: const Offset(0, -8),
                          ),
                        ],
                        border: Border.all(
                          color: theme.colorScheme.outline.withAlpha(30),
                          width: 1.5,
                        ),
                      ),
                      child: DraggableScrollableSheet(
                        initialChildSize: 1.0,
                        minChildSize: 0.5,
                        maxChildSize: 1.0,
                        expand: false,
                        builder: (context, scrollController) => SingleChildScrollView(
                          controller: scrollController,
                          child: Padding(
                            padding: EdgeInsets.only(
                              bottom: MediaQuery.of(context).viewInsets.bottom,
                            ),
                            child: ContractFormModal(contract: contract),
                          ),
                        ),
                      ),
                    );
                    if (isDesktop) {
                      return Align(
                        alignment: Alignment.topCenter,
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width * 0.5,
                          ),
                          child: modalContent,
                        ),
                      );
                    } else {
                      return modalContent;
                    }
                  },
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              tooltip: 'Удалить',
              onPressed: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (ctx2) => AlertDialog(
                    title: const Text('Удалить договор?'),
                    content: const Text('Вы уверены, что хотите удалить этот договор?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(ctx2).pop(false),
                        child: const Text('Отмена'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(ctx2).pop(true),
                        child: const Text('Удалить', style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                );
                if (!context.mounted) return;
                if (confirmed == true) {
                  try {
                    await ref.read(contractProvider.notifier).deleteContract(contract.id);
                    if (!context.mounted) return;
                    context.pop();
                    SnackBarUtils.showError(context, 'Договор удалён');
                  } catch (e) {
                    if (!context.mounted) return;
                    SnackBarUtils.showError(context, 'Ошибка удаления: ${e.toString()}');
                  }
                }
              },
            ),
          ],
        ),
        body: content,
      );
    } else {
      return content;
    }
  }

  /// Строит секцию с заголовком [title] и списком виджетов [children].
  Widget _buildSection(String title, List<Widget> children) {
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.colorScheme.outline.withAlpha(30)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  /// Строит элемент информации с подписью [label] и значением [value].
  Widget _buildInfoItem(String label, String value) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(label, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurface.withAlpha(180))),
          ),
          Expanded(
            child: Text(value, style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }

  /// Форматирует дату в формате ДД.ММ.ГГГГ.
  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }

  /// Форматирует дату и время в формате ДД.ММ.ГГГГ ЧЧ:ММ.
  String _formatDateTime(DateTime date) {
    return '${_formatDate(date)} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  /// Возвращает строковое представление статуса договора.
  String _statusText(ContractStatus status) {
    switch (status) {
      case ContractStatus.active:
        return 'В работе';
      case ContractStatus.suspended:
        return 'Приостановлен';
      case ContractStatus.completed:
        return 'Завершен';
    }
  }

  /// Форматирует сумму с разделителями и двумя знаками после запятой.
  String _formatAmount(num amount) {
    final formatter = NumberFormat('###,##0.00', 'ru_RU');
    return formatter.format(amount);
  }
}

/// Возвращает пару (текст, цвет) для отображения статуса договора [status].
(String, Color) _getContractStatusInfo(ContractStatus status) {
  switch (status) {
    case ContractStatus.active:
      return ('В работе', Colors.green);
    case ContractStatus.suspended:
      return ('Приостановлен', Colors.orange);
    case ContractStatus.completed:
      return ('Завершен', Colors.grey);
  }
} 