import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:projectgt/core/widgets/desktop_dialog_content.dart';
import 'package:projectgt/core/widgets/gt_buttons.dart';
import 'package:projectgt/core/widgets/app_snackbar.dart';
import 'package:projectgt/features/company/domain/entities/company_profile.dart';
import 'package:projectgt/features/company/presentation/providers/company_providers.dart';

/// Диалоговое окно для редактирования данных профиля компании.
class CompanyProfileEditDialog extends ConsumerStatefulWidget {
  /// Текущий профиль компании.
  final CompanyProfile profile;

  /// Создаёт диалог редактирования профиля.
  const CompanyProfileEditDialog({
    super.key,
    required this.profile,
  });

  /// Показывает диалог редактирования профиля.
  static void show(BuildContext context, CompanyProfile profile) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(24),
        child: CompanyProfileEditDialog(profile: profile),
      ),
    );
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
    _activityDescriptionController =
        TextEditingController(text: p.activityDescription);
    _innController = TextEditingController(text: p.inn);
    _kppController = TextEditingController(text: p.kpp);
    _ogrnController = TextEditingController(text: p.ogrn);
    _okpoController = TextEditingController(text: p.okpo);
    _websiteController = TextEditingController(text: p.website);
    _emailController = TextEditingController(text: p.email);
    _phoneController = TextEditingController(text: p.phone);
    _directorNameController = TextEditingController(text: p.directorName);
    _directorPositionController =
        TextEditingController(text: p.directorPosition);
    _directorBasisController = TextEditingController(text: p.directorBasis);
    _directorPhoneController = TextEditingController(text: p.directorPhone);
    _chiefAccountantNameController =
        TextEditingController(text: p.chiefAccountantName);
    _chiefAccountantPhoneController =
        TextEditingController(text: p.chiefAccountantPhone);
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
        vatRate: double.tryParse(_vatRateController.text) ?? 0,
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
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SectionTitle(title: 'Основная информация'),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameFullController,
              decoration: const InputDecoration(
                labelText: 'Полное наименование',
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
                  v == null || v.isEmpty ? 'Введите наименование' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameShortController,
              decoration: const InputDecoration(
                labelText: 'Краткое наименование',
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
                  v == null || v.isEmpty ? 'Введите краткое наименование' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _activityDescriptionController,
              decoration: const InputDecoration(
                labelText: 'Сфера деятельности',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            const _SectionTitle(title: 'Юридические данные'),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _innController,
                    decoration: const InputDecoration(
                      labelText: 'ИНН',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _kppController,
                    decoration: const InputDecoration(
                      labelText: 'КПП',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _ogrnController,
                    decoration: const InputDecoration(
                      labelText: 'ОГРН',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _okpoController,
                    decoration: const InputDecoration(
                      labelText: 'ОКПО',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const _SectionTitle(title: 'Налогообложение'),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _taxationSystemController,
                    decoration: const InputDecoration(
                      labelText: 'Система налогообложения',
                      hintText: 'ОСНО, УСН и др.',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: InkWell(
                          onTap: () => setState(() => _isVatPayer = !_isVatPayer),
                          splashColor: Colors.transparent,
                          highlightColor: Colors.transparent,
                          hoverColor: Colors.transparent,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Плательщик НДС',
                                style: Theme.of(context).textTheme.bodyLarge,
                              ),
                              Switch(
                                value: _isVatPayer,
                                onChanged: (v) =>
                                    setState(() => _isVatPayer = v),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (_isVatPayer)
                        TextFormField(
                          controller: _vatRateController,
                          decoration: const InputDecoration(
                            labelText: 'Ставка НДС (%)',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const _SectionTitle(title: 'Контакты'),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _websiteController,
                    decoration: const InputDecoration(
                      labelText: 'Сайт',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(CupertinoIcons.globe),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(CupertinoIcons.mail),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _phoneController,
              decoration: const InputDecoration(
                labelText: 'Телефон компании',
                border: OutlineInputBorder(),
                prefixIcon: Icon(CupertinoIcons.phone),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _contactPersonController,
              decoration: const InputDecoration(
                labelText: 'Контактное лицо',
                border: OutlineInputBorder(),
                prefixIcon: Icon(CupertinoIcons.person_crop_square),
              ),
            ),
            const SizedBox(height: 24),
            const _SectionTitle(title: 'Адреса'),
            const SizedBox(height: 16),
            TextFormField(
              controller: _legalAddressController,
              decoration: const InputDecoration(
                labelText: 'Юридический адрес',
                border: OutlineInputBorder(),
                prefixIcon: Icon(CupertinoIcons.location),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _actualAddressController,
              decoration: const InputDecoration(
                labelText: 'Фактический адрес',
                border: OutlineInputBorder(),
                prefixIcon: Icon(CupertinoIcons.location_north),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 24),
            const _SectionTitle(title: 'Руководство'),
            const SizedBox(height: 16),
            TextFormField(
              controller: _directorNameController,
              decoration: const InputDecoration(
                labelText: 'Генеральный директор',
                border: OutlineInputBorder(),
                prefixIcon: Icon(CupertinoIcons.person),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _directorPositionController,
                    decoration: const InputDecoration(
                      labelText: 'Должность руководителя',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _directorPhoneController,
                    decoration: const InputDecoration(
                      labelText: 'Телефон руководителя',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(CupertinoIcons.phone),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _directorBasisController,
              decoration: const InputDecoration(
                labelText: 'Действует на основании',
                hintText: 'Устава, Доверенности...',
                border: OutlineInputBorder(),
                prefixIcon: Icon(CupertinoIcons.doc_plaintext),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _chiefAccountantNameController,
                    decoration: const InputDecoration(
                      labelText: 'Главный бухгалтер',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(CupertinoIcons.person_crop_circle),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _chiefAccountantPhoneController,
                    decoration: const InputDecoration(
                      labelText: 'Телефон бухгалтера',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(CupertinoIcons.phone),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title.toUpperCase(),
      style: Theme.of(context).textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
            letterSpacing: 1.1,
          ),
    );
  }
}

