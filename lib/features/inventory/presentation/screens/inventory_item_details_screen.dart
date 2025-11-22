import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:projectgt/features/inventory/domain/entities/inventory_item.dart';
import 'package:projectgt/features/inventory/presentation/providers/inventory_provider.dart';
import 'package:projectgt/features/inventory/presentation/widgets/inventory_item_form.dart';
import 'package:projectgt/presentation/widgets/app_bar_widget.dart';
import 'package:projectgt/features/roles/presentation/widgets/permission_guard.dart';

/// Экран редактирования ТМЦ.
class InventoryItemDetailsScreen extends ConsumerStatefulWidget {
  /// ID ТМЦ для редактирования (null для создания нового).
  final String? itemId;

  /// Создаёт экран редактирования ТМЦ.
  const InventoryItemDetailsScreen({
    super.key,
    this.itemId,
  });

  @override
  ConsumerState<InventoryItemDetailsScreen> createState() =>
      _InventoryItemDetailsScreenState();
}

class _InventoryItemDetailsScreenState
    extends ConsumerState<InventoryItemDetailsScreen> {
  InventoryItem? _item;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.itemId != null) {
      _loadItem();
    } else {
      _isLoading = false;
    }
  }

  Future<void> _loadItem() async {
    try {
      final repository = ref.read(inventoryRepositoryProvider);
      final item = await repository.getInventoryItem(widget.itemId!);

      if (!mounted) return;

      setState(() {
        _item = item;
        _isLoading = false;
        _error = item == null ? 'ТМЦ не найдено' : null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = 'Ошибка загрузки: $e';
      });
    }
  }

  Future<void> _handleSave(InventoryItem item) async {
    final repository = ref.read(inventoryRepositoryProvider);
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);

    try {
      if (widget.itemId == null) {
        // Создание нового ТМЦ
        await repository.createInventoryItem(item);
        messenger.showSnackBar(
          const SnackBar(
            content: Text('ТМЦ успешно создано'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        // Обновление существующего ТМЦ
        await repository.updateInventoryItem(item);
        messenger.showSnackBar(
          const SnackBar(
            content: Text('ТМЦ успешно обновлено'),
            backgroundColor: Colors.green,
          ),
        );
      }

      // Обновляем список ТМЦ
      ref.invalidate(inventoryItemsProvider);

      // Возвращаемся назад
      if (mounted) {
        router.pop();
      }
    } catch (e) {
      String errorMessage = 'Ошибка сохранения';

      // Проверяем тип ошибки для более понятного сообщения
      if (e.toString().contains('не найдена в базе данных')) {
        errorMessage =
            'Запись не найдена в базе данных. Возможно, она была удалена.';
      } else if (e.toString().contains('PGRST116') ||
          e.toString().contains('0 rows')) {
        errorMessage =
            'Не удалось обновить запись. Возможно, она была удалена или изменена другим пользователем.';
      } else {
        errorMessage = 'Ошибка сохранения: $e';
      }

      messenger.showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  void _handleCancel() {
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final isCreating = widget.itemId == null;

    return Scaffold(
      appBar: AppBarWidget(
        title: isCreating ? 'Новое ТМЦ' : 'Редактирование ТМЦ',
        leading: const BackButton(),
        showThemeSwitch: false,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _error!,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: () => context.pop(),
                        child: const Text('Назад'),
                      ),
                    ],
                  ),
                )
              : PermissionGuard(
                  module: 'inventory',
                  permission: isCreating ? 'create' : 'update',
                  fallback: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.lock_outline,
                            size: 64, color: Colors.grey),
                        const SizedBox(height: 16),
                        Text(
                          'У вас нет прав на ${isCreating ? "создание" : "редактирование"} ТМЦ',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                  ),
                  child: InventoryItemForm(
                    item: _item,
                    onSave: _handleSave,
                    onCancel: _handleCancel,
                  ),
                ),
    );
  }
}
