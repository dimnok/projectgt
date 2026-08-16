import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:projectgt/core/di/providers.dart';
import 'package:projectgt/core/utils/supabase_error_message.dart';
import 'package:projectgt/core/widgets/app_snackbar.dart';
import 'package:projectgt/core/widgets/gt_buttons.dart';
import 'package:projectgt/core/widgets/gt_text_field.dart';
import 'package:projectgt/features/purchase_requests/domain/entities/purchase_request.dart';
import 'package:projectgt/features/purchase_requests/presentation/state/purchase_request_providers.dart';
import 'package:projectgt/features/purchase_requests/presentation/utils/purchase_request_ui_labels.dart';
import 'package:projectgt/features/purchase_requests/presentation/widgets/purchase_request_actions_bar.dart';
import 'package:projectgt/features/purchase_requests/presentation/widgets/purchase_request_details_summary.dart';
import 'package:projectgt/features/purchase_requests/presentation/widgets/purchase_request_details_tokens.dart';
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

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: ColoredBox(
        color: PurchaseRequestDetailsTokens.pageBackground(theme),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(context, theme, requestAsync),
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

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: ListView(
                          padding: const EdgeInsets.fromLTRB(
                            PurchaseRequestDetailsTokens.pagePadding,
                            16,
                            PurchaseRequestDetailsTokens.pagePadding,
                            16,
                          ),
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
                            const SizedBox(
                              height: PurchaseRequestDetailsTokens.sectionGap,
                            ),
                            _DetailSection(
                              title: 'Позиции',
                              trailing: actions.canEditItems
                                  ? GTTextButton(
                                      text: 'Добавить',
                                      icon: Icons.add_rounded,
                                      dense: true,
                                      onPressed: () => _addItem(context, ref),
                                    )
                                  : null,
                              child: itemsAsync.when(
                                loading: () => const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 32),
                                  child: Center(
                                    child: CupertinoActivityIndicator(),
                                  ),
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
                                              invalidatePurchaseRequestCaches(
                                                ref,
                                                requestId,
                                              );
                                            } catch (e) {
                                              if (!context.mounted) return;
                                              AppSnackBar.show(
                                                context: context,
                                                message:
                                                    formatSupabaseErrorMessage(
                                                  e,
                                                ),
                                                kind: AppSnackBarKind.error,
                                              );
                                            }
                                          }
                                        : null,
                                  );
                                },
                              ),
                            ),
                            const SizedBox(
                              height: PurchaseRequestDetailsTokens.sectionGap,
                            ),
                            _DetailSection(
                              title: 'История',
                              child: historyAsync.when(
                                loading: () => const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 32),
                                  child: Center(
                                    child: CupertinoActivityIndicator(),
                                  ),
                                ),
                                error: (e, _) => _SectionMessage(text: '$e'),
                                data: (entries) =>
                                    PurchaseRequestHistoryTimeline(
                                  entries: entries,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      _ActionsFooter(
                        child: PurchaseRequestActionsBar(
                          requestId: requestId,
                          request: request,
                          actions: actions,
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
    );
  }

  Widget _buildHeader(
    BuildContext context,
    ThemeData theme,
    AsyncValue<PurchaseRequest?> requestAsync,
  ) {
    final hasBack = showCloseButton && onClose != null;

    return DecoratedBox(
      decoration: PurchaseRequestDetailsTokens.headerDecoration(theme),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          hasBack ? 4 : PurchaseRequestDetailsTokens.pagePadding,
          10,
          PurchaseRequestDetailsTokens.pagePadding,
          14,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (hasBack)
              IconButton(
                tooltip: 'К списку',
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: onClose,
              ),
            Expanded(
              child: requestAsync.when(
                loading: () => _HeaderContent(
                  number: 'Заявка',
                  theme: theme,
                ),
                error: (_, __) => _HeaderContent(
                  number: 'Заявка',
                  theme: theme,
                ),
                data: (request) {
                  if (request == null) {
                    return _HeaderContent(
                      number: 'Заявка',
                      theme: theme,
                    );
                  }

                  return _HeaderContent(
                    number: request.number,
                    objectName: request.objectName,
                    initiator: request.initiatorLabel,
                    theme: theme,
                  );
                },
              ),
            ),
          ],
        ),
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
      invalidatePurchaseRequestCaches(ref, requestId);
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

class _HeaderContent extends StatelessWidget {
  const _HeaderContent({
    required this.number,
    required this.theme,
    this.objectName,
    this.initiator,
  });

  final String number;
  final ThemeData theme;
  final String? objectName;
  final String? initiator;

  @override
  Widget build(BuildContext context) {
    final muted = PurchaseRequestDetailsTokens.mutedText(theme);
    final meta = <String>[
      if ((objectName ?? '').trim().isNotEmpty) objectName!.trim(),
      if ((initiator ?? '').trim().isNotEmpty) initiator!.trim(),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          number,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
            height: 1.1,
          ),
        ),
        if (meta.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(
            meta.join(' · '),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              color: muted,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
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
    final theme = Theme.of(context);
    final muted = PurchaseRequestDetailsTokens.mutedText(theme);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text(
              title.toUpperCase(),
              style: theme.textTheme.labelMedium?.copyWith(
                color: muted,
                fontWeight: FontWeight.w700,
                letterSpacing: 1,
              ),
            ),
            const Spacer(),
            if (trailing != null) trailing!,
          ],
        ),
        const SizedBox(height: PurchaseRequestDetailsTokens.sectionTitleGap),
        child,
      ],
    );
  }
}

class _ActionsFooter extends StatelessWidget {
  const _ActionsFooter({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DecoratedBox(
      decoration: PurchaseRequestDetailsTokens.footerDecoration(theme),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            PurchaseRequestDetailsTokens.pagePadding,
            12,
            PurchaseRequestDetailsTokens.pagePadding,
            12,
          ),
          child: child,
        ),
      ),
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
    final muted = PurchaseRequestDetailsTokens.mutedText(theme);

    return DecoratedBox(
      decoration: PurchaseRequestDetailsTokens.cardDecoration(theme),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
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
      ),
    );
  }
}
