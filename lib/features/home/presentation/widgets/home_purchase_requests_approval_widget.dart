import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:projectgt/core/widgets/gt_buttons.dart';
import 'package:projectgt/core/widgets/mobile_atmosphere_backdrop.dart';
import 'package:projectgt/core/widgets/mobile_atmosphere_card_style.dart';
import 'package:projectgt/features/home/presentation/widgets/home_dashboard_constants.dart';
import 'package:projectgt/features/purchase_requests/domain/entities/purchase_request_list_item.dart';
import 'package:projectgt/features/purchase_requests/presentation/state/purchase_request_providers.dart';
import 'package:projectgt/features/purchase_requests/presentation/utils/purchase_request_module_utils.dart';
import 'package:projectgt/features/purchase_requests/presentation/widgets/purchase_request_status_badge.dart';
import 'package:projectgt/features/roles/application/permission_service.dart';

/// Блок на главной: заявки, которые текущий пользователь должен согласовать.
///
/// Не показывается, если заявок нет, нет права на модуль или идёт загрузка.
class HomePurchaseRequestsApprovalWidget extends ConsumerWidget {
  /// Создаёт блок согласования заявок.
  const HomePurchaseRequestsApprovalWidget({super.key});

  static const int _visibleLimit = 5;

  /// Акцент «требует внимания»: в тёмной теме светлее, чтобы контур читался.
  static Color alertAccent(ThemeData theme) {
    return theme.brightness == Brightness.dark
        ? const Color(0xFFF87171)
        : const Color(0xFFDC2626);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final permissions = ref.watch(permissionServiceProvider);
    if (!permissions.can('purchase_requests', 'read')) {
      return const SizedBox.shrink();
    }

    final async = ref.watch(purchaseRequestsAwaitingMyApprovalProvider);

    return async.when(
      data: (items) {
        if (items.isEmpty) return const SizedBox.shrink();
        return _ApprovalCard(items: items);
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class _ApprovalCard extends StatelessWidget {
  const _ApprovalCard({required this.items});

  final List<PurchaseRequestListItem> items;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = HomePurchaseRequestsApprovalWidget.alertAccent(theme);
    final isDesktop =
        MediaQuery.sizeOf(context).width >= kHomeDesktopDashboardBreakpoint;
    final visible = items
        .take(HomePurchaseRequestsApprovalWidget._visibleLimit)
        .toList();
    final remaining = items.length - visible.length;
    final countLabel =
        '${items.length} ${_requestsWord(items.length)} ${_awaitVerb(items.length)} вас';

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: accent,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                CupertinoIcons.exclamationmark,
                size: 22,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Нужно согласовать',
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    countLabel,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              constraints: const BoxConstraints(minWidth: 28),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: accent,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '${items.length}',
                textAlign: TextAlign.center,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        for (var i = 0; i < visible.length; i++) ...[
          if (i > 0) const SizedBox(height: 4),
          _ApprovalRow(item: visible[i]),
        ],
        if (remaining > 0) ...[
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: GTTextButton(
              text: 'Ещё $remaining',
              onPressed: () => _openRequests(context),
            ),
          ),
        ],
      ],
    );

    return Semantics(
      liveRegion: true,
      label: 'Внимание. Нужно согласовать, $countLabel',
      child: Padding(
        padding: const EdgeInsets.only(bottom: 24),
        child: isDesktop
            ? _DesktopShell(accent: accent, child: content)
            : _MobileShell(accent: accent, child: content),
      ),
    );
  }
}

class _ApprovalRow extends StatelessWidget {
  const _ApprovalRow({required this.item});

  final PurchaseRequestListItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final objectName = item.objectName.trim();

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _openRequests(context, requestId: item.id),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.number,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (objectName.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        objectName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.55,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Flexible(child: PurchaseRequestStatusBadge(status: item.status)),
            ],
          ),
        ),
      ),
    );
  }
}

class _DesktopShell extends StatelessWidget {
  const _DesktopShell({required this.accent, required this.child});

  final Color accent;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return _AlertFrame(
      accent: accent,
      fill: [accent.withValues(alpha: 0.07), theme.colorScheme.surface],
      child: child,
    );
  }
}

class _MobileShell extends StatelessWidget {
  const _MobileShell({required this.accent, required this.child});

  final Color accent;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final appearance = MobileAtmosphereAppearance.of(context);
    final style = MobileAtmosphereCardStyle.fromAppearance(appearance);

    return _AlertFrame(
      accent: accent,
      fill: [
        Color.alphaBlend(accent.withValues(alpha: 0.10), style.cardTop),
        style.cardBottom,
      ],
      shadows: [
        BoxShadow(
          color: accent.withValues(alpha: 0.18),
          blurRadius: 18,
          offset: const Offset(0, 8),
        ),
        ...style.cardShadows,
      ],
      child: child,
    );
  }
}

/// Общая рамка блока: красный контур, полоса слева, лёгкая красная заливка.
class _AlertFrame extends StatelessWidget {
  const _AlertFrame({
    required this.accent,
    required this.fill,
    required this.child,
    this.shadows,
  });

  final Color accent;
  final List<Color> fill;
  final List<BoxShadow>? shadows;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: fill,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: accent, width: 2),
        boxShadow:
            shadows ??
            [
              BoxShadow(
                color: accent.withValues(alpha: 0.22),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            width: 5,
            child: ColoredBox(color: accent),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
            child: child,
          ),
        ],
      ),
    );
  }
}

void _openRequests(BuildContext context, {String? requestId}) {
  if (requestId == null || requestId.isEmpty) {
    context.pushNamed('purchase_requests');
    return;
  }
  context.pushNamed(
    'purchase_requests',
    queryParameters: {kPurchaseRequestIdQueryParam: requestId},
  );
}

String _requestsWord(int count) {
  final mod100 = count % 100;
  if (mod100 >= 11 && mod100 <= 14) return 'заявок';
  return switch (count % 10) {
    1 => 'заявка',
    2 || 3 || 4 => 'заявки',
    _ => 'заявок',
  };
}

String _awaitVerb(int count) {
  final mod100 = count % 100;
  if (mod100 >= 11 && mod100 <= 14) return 'ждут';
  return count % 10 == 1 ? 'ждёт' : 'ждут';
}
