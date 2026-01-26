import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:projectgt/core/utils/formatters.dart';
import 'package:projectgt/core/widgets/desktop_dialog_content.dart';
import 'package:projectgt/core/widgets/mobile_bottom_sheet_content.dart';
import 'package:projectgt/core/widgets/gt_buttons.dart';
import 'package:projectgt/core/widgets/app_snackbar.dart';
import 'package:projectgt/features/company/domain/entities/company_profile.dart';
import 'package:projectgt/features/company/presentation/providers/company_providers.dart';
import 'package:projectgt/features/company/presentation/widgets/company_form_content.dart';

/// Диалоговое окно для редактирования данных профиля компании.
class CompanyProfileEditDialog extends ConsumerStatefulWidget {
  /// Текущий профиль компании.
  final CompanyProfile profile;

  /// Создаёт диалог редактирования профиля.
  const CompanyProfileEditDialog({super.key, required this.profile});

  /// Показывает диалог редактирования профиля адаптивно.
  static void show(BuildContext context, CompanyProfile profile) {
    final isDesktop = MediaQuery.of(context).size.width >= 800;

    if (isDesktop) {
      showDialog(
        context: context,
        builder: (context) => Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(24),
          child: CompanyProfileEditDialog(profile: profile),
        ),
      );
    } else {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        backgroundColor: Colors.transparent,
        builder: (context) => CompanyProfileEditDialog(profile: profile),
      );
    }
  }

  @override
  ConsumerState<CompanyProfileEditDialog> createState() =>
      _CompanyProfileEditDialogState();
}

class _CompanyProfileEditDialogState
    extends ConsumerState<CompanyProfileEditDialog> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  late TextEditingController _nameFullController;
  late TextEditingController _nameShortController;
  late TextEditingController _activityDescriptionController;
  late TextEditingController _innController;
  late TextEditingController _kppController;
  late TextEditingController _ogrnController;
  late TextEditingController _okpoController;
  late TextEditingController _websiteController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _directorNameController;
  late TextEditingController _directorPositionController;
  late TextEditingController _directorBasisController;
  late TextEditingController _directorPhoneController;
  late TextEditingController _chiefAccountantNameController;
  late TextEditingController _chiefAccountantPhoneController;
  late TextEditingController _contactPersonController;
  late TextEditingController _legalAddressController;
  late TextEditingController _actualAddressController;
  late TextEditingController _taxationSystemController;
  late TextEditingController _vatRateController;
  late bool _isVatPayer;

  @override
  void initState() {
    super.initState();
    final p = widget.profile;
    _nameFullController = TextEditingController(text: p.nameFull);
    _nameShortController = TextEditingController(text: p.nameShort);
    _activityDescriptionController = TextEditingController(
      text: p.activityDescription,
    );
    _innController = TextEditingController(text: p.inn);
    _kppController = TextEditingController(text: p.kpp);
    _ogrnController = TextEditingController(text: p.ogrn);
    _okpoController = TextEditingController(text: p.okpo);
    _websiteController = TextEditingController(text: p.website);
    _emailController = TextEditingController(text: p.email);
    _phoneController = TextEditingController(text: p.phone);
    _directorNameController = TextEditingController(text: p.directorName);
    _directorPositionController = TextEditingController(
      text: p.directorPosition,
    );
    _directorBasisController = TextEditingController(text: p.directorBasis);
    _directorPhoneController = TextEditingController(text: p.directorPhone);
    _chiefAccountantNameController = TextEditingController(
      text: p.chiefAccountantName,
    );
    _chiefAccountantPhoneController = TextEditingController(
      text: p.chiefAccountantPhone,
    );
    _contactPersonController = TextEditingController(text: p.contactPerson);
    _legalAddressController = TextEditingController(text: p.legalAddress);
    _actualAddressController = TextEditingController(text: p.actualAddress);
    _taxationSystemController = TextEditingController(text: p.taxationSystem);
    _vatRateController = TextEditingController(text: p.vatRate.toString());
    _isVatPayer = p.isVatPayer;
  }

  @override
  void dispose() {
    _nameFullController.dispose();
    _nameShortController.dispose();
    _activityDescriptionController.dispose();
    _innController.dispose();
    _kppController.dispose();
    _ogrnController.dispose();
    _okpoController.dispose();
    _websiteController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _directorNameController.dispose();
    _directorPositionController.dispose();
    _directorBasisController.dispose();
    _directorPhoneController.dispose();
    _chiefAccountantNameController.dispose();
    _chiefAccountantPhoneController.dispose();
    _contactPersonController.dispose();
    _legalAddressController.dispose();
    _actualAddressController.dispose();
    _taxationSystemController.dispose();
    _vatRateController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final updatedProfile = widget.profile.copyWith(
        nameFull: _nameFullController.text,
        nameShort: _nameShortController.text,
        activityDescription: _activityDescriptionController.text,
        inn: _innController.text,
        kpp: _kppController.text,
        ogrn: _ogrnController.text,
        okpo: _okpoController.text,
        website: _websiteController.text,
        email: _emailController.text,
        phone: _phoneController.text,
        directorName: _directorNameController.text,
        directorPosition: _directorPositionController.text,
        directorBasis: _directorBasisController.text,
        directorPhone: _directorPhoneController.text,
        chiefAccountantName: _chiefAccountantNameController.text,
        chiefAccountantPhone: _chiefAccountantPhoneController.text,
        contactPerson: _contactPersonController.text,
        legalAddress: _legalAddressController.text,
        actualAddress: _actualAddressController.text,
        taxationSystem: _taxationSystemController.text,
        isVatPayer: _isVatPayer,
        vatRate: parseAmount(_vatRateController.text) ?? 0,
      );

      await ref
          .read(companyRepositoryProvider)
          .updateCompanyProfile(updatedProfile);

      // Инвалидируем провайдер для обновления UI
      ref.invalidate(companyProfileProvider);

      if (mounted) {
        Navigator.of(context).pop();
        AppSnackBar.show(
          context: context,
          message: 'Данные компании успешно обновлены',
          kind: AppSnackBarKind.success,
        );
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.show(
          context: context,
          message: 'Ошибка при сохранении: $e',
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
        isSearching:
            false, // В режиме редактирования поиск обычно не нужен, но можно добавить если требуется
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
        onSearchByInn: () {}, // Можно добавить логику поиска если нужно
      ),
    );

    if (isDesktop) {
      return DesktopDialogContent(
        title: 'Редактирование данных компании',
        onClose: _isLoading ? () {} : null,
        footer: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            GTSecondaryButton(
              text: 'Отмена',
              onPressed: _isLoading ? null : () => Navigator.pop(context),
            ),
            const SizedBox(width: 16),
            GTPrimaryButton(
              text: 'Сохранить',
              isLoading: _isLoading,
              onPressed: _save,
            ),
          ],
        ),
        child: content,
      );
    } else {
      return MobileBottomSheetContent(
        title: 'Данные компании',
        footer: GTPrimaryButton(
          text: 'Сохранить',
          isLoading: _isLoading,
          onPressed: _save,
        ),
        child: content,
      );
    }
  }
}

// Удаляем _SectionTitle так как он теперь внутри CompanyFormContent или не нужен здесь
