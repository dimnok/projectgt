import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:projectgt/core/di/providers.dart';
import 'package:projectgt/core/utils/formatters.dart';
import 'package:projectgt/core/utils/supabase_error_message.dart';
import 'package:projectgt/core/widgets/app_snackbar.dart';
import 'package:projectgt/core/widgets/gt_buttons.dart';
import 'package:projectgt/core/widgets/gt_text_field.dart';
import 'package:projectgt/features/purchase_requests/domain/entities/purchase_request.dart';
import 'package:projectgt/features/purchase_requests/domain/entities/purchase_request_status.dart';
import 'package:projectgt/features/purchase_requests/presentation/state/purchase_request_providers.dart';
import 'package:projectgt/features/purchase_requests/presentation/utils/purchase_request_ui_labels.dart';
import 'package:projectgt/features/purchase_requests/presentation/widgets/purchase_request_actions_bar.dart';
import 'package:projectgt/features/roles/application/permission_service.dart';

/// Панель деталей заявки на закупку (встраивается в текущий экран).
class PurchaseRequestDetailsPanel extends ConsumerWidget {
  /// Создаёт панель.
  const PurchaseRequestDetailsPanel({
    super.key,
    required this.requestId,
    this.onClose,
    this.showCloseButton = false,
  });

  /// Идентификатор заявки.
  final String requestId;

  /// Закрыть панель и вернуться к списку.
  final VoidCallback? onClose;

