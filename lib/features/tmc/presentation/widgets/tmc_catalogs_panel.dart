import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:projectgt/core/widgets/app_snackbar.dart';
import 'package:projectgt/core/widgets/gt_buttons.dart';
import 'package:projectgt/core/widgets/gt_text_field.dart';
import 'package:projectgt/features/company/presentation/providers/company_providers.dart';
import 'package:projectgt/features/tmc/domain/entities/tmc_category.dart';
import 'package:projectgt/features/tmc/domain/entities/tmc_warehouse.dart';
import 'package:projectgt/features/tmc/presentation/state/tmc_providers.dart';
import 'package:projectgt/features/tmc/presentation/utils/tmc_ui_labels.dart';

/// Справочники складов и категорий ТМЦ.
class TmcCatalogsPanel extends ConsumerStatefulWidget {
  /// Создаёт панель справочников.
  const TmcCatalogsPanel({super.key});

  @override
  ConsumerState<TmcCatalogsPanel> createState() => _TmcCatalogsPanelState();
}

class _TmcCatalogsPanelState extends ConsumerState<TmcCatalogsPanel> {
  final _warehouseNameController = TextEditingController();
  final _categoryNameController = TextEditingController();
  bool _savingWarehouse = false;
  bool _savingCategory = false;

  @override
  void dispose() {
    _warehouseNameController.dispose();
    _categoryNameController.dispose();
    super.dispose();
  }

  Future<void> _addWarehouse() async {
    final name = _warehouseNameController.text.trim();
    if (name.isEmpty) return;
    setState(() => _savingWarehouse = true);
    try {
      final companyId = ref.read(activeCompanyIdProvider) ?? '';
      await ref
          .read(tmcRepositoryProvider)
          .createWarehouse(
            TmcWarehouse(id: '', companyId: companyId, name: name),
          );
      _warehouseNameController.clear();
      ref.invalidate(tmcWarehousesProvider);
      if (!mounted) return;
      AppSnackBar.show(
        context: context,
        message: 'Склад добавлен',
        kind: AppSnackBarKind.success,
      );
    } catch (e) {
      if (!mounted) return;
      AppSnackBar.show(
        context: context,
        message: e.toString(),
        kind: AppSnackBarKind.error,
      );
    } finally {
      if (mounted) setState(() => _savingWarehouse = false);
    }
  }

  Future<void> _addCategory() async {
    final name = _categoryNameController.text.trim();
    if (name.isEmpty) return;
    setState(() => _savingCategory = true);
    try {
      final companyId = ref.read(activeCompanyIdProvider) ?? '';
      await ref
          .read(tmcRepositoryProvider)
          .createCategory(
            TmcCategory(id: '', companyId: companyId, name: name),
          );
      _categoryNameController.clear();
      ref.invalidate(tmcCategoriesProvider);
      if (!mounted) return;
      AppSnackBar.show(
        context: context,
        message: 'Категория добавлена',
        kind: AppSnackBarKind.success,
      );
    } catch (e) {
      if (!mounted) return;
      AppSnackBar.show(
        context: context,
        message: e.toString(),
        kind: AppSnackBarKind.error,
      );
    } finally {
      if (mounted) setState(() => _savingCategory = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final warehousesAsync = ref.watch(tmcWarehousesProvider);
    final categoriesAsync = ref.watch(tmcCategoriesProvider);

    return DefaultTabController(
      length: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const TabBar(
            tabs: [
              Tab(text: 'Склады'),
              Tab(text: 'Категории'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _ListTab(
                  async: warehousesAsync,
                  nameBuilder: (w) {
                    final warehouse = w as TmcWarehouse;
                    return TmcUiLabels.warehouseLabel(warehouse);
                  },
                  controller: _warehouseNameController,
                  label: 'Новый склад',
                  saving: _savingWarehouse,
                  onAdd: _addWarehouse,
                ),
                _ListTab(
                  async: categoriesAsync,
                  nameBuilder: (c) => (c as TmcCategory).name,
                  controller: _categoryNameController,
                  label: 'Новая категория',
                  saving: _savingCategory,
                  onAdd: _addCategory,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ListTab extends StatelessWidget {
  final AsyncValue<List<dynamic>> async;
  final String Function(dynamic item) nameBuilder;
  final TextEditingController controller;
  final String label;
  final bool saving;
  final VoidCallback onAdd;

  const _ListTab({
    required this.async,
    required this.nameBuilder,
    required this.controller,
    required this.label,
    required this.saving,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: GTTextField(controller: controller, labelText: label),
              ),
              const SizedBox(width: 8),
              GTPrimaryButton(
                text: 'Добавить',
                onPressed: saving ? null : onAdd,
                isLoading: saving,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: async.when(
              data: (items) => ListView.separated(
                itemCount: items.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) => ListTile(
                  dense: true,
                  title: Text(nameBuilder(items[index])),
                ),
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text(e.toString()),
            ),
          ),
        ],
      ),
    );
  }
}
