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

/// Ширина окна настроек маршрута на desktop.
///
/// Material 3 [Dialog] по умолчанию ограничивает ширину 560 px — поэтому
/// ограничение задаётся явно, иначе окно выглядит как узкая мобильная карточка.
const _kDesktopDialogWidth = 880.0;

/// Ширина выпадающих списков на desktop — короче правой колонки, без растягивания.
const _kDesktopFieldWidth = 340.0;

/// Заголовок окна настроек согласующих.
const _kTitle = 'Настройка согласующих';

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
          insetPadding: EdgeInsets.symmetric(horizontal: 40, vertical: 28),
          constraints: BoxConstraints(maxWidth: _kDesktopDialogWidth),
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

  String _userDisplayName(String id) {
    for (final user in _users) {
      if (user.id == id) return user.displayName;
    }
    return id;
  }

  String _namesFor(List<String> ids) {
    if (ids.isEmpty) return '';
    return ids.map(_userDisplayName).join(', ');
  }

  void _setReceiverMode(PurchaseRequestReceiverMode? mode) {
    if (mode == null) return;
    setState(() {
      _receiverMode = mode;
      if (mode == PurchaseRequestReceiverMode.initiator) {
        _fixedReceiverIds = [];
      }
    });
  }

  Widget _usersDropdown({
    required String label,
    required List<String> selectedIds,
    required ValueChanged<List<String>> onChanged,
  }) {
    return GTDropdown<String>(
      labelText: label,
      hintText: 'Выберите пользователей',
      items: _users.map((u) => u.id).toList(),
      allowMultipleSelection: true,
      selectedItems: selectedIds,
      itemDisplayBuilder: _userDisplayName,
      onMultiSelectionChanged: onChanged,
    );
  }

  Widget _receiverModeDropdown({required String label, required String hint}) {
    return GTDropdown<PurchaseRequestReceiverMode>(
      labelText: label,
      hintText: hint,
      items: const [
        PurchaseRequestReceiverMode.initiator,
        PurchaseRequestReceiverMode.fixedUser,
      ],
      selectedItem: _receiverMode,
      itemDisplayBuilder: (mode) => switch (mode) {
        PurchaseRequestReceiverMode.initiator => 'Инициатор заявки',
        PurchaseRequestReceiverMode.fixedUser => 'Указанный сотрудник',
      },
      onSelectionChanged: _setReceiverMode,
    );
  }

  bool get _receiverComplete =>
      _receiverMode == PurchaseRequestReceiverMode.initiator ||
      _fixedReceiverIds.isNotEmpty;

  Widget _hint() {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Порядок этапов заявки. На каждом этапе достаточно действия '
          'любого из выбранных.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            height: 1.35,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'В списке только пользователи приложения, не карточки из «Сотрудники».',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
          ),
        ),
      ],
    );
  }

  Widget _emptyUsersWarning() {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        'Нет пользователей с доступом в приложение. '
        'Добавьте их в раздел «Пользователи» и пригласите в компанию.',
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.error,
        ),
      ),
    );
  }

  Widget _saveButton() {
    return GTPrimaryButton(
      text: 'Сохранить',
      isLoading: _saving,
      onPressed: _saving || _users.isEmpty ? null : _save,
    );
  }

  Widget _desktopFooter() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        GTSecondaryButton(
          text: 'Отмена',
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
        ),
        const SizedBox(width: 12),
        _saveButton(),
      ],
    );
  }

  Widget _desktopRoute() {
    return Column(
      children: [
        _DesktopRouteStep(
          number: 1,
          title: 'Первый согласующий',
          hint: 'Проверяет и согласует заявку',
          isComplete: _firstApproverIds.isNotEmpty,
          selectedNames: _namesFor(_firstApproverIds),
          field: _usersDropdown(
            label: '',
            selectedIds: _firstApproverIds,
            onChanged: (v) => setState(() => _firstApproverIds = v),
          ),
        ),
        _DesktopRouteStep(
          number: 2,
          title: 'Подготовка счетов',
          hint: 'Загружает счета по заявке',
          isComplete: _invoicePreparerIds.isNotEmpty,
          selectedNames: _namesFor(_invoicePreparerIds),
          field: _usersDropdown(
            label: '',
            selectedIds: _invoicePreparerIds,
            onChanged: (v) => setState(() => _invoicePreparerIds = v),
          ),
        ),
        _DesktopRouteStep(
          number: 3,
          title: 'Согласование счетов',
          hint: 'Проверяет счета перед оплатой',
          isComplete: _invoiceApproverIds.isNotEmpty,
          selectedNames: _namesFor(_invoiceApproverIds),
          field: _usersDropdown(
            label: '',
            selectedIds: _invoiceApproverIds,
            onChanged: (v) => setState(() => _invoiceApproverIds = v),
          ),
        ),
        _DesktopRouteStep(
          number: 4,
          title: 'Бухгалтер',
          hint: 'Проводит оплату',
          isComplete: _accountantIds.isNotEmpty,
          selectedNames: _namesFor(_accountantIds),
          field: _usersDropdown(
            label: '',
            selectedIds: _accountantIds,
            onChanged: (v) => setState(() => _accountantIds = v),
          ),
        ),
        _DesktopRouteStep(
          number: 5,
          title: 'Получение материала',
          hint: 'Подтверждает, что материал получен',
          isComplete: _receiverComplete,
          isLast: true,
          selectedNames: _receiverMode == PurchaseRequestReceiverMode.fixedUser
              ? _namesFor(_fixedReceiverIds)
              : '',
          field: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _receiverModeDropdown(label: '', hint: 'Кто получает'),
              if (_receiverMode == PurchaseRequestReceiverMode.fixedUser) ...[
                const SizedBox(height: 10),
                _usersDropdown(
                  label: '',
                  selectedIds: _fixedReceiverIds,
                  onChanged: (v) => setState(() => _fixedReceiverIds = v),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _mobileForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _hint(),
        const SizedBox(height: 16),
        if (_users.isEmpty) _emptyUsersWarning(),
        _usersDropdown(
          label: 'Первый согласующий',
          selectedIds: _firstApproverIds,
          onChanged: (v) => setState(() => _firstApproverIds = v),
        ),
        const SizedBox(height: 12),
        _usersDropdown(
          label: 'Подготовка счетов',
          selectedIds: _invoicePreparerIds,
          onChanged: (v) => setState(() => _invoicePreparerIds = v),
        ),
        const SizedBox(height: 12),
        _usersDropdown(
          label: 'Согласование счетов',
          selectedIds: _invoiceApproverIds,
          onChanged: (v) => setState(() => _invoiceApproverIds = v),
        ),
        const SizedBox(height: 12),
        _usersDropdown(
          label: 'Бухгалтер (оплата)',
          selectedIds: _accountantIds,
          onChanged: (v) => setState(() => _accountantIds = v),
        ),
        const SizedBox(height: 12),
        _receiverModeDropdown(
          label: 'Получение материала',
          hint: 'Выберите режим',
        ),
        if (_receiverMode == PurchaseRequestReceiverMode.fixedUser) ...[
          const SizedBox(height: 12),
          _usersDropdown(
            label: 'Ответственный за получение',
            selectedIds: _fixedReceiverIds,
            onChanged: (v) => setState(() => _fixedReceiverIds = v),
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveUtils.isDesktop(context);

    if (_loading) {
      const loader = Center(
        child: Padding(
          padding: EdgeInsets.all(48),
          child: CupertinoActivityIndicator(),
        ),
      );
      if (isDesktop) {
        return const DesktopDialogContent(
          title: _kTitle,
          width: _kDesktopDialogWidth,
          child: loader,
        );
      }
      return const MobileBottomSheetContent(title: _kTitle, child: loader);
    }

    if (isDesktop) {
      return DesktopDialogContent(
        title: _kTitle,
        width: _kDesktopDialogWidth,
        footer: _desktopFooter(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _hint(),
            const SizedBox(height: 20),
            if (_users.isEmpty) _emptyUsersWarning(),
            _desktopRoute(),
          ],
        ),
      );
    }

    return MobileBottomSheetContent(
      title: _kTitle,
      footer: _saveButton(),
      child: _mobileForm(),
    );
  }
}

/// Один этап маршрута в десктопной вёрстке: номер, смысл этапа и выбор людей.
class _DesktopRouteStep extends StatelessWidget {
  const _DesktopRouteStep({
    required this.number,
    required this.title,
    required this.hint,
    required this.isComplete,
    required this.field,
    this.selectedNames = '',
    this.isLast = false,
  });

  final int number;
  final String title;
  final String hint;
  final bool isComplete;
  final Widget field;
  final String selectedNames;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurface.withValues(alpha: 0.5);
    final line = theme.colorScheme.outline.withValues(alpha: 0.18);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 28,
            child: Column(
              children: [
                _StepIndex(number: number, isComplete: isComplete),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 1,
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      color: line,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 20),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            hint,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: muted,
                              height: 1.3,
                            ),
                          ),
                          if (selectedNames.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(
                              selectedNames,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurface.withValues(
                                  alpha: 0.8,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  SizedBox(width: _kDesktopFieldWidth, child: field),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Номер этапа маршрута.
class _StepIndex extends StatelessWidget {
  const _StepIndex({required this.number, required this.isComplete});

  final int number;
  final bool isComplete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bg = isComplete ? theme.colorScheme.primary : Colors.transparent;
    final fg = isComplete
        ? theme.colorScheme.onPrimary
        : theme.colorScheme.onSurface.withValues(alpha: 0.55);

    return Semantics(
      label: 'Этап $number',
      child: Container(
        width: 28,
        height: 28,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: bg,
          shape: BoxShape.circle,
          border: isComplete
              ? null
              : Border.all(
                  color: theme.colorScheme.outline.withValues(alpha: 0.4),
                ),
        ),
        child: Text(
          '$number',
          style: theme.textTheme.labelMedium?.copyWith(
            color: fg,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
