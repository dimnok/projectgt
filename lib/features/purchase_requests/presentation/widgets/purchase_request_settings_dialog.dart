import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:projectgt/core/utils/responsive_utils.dart';
import 'package:projectgt/core/utils/supabase_error_message.dart';
import 'package:projectgt/core/widgets/app_snackbar.dart';
import 'package:projectgt/core/widgets/desktop_dialog_content.dart';
import 'package:projectgt/core/widgets/gt_buttons.dart';
import 'package:projectgt/core/widgets/gt_dropdown.dart';
import 'package:projectgt/core/widgets/mobile_bottom_sheet_content.dart';
import 'package:projectgt/features/company/presentation/providers/company_providers.dart';
import 'package:projectgt/features/purchase_requests/domain/entities/purchase_request_company_user.dart';
import 'package:projectgt/features/purchase_requests/domain/entities/purchase_request_settings.dart';
import 'package:projectgt/features/purchase_requests/presentation/state/purchase_request_providers.dart';

/// Диалог настройки маршрута заявок (согласующие на компанию).
class PurchaseRequestSettingsDialog extends ConsumerStatefulWidget {
  /// Создаёт диалог.
  const PurchaseRequestSettingsDialog({super.key});

  /// Показать диалог настроек.
  static Future<void> show(BuildContext context) {
    final isDesktop = ResponsiveUtils.isDesktop(context);
    if (isDesktop) {
      return showDialog<void>(
        context: context,
        builder: (_) => const Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.all(24),
          child: PurchaseRequestSettingsDialog(),
        ),
      );
    }
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const PurchaseRequestSettingsDialog(),
    );
  }

  @override
  ConsumerState<PurchaseRequestSettingsDialog> createState() =>
      _PurchaseRequestSettingsDialogState();
}

