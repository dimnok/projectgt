import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:projectgt/core/widgets/gt_text_field.dart';
import 'package:projectgt/core/widgets/gt_buttons.dart';
import 'package:projectgt/core/widgets/gt_dropdown.dart';
import 'package:projectgt/core/di/providers.dart';
import 'package:projectgt/features/contractors/presentation/state/contractor_state.dart';
import 'package:projectgt/features/cash_flow/presentation/widgets/cash_flow_details_panel.dart';
import 'package:projectgt/features/cash_flow/presentation/screens/desktop/bank_statement_view.dart';
import 'package:projectgt/features/cash_flow/presentation/widgets/cash_flow_form_dialog.dart';
import 'package:projectgt/features/cash_flow/presentation/widgets/cash_flow_categories_dialog.dart';
import 'package:projectgt/features/cash_flow/presentation/state/cash_flow_state.dart';
import 'package:projectgt/features/company/presentation/providers/company_providers.dart';
import 'package:projectgt/features/objects/domain/entities/object.dart';
import 'package:projectgt/features/contractors/domain/entities/contractor.dart';
import 'package:projectgt/domain/entities/contract.dart';

/// Десктопное представление модуля Cash Flow.
///
/// Использует двухпанельную компоновку (Master-Detail):
/// - Левая панель: Список операций с поиском и кнопкой добавления.
/// - Правая панель: Детальная информация о выбранной операции.
class CashFlowListDesktopView extends ConsumerStatefulWidget {
  /// Создаёт десктопный вид списка Cash Flow.
  const CashFlowListDesktopView({super.key});

  @override
  ConsumerState<CashFlowListDesktopView> createState() =>
      _CashFlowListDesktopViewState();
}

