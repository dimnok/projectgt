import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:projectgt/core/utils/formatters.dart';
import 'package:projectgt/core/widgets/app_snackbar.dart';
import 'package:projectgt/core/widgets/gt_buttons.dart';
import 'package:projectgt/features/company/data/invitation_error_messages.dart';
import 'package:projectgt/features/company/domain/entities/company_invitation.dart';
import 'package:projectgt/features/company/presentation/providers/company_providers.dart';
import 'package:projectgt/features/company/presentation/widgets/company_info_widgets.dart';
import 'package:projectgt/presentation/state/auth_state.dart';

/// Блок выдачи одноразовых кодов приглашения (владелец / админ).
class CompanyInvitationsCard extends ConsumerStatefulWidget {
  /// Создаёт карточку приглашений.
  const CompanyInvitationsCard({super.key});

  @override
  ConsumerState<CompanyInvitationsCard> createState() =>
      _CompanyInvitationsCardState();
}

class _CompanyInvitationsCardState extends ConsumerState<CompanyInvitationsCard> {
  bool _isCreating = false;

  Future<void> _createCode() async {
    final companyId = ref.read(activeCompanyIdProvider);
    if (companyId == null) return;

    setState(() => _isCreating = true);
    try {
      final invitation = await ref
          .read(companyRepositoryProvider)
          .createInvitation(companyId: companyId);
      await Clipboard.setData(ClipboardData(text: invitation.code));
      ref.invalidate(companyInvitationsProvider);
      if (!mounted) return;
      AppSnackBar.show(
        context: context,
        message: 'Код ${invitation.code} скопирован. Действует до '
            '${formatRuDate(invitation.expiresAt)}',
        kind: AppSnackBarKind.success,
      );
    } catch (e) {
      if (!mounted) return;
      AppSnackBar.show(
        context: context,
        message: _errorText(e),
        kind: AppSnackBarKind.error,
      );
    } finally {
      if (mounted) setState(() => _isCreating = false);
    }
  }

  Future<void> _revoke(CompanyInvitation invitation) async {
    try {
      await ref
          .read(companyRepositoryProvider)
          .revokeInvitation(invitation.id);
      ref.invalidate(companyInvitationsProvider);
      if (!mounted) return;
      AppSnackBar.show(
        context: context,
        message: 'Код отменён',
        kind: AppSnackBarKind.success,
      );
    } catch (e) {
      if (!mounted) return;
      AppSnackBar.show(
        context: context,
        message: _errorText(e),
        kind: AppSnackBarKind.error,
      );
    }
  }

  String _errorText(Object e) {
    final raw = e.toString();
    if (raw.startsWith('Exception: ')) {
      return raw.substring(11);
    }
    return invitationErrorMessage(e);
  }

  String _statusLabel(CompanyInvitation inv) {
    if (inv.usedAt != null) return 'Использован';
    if (inv.revokedAt != null) return 'Отменён';
    if (!inv.expiresAt.isAfter(DateTime.now())) return 'Истёк';
    return 'Активен';
  }

  @override
  Widget build(BuildContext context) {
    final systemRole = ref.watch(authProvider).user?.systemRole;
    if (!canManageCompanyInvitations(systemRole)) {
      return const SizedBox.shrink();
    }

    final invitationsAsync = ref.watch(companyInvitationsProvider);
    final theme = Theme.of(context);

    return CompanyInfoCard(
      title: 'Приглашения сотрудников',
      icon: CupertinoIcons.ticket,
      action: GTTextButton(
        text: 'Создать код',
        onPressed: _isCreating ? null : _createCode,
      ),
      children: [
        Text(
          'Одноразовый код на 7 дней. Передайте его новому сотруднику — '
          'после входа он вводит код на экране «Вступить в компанию».',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
        const SizedBox(height: 12),
        invitationsAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Center(child: CupertinoActivityIndicator()),
          ),
          error: (_, __) => const Text('Не удалось загрузить список кодов'),
          data: (list) {
            if (list.isEmpty) {
              return Text(
                'Активных кодов нет. Нажмите «Создать код».',
                style: theme.textTheme.bodyMedium,
              );
            }
            return Column(
              children: [
                for (var i = 0; i < list.length; i++)
                  _InvitationRow(
                    invitation: list[i],
                    status: _statusLabel(list[i]),
                    isLast: i == list.length - 1,
                    onCopy: list[i].isActive
                        ? () => Clipboard.setData(
                              ClipboardData(text: list[i].code),
                            )
                        : null,
                    onRevoke: list[i].isActive
                        ? () => _revoke(list[i])
                        : null,
                  ),
              ],
            );
          },
        ),
        if (_isCreating)
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: LinearProgressIndicator(minHeight: 2),
          ),
      ],
    );
  }
}

class _InvitationRow extends StatelessWidget {
  const _InvitationRow({
    required this.invitation,
    required this.status,
    required this.isLast,
    this.onCopy,
    this.onRevoke,
  });

  final CompanyInvitation invitation;
  final String status;
  final bool isLast;
  final VoidCallback? onCopy;
  final VoidCallback? onRevoke;

  @override
  Widget build(BuildContext context) {
    final subtitle = 'до ${formatRuDate(invitation.expiresAt)} · $status';

    return CompanyInfoRow(
      label: subtitle,
      value: invitation.code,
      canCopy: onCopy != null,
      onDelete: onRevoke,
      isLast: isLast,
    );
  }
}
