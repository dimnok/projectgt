import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:projectgt/core/widgets/desktop_dialog_content.dart';
import 'package:projectgt/core/widgets/mobile_bottom_sheet_content.dart';
import 'package:projectgt/core/widgets/gt_buttons.dart';
import 'package:projectgt/core/widgets/app_snackbar.dart';
import 'package:projectgt/features/company/presentation/providers/company_providers.dart';
import 'package:projectgt/features/company/presentation/widgets/company_form_content.dart';
import 'package:projectgt/presentation/state/profile_state.dart';
import 'package:projectgt/presentation/state/auth_state.dart';

/// Диалоговое окно для создания новой компании.
///
/// Адаптивно отображается как Desktop Dialog или Mobile Bottom Sheet.
class CompanyCreateDialog extends ConsumerStatefulWidget {
  /// Callback, вызываемый после успешного создания компании.
  final VoidCallback? onSuccess;

  /// Создаёт диалог создания компании.
  const CompanyCreateDialog({super.key, this.onSuccess});

  /// Показывает окно создания компании адаптивно.
  static void show(BuildContext context, {VoidCallback? onSuccess}) {
    final isDesktop = MediaQuery.of(context).size.width >= 800;

    if (isDesktop) {
      showDialog(
        context: context,
        builder: (context) => Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(24),
          child: CompanyCreateDialog(onSuccess: onSuccess),
        ),
      );
    } else {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        backgroundColor: Colors.transparent,
        builder: (context) => CompanyCreateDialog(onSuccess: onSuccess),
      );
    }
  }

  @override
  ConsumerState<CompanyCreateDialog> createState() =>
      _CompanyCreateDialogState();
}

class _CompanyCreateDialogState extends ConsumerState<CompanyCreateDialog> {
  final _formKey = GlobalKey<FormState>();

  // Контроллеры для полей
  final _nameFullController = TextEditingController();
  final _nameShortController = TextEditingController();
  final _innController = TextEditingController();
  final _kppController = TextEditingController();
  final _ogrnController = TextEditingController();
  final _okpoController = TextEditingController();
  final _legalAddressController = TextEditingController();
  final _actualAddressController = TextEditingController();
  final _directorNameController = TextEditingController();
  final _directorPositionController = TextEditingController();
  final _directorBasisController = TextEditingController();
  final _directorPhoneController = TextEditingController();
  final _chiefAccountantNameController = TextEditingController();
  final _chiefAccountantPhoneController = TextEditingController();
  final _contactPersonController = TextEditingController();
  final _websiteController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _activityDescriptionController = TextEditingController();
  final _taxationSystemController = TextEditingController();
  final _vatRateController = TextEditingController(text: '0');

  bool _isVatPayer = false;
  bool _isLoading = false;
  bool _isSearching = false;

  @override
  void dispose() {
    _nameFullController.dispose();
    _nameShortController.dispose();
    _innController.dispose();
    _kppController.dispose();
    _ogrnController.dispose();
    _okpoController.dispose();
    _legalAddressController.dispose();
    _actualAddressController.dispose();
    _directorNameController.dispose();
    _directorPositionController.dispose();
    _directorBasisController.dispose();
    _directorPhoneController.dispose();
    _chiefAccountantNameController.dispose();
    _chiefAccountantPhoneController.dispose();
    _contactPersonController.dispose();
    _websiteController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _activityDescriptionController.dispose();
    _taxationSystemController.dispose();
    _vatRateController.dispose();
    super.dispose();
  }