class _CashFlowListDesktopViewState
    extends ConsumerState<CashFlowListDesktopView> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final notifier = ref.read(cashFlowProvider.notifier);

    return Padding(
      padding: const EdgeInsets.all(16),
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
              // Левая панель - Список операций
              Container(
                width: 350,
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
                    // Поиск и кнопка добавления (всегда сверху)
                    Consumer(
                      builder: (context, ref, child) {
                        final state = ref.watch(cashFlowProvider);
                        final isTransactions =
                            state.currentView == CashFlowView.transactions;

                        return Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              GTTextField(
                                controller: _searchController,
                                hintText: isTransactions
                                    ? 'Поиск операций...'
                                    : 'Поиск в выписках...',
                                prefixIcon: CupertinoIcons.search,
                                onChanged: isTransactions
                                    ? notifier.setSearchQuery
                                    : (query) {
                                        // TODO: Реализовать поиск по выпискам
                                      },
                              ),
                              const SizedBox(height: 12),
                              if (isTransactions)
                                SizedBox(
                                  width: double.infinity,
                                  child: GTPrimaryButton(
                                    text: 'Добавить операцию',
                                    icon: CupertinoIcons.plus,
                                    onPressed: () {
                                      showDialog(
                                        context: context,
                                        builder: (context) => const Dialog(
                                          backgroundColor: Colors.transparent,
                                          insetPadding: EdgeInsets.all(24),
                                          child: CashFlowFormDialog(),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                            ],
                          ),
                        );
                      },
                    ),
                    const Divider(height: 1),
                    // Фильтры или список счетов (прокручиваемые)
                    Expanded(
                      child: Consumer(
                        builder: (context, ref, child) {
                          final state = ref.watch(cashFlowProvider);

                          if (state.currentView == CashFlowView.bankStatement) {
                            final bankAccountsAsync = ref.watch(
                              companyBankAccountsProvider,
                            );

                            return bankAccountsAsync.when(
                              data: (accounts) {
                                if (accounts.isEmpty) {
                                  return const Center(
                                    child: Text(
                                      'У компании нет\nбанковских счетов',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(color: Colors.grey),
                                    ),
                                  );
                                }

                                // Если счет не выбран, выбираем основной или первый
                                if (state.selectedBankAccountId == null) {
                                  WidgetsBinding.instance.addPostFrameCallback((
                                    _,
                                  ) {
                                    // Проверяем, что список все еще не пустой
                                    final currentAccounts = ref.read(
                                      companyBankAccountsProvider,
                                    );
                                    currentAccounts.whenData((accs) {
                                      // Проверка на пустоту перед использованием
                                      if (accs.isEmpty) return;
                                      
                                      final primary = accs.firstWhere(
                                        (a) => a.isPrimary,
                                        orElse: () {
                                          // Дополнительная проверка на пустоту
                                          if (accs.isEmpty) {
                                            throw StateError(
                                              'Accounts list is empty',
                                            );
                                          }
                                          return accs.first;
                                        },
                                      );
                                      ref
                                          .read(cashFlowProvider.notifier)
                                          .setSelectedBankAccount(primary.id);
                                    });
                                  });
                                }

                                return ListView.builder(
                                  padding: const EdgeInsets.all(16.0),
                                  itemCount: accounts.length,
                                  itemBuilder: (context, index) {
                                    final account = accounts[index];
                                    final isSelected =
                                        state.selectedBankAccountId ==
                                        account.id;

                                    return Padding(
                                      padding: const EdgeInsets.only(
                                        bottom: 8.0,
                                      ),
                                      child: InkWell(
                                        onTap: () {
                                          ref
                                              .read(cashFlowProvider.notifier)
                                              .setSelectedBankAccount(
                                                account.id,
                                              );
                                        },
                                        borderRadius: BorderRadius.circular(12),
                                        child: Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: isSelected
                                                ? (isDark
                                                      ? Colors.grey[800]
                                                      : Colors.grey[100])
                                                : Colors.transparent,
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            border: Border.all(
                                              color: isSelected
                                                  ? (isDark
                                                        ? Colors.white24
                                                        : Colors.black12)
                                                  : Colors.transparent,
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              Container(
                                                width: 40,
                                                height: 40,
                                                decoration: BoxDecoration(
                                                  color: isDark
                                                      ? Colors.black26
                                                      : Colors.white,
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                  border: Border.all(
                                                    color: isDark
                                                        ? Colors.white10
                                                        : Colors.black12,
                                                  ),
                                                ),
                                                child: Icon(
                                                  account.isPrimary
                                                      ? CupertinoIcons.star_fill
                                                      : CupertinoIcons
                                                            .creditcard,
                                                  size: 20,
                                                  color: account.isPrimary
                                                      ? Colors.orange
                                                      : null,
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      account.bankName,
                                                      style: theme
                                                          .textTheme
                                                          .titleSmall
                                                          ?.copyWith(
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            fontSize: 13,
                                                          ),
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                    const SizedBox(height: 2),
                                                    Text(
                                                      account.accountNumber,
                                                      style: theme
                                                          .textTheme
                                                          .bodySmall
                                                          ?.copyWith(
                                                            fontFamily:
                                                                'monospace',
                                                            letterSpacing: 0.5,
                                                          ),
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              if (isSelected)
                                                const Icon(
                                                  CupertinoIcons.chevron_right,
                                                  size: 16,
                                                ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                );
                              },
                              loading: () => const Center(
                                child: CupertinoActivityIndicator(),
                              ),
                              error: (e, s) =>
                                  Center(child: Text('Ошибка: $e')),
                            );
                          }

                          return SingleChildScrollView(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              children: [
                                // Выбор года
                                Consumer(
                                  builder: (context, ref, child) {
                                    final state = ref.watch(cashFlowProvider);
                                    final currentYear = DateTime.now().year;
                                    final years = List.generate(
                                      6,
                                      (index) => currentYear - 3 + index,
                                    );

                                    return GTDropdown<int>(
                                      items: years,
                                      selectedItem: state.selectedYear,
                                      itemDisplayBuilder: (year) =>
                                          'Год: $year',
                                      labelText: 'Период',
                                      hintText: 'Выберите год',
                                      allowClear: false,
                                      isDense: true,
                                      prefixIcon: CupertinoIcons.calendar,
                                      onSelectionChanged: (newValue) {
                                        if (newValue != null) {
                                          ref
                                              .read(cashFlowProvider.notifier)
                                              .setSelectedYear(newValue);
                                        }
                                      },
                                    );
                                  },
                                ),
                                const SizedBox(height: 12),
                                // Фильтр по объекту
                                Consumer(
                                  builder: (context, ref, child) {
                                    final objectState = ref.watch(
                                      objectProvider,
                                    );
                                    final cashFlowState = ref.watch(
                                      cashFlowProvider,
                                    );
                                    final selectedObject = objectState.objects
                                        .where(
                                          (o) =>
                                              o.id ==
                                              cashFlowState.selectedObjectId,
                                        )
                                        .firstOrNull;

                                    final availableObjects = objectState.objects
                                        .where(
                                          (o) => cashFlowState
                                              .availableFilters
                                              .objectIds
                                              .contains(o.id),
                                        )
                                        .toList();

                                    return GTDropdown<ObjectEntity>(
                                      items: availableObjects,
                                      selectedItem: selectedObject,
                                      itemDisplayBuilder: (item) => item.name,
                                      labelText: 'Объект',
                                      hintText: 'Все объекты',
                                      allowClear: true,
                                      isDense: true,
                                      onSelectionChanged: (item) {
                                        ref
                                            .read(cashFlowProvider.notifier)
                                            .setSelectedObject(item?.id);
                                      },
                                    );
                                  },
                                ),
                                const SizedBox(height: 12),
                                // Фильтр по контрагенту
                                Consumer(
                                  builder: (context, ref, child) {
                                    final contractorState = ref.watch(
                                      contractorNotifierProvider,
                                    );
                                    final cashFlowState = ref.watch(
                                      cashFlowProvider,
                                    );
                                    final selectedContractor = contractorState
                                        .contractors
                                        .where(
                                          (c) =>
                                              c.id ==
                                              cashFlowState
                                                  .selectedContractorId,
                                        )
                                        .firstOrNull;

                                    final availableContractors = contractorState
                                        .contractors
                                        .where(
                                          (c) => cashFlowState
                                              .availableFilters
                                              .contractorIds
                                              .contains(c.id),
                                        )
                                        .toList();

                                    return GTDropdown<Contractor>(
                                      items: availableContractors,
                                      selectedItem: selectedContractor,
                                      itemDisplayBuilder: (item) =>
                                          item.shortName,
                                      labelText: 'Контрагент',
                                      hintText: 'Все контрагенты',
                                      allowClear: true,
                                      isDense: true,
                                      onSelectionChanged: (item) {
                                        ref
                                            .read(cashFlowProvider.notifier)
                                            .setSelectedContractor(item?.id);
                                      },
                                    );
                                  },
                                ),
                                const SizedBox(height: 12),
                                // Фильтр по договору (множественный выбор)
                                Consumer(
                                  builder: (context, ref, child) {
                                    final contractState = ref.watch(
                                      contractProvider,
                                    );
                                    final cashFlowState = ref.watch(
                                      cashFlowProvider,
                                    );
                                    final selectedContracts = contractState
                                        .contracts
                                        .where(
                                          (c) => cashFlowState
                                              .selectedContractIds
                                              .contains(c.id),
                                        )
                                        .toList();

                                    final availableContracts = contractState
                                        .contracts
                                        .where(
                                          (c) => cashFlowState
                                              .availableFilters
                                              .contractIds
                                              .contains(c.id),
                                        )
                                        .toList();

                                    return GTDropdown<Contract>(
                                      items: availableContracts,
                                      selectedItems: selectedContracts,
                                      allowMultipleSelection: true,
                                      itemDisplayBuilder: (item) =>
                                          '№${item.number}',
                                      labelText: 'Договоры',
                                      hintText: 'Все договоры',
                                      allowClear: true,
                                      isDense: true,
                                      onMultiSelectionChanged: (items) {
                                        ref
                                            .read(cashFlowProvider.notifier)
                                            .setSelectedContracts(
                                              items.map((i) => i.id).toList(),
                                            );
                                      },
                                    );
                                  },
                                ),
                                const SizedBox(height: 12),
                                // Фильтр по операциям (множественный выбор)
                                Consumer(
                                  builder: (context, ref, child) {
                                    final cashFlowState = ref.watch(
                                      cashFlowProvider,
                                    );
                                    final types = [
                                      {'id': 'income', 'name': 'Приход'},
                                      {'id': 'expense', 'name': 'Расход'},
                                    ];
                                    final selectedTypes = types
                                        .where(
                                          (t) => cashFlowState
                                              .selectedOperationTypes
                                              .contains(t['id']),
                                        )
                                        .toList();

                                    return GTDropdown<Map<String, String>>(
                                      items: types,
                                      selectedItems: selectedTypes,
                                      allowMultipleSelection: true,
                                      itemDisplayBuilder: (item) =>
                                          item['name']!,
                                      labelText: 'Тип операции',
                                      hintText: 'Все типы',
                                      allowClear: true,
                                      isDense: true,
                                      onMultiSelectionChanged: (items) {
                                        ref
                                            .read(cashFlowProvider.notifier)
                                            .setSelectedOperationTypes(
                                              items
                                                  .map((i) => i['id']!)
                                                  .toList(),
                                            );
                                      },
                                    );
                                  },
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    const Divider(height: 1),
                    // Кнопки действий (всегда снизу)
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Consumer(
                        builder: (context, ref, child) {
                          final state = ref.watch(cashFlowProvider);
                          final isTransactions =
                              state.currentView == CashFlowView.transactions;

                          return Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (isTransactions) ...[
                                SizedBox(
                                  width: double.infinity,
                                  child: GTSecondaryButton(
                                    text: 'Статьи ДДС',
                                    icon: CupertinoIcons.list_bullet,
                                    onPressed: () {
                                      showDialog(
                                        context: context,
                                        builder: (context) => const Dialog(
                                          backgroundColor: Colors.transparent,
                                          insetPadding: EdgeInsets.all(24),
                                          child: CashFlowCategoriesDialog(),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                const SizedBox(height: 8),
                              ],
                              SizedBox(
                                width: double.infinity,
                                child: GTSecondaryButton(
                                  text: isTransactions
                                      ? 'Банковская выписка'
                                      : 'CASH FLOW',
                                  icon: isTransactions
                                      ? CupertinoIcons.doc_text
                                      : CupertinoIcons.money_dollar_circle,
                                  onPressed: () {
                                    final newView = isTransactions
                                        ? CashFlowView.bankStatement
                                        : CashFlowView.transactions;
                                    ref
                                        .read(cashFlowProvider.notifier)
                                        .setView(newView);
                                  },
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              // Правая панель - Детали
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey[900] : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark ? Colors.grey[800]! : Colors.grey[300]!,
                    ),
                  ),
                  child: Consumer(
                    builder: (context, ref, child) {
                      final view = ref.watch(
                        cashFlowProvider.select((s) => s.currentView),
                      );
                      switch (view) {
                        case CashFlowView.transactions:
                          return const CashFlowDetailsPanel();
                        case CashFlowView.bankStatement:
                          return const BankStatementView();
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