  /// Показать кнопку «назад» в шапке панели.
  final bool showCloseButton;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requestAsync = ref.watch(purchaseRequestDetailsProvider(requestId));
    final itemsAsync = ref.watch(purchaseRequestItemsProvider(requestId));
    final historyAsync = ref.watch(purchaseRequestHistoryProvider(requestId));
    final permissions = ref.watch(permissionServiceProvider);
    final uid = ref.watch(supabaseClientProvider).auth.currentUser?.id;
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildHeader(context, theme, requestAsync),
        const Divider(height: 1),
        Expanded(
          child: requestAsync.when(
            loading: () => const Center(child: CupertinoActivityIndicator()),
            error: (e, _) => Center(child: Text('$e')),
            data: (request) {
              if (request == null) {
                return const Center(child: Text('Заявка не найдена'));
              }

              final actions = resolvePurchaseRequestActions(
                request: request,
                currentUserId: uid,
                permissions: permissions,
              );
              final statusColor = PurchaseRequestUiLabels.statusColor(
                theme,
                request.status,
              );

              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (request.status == PurchaseRequestStatus.revision)
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.tertiary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text('Возвращено на доработку'),
                    ),
                  Text(
                    request.objectName ?? '',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '● ${request.status.displayName}',
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _MetaRow(
                    label: 'Создана',
                    value: request.createdAt != null
                        ? formatRuDateTime(request.createdAt!)
                        : '—',
                  ),
                  _MetaRow(
                    label: 'Сумма',
                    value: request.totalAmount > 0
                        ? formatCurrency(request.totalAmount)
                        : '—',
                  ),
                  if (request.comment != null && request.comment!.isNotEmpty)
                    _MetaRow(label: 'Комментарий', value: request.comment!),
                  const SizedBox(height: 16),
                  Text('Позиции', style: theme.textTheme.titleSmall),
                  const SizedBox(height: 8),
                  itemsAsync.when(
                    loading: () => const CupertinoActivityIndicator(),
                    error: (e, _) => Text('$e'),
                    data: (items) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (items.isEmpty)
                            Text(
                              actions.canEditItems
                                  ? 'Добавьте позиции — что нужно закупить'
                                  : 'Нет позиций',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurface
                                    .withValues(alpha: 0.7),
                              ),
                            ),
                          for (final item in items)
                            ListTile(
                              title: Text(item.name),
                              subtitle: Text(
                                [
                                  if (item.article != null &&
                                      item.article!.trim().isNotEmpty)
                                    'Арт. ${item.article!.trim()}',
                                  '${formatQuantity(item.quantity)} ${item.unit}',
                                ].join(' · '),
                              ),
                              trailing: actions.canEditItems
                                  ? IconButton(
                                      icon: const Icon(Icons.delete_outline),
                                      onPressed: () async {
                                        try {
                                          await ref
                                              .read(
                                                purchaseRequestRepositoryProvider,
                                              )
                                              .deleteItem(item.id);
                                          ref.invalidate(
                                            purchaseRequestItemsProvider(
                                              requestId,
                                            ),
                                          );
                                          ref.invalidate(
                                            purchaseRequestListProvider,
                                          );
                                        } catch (e) {
                                          if (!context.mounted) return;
                                          AppSnackBar.show(
                                            context: context,
                                            message:
                                                formatSupabaseErrorMessage(e),
                                            kind: AppSnackBarKind.error,
                                          );
                                        }
                                      },
                                    )
                                  : null,
                            ),
                          if (actions.canEditItems)
                            GTTextButton(
                              text: '+ Добавить позицию',
                              onPressed: () => _addItem(context, ref),
                            ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  Text('История', style: theme.textTheme.titleSmall),
                  const SizedBox(height: 8),
                  historyAsync.when(
                    loading: () => const CupertinoActivityIndicator(),
                    error: (e, _) => Text('$e'),
                    data: (entries) => Column(
                      children: entries.map((e) {
                        return ListTile(
                          dense: true,
                          title: Text(
                            PurchaseRequestUiLabels.historyActionLabel(
                              e.action,
                            ),
                          ),
                          subtitle: Text(
                            [
                              formatRuDateTime(e.createdAt),
                              if (e.comment != null && e.comment!.isNotEmpty)
                                e.comment!,
                            ].join('\n'),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 24),
                  PurchaseRequestActionsBar(
                    requestId: requestId,
                    request: request,
                    actions: actions,
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(
    BuildContext context,
    ThemeData theme,
    AsyncValue<PurchaseRequest?> requestAsync,
  ) {
    final title = requestAsync.when(
      data: (r) => r?.number ?? 'Заявка',
      loading: () => 'Заявка',
      error: (_, __) => 'Заявка',
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
      child: Row(
        children: [
          if (showCloseButton && onClose != null)
            IconButton(
              tooltip: 'К списку',
              icon: const Icon(Icons.arrow_back),
              onPressed: onClose,
            ),
          Expanded(
            child: Text(
              title,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _addItem(BuildContext context, WidgetRef ref) async {
    final nameController = TextEditingController();
    final qtyController = TextEditingController(text: '1');
    final unitController = TextEditingController(text: 'шт');

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Позиция'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            GTTextField(controller: nameController, labelText: 'Наименование'),
            GTTextField(controller: qtyController, labelText: 'Количество'),
            GTTextField(controller: unitController, labelText: 'Ед. изм.'),
          ],
        ),
        actions: [
          GTTextButton(
            text: 'Отмена',
            onPressed: () => Navigator.pop(ctx, false),
          ),
          GTPrimaryButton(
            text: 'Добавить',
            onPressed: () => Navigator.pop(ctx, true),
          ),
        ],
      ),
    );

    if (ok != true) return;
    final name = nameController.text.trim();
    final qty = double.tryParse(qtyController.text.replaceAll(',', '.')) ?? 0;
    if (name.isEmpty || qty <= 0) return;

    try {
      await ref.read(purchaseRequestRepositoryProvider).addItem(
            requestId: requestId,
            name: name,
            quantity: qty,
            unit: unitController.text.trim().isEmpty
                ? 'шт'
                : unitController.text.trim(),
          );
      ref.invalidate(purchaseRequestItemsProvider(requestId));
      ref.invalidate(purchaseRequestListProvider);
    } catch (e) {
      if (context.mounted) {
        AppSnackBar.show(
          context: context,
          message: formatSupabaseErrorMessage(e),
          kind: AppSnackBarKind.error,
        );
      }
    }
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.6),
                  ),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
