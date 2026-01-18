import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:projectgt/core/widgets/desktop_dialog_content.dart';
import 'package:projectgt/core/widgets/mobile_bottom_sheet_content.dart';
import 'package:projectgt/core/widgets/gt_buttons.dart';
import 'package:projectgt/core/widgets/gt_text_field.dart';
import 'package:projectgt/core/widgets/app_snackbar.dart';
import 'package:projectgt/features/company/presentation/providers/company_providers.dart';
import 'package:projectgt/presentation/state/profile_state.dart';
import 'package:projectgt/presentation/state/auth_state.dart';

/// Диалоговое окно для вступления в компанию по коду приглашения.
class CompanyJoinDialog extends ConsumerStatefulWidget {
  /// Callback, вызываемый после успешного вступления.
  final VoidCallback? onSuccess;

  /// Создаёт диалог вступления в компанию.
  const CompanyJoinDialog({super.key, this.onSuccess});

  /// Показывает окно вступления адаптивно.
  static void show(BuildContext context, {VoidCallback? onSuccess}) {
    final isDesktop = MediaQuery.of(context).size.width >= 800;

    if (isDesktop) {
      showDialog(
        context: context,
        builder: (context) => Dialog(
          backgroundColor: Colors.transparent,
          child: CompanyJoinDialog(onSuccess: onSuccess),
        ),
      );
    } else {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        backgroundColor: Colors.transparent,
        builder: (context) => CompanyJoinDialog(onSuccess: onSuccess),
      );
    }
  }

  @override
  ConsumerState<CompanyJoinDialog> createState() => _CompanyJoinDialogState();
}

class _CompanyJoinDialogState extends ConsumerState<CompanyJoinDialog> {
  final _codeController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) {
      AppSnackBar.show(
        context: context,
        message: 'Введите код приглашения',
        kind: AppSnackBarKind.error,
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await ref.read(joinCompanyUseCaseProvider).execute(invitationCode: code);

      // Обновляем данные
      ref.invalidate(userCompaniesProvider);
      final userId = ref.read(authProvider).user?.id;
      if (userId != null) {
        await ref
            .read(currentUserProfileProvider.notifier)
            .refreshCurrentUserProfile(userId);
      }

      if (mounted) {
        Navigator.of(context).pop();
        AppSnackBar.show(
          context: context,
          message: 'Вы успешно присоединились к компании',
          kind: AppSnackBarKind.success,
        );
        widget.onSuccess?.call();
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.show(
          context: context,
          message: 'Ошибка при вступлении: Код недействителен или уже использован',
          kind: AppSnackBarKind.error,
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 800;
    final theme = Theme.of(context);

    final content = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Введите уникальный код приглашения, полученный от администратора организации.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
        const SizedBox(height: 24),
        GTTextField(
          controller: _codeController,
          labelText: 'Код приглашения',
          hintText: 'GT-XXXXXX',
          prefixIcon: CupertinoIcons.ticket,
          onSubmitted: (_) => _submit(),
        ),
        const SizedBox(height: 8),
      ],
    );

    if (isDesktop) {
      return DesktopDialogContent(
        title: 'Вступить в компанию',
        onClose: _isLoading ? () {} : null,
        footer: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            GTSecondaryButton(
              text: 'Отмена',
              onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
            ),
            const SizedBox(width: 16),
            GTPrimaryButton(
              text: 'Присоединиться',
              isLoading: _isLoading,
              onPressed: _submit,
            ),
          ],
        ),
        child: content,
      );
    } else {
      return MobileBottomSheetContent(
        title: 'Вступить в компанию',
        footer: GTPrimaryButton(
          text: 'Присоединиться',
          isLoading: _isLoading,
          onPressed: _submit,
        ),
        child: content,
      );
    }
  }
}
