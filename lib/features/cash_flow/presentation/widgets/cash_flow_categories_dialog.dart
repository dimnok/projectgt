import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:projectgt/core/widgets/gt_text_field.dart';
import 'package:projectgt/core/widgets/desktop_dialog_content.dart';
import 'package:projectgt/core/widgets/gt_buttons.dart';
import 'package:projectgt/core/widgets/gt_dropdown.dart';
import 'package:projectgt/core/widgets/app_snackbar.dart';
import 'package:projectgt/features/cash_flow/domain/entities/cash_flow_category.dart';
import 'package:projectgt/features/company/presentation/providers/company_providers.dart';
import 'package:projectgt/features/cash_flow/presentation/state/cash_flow_state.dart';

/// Диалоговое окно управления статьями ДДС.
///
/// Позволяет просматривать список существующих статей и
/// добавлять новые статьи в инлайн-режиме.
class CashFlowCategoriesDialog extends ConsumerStatefulWidget {
  /// Создаёт диалог управления статьями.
  const CashFlowCategoriesDialog({super.key});

  @override
  ConsumerState<CashFlowCategoriesDialog> createState() =>
      _CashFlowCategoriesDialogState();
}

class _CashFlowCategoriesDialogState
    extends ConsumerState<CashFlowCategoriesDialog> {
  final _newCategoryController = TextEditingController();
  CashFlowOperationType _selectedType = CashFlowOperationType.expense;

  @override
  void dispose() {
    _newCategoryController.dispose();
    super.dispose();
  }

  /// Обрабатывает сохранение новой статьи.
  Future<void> _addCategory() async {
    final name = _newCategoryController.text.trim();
    if (name.isEmpty) return;

    final activeCompanyId = ref.read(activeCompanyIdProvider);
    if (activeCompanyId == null) return;

    final category = CashFlowCategory(
      id: '', // Supabase сгенерирует UUID
      companyId: activeCompanyId,
      name: name,
      type: _selectedType,
    );

    try {
      await ref.read(cashFlowProvider.notifier).saveCategory(category);
      _newCategoryController.clear();
      if (mounted) {
        FocusScope.of(context).unfocus();
        AppSnackBar.show(
          context: context,
          message: 'Статья добавлена',
          kind: AppSnackBarKind.success,
        );
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.show(
          context: context,
          message: 'Ошибка при добавлении: $e',
          kind: AppSnackBarKind.error,
        );
      }
    }
  }

  /// Обрабатывает удаление (архивацию) статьи.
  Future<void> _deleteCategory(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удаление статьи'),
        content: const Text(
          'Вы уверены, что хотите удалить эту статью ДДС? Она перестанет отображаться в списках.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Удалить', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ref.read(cashFlowProvider.notifier).deleteCategory(id);
        if (mounted) {
          AppSnackBar.show(
            context: context,
            message: 'Статья успешно удалена',
            kind: AppSnackBarKind.success,
          );
        }
      } catch (e) {
        if (mounted) {
          String errorMessage = 'Ошибка при удалении';

          // Проверяем на нарушение целостности данных (foreign key constraint)
          final errorStr = e.toString().toLowerCase();
          if (e is PostgrestException && e.code == '23503' ||
              errorStr.contains('foreign key') ||
              errorStr.contains('violates') ||
              errorStr.contains('connection reset by peer')) {
            errorMessage =
                'Невозможно удалить статью, так как она используется в финансовых операциях. Сначала выберите другую статью для этих операций.';
          } else {
            errorMessage = 'Ошибка при удалении: $e';
          }

          AppSnackBar.show(
            context: context,
            message: errorMessage,
            kind: AppSnackBarKind.error,
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = ref.watch(cashFlowProvider);
    final categories = state.categories;
    final isLoading = state.status == CashFlowStatus.loading;

    final incomeCategories = categories
        .where((c) => c.type == CashFlowOperationType.income)
        .toList();
    final expenseCategories = categories
        .where((c) => c.type == CashFlowOperationType.expense)
        .toList();

    return DesktopDialogContent(
      title: 'Статьи ДДС',
      footer: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          GTSecondaryButton(
            text: 'Закрыть',
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Инлайн форма добавления
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                flex: 2,
                child: GTTextField(
                  controller: _newCategoryController,
                  enabled: !isLoading,
                  hintText: 'Название статьи...',
                  onSubmitted: (_) => _addCategory(),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 1,
                child: GTEnumDropdown<CashFlowOperationType>(
                  values: CashFlowOperationType.values,
                  selectedValue: _selectedType,
                  labelText: '',
                  hintText: 'Тип',
                  isDense: true,
                  enumToString: (type) => type == CashFlowOperationType.income
                      ? 'Приход'
                      : 'Расход',
                  readOnly: isLoading,
                  allowClear: false,
                  onChanged: (v) {
                    if (v != null) setState(() => _selectedType = v);
                  },
                ),
              ),
              const SizedBox(width: 8),
              if (isLoading)
                const SizedBox(
                  width: 36,
                  height: 36,
                  child: Padding(
                    padding: EdgeInsets.all(8.0),
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              else
                IconButton.filled(
                  onPressed: _addCategory,
                  icon: const Icon(CupertinoIcons.plus, size: 18),
                  tooltip: 'Добавить',
                  style: IconButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                    minimumSize: const Size(36, 36),
                    maximumSize: const Size(36, 36),
                    padding: EdgeInsets.zero,
                    shape: const CircleBorder(),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 24),

          // Список существующих статей с группировкой
          if (categories.isEmpty && !isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32.0),
                child: Text('Список статей пуст'),
              ),
            )
          else ...[
            if (incomeCategories.isNotEmpty) ...[
              _buildSectionHeader(context, 'Приход', Colors.green),
              _buildCategoryList(incomeCategories, theme, isLoading),
              const SizedBox(height: 16),
            ],
            if (expenseCategories.isNotEmpty) ...[
              _buildSectionHeader(context, 'Расход', Colors.red),
              _buildCategoryList(expenseCategories, theme, isLoading),
            ],
          ],
        ],
      ),
    );
  }

  /// Заголовок секции (Приход/Расход).
  Widget _buildSectionHeader(BuildContext context, String title, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: color.withValues(alpha: 0.3), width: 2),
        ),
      ),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
          fontSize: 12,
        ),
      ),
    );
  }

  /// Список статей для конкретной секции.
  Widget _buildCategoryList(
    List<CashFlowCategory> categories,
    ThemeData theme,
    bool isLoading,
  ) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: categories.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final category = categories[index];
        return ListTile(
          contentPadding: EdgeInsets.zero,
          dense: true,
          visualDensity: const VisualDensity(vertical: -2),
          title: Text(category.name),
          trailing: IconButton(
            icon: const Icon(CupertinoIcons.trash, size: 20),
            onPressed: isLoading ? null : () => _deleteCategory(category.id),
            color: Colors.red.withValues(alpha: 0.7),
          ),
        );
      },
    );
  }
}
