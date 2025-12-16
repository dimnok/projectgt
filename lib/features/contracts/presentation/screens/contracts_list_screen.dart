import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:projectgt/presentation/state/contract_state.dart';
import 'package:projectgt/domain/entities/contract.dart';
import 'package:projectgt/core/di/providers.dart';
import 'package:projectgt/presentation/widgets/app_bar_widget.dart';
import 'package:projectgt/presentation/widgets/app_drawer.dart';
import 'package:projectgt/presentation/widgets/app_badge.dart';
import 'contract_form_screen.dart';
import 'package:projectgt/core/utils/formatters.dart';
import 'package:projectgt/core/utils/snackbar_utils.dart';
import 'package:go_router/go_router.dart';
import 'package:projectgt/features/contracts/presentation/widgets/contract_costs_info.dart';
import 'package:projectgt/features/roles/presentation/widgets/permission_guard.dart';

import 'package:projectgt/features/ks2/presentation/widgets/ks2_acts_sheet.dart';

/// Экран списка договоров с поддержкой поиска, фильтрации и адаптивного отображения.
///
/// - Отображает список договоров в виде карточек-строк.
/// - Поддерживает поиск и фильтрацию.
/// - Использует Riverpod для управления состоянием и загрузкой данных.
/// - Все действия (создание, редактирование, удаление) реализованы через модальные окна.
/// - Поддерживает строгий минимализм, адаптивность, доступность.
class ContractsListScreen extends ConsumerStatefulWidget {
  /// Создаёт экран списка договоров.
  const ContractsListScreen({super.key});

  @override
  ConsumerState<ContractsListScreen> createState() =>
      _ContractsListScreenState();
}