  Future<void> _searchByInn() async {
    final inn = _innController.text.trim();
    if (inn.length < 10) {
      AppSnackBar.show(
        context: context,
        message: 'Введите корректный ИНН (10 или 12 цифр)',
        kind: AppSnackBarKind.error,
      );
      return;
    }

    setState(() => _isSearching = true);
    try {
      final data = await ref
          .read(companyRepositoryProvider)
          .searchCompanyByInn(inn);

      if (data != null && mounted) {
        setState(() {
          _nameFullController.text = data['nameFull'] ?? '';
          _nameShortController.text = data['nameShort'] ?? '';
          _kppController.text = data['kpp'] ?? '';
          _ogrnController.text = data['ogrn'] ?? '';
          _okpoController.text = data['okpo'] ?? '';
          _legalAddressController.text = data['legalAddress'] ?? '';
          _actualAddressController.text =
              data['legalAddress'] ?? ''; // По умолчанию такой же
          _directorNameController.text = data['directorName'] ?? '';
          _directorPositionController.text = data['directorPosition'] ?? '';
          _activityDescriptionController.text =
              data['activityDescription'] ?? '';
          _emailController.text = data['email'] ?? '';
          _phoneController.text = data['phone'] ?? '';
        });
        AppSnackBar.show(
          context: context,
          message: 'Данные организации получены',
          kind: AppSnackBarKind.success,
        );
      } else if (mounted) {
        AppSnackBar.show(
          context: context,
          message: 'Организация не найдена',
          kind: AppSnackBarKind.warning,
        );
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.show(
          context: context,
          message: 'Ошибка при поиске: $e',
          kind: AppSnackBarKind.error,
        );
      }
    } finally {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final nameShort = _nameShortController.text.trim();
      final additionalData = {
        'name_full': _nameFullController.text.trim(),
        'name_short': nameShort,
        'inn': _innController.text.trim(),
        'kpp': _kppController.text.trim(),
        'ogrn': _ogrnController.text.trim(),
        'okpo': _okpoController.text.trim(),
        'legal_address': _legalAddressController.text.trim(),
        'actual_address': _actualAddressController.text.trim(),
        'director_name': _directorNameController.text.trim(),
        'director_position': _directorPositionController.text.trim(),
        'director_basis': _directorBasisController.text.trim(),
        'director_phone': _directorPhoneController.text.trim(),
        'chief_accountant_name': _chiefAccountantNameController.text.trim(),
        'chief_accountant_phone': _chiefAccountantPhoneController.text.trim(),
        'contact_person': _contactPersonController.text.trim(),
        'website': _websiteController.text.trim(),
        'email': _emailController.text.trim(),
        'phone': _phoneController.text.trim(),
        'activity_description': _activityDescriptionController.text.trim(),
        'taxation_system': _taxationSystemController.text.trim(),
        'is_vat_payer': _isVatPayer,
        'vat_rate': double.tryParse(_vatRateController.text) ?? 0,
      };

      await ref
          .read(createCompanyUseCaseProvider)
          .execute(name: nameShort, additionalData: additionalData);

      // Инвалидируем список компаний пользователя
      ref.invalidate(userCompaniesProvider);

      // Принудительно обновляем профиль текущего пользователя,
      // чтобы подхватить новый last_company_id
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
          message: 'Компания "$nameShort" успешно создана',
          kind: AppSnackBarKind.success,
        );
        widget.onSuccess?.call();
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.show(
          context: context,
          message: 'Ошибка при создании компании: $e',
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

    final content = Form(
      key: _formKey,
      child: CompanyFormContent(
        isDesktop: isDesktop,
        isLoading: _isLoading,
        isSearching: _isSearching,
        nameFullController: _nameFullController,
        nameShortController: _nameShortController,
        innController: _innController,
        kppController: _kppController,
        ogrnController: _ogrnController,
        okpoController: _okpoController,
        legalAddressController: _legalAddressController,
        actualAddressController: _actualAddressController,
        directorNameController: _directorNameController,
        directorPositionController: _directorPositionController,
        directorBasisController: _directorBasisController,
        directorPhoneController: _directorPhoneController,
        chiefAccountantNameController: _chiefAccountantNameController,
        chiefAccountantPhoneController: _chiefAccountantPhoneController,
        contactPersonController: _contactPersonController,
        websiteController: _websiteController,
        emailController: _emailController,
        phoneController: _phoneController,
        activityDescriptionController: _activityDescriptionController,
        taxationSystemController: _taxationSystemController,
        vatRateController: _vatRateController,
        isVatPayer: _isVatPayer,
        onVatPayerChanged: (v) => setState(() => _isVatPayer = v),
        onTaxationSystemChanged: (v) => setState(() {}),
        onSearchByInn: _searchByInn,
      ),
    );

    if (isDesktop) {
      return DesktopDialogContent(
        title: 'Создать компанию',
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
              text: 'Создать компанию',
              isLoading: _isLoading,
              onPressed: _submit,
            ),
          ],
        ),
        child: content,
      );
    } else {
      return MobileBottomSheetContent(
        title: 'Создать компанию',
        footer: GTPrimaryButton(
          text: 'Создать компанию',
          isLoading: _isLoading,
          onPressed: _submit,
        ),
        child: content,
      );
    }
  }
}
