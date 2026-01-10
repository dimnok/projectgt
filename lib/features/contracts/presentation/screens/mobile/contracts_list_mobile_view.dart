import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:projectgt/domain/entities/contract.dart';
import 'package:projectgt/core/di/providers.dart';
import 'package:projectgt/features/contracts/presentation/widgets/contract_row_item_mobile.dart';

/// Мобильное представление списка договоров.
///
/// Реализует отображение списка договоров в виде карточек, интерактивный поиск
/// (появляющийся при свайпе вниз) и механизм обновления данных через pull-to-refresh.
class ContractsListMobileView extends ConsumerStatefulWidget {
  /// Список отфильтрованных договоров, отображаемых в данный момент.
  final List<Contract> filteredContracts;

  /// Текущее значение строки поиска для синхронизации с текстовым полем.
  final String searchQuery;

  /// Индикатор процесса загрузки данных из репозитория.
  final bool isLoading;

  /// Флаг, указывающий на возникновение ошибки при получении данных.
  final bool isError;

  /// Текстовое описание ошибки (если есть) для вывода пользователю.
  final String? errorMessage;

  /// Функция обратного вызова, срабатывающая при изменении текста в поле поиска.
  final Function(String) onSearch;

  /// Создает виджет мобильного представления списка договоров.
  const ContractsListMobileView({
    super.key,
    required this.filteredContracts,
    required this.searchQuery,
    required this.isLoading,
    required this.isError,
    this.errorMessage,
    required this.onSearch,
  });

  @override
  ConsumerState<ContractsListMobileView> createState() =>
      _ContractsListMobileViewState();
}

class _ContractsListMobileViewState
    extends ConsumerState<ContractsListMobileView> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  bool _isSearchVisible = false;

  @override
  void initState() {
    super.initState();
    _searchController.text = widget.searchQuery;
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
    if (_scrollController.position.pixels < -50) {
      if (!_isSearchVisible) {
        setState(() {
          _isSearchVisible = true;
        });
      }
    } else if (_scrollController.position.pixels > 0 && _isSearchVisible) {
      setState(() {
        _isSearchVisible = false;
      });
    }
  }

  Future<void> _handleRefresh() async {
    if (!_isSearchVisible) {
      setState(() {
        _isSearchVisible = true;
      });
      return Future.delayed(const Duration(milliseconds: 500));
    }
    await ref.read(contractProvider.notifier).loadContracts();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
                                widget.onSearch('');
                              },
                            )
                          : null,
                    ),
                    onChanged: widget.onSearch,
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
        if (_isSearchVisible)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: Center(
              child: Text(
                "↓ Потяните ещё раз для обновления списка ↓",
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
            ),
          ),
        Expanded(
          child: !_isSearchVisible
              ? NotificationListener<ScrollNotification>(
                  onNotification: (notification) {
                    if (notification is OverscrollNotification &&
                        notification.overscroll < 0) {
                      setState(() {
                        _isSearchVisible = true;
                      });
                    }
                    return false;
                  },
                  child: _buildList(theme),
                )
              : RefreshIndicator(
                  onRefresh: _handleRefresh,
                  child: _buildList(theme),
                ),
        ),
      ],
    );
  }

  Widget _buildList(ThemeData theme) {
    if (widget.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (widget.isError) {
      return Center(child: Text(widget.errorMessage ?? 'Ошибка'));
    }
    if (widget.filteredContracts.isEmpty) {
      return Center(
        child: Text(
          widget.searchQuery.isEmpty
              ? 'Список договоров пуст'
              : 'Договоры не найдены',
          style: theme.textTheme.bodyLarge,
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: widget.filteredContracts.length,
      itemBuilder: (context, index) {
        final contract = widget.filteredContracts[index];
        return ContractRowItemMobile(
          key: ValueKey(contract.id),
          contract: contract,
          onEdit: () {
            context.pushNamed('contract-form', extra: contract);
          },
        );
      },
    );
  }
}
