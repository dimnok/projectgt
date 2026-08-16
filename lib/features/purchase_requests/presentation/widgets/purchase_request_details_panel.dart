import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:projectgt/core/di/providers.dart';
import 'package:projectgt/core/utils/supabase_error_message.dart';
import 'package:projectgt/core/widgets/app_snackbar.dart';
import 'package:projectgt/core/widgets/gt_buttons.dart';
import 'package:projectgt/core/widgets/gt_section_title.dart';
import 'package:projectgt/core/widgets/gt_text_field.dart';
import 'package:projectgt/features/purchase_requests/domain/entities/purchase_request.dart';
import 'package:projectgt/features/purchase_requests/presentation/state/purchase_request_providers.dart';
import 'package:projectgt/features/purchase_requests/presentation/utils/purchase_request_ui_labels.dart';
import 'package:projectgt/features/purchase_requests/presentation/widgets/purchase_request_actions_bar.dart';
import 'package:projectgt/features/purchase_requests/presentation/widgets/purchase_request_details_summary.dart';
import 'package:projectgt/features/purchase_requests/presentation/widgets/purchase_request_history_timeline.dart';
import 'package:projectgt/features/purchase_requests/presentation/widgets/purchase_request_items_table.dart';
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
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                children: [
                  itemsAsync.maybeWhen(
                    data: (items) => PurchaseRequestDetailsSummary(
                      request: request,
                      statusColor: statusColor,
                      itemsCount: items.length,
                    ),
                    orElse: () => PurchaseRequestDetailsSummary(
                      request: request,
                      statusColor: statusColor,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _DetailSection(
                    title: itemsAsync.maybeWhen(
                      data: (items) => 'Позиции (${items.length})',
                      orElse: () => 'Позиции',
                    ),
                    trailing: actions.canEditItems
                        ? GTTextButton(
                            text: '+ Добавить',
                            onPressed: () => _addItem(context, ref),
                          )
                        : null,
                    child: itemsAsync.when(
                      loading: () => const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Center(child: CupertinoActivityIndicator()),
                      ),
                      error: (e, _) => _SectionMessage(text: '$e'),
                      data: (items) {
                        if (items.isEmpty) {
                          return _SectionMessage(
                            icon: Icons.inventory_2_outlined,
                            text: actions.canEditItems
                                ? 'Добавьте позиции — что нужно закупить'
                                : 'Нет позиций',
                          );
                        }

                        return PurchaseRequestItemsTable(
                          items: items,
                          canEdit: actions.canEditItems,
                          onDelete: actions.canEditItems
                              ? (itemId) async {
                                  try {
                                    await ref
                                        .read(
                                          purchaseRequestRepositoryProvider,
                                        )
                                        .deleteItem(itemId);
                                    ref.invalidate(
                                      purchaseRequestItemsProvider(requestId),
                                    );
                                    ref.invalidate(purchaseRequestListProvider);
                                  } catch (e) {
                                    if (!context.mounted) return;
                                    AppSnackBar.show(
                                      context: context,
                                      message: formatSupabaseErrorMessage(e),
                                      kind: AppSnackBarKind.error,
                                    );
                                  }
                                }
                              : null,
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                  _DetailSection(
                    title: 'История',
                    child: historyAsync.when(
                      loading: () => const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Center(child: CupertinoActivityIndicator()),
                      ),
                      error: (e, _) => _SectionMessage(text: '$e'),
                      data: (entries) =>
                          PurchaseRequestHistoryTimeline(entries: entries),
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (showCloseButton && onClose != null)
            IconButton(
              tooltip: 'К списку',
              icon: const Icon(Icons.arrow_back),
              onPressed: onClose,
            ),
          Expanded(
            child: requestAsync.when(
              loading: () => Text(
                'Заявка',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              error: (_, __) => Text(
                'Заявка',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              data: (request) {
                if (request == null) {
                  return Text(
                    'Заявка',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  );
                }

                final parts = <String>[
                  'Заявка ${request.number}',
                  if ((request.objectName ?? '').trim().isNotEmpty)
                    request.objectName!.trim(),
                  request.initiatorLabel,
                ];

                return Text(
                  parts.join(' · '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                );
              },
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

class _DetailSection extends StatelessWidget {
  const _DetailSection({
    required this.title,
    required this.child,
    this.trailing,
  });

  final String title;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(child: GTSectionTitle(title: title)),
            if (trailing != null) trailing!,
          ],
        ),
        const SizedBox(height: 12),
        child,
      ],
    );
  }
}

class _SectionMessage extends StatelessWidget {
  const _SectionMessage({required this.text, this.icon});

  final String text;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurface.withValues(alpha: 0.55);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.12),
        ),
      ),
      child: Column(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 28, color: muted),
            const SizedBox(height: 10),
          ],
          Text(
            text,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(color: muted),
          ),
        ],
      ),
    );
  }
}
