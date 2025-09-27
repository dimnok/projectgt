import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:projectgt/presentation/widgets/app_bar_widget.dart';
import 'package:projectgt/presentation/widgets/app_drawer.dart';
import 'package:projectgt/presentation/state/contractor_state.dart';
import 'package:projectgt/domain/entities/contractor.dart';
import 'package:projectgt/core/di/providers.dart';
import 'contractor_details_screen.dart';
import 'contractor_form_screen.dart';
import 'package:projectgt/core/utils/snackbar_utils.dart';
import 'package:projectgt/presentation/widgets/app_badge.dart';

/// Экран списка контрагентов (заказчики, подрядчики, поставщики).
///
/// Позволяет искать, фильтровать, создавать, редактировать и удалять контрагентов. Адаптирован под desktop и mobile.
///
/// Пример использования:
/// ```dart
/// const ContractorsListScreen();
/// ```
class ContractorsListScreen extends ConsumerStatefulWidget {
  /// Создаёт экран списка контрагентов.
  const ContractorsListScreen({super.key});

  @override
  ConsumerState<ContractorsListScreen> createState() =>
      _ContractorsListScreenState();
}

/// Состояние для [ContractorsListScreen].
///
/// Управляет поиском, фильтрацией, выбором, обновлением и отображением контрагентов.
class _ContractorsListScreenState extends ConsumerState<ContractorsListScreen> {
  String? selectedContractorId;
  final _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isSearchVisible = false;
  bool _preventRefresh = false;

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);
  }

  void _scrollListener() {
    if (_isMobileDevice() && _scrollController.position.pixels < -50) {
      if (!_isSearchVisible) {
        setState(() {
          _isSearchVisible = true;
          _preventRefresh = true;
        });
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) {
            setState(() {
              _preventRefresh = false;
            });
          }
        });
      }
    } else if (_scrollController.position.pixels > 0 &&
        _isSearchVisible &&
        _isMobileDevice()) {
      setState(() {
        _isSearchVisible = false;
      });
    }
  }

  bool _isMobileDevice() {
    final width = MediaQuery.of(context).size.width;
    return width < 600;
  }

  Future<void> _handleRefresh() async {
    if (_preventRefresh) return Future.value();
    await ref.read(contractorProvider.notifier).loadContractors();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = ref.watch(contractorProvider);
    final notifier = ref.read(contractorProvider.notifier);
    final isLoading = state.status == ContractorStatus.loading;
    final contractors = state.filteredContractors;
    final isDesktop = MediaQuery.of(context).size.width >= 900;

    Widget contractorList;
    if (isDesktop) {
      contractorList = Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'Поиск контрагента',
                prefixIcon: Icon(Icons.search),
                suffixIcon: null,
              ),
              onChanged: notifier.setSearchQuery,
            ),
          ),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : contractors.isEmpty
                    ? const Center(child: Text('Контрагенты не найдены'))
                    : ListView.builder(
                        itemCount: contractors.length,
                        itemBuilder: (context, index) {
                          final contractor = contractors[index];
                          final isSelected = isDesktop &&
                              selectedContractorId == contractor.id;
                          return Card(
                            margin: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 6),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(
                                color: isSelected
                                    ? Colors.green
                                    : theme.colorScheme.outline
                                        .withValues(alpha: 0.1),
                                width: isSelected ? 2 : 1,
                              ),
                            ),
                            child: Stack(
                              children: [
                                Padding(
                                  padding:
                                      const EdgeInsets.only(top: 8, right: 8),
                                  child: Align(
                                    alignment: Alignment.topRight,
                                    child: AppBadge(
                                      text: _typeLabel(contractor.type),
                                      color: _typeColor(contractor.type),
                                    ),
                                  ),
                                ),
                                ListTile(
                                  contentPadding:
                                      const EdgeInsets.fromLTRB(16, 16, 16, 16),
                                  leading: Hero(
                                    tag: 'contractor_avatar_${contractor.id}',
                                    child: contractor.logoUrl != null &&
                                            contractor.logoUrl!.isNotEmpty
                                        ? CircleAvatar(
                                            backgroundImage: NetworkImage(
                                                contractor.logoUrl!),
                                            radius: 24,
                                          )
                                        : const CircleAvatar(
                                            radius: 24,
                                            child: Icon(Icons.business),
                                          ),
                                  ),
                                  title: Text(contractor.fullName,
                                      style: theme.textTheme.titleMedium),
                                  subtitle: Text(contractor.inn,
                                      style: theme.textTheme.bodySmall),
                                  selected: isSelected,
                                  onTap: () {
                                    if (isDesktop) {
                                      setState(() {
                                        selectedContractorId = contractor.id;
                                      });
                                    } else {
                                      context.pushNamed('contractor_details',
                                          pathParameters: {
                                            'contractorId': contractor.id
                                          });
                                    }
                                  },
                                ),
                              ],
                            ),
                          );
                        },
                      ),
          ),
        ],
      );
    } else {
      contractorList = Column(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            height: _isSearchVisible ? 80 : 0,
            child: _isSearchVisible
                ? Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: TextField(
                      controller: _searchController,
                      decoration: const InputDecoration(
                        labelText: 'Поиск контрагента',
                        prefixIcon: Icon(Icons.search),
                        suffixIcon: null,
                      ),
                      onChanged: notifier.setSearchQuery,
                    ),
                  )
                : const SizedBox.shrink(),
          ),
          if (!_isSearchVisible)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Center(
                child: Text(
                  "↓ Потяните вниз для поиска ↓",
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
              ),
            ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _handleRefresh,
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : contractors.isEmpty
                      ? const Center(child: Text('Контрагенты не найдены'))
                      : ListView.builder(
                          controller: _scrollController,
                          physics: const AlwaysScrollableScrollPhysics(),
                          itemCount: contractors.length,
                          itemBuilder: (context, index) {
                            final contractor = contractors[index];
                            final isSelected = isDesktop &&
                                selectedContractorId == contractor.id;
                            return Card(
                              margin: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 6),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(
                                  color: isSelected
                                      ? Colors.green
                                      : theme.colorScheme.outline
                                          .withValues(alpha: 0.1),
                                  width: isSelected ? 2 : 1,
                                ),
                              ),
                              child: Stack(
                                children: [
                                  Padding(
                                    padding:
                                        const EdgeInsets.only(top: 8, right: 8),
                                    child: Align(
                                      alignment: Alignment.topRight,
                                      child: AppBadge(
                                        text: _typeLabel(contractor.type),
                                        color: _typeColor(contractor.type),
                                      ),
                                    ),
                                  ),
                                  ListTile(
                                    contentPadding: const EdgeInsets.fromLTRB(
                                        16, 16, 16, 16),
                                    leading: Hero(
                                      tag: 'contractor_avatar_${contractor.id}',
                                      child: contractor.logoUrl != null &&
                                              contractor.logoUrl!.isNotEmpty
                                          ? CircleAvatar(
                                              backgroundImage: NetworkImage(
                                                  contractor.logoUrl!),
                                              radius: 24,
                                            )
                                          : const CircleAvatar(
                                              radius: 24,
                                              child: Icon(Icons.business),
                                            ),
                                    ),
                                    title: Text(contractor.fullName,
                                        style: theme.textTheme.titleMedium),
                                    subtitle: Text(contractor.inn,
                                        style: theme.textTheme.bodySmall),
                                    selected: isSelected,
                                    onTap: () {
                                      context.pushNamed('contractor_details',
                                          pathParameters: {
                                            'contractorId': contractor.id
                                          });
                                    },
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
            ),
          ),
        ],
      );
    }

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBarWidget(
        title: 'Контрагенты',
        actions: [
          if (isDesktop && selectedContractorId != null) ...[
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.amber),
              tooltip: 'Редактировать',
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height -
                        MediaQuery.of(context).padding.top -
                        kToolbarHeight,
                  ),
                  builder: (context) {
                    final isDesktop = MediaQuery.of(context).size.width > 800;
                    Widget modalContent = Container(
                      clipBehavior: Clip.antiAlias,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(28)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 10,
                            offset: const Offset(0, -5),
                          ),
                        ],
                      ),
                      child: DraggableScrollableSheet(
                        initialChildSize: 1.0,
                        minChildSize: 0.5,
                        maxChildSize: 1.0,
                        expand: false,
                        builder: (context, scrollController) =>
                            SingleChildScrollView(
                          controller: scrollController,
                          child: Padding(
                            padding: EdgeInsets.only(
                              bottom: MediaQuery.of(context).viewInsets.bottom,
                            ),
                            child: ContractorFormScreen(
                                contractorId: selectedContractorId,
                                showScaffold: false),
                          ),
                        ),
                      ),
                    );
                    if (isDesktop) {
                      return Center(
                        child: SizedBox(
                          width: (MediaQuery.of(context).size.width * 0.5)
                              .clamp(400.0, 900.0),
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
                  builder: (ctx) => AlertDialog(
                    title: const Text('Удалить контрагента?'),
                    content: const Text(
                        'Вы уверены, что хотите удалить этого контрагента?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(false),
                        child: const Text('Отмена'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(true),
                        child: const Text('Удалить',
                            style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                );
                if (confirmed == true) {
                  try {
                    await ref
                        .read(contractorProvider.notifier)
                        .deleteContractor(selectedContractorId!);
                    if (!context.mounted) return;
                    setState(() {
                      selectedContractorId = null;
                    });
                    SnackBarUtils.showSuccess(context, 'Контрагент удалён');
                  } catch (e) {
                    if (!context.mounted) return;
                    SnackBarUtils.showError(
                        context, 'Ошибка удаления: ${e.toString()}');
                  }
                }
              },
            ),
          ],
        ],
      ),
      drawer: const AppDrawer(activeRoute: AppRoute.contractors),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height -
                MediaQuery.of(context).padding.top -
                kToolbarHeight,
          ),
          builder: (context) {
            final isDesktop = MediaQuery.of(context).size.width > 800;
            Widget modalContent = Container(
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(28)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
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
                    child: const ContractorFormScreen(showScaffold: false),
                  ),
                ),
              ),
            );
            if (isDesktop) {
              return Center(
                child: SizedBox(
                  width: (MediaQuery.of(context).size.width * 0.5)
                      .clamp(400.0, 900.0),
                  child: modalContent,
                ),
              );
            } else {
              return modalContent;
            }
          },
        ),
        tooltip: 'Добавить контрагента',
        child: const Icon(Icons.add),
      ),
      body: SafeArea(
        child: isDesktop
            ? Row(
                children: [
                  SizedBox(width: 570, child: contractorList),
                  Expanded(
                    child: selectedContractorId == null
                        ? Center(
                            child: Text(
                              'Выберите контрагента из списка',
                              style: theme.textTheme.bodyLarge,
                            ),
                          )
                        : ContractorDetailsScreen(
                            contractorId: selectedContractorId!),
                  ),
                ],
              )
            : contractorList,
      ),
    );
  }

  static String _typeLabel(ContractorType type) {
    switch (type) {
      case ContractorType.customer:
        return 'Заказчик';
      case ContractorType.contractor:
        return 'Подрядчик';
      case ContractorType.supplier:
        return 'Поставщик';
    }
  }

  static Color _typeColor(ContractorType type) {
    switch (type) {
      case ContractorType.customer:
        return Colors.blue;
      case ContractorType.contractor:
        return Colors.green;
      case ContractorType.supplier:
        return Colors.orange;
    }
  }
}
