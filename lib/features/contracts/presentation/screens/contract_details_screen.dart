import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:projectgt/core/di/providers.dart';
import 'package:projectgt/domain/entities/contract.dart';
import 'package:collection/collection.dart';
import 'package:go_router/go_router.dart';
import 'package:projectgt/presentation/widgets/app_bar_widget.dart';
import 'package:projectgt/presentation/widgets/app_drawer.dart';
import 'package:projectgt/presentation/widgets/app_badge.dart';
import 'package:projectgt/core/utils/notifications_service.dart';

/// Экран подробной информации о договоре (контракте).
///
/// Позволяет просматривать, редактировать и удалять договор, отображает все ключевые поля и статусы.
/// Использует [contractProvider] для получения данных.
///
/// Пример использования:
/// ```dart
/// ContractDetailsScreen(contractId: 'contract-123');
/// ```
class ContractDetailsScreen extends ConsumerWidget {
  /// Идентификатор договора для отображения.
  final String contractId;
  /// Создаёт экран деталей для договора с [contractId].
  const ContractDetailsScreen({super.key, required this.contractId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contractState = ref.watch(contractProvider);
    final contract = contractState.contracts.firstWhereOrNull((c) => c.id == contractId);
    final theme = Theme.of(context);

    if (contract == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Договор')),
        body: const Center(child: Text('Договор не найден')),
      );
    }

    return Scaffold(
      appBar: AppBarWidget(
        title: 'Договор №${contract.number}',
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: 'Редактировать',
            onPressed: () {
              context.goNamed('contract_edit', pathParameters: {'contractId': contract.id});
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            tooltip: 'Удалить',
            onPressed: () async {
              final ctx = context;
              final confirmed = await showDialog<bool>(
                context: ctx,
                builder: (ctx2) => AlertDialog(
                  title: const Text('Удалить договор?'),
                  content: const Text('Вы уверены, что хотите удалить этот договор?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx2, false),
                      child: const Text('Отмена'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(ctx2, true),
                      child: const Text('Удалить', style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              );
              if (!ctx.mounted) return;
              if (confirmed == true) {
                try {
                  await ref.read(contractProvider.notifier).deleteContract(contract.id);
                  if (!ctx.mounted) return;
                  Navigator.of(ctx).pop();
                  NotificationsService.showErrorNotification(ctx, 'Договор удалён');
                } catch (e) {
                  if (!ctx.mounted) return;
                  NotificationsService.showErrorNotification(ctx, 'Ошибка удаления: ${e.toString()}');
                }
              }
            },
          ),
        ],
        showThemeSwitch: true,
      ),
      drawer: const AppDrawer(activeRoute: AppRoute.contracts),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          AppBadge(
                            text: _statusText(contract.status),
                            color: _getContractStatusInfo(contract.status).$2,
                          ),
                          const SizedBox(width: 16),
                          Text('№${contract.number}', style: theme.textTheme.titleLarge),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _infoRow('Дата договора:', _formatDate(contract.date)),
                      if (contract.endDate != null)
                        _infoRow('Дата окончания:', _formatDate(contract.endDate!)),
                      _infoRow('Контрагент:', contract.contractorName ?? contract.contractorId),
                      _infoRow('Объект:', contract.objectName ?? contract.objectId),
                      _infoRow('Сумма:', contract.amount.toStringAsFixed(2)),
                      _infoRow('Статус:', _statusText(contract.status)),
                      if (contract.createdAt != null)
                        _infoRow('Создан:', _formatDateTime(contract.createdAt!)),
                      if (contract.updatedAt != null)
                        _infoRow('Обновлен:', _formatDateTime(contract.updatedAt!)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          const SizedBox(width: 8),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }

  String _formatDateTime(DateTime date) {
    return '${_formatDate(date)} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

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
} 