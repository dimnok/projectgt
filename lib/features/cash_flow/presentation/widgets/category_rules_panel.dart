import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:projectgt/features/company/presentation/providers/company_providers.dart';
import 'package:projectgt/core/widgets/app_snackbar.dart';
import 'package:projectgt/core/widgets/gt_buttons.dart';
import 'package:projectgt/core/widgets/gt_dropdown.dart';
import 'package:projectgt/core/widgets/gt_text_field.dart';
import 'package:projectgt/features/cash_flow/domain/entities/cash_flow_category.dart';
import 'package:projectgt/features/cash_flow/domain/entities/cash_flow_category_rule.dart';
import 'package:projectgt/features/cash_flow/presentation/state/cash_flow_state.dart';

/// Панель управления правилами автосопоставления статей ДДС.
class CategoryRulesPanel extends ConsumerStatefulWidget {
  /// Создаёт панель правил.
  const CategoryRulesPanel({super.key});

  @override
  ConsumerState<CategoryRulesPanel> createState() => _CategoryRulesPanelState();
}

class _CategoryRulesPanelState extends ConsumerState<CategoryRulesPanel> {
  final _keywordController = TextEditingController();
  final _priorityController = TextEditingController(text: '0');
  CashFlowOperationType _operationType = CashFlowOperationType.expense;
  String? _selectedCategoryId;
  String? _editingRuleId;
  bool _requiresContractBinding = true;

  @override
  void dispose() {
    _keywordController.dispose();
    _priorityController.dispose();
    super.dispose();
  }

  void _loadRule(CashFlowCategoryRule rule) {
    setState(() {
      _editingRuleId = rule.id;
      _keywordController.text = rule.keyword;
      _priorityController.text = rule.priority.toString();
      _operationType = rule.operationType;
      _selectedCategoryId = rule.categoryId;
      _requiresContractBinding = rule.requiresContractBinding;
    });
  }

  void _clearForm() {
    setState(() {
      _editingRuleId = null;
      _keywordController.clear();
      _priorityController.text = '0';
      _operationType = CashFlowOperationType.expense;
      _selectedCategoryId = null;
      _requiresContractBinding = true;
    });
  }

  Future<void> _saveRule() async {
    final keyword = _keywordController.text.trim();
    if (keyword.isEmpty) {
      AppSnackBar.show(
        context: context,
        message: 'Укажите ключевое слово',
        kind: AppSnackBarKind.error,
      );
      return;
    }

    if (_selectedCategoryId == null) {
      AppSnackBar.show(
        context: context,
        message: 'Выберите статью ДДС',
        kind: AppSnackBarKind.error,
      );
      return;
    }

    final companyId = ref.read(activeCompanyIdProvider);
    if (companyId == null) return;

    final priority = int.tryParse(_priorityController.text.trim()) ?? 0;

    final rule = CashFlowCategoryRule(
      id: _editingRuleId ?? '',
      companyId: companyId,
      categoryId: _selectedCategoryId!,
      keyword: keyword,
      operationType: _operationType,
      priority: priority,
      requiresContractBinding: _requiresContractBinding,
    );

    try {
      await ref.read(cashFlowProvider.notifier).saveCategoryRule(rule);
      if (mounted) {
        AppSnackBar.show(
          context: context,
          message: _editingRuleId == null
              ? 'Правило добавлено'
              : 'Правило обновлено',
          kind: AppSnackBarKind.success,
        );
        _clearForm();
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.show(
          context: context,
          message: e.toString(),
          kind: AppSnackBarKind.error,
        );
      }
    }
  }

  Future<void> _deleteRule(String id) async {
    try {
      await ref.read(cashFlowProvider.notifier).deleteCategoryRule(id);
      if (mounted) {
        AppSnackBar.show(
          context: context,
          message: 'Правило удалено',
          kind: AppSnackBarKind.success,
        );
        if (_editingRuleId == id) _clearForm();
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.show(
          context: context,
          message: e.toString(),
          kind: AppSnackBarKind.error,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = ref.watch(cashFlowProvider);
    final rules = state.categoryRules;

    final expenseCategories = state.categories
        .where((c) => c.type == CashFlowOperationType.expense)
        .toList();
    final incomeCategories = state.categories
        .where((c) => c.type == CashFlowOperationType.income)
        .toList();
    final categoryOptions = _operationType == CashFlowOperationType.income
        ? incomeCategories
        : expenseCategories;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Если в назначении платежа есть ключевое слово — система подставит статью ДДС при автосопоставлении.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: GTTextField(
                controller: _keywordController,
                labelText: 'Ключевое слово',
                hintText: 'например: аренда',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: GTEnumDropdown<CashFlowOperationType>(
                labelText: 'Тип операции',
                hintText: 'Выберите тип',
                values: CashFlowOperationType.values,
                selectedValue: _operationType,
                enumToString: (t) =>
                    t == CashFlowOperationType.income ? 'Приход' : 'Расход',
                onChanged: (value) {
                  if (value == null) return;
                  setState(() {
                    _operationType = value;
                    _selectedCategoryId = null;
                  });
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: GTDropdown<String>(
                labelText: 'Статья ДДС',
                hintText: 'Выберите статью',
                items: categoryOptions.map((c) => c.id).toList(),
                selectedItem: _selectedCategoryId,
                itemDisplayBuilder: (id) =>
                    categoryOptions.firstWhere((c) => c.id == id).name,
                onSelectionChanged: (value) =>
                    setState(() => _selectedCategoryId = value),
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: 120,
              child: GTTextField(
                controller: _priorityController,
                labelText: 'Приоритет',
                hintText: '0',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Checkbox(
              value: !_requiresContractBinding,
              onChanged: (value) => setState(
                () => _requiresContractBinding = value != true,
              ),
            ),
            Expanded(
              child: Text(
                'Только статья (без договора и объекта) — для налогов и прочих общих платежей',
                style: theme.textTheme.bodySmall,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            GTSecondaryButton(
              text: 'Очистить',
              onPressed: _clearForm,
            ),
            const SizedBox(width: 12),
            GTPrimaryButton(
              text: _editingRuleId == null ? 'Добавить правило' : 'Сохранить',
              onPressed: _saveRule,
            ),
          ],
        ),
        const SizedBox(height: 24),
        if (rules.isEmpty)
          Text(
            'Правила не настроены',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.hintColor,
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: rules.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final rule = rules[index];
              final typeLabel = rule.operationType == CashFlowOperationType.income
                  ? 'Приход'
                  : 'Расход';
              final bindingLabel = rule.requiresContractBinding
                  ? 'с договором'
                  : 'только статья';

              return ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                title: Text(
                  '«${rule.keyword}» → ${rule.categoryName ?? rule.categoryId}',
                  style: theme.textTheme.bodyMedium,
                ),
                subtitle: Text('$typeLabel · $bindingLabel · приоритет ${rule.priority}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(CupertinoIcons.pencil, size: 18),
                      onPressed: () => _loadRule(rule),
                      tooltip: 'Редактировать',
                    ),
                    IconButton(
                      icon: const Icon(
                        CupertinoIcons.trash,
                        size: 18,
                        color: Colors.red,
                      ),
                      onPressed: () => _deleteRule(rule.id),
                      tooltip: 'Удалить',
                    ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }
}