class _PurchaseRequestSettingsDialogState
    extends ConsumerState<PurchaseRequestSettingsDialog> {
  List<String> _firstApproverIds = [];
  List<String> _invoicePreparerIds = [];
  List<String> _invoiceApproverIds = [];
  List<String> _accountantIds = [];
  PurchaseRequestReceiverMode _receiverMode =
      PurchaseRequestReceiverMode.initiator;
  List<String> _fixedReceiverIds = [];
  bool _loading = true;
  bool _saving = false;
  List<PurchaseRequestCompanyUser> _users = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final users = await ref.read(purchaseRequestCompanyUsersProvider.future);
      final settings = await ref.read(purchaseRequestSettingsProvider.future);
      if (!mounted) return;
      _users = users;
      if (settings != null) {
        _firstApproverIds = List<String>.from(settings.firstApproverIds);
        _invoicePreparerIds = List<String>.from(settings.invoicePreparerIds);
        _invoiceApproverIds = List<String>.from(settings.invoiceApproverIds);
        _accountantIds = List<String>.from(settings.accountantIds);
        _receiverMode = settings.receiverMode;
        _fixedReceiverIds = List<String>.from(settings.fixedReceiverIds);
      }
    } catch (e) {
      if (!mounted) return;
      AppSnackBar.show(
        context: context,
        message: formatSupabaseErrorMessage(e),
        kind: AppSnackBarKind.error,
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    final companyId = ref.read(activeCompanyIdProvider);
    if (companyId == null) return;

    if (_firstApproverIds.isEmpty ||
        _invoicePreparerIds.isEmpty ||
        _invoiceApproverIds.isEmpty ||
        _accountantIds.isEmpty) {
      AppSnackBar.show(
        context: context,
        message: 'Укажите всех участников маршрута',
        kind: AppSnackBarKind.error,
      );
      return;
    }
    if (_receiverMode == PurchaseRequestReceiverMode.fixedUser &&
        _fixedReceiverIds.isEmpty) {
      AppSnackBar.show(
        context: context,
        message: 'Укажите ответственного за получение',
        kind: AppSnackBarKind.error,
      );
      return;
    }

    setState(() => _saving = true);
    try {
      await ref
          .read(purchaseRequestRepositoryProvider)
          .upsertSettings(
            PurchaseRequestSettings(
              companyId: companyId,
              firstApproverIds: _firstApproverIds,
              invoicePreparerIds: _invoicePreparerIds,
              invoiceApproverIds: _invoiceApproverIds,
              accountantIds: _accountantIds,
              receiverMode: _receiverMode,
              fixedReceiverIds:
                  _receiverMode == PurchaseRequestReceiverMode.fixedUser
                  ? _fixedReceiverIds
                  : const [],
            ),
          );
      ref.invalidate(purchaseRequestSettingsProvider);
      ref.invalidate(purchaseRequestCompanyUsersProvider);
      if (!mounted) return;
      AppSnackBar.show(
        context: context,
        message: 'Настройки сохранены',
        kind: AppSnackBarKind.success,
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      AppSnackBar.show(
        context: context,
        message: formatSupabaseErrorMessage(e),
        kind: AppSnackBarKind.error,
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _usersDropdown({
    required String label,
    required List<String> selectedIds,
    required List<PurchaseRequestCompanyUser> users,
    required ValueChanged<List<String>> onChanged,
  }) {
    return GTDropdown<String>(
      labelText: label,
      hintText: 'Выберите пользователей',
      items: users.map((u) => u.id).toList(),
      allowMultipleSelection: true,
      selectedItems: selectedIds,
      itemDisplayBuilder: (id) {
        for (final user in users) {
          if (user.id == id) return user.displayName;
        }
        return id;
      },
      onMultiSelectionChanged: onChanged,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveUtils.isDesktop(context);
    final theme = Theme.of(context);
    final users = _users;

    final content = _loading
        ? const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: CupertinoActivityIndicator(),
            ),
          )
        : SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'На каждом этапе можно выбрать несколько человек. '
                  'Действует любой из списка. '
                  'Выберите пользователей приложения (раздел «Пользователи»). '
                  'Карточки из «Сотрудники» без входа в систему здесь не отображаются.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 16),
                if (users.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      'Нет пользователей с доступом в приложение. '
                      'Добавьте их в раздел «Пользователи» и пригласите в компанию.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.error,
                      ),
                    ),
                  ),
                _usersDropdown(
                  label: 'Первый согласующий',
                  selectedIds: _firstApproverIds,
                  users: users,
                  onChanged: (v) => setState(() => _firstApproverIds = v),
                ),
                const SizedBox(height: 12),
                _usersDropdown(
                  label: 'Подготовка счетов',
                  selectedIds: _invoicePreparerIds,
                  users: users,
                  onChanged: (v) => setState(() => _invoicePreparerIds = v),
                ),
                const SizedBox(height: 12),
                _usersDropdown(
                  label: 'Согласование счетов',
                  selectedIds: _invoiceApproverIds,
                  users: users,
                  onChanged: (v) => setState(() => _invoiceApproverIds = v),
                ),
                const SizedBox(height: 12),
                _usersDropdown(
                  label: 'Бухгалтер (оплата)',
                  selectedIds: _accountantIds,
                  users: users,
                  onChanged: (v) => setState(() => _accountantIds = v),
                ),
                const SizedBox(height: 12),
                GTDropdown<PurchaseRequestReceiverMode>(
                  labelText: 'Получение материала',
                  hintText: 'Выберите режим',
                  items: const [
                    PurchaseRequestReceiverMode.initiator,
                    PurchaseRequestReceiverMode.fixedUser,
                  ],
                  selectedItem: _receiverMode,
                  itemDisplayBuilder: (mode) => switch (mode) {
                    PurchaseRequestReceiverMode.initiator => 'Инициатор заявки',
                    PurchaseRequestReceiverMode.fixedUser =>
                      'Указанный сотрудник',
                  },
                  onSelectionChanged: (v) {
                    if (v == null) return;
                    setState(() {
                      _receiverMode = v;
                      if (v == PurchaseRequestReceiverMode.initiator) {
                        _fixedReceiverIds = [];
                      }
                    });
                  },
                ),
                if (_receiverMode == PurchaseRequestReceiverMode.fixedUser) ...[
                  const SizedBox(height: 12),
                  _usersDropdown(
                    label: 'Ответственный за получение',
                    selectedIds: _fixedReceiverIds,
                    users: users,
                    onChanged: (v) => setState(() => _fixedReceiverIds = v),
                  ),
                ],
                const SizedBox(height: 20),
                GTPrimaryButton(
                  text: 'Сохранить',
                  isLoading: _saving,
                  onPressed: _saving || users.isEmpty ? null : _save,
                ),
              ],
            ),
          );

    if (isDesktop) {
      return DesktopDialogContent(
        title: 'Настройка согласующих',
        child: content,
      );
    }
    return MobileBottomSheetContent(
      title: 'Настройка согласующих',
      child: content,
    );
  }
}