/// Состояние экрана ContractsListScreen.
///
/// Управляет поиском, фильтрацией, выбором договора, обработкой событий pull-to-refresh.
class _ContractsListScreenState extends ConsumerState<ContractsListScreen> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  String? _expandedContractId;
  bool _isSearchVisible = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _scrollController.addListener(_scrollListener);
      }
    });
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
    } else if (_scrollController.position.pixels > 0 &&
        _isSearchVisible &&
        _isMobileDevice()) {
      setState(() {
        _isSearchVisible = false;
      });
    }
  }

  /// Проверяет, является ли устройство мобильным (ширина экрана < 900).
  bool _isMobileDevice() {
    final width = MediaQuery.of(context).size.width;
    return width < 900;
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
    final contracts = state.contracts;
    final isLoading = state.status == ContractStatusState.loading;
    final isError = state.status == ContractStatusState.error;
    final searchQuery = _searchController.text;
    final filteredContracts = List<Contract>.from(searchQuery.isEmpty
        ? contracts
        : contracts
            .where((c) =>
                c.number.toLowerCase().contains(searchQuery.toLowerCase()) ||
                (c.contractorName
                        ?.toLowerCase()
                        .contains(searchQuery.toLowerCase()) ??
                    false) ||
                (c.objectName
                        ?.toLowerCase()
                        .contains(searchQuery.toLowerCase()) ??
                    false))
            .toList())
      ..sort((a, b) => b.date.compareTo(a.date));

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: const AppBarWidget(
        title: 'Договоры',
        showThemeSwitch: true,
      ),
      drawer: const AppDrawer(activeRoute: AppRoute.contracts),
      floatingActionButton: PermissionGuard(
        module: 'contracts',
        permission: 'create',
        child: FloatingActionButton(
          onPressed: () {
            final theme = Theme.of(context);
            final isDesktop = MediaQuery.of(context).size.width > 800;

            Widget modalContent = Container(
              width: double.infinity,
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
              child: IntrinsicHeight(
                child: Padding(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).viewInsets.bottom,
                  ),
                  child: const ContractFormModal(),
                ),
              ),
            );

            if (isDesktop) {
              modalContent = Align(
                alignment: Alignment.bottomCenter,
                child: SizedBox(
                  width: MediaQuery.of(context).size.width * 0.5,
                  child: modalContent,
                ),
              );
            }

            showModalBottomSheet(
              context: context,
              useRootNavigator: true,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              useSafeArea: true,
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height -
                    MediaQuery.of(context).padding.top,
              ),
              builder: (context) => modalContent,
            );
          },
          child: const Icon(Icons.add),
        ),
      ),
      body: Column(
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
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
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
                          notification.overscroll < 0 &&
                          _isMobileDevice()) {
                        setState(() {
                          _isSearchVisible = true;
                        });
                      }
                      return false;
                    },
                    child: isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : isError
                            ? Center(
                                child: Text(state.errorMessage ?? 'Ошибка'))
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
                                    physics:
                                        const AlwaysScrollableScrollPhysics(),
                                    itemCount: filteredContracts.length,
                                    itemBuilder: (context, index) {
                                      final contract = filteredContracts[index];
                                      return _ContractRowItem(
                                        key: ValueKey(contract.id),
                                        contract: contract,
                                        isExpanded:
                                            _expandedContractId == contract.id,
                                        onExpandedChanged: (expanded) {
                                          if (mounted) {
                                            setState(() {
                                              _expandedContractId =
                                                  expanded ? contract.id : null;
                                            });
                                          }
                                        },
                                        onEdit: () {
                                          if (_isMobileDevice()) {
                                            context.pushNamed('contract-form',
                                                extra: contract);
                                          } else {
                                            final theme = Theme.of(context);
                                            final isDesktop =
                                                MediaQuery.of(context)
                                                        .size
                                                        .width >
                                                    800;

                                            showModalBottomSheet(
                                              context: context,
                                              useRootNavigator: true,
                                              isScrollControlled: true,
                                              backgroundColor:
                                                  Colors.transparent,
                                              useSafeArea: true,
                                              constraints: BoxConstraints(
                                                maxHeight:
                                                    MediaQuery.of(context)
                                                            .size
                                                            .height -
                                                        MediaQuery.of(context)
                                                            .padding
                                                            .top,
                                              ),
                                              builder: (context) {
                                                Widget modalContent = Container(
                                                  width: double.infinity,
                                                  clipBehavior: Clip.antiAlias,
                                                  decoration: BoxDecoration(
                                                    color: theme
                                                        .colorScheme.surface,
                                                    borderRadius:
                                                        const BorderRadius
                                                            .vertical(
                                                            top:
                                                                Radius.circular(
                                                                    28)),
                                                    boxShadow: [
                                                      BoxShadow(
                                                        color: Colors.black
                                                            .withValues(
                                                                alpha: 0.1),
                                                        blurRadius: 10,
                                                        offset:
                                                            const Offset(0, -5),
                                                      ),
                                                    ],
                                                  ),
                                                  child: IntrinsicHeight(
                                                    child: Padding(
                                                      padding: EdgeInsets.only(
                                                        bottom: MediaQuery.of(
                                                                context)
                                                            .viewInsets
                                                            .bottom,
                                                      ),
                                                      child: ContractFormModal(
                                                          contract: contract),
                                                    ),
                                                  ),
                                                );

                                                if (isDesktop) {
                                                  modalContent = Align(
                                                    alignment:
                                                        Alignment.bottomCenter,
                                                    child: SizedBox(
                                                      width:
                                                          MediaQuery.of(context)
                                                                  .size
                                                                  .width *
                                                              0.5,
                                                      child: modalContent,
                                                    ),
                                                  );
                                                }
                                                return modalContent;
                                              },
                                            );
                                          }
                                        },
                                      );
                                    },
                                  ),
                  )
                : RefreshIndicator(
                    onRefresh: _handleRefresh,
                    child: isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : isError
                            ? Center(
                                child: Text(state.errorMessage ?? 'Ошибка'))
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
                                    physics:
                                        const AlwaysScrollableScrollPhysics(),
                                    itemCount: filteredContracts.length,
                                    itemBuilder: (context, index) {
                                      final contract = filteredContracts[index];
                                      return _ContractRowItem(
                                        key: ValueKey(contract.id),
                                        contract: contract,
                                        isExpanded:
                                            _expandedContractId == contract.id,
                                        onExpandedChanged: (expanded) {
                                          if (mounted) {
                                            setState(() {
                                              _expandedContractId =
                                                  expanded ? contract.id : null;
                                            });
                                          }
                                        },
                                        onEdit: () {
                                          if (_isMobileDevice()) {
                                            context.pushNamed('contract-form',
                                                extra: contract);
                                          } else {
                                            final theme = Theme.of(context);
                                            final isDesktop =
                                                MediaQuery.of(context)
                                                        .size
                                                        .width >
                                                    800;

                                            showModalBottomSheet(
                                              context: context,
                                              useRootNavigator: true,
                                              isScrollControlled: true,
                                              backgroundColor:
                                                  Colors.transparent,
                                              useSafeArea: true,
                                              constraints: BoxConstraints(
                                                maxHeight:
                                                    MediaQuery.of(context)
                                                            .size
                                                            .height -
                                                        MediaQuery.of(context)
                                                            .padding
                                                            .top,
                                              ),
                                              builder: (context) {
                                                Widget modalContent = Container(
                                                  width: double.infinity,
                                                  clipBehavior: Clip.antiAlias,
                                                  decoration: BoxDecoration(
                                                    color: theme
                                                        .colorScheme.surface,
                                                    borderRadius:
                                                        const BorderRadius
                                                            .vertical(
                                                            top:
                                                                Radius.circular(
                                                                    28)),
                                                    boxShadow: [
                                                      BoxShadow(
                                                        color: Colors.black
                                                            .withValues(
                                                                alpha: 0.1),
                                                        blurRadius: 10,
                                                        offset:
                                                            const Offset(0, -5),
                                                      ),
                                                    ],
                                                  ),
                                                  child: IntrinsicHeight(
                                                    child: Padding(
                                                      padding: EdgeInsets.only(
                                                        bottom: MediaQuery.of(
                                                                context)
                                                            .viewInsets
                                                            .bottom,
                                                      ),
                                                      child: ContractFormModal(
                                                          contract: contract),
                                                    ),
                                                  ),
                                                );

                                                if (isDesktop) {
                                                  modalContent = Align(
                                                    alignment:
                                                        Alignment.bottomCenter,
                                                    child: SizedBox(
                                                      width:
                                                          MediaQuery.of(context)
                                                                  .size
                                                                  .width *
                                                              0.5,
                                                      child: modalContent,
                                                    ),
                                                  );
                                                }
                                                return modalContent;
                                              },
                                            );
                                          }
                                        },
                                      );
                                    },
                                  ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _ContractRowItem extends ConsumerStatefulWidget {
  final Contract contract;
  final VoidCallback onEdit;
  final bool isExpanded;
  final Function(bool) onExpandedChanged;

  const _ContractRowItem({
    super.key,
    required this.contract,
    required this.onEdit,
    required this.isExpanded,
    required this.onExpandedChanged,
  });

  @override
  ConsumerState<_ContractRowItem> createState() => _ContractRowItemState();
}

class _ContractRowItemState extends ConsumerState<_ContractRowItem> {
  /// Обработка удаления договора с подтверждением.
  Future<void> _handleDelete(BuildContext context) async {
    final confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder: (BuildContext context) => CupertinoAlertDialog(
        title: const Text('Удалить договор?'),
        content: Text(
            'Вы уверены, что хотите удалить договор № ${widget.contract.number}?'),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Отмена'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await ref
            .read(contractProvider.notifier)
            .deleteContract(widget.contract.id);
        if (!context.mounted) return;
        SnackBarUtils.showSuccess(context, 'Договор удален');
      } catch (e) {
        if (!context.mounted) return;
        SnackBarUtils.showError(context, 'Ошибка при удалении: $e');
      }
    }
  }

  /// Строит иконку предупреждения, если срок действия договора истекает или истек.
  Widget? _buildWarningIcon() {
    if (widget.contract.endDate == null) return null;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final end = DateTime(widget.contract.endDate!.year,
        widget.contract.endDate!.month, widget.contract.endDate!.day);
    final difference = end.difference(today).inDays;

    Widget? icon;

    if (difference < 0) {
      // Срок истёк: красный треугольник с восклицательным знаком
      icon = const Tooltip(
        message: 'Срок действия истёк',
        child: Padding(
          padding: EdgeInsets.only(right: 8.0),
          child:
              Icon(Icons.report_problem_rounded, color: Colors.red, size: 20),
        ),
      );
    } else if (difference <= 30) {
      // Осталось 30 дней или меньше: жёлтый треугольник с восклицательным знаком
      icon = const Tooltip(
        message: 'Срок действия истекает',
        child: Padding(
          padding: EdgeInsets.only(right: 8.0),
          child:
              Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 20),
        ),
      );
    }
    return icon;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isMobile = MediaQuery.of(context).size.width < 900;

    final numberStyle = theme.textTheme.titleMedium?.copyWith(
      fontWeight: FontWeight.w700,
      letterSpacing: 0.5,
    );

    final labelStyle = theme.textTheme.labelSmall?.copyWith(
      color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
      fontWeight: FontWeight.w500,
      letterSpacing: 0.2,
    );

    final valueStyle = theme.textTheme.bodyMedium?.copyWith(
      color: theme.colorScheme.onSurface.withValues(alpha: 0.9),
      fontWeight: FontWeight.w400,
    );

    final amountStyle = theme.textTheme.titleMedium?.copyWith(
      fontWeight: FontWeight.w700,
      letterSpacing: 0.2,
    );

    final warningIcon = _buildWarningIcon();

    if (isMobile) {
      // Mobile: Elegant vertical card (unchanged)
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: theme.colorScheme.outline.withValues(alpha: 0.08),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onEdit,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            if (warningIcon != null) warningIcon,
                            Flexible(
                              child: Text(
                                '№ ${widget.contract.number}',
                                style: numberStyle,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      AppBadge(
                        text: _ContractRowItemHelper.getContractStatusInfo(
                                widget.contract.status, theme)
                            .$1,
                        color: _ContractRowItemHelper.getContractStatusInfo(
                                widget.contract.status, theme)
                            .$2,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Контрагент', style: labelStyle),
                            const SizedBox(height: 2),
                            Text(widget.contract.contractorName ?? '—',
                                style: valueStyle),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Объект', style: labelStyle),
                            const SizedBox(height: 2),
                            Text(widget.contract.objectName ?? '—',
                                style: valueStyle),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Divider(height: 1, thickness: 0.5),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Дата', style: labelStyle),
                          Text(formatRuDate(widget.contract.date),
                              style: valueStyle),
                        ],
                      ),
                      Text(
                        formatCurrency(widget.contract.amount),
                        style: amountStyle,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    // Desktop: Expandable Table Row
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      decoration: BoxDecoration(
        color: widget.isExpanded
            ? theme.colorScheme.surfaceContainerLow.withValues(alpha: 0.5)
            : theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: widget.isExpanded
              ? theme.colorScheme.primary.withValues(alpha: 0.2)
              : theme.colorScheme.outline.withValues(alpha: 0.06),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // Main Row Header
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                if (mounted) {
                  widget.onExpandedChanged(!widget.isExpanded);
                }
              },
              borderRadius: BorderRadius.vertical(
                  top: const Radius.circular(12),
                  bottom: Radius.circular(widget.isExpanded ? 0 : 12)),
              hoverColor: theme.colorScheme.surfaceContainerHighest
                  .withValues(alpha: 0.3),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    vertical: 16.0, horizontal: 24.0),
                child: Row(
                  children: [
                    // Number
                    Expanded(
                      flex: 2,
                      child: Row(
                        children: [
                          if (warningIcon != null) warningIcon,
                          Flexible(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '№ ${widget.contract.number}',
                                  style: numberStyle?.copyWith(fontSize: 15),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Object
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('Объект', style: labelStyle),
                          const SizedBox(height: 2),
                          Text(
                            widget.contract.objectName ?? '—',
                            style: valueStyle,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    // Contractor
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('Контрагент', style: labelStyle),
                          const SizedBox(height: 2),
                          Text(
                            widget.contract.contractorName ?? '—',
                            style: valueStyle,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    // Start Date
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('Начало', style: labelStyle),
                          const SizedBox(height: 2),
                          Text(
                            formatRuDate(widget.contract.date),
                            style: valueStyle,
                          ),
                        ],
                      ),
                    ),
                    // End Date
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('Окончание', style: labelStyle),
                          const SizedBox(height: 2),
                          Text(
                            widget.contract.endDate != null
                                ? formatRuDate(widget.contract.endDate!)
                                : '—',
                            style: valueStyle,
                          ),
                        ],
                      ),
                    ),
                    // Amount
                    Expanded(
                      flex: 2,
                      child: Text(
                        formatCurrency(widget.contract.amount),
                        style: amountStyle,
                        textAlign: TextAlign.end,
                      ),
                    ),
                    // Status & Chevron
                    Expanded(
                      flex: 2,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          AppBadge(
                            text: _ContractRowItemHelper.getContractStatusInfo(
                                    widget.contract.status, theme)
                                .$1,
                            color: _ContractRowItemHelper.getContractStatusInfo(
                                    widget.contract.status, theme)
                                .$2,
                          ),
                          const SizedBox(width: 12),
                          AnimatedRotation(
                            turns: widget.isExpanded ? 0.5 : 0,
                            duration: const Duration(milliseconds: 300),
                            child: Icon(
                              Icons.keyboard_arrow_down,
                              color: theme.colorScheme.onSurface
                                  .withValues(alpha: 0.5),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Expanded Details Panel
          AnimatedCrossFade(
            firstChild: const SizedBox(width: double.infinity),
            secondChild: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(height: 1),
                  const SizedBox(height: 20),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Financial Details
                      Expanded(
                        flex: 3,
                        child: Row(
                          children: [
                            Expanded(
                              child: _DetailItem(
                                label: widget.contract.isVatIncluded
                                    ? 'НДС ${widget.contract.vatRate.toStringAsFixed(0)}% (включен)'
                                    : 'НДС ${widget.contract.vatRate.toStringAsFixed(0)}% (сверху)',
                                value:
                                    formatCurrency(widget.contract.vatAmount),
                              ),
                            ),
                            Expanded(
                              child: _DetailItem(
                                label: 'Аванс',
                                value: formatCurrency(
                                    widget.contract.advanceAmount),
                              ),
                            ),
                            Expanded(
                              child: _DetailItem(
                                label: widget.contract.warrantyPeriodMonths > 0
                                    ? 'Гарантийные ${widget.contract.warrantyRetentionRate.toStringAsFixed(0)}% (${widget.contract.warrantyPeriodMonths} мес.)'
                                    : 'Гарантийные',
                                value: formatCurrency(
                                    widget.contract.warrantyRetentionAmount),
                              ),
                            ),
                            Expanded(
                              child: _DetailItem(
                                label: widget
                                            .contract.generalContractorFeeRate >
                                        0
                                    ? 'Генподрядные ${widget.contract.generalContractorFeeRate.toStringAsFixed(0)}%'
                                    : 'Генподрядные',
                                value: formatCurrency(
                                    widget.contract.generalContractorFeeAmount),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Actions
                      Expanded(
                        flex: 1,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            PermissionGuard(
                              module: 'contracts',
                              permission: 'read',
                              child: IconButton(
                                onPressed: () {
                                  showModalBottomSheet(
                                    context: context,
                                    isScrollControlled: true,
                                    useSafeArea: true,
                                    builder: (context) => Ks2ActsSheet(
                                        contractId: widget.contract.id),
                                  );
                                },
                                icon: const Icon(Icons.description_outlined),
                                tooltip: 'Акты КС-2',
                                color: theme.colorScheme.primary,
                              ),
                            ),
                            PermissionGuard(
                              module: 'contracts',
                              permission: 'update',
                              child: IconButton(
                                onPressed: widget.onEdit,
                                icon: const Icon(Icons.edit_outlined),
                                tooltip: 'Редактировать',
                                color: theme.colorScheme.primary,
                              ),
                            ),
                            PermissionGuard(
                              module: 'contracts',
                              permission: 'delete',
                              child: IconButton(
                                onPressed: () => _handleDelete(context),
                                icon: const Icon(Icons.delete_outline),
                                tooltip: 'Удалить',
                                color: theme.colorScheme.error,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  ContractCostsInfo(
                    contractId: widget.contract.id,
                    objectId: widget.contract.objectId,
                    contractAmount: widget.contract.amount,
                  ),
                ],
              ),
            ),
            crossFadeState: widget.isExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 300),
            sizeCurve: Curves.easeInOut,
          ),
        ],
      ),
    );
  }
}

class _DetailItem extends StatelessWidget {
  final String label;
  final String value;

  const _DetailItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        SelectableText(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

/// Вспомогательный виджет для отображения статуса
class _ContractRowItemHelper {
  static (String, Color) getContractStatusInfo(
      ContractStatus status, ThemeData theme) {
    switch (status) {
      case ContractStatus.active:
        return ('В работе', Colors.green);
      case ContractStatus.suspended:
        return ('Приостановлен', Colors.orange);
      case ContractStatus.completed:
        return ('Завершен', Colors.grey);
    }
  }
}
