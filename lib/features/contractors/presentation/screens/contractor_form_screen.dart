import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';
import 'package:projectgt/features/contractors/domain/entities/contractor.dart';
import 'package:projectgt/features/contractors/presentation/state/contractor_state.dart';
import 'package:projectgt/features/company/presentation/providers/company_providers.dart';
import 'package:uuid/uuid.dart';
import 'package:projectgt/presentation/widgets/photo_picker_avatar.dart';
import 'package:projectgt/core/widgets/gt_dropdown.dart';
import 'package:projectgt/core/widgets/gt_text_field.dart';
import 'package:projectgt/core/widgets/gt_section_title.dart';
import 'package:projectgt/core/utils/snackbar_utils.dart';
import 'package:projectgt/core/widgets/gt_buttons.dart';
import 'package:projectgt/core/widgets/desktop_dialog_content.dart';
import 'package:projectgt/core/widgets/mobile_bottom_sheet_content.dart';

/// Виджет, содержащий поля формы для ввода и редактирования данных контрагента.
///
/// Используется как в мобильной версии (bottom sheet), так и в десктопной (диалог).
class ContractorFormFields extends StatelessWidget {
  /// Флаг состояния загрузки данных или процесса сохранения.
  final bool isLoading;

  /// Контроллер для полного юридического наименования организации.
  final TextEditingController fullNameController;

  /// Контроллер для сокращенного наименования организации.
  final TextEditingController shortNameController;

  /// Контроллер для ИНН (Идентификационный номер налогоплательщика).
  final TextEditingController innController;

  /// Контроллер для ФИО руководителя организации.
  final TextEditingController directorController;

  /// Контроллер для юридического адреса организации.
  final TextEditingController legalAddressController;

  /// Контроллер для фактического адреса организации.
  final TextEditingController actualAddressController;

  /// Контроллер для основного контактного телефона организации.
  final TextEditingController phoneController;

  /// Контроллер для контактного адреса электронной почты.
  final TextEditingController emailController;

  /// Контроллер для адреса веб-сайта организации.
  final TextEditingController websiteController;

  /// Контроллер для краткого описания сферы деятельности организации.
  final TextEditingController activityDescriptionController;

  /// Контроллер для КПП (Код причины постановки на учет).
  final TextEditingController kppController;

  /// Контроллер для ОГРН (Основной государственный регистрационный номер).
  final TextEditingController ogrnController;

  /// Контроллер для ОКПО (Общероссийский классификатор предприятий и организаций).
  final TextEditingController okpoController;

  /// Контроллер для документального основания полномочий руководителя (например, "Устав").
  final TextEditingController directorBasisController;

  /// Контроллер для контактного телефона руководителя.
  final TextEditingController directorPhoneController;

  /// Контроллер для ФИО главного бухгалтера.
  final TextEditingController chiefAccountantNameController;

  /// Контроллер для контактного телефона главного бухгалтера.
  final TextEditingController chiefAccountantPhoneController;

  /// Контроллер для ФИО основного контактного лица.
  final TextEditingController contactPersonController;

  /// Контроллер для описания применяемой системы налогообложения (например, "ОСНО").
  final TextEditingController taxationSystemController;

  /// Контроллер для указания процентной ставки НДС.
  final TextEditingController vatRateController;

  /// Является ли контрагент плательщиком НДС.
  final bool isVatPayer;

  /// Колбэк, вызываемый при изменении статуса плательщика НДС.
  final void Function(bool) onVatPayerChanged;

  /// Тип контрагента (заказчик, подрядчик, поставщик).
  final ContractorType type;

  /// Колбэк, вызываемый при изменении типа контрагента.
  final void Function(ContractorType) onTypeChanged;

  /// Колбэк для поиска в DaData.
  final VoidCallback? onSearchInn;

  /// Создает экземпляр полей формы контрагента.
  const ContractorFormFields({
    super.key,
    required this.isLoading,
    required this.fullNameController,
    required this.shortNameController,
    required this.innController,
    required this.directorController,
    required this.legalAddressController,
    required this.actualAddressController,
    required this.phoneController,
    required this.emailController,
    required this.websiteController,
    required this.activityDescriptionController,
    required this.kppController,
    required this.ogrnController,
    required this.okpoController,
    required this.directorBasisController,
    required this.directorPhoneController,
    required this.chiefAccountantNameController,
    required this.chiefAccountantPhoneController,
    required this.contactPersonController,
    required this.taxationSystemController,
    required this.vatRateController,
    required this.isVatPayer,
    required this.onVatPayerChanged,
    required this.type,
    required this.onTypeChanged,
    this.onSearchInn,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const GTSectionTitle(title: 'Основная информация'),
        const SizedBox(height: 16),
        GTTextField(
          controller: fullNameController,
          labelText: 'Полное наименование *',
          prefixIcon: CupertinoIcons.doc_text,
          validator: (v) => v == null || v.trim().isEmpty
              ? 'Введите полное наименование'
              : null,
          enabled: !isLoading,
        ),
        const SizedBox(height: 16),
        GTTextField(
          controller: shortNameController,
          labelText: 'Сокращенное наименование *',
          prefixIcon: CupertinoIcons.doc_plaintext,
          validator: (v) => v == null || v.trim().isEmpty
              ? 'Введите сокращенное наименование'
              : null,
          enabled: !isLoading,
        ),
        const SizedBox(height: 16),
        GTTextField(
          controller: activityDescriptionController,
          labelText: 'Сфера деятельности',
          prefixIcon: CupertinoIcons.briefcase,
          enabled: !isLoading,
        ),
        const SizedBox(height: 16),
        GTEnumDropdown<ContractorType>(
          values: ContractorType.values,
          selectedValue: type,
          labelText: 'Тип контрагента',
          hintText: 'Выберите тип...',
          enumToString: (val) => val.label,
          onChanged: (val) => onTypeChanged(val!),
          readOnly: isLoading,
          allowClear: false,
        ),
        const SizedBox(height: 24),
        const GTSectionTitle(title: 'Юридические данные'),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: GTTextField(
                controller: innController,
                labelText: 'ИНН *',
                prefixIcon: CupertinoIcons.number,
                suffixIcon: onSearchInn != null
                    ? IconButton(
                        icon: const Icon(CupertinoIcons.search),
                        onPressed: isLoading ? null : onSearchInn,
                        tooltip: 'Поиск в DaData',
                      )
                    : null,
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Введите ИНН' : null,
                enabled: !isLoading,
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: GTTextField(
                controller: kppController,
                labelText: 'КПП',
                prefixIcon: CupertinoIcons.number,
                enabled: !isLoading,
                keyboardType: TextInputType.number,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: GTTextField(
                controller: ogrnController,
                labelText: 'ОГРН',
                prefixIcon: CupertinoIcons.number,
                enabled: !isLoading,
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: GTTextField(
                controller: okpoController,
                labelText: 'ОКПО',
                prefixIcon: CupertinoIcons.number,
                enabled: !isLoading,
                keyboardType: TextInputType.number,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        const GTSectionTitle(title: 'Налогообложение'),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: GTTextField(
                controller: taxationSystemController,
                labelText: 'Система налогообложения',
                hintText: 'ОСНО, УСН и др.',
                prefixIcon: CupertinoIcons.percent,
                enabled: !isLoading,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                children: [
                  InkWell(
                    onTap: isLoading
                        ? null
                        : () => onVatPayerChanged(!isVatPayer),
                    splashColor: Colors.transparent,
                    highlightColor: Colors.transparent,
                    hoverColor: Colors.transparent,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              'НДС',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ),
                          Switch.adaptive(
                            value: isVatPayer,
                            onChanged: isLoading ? null : onVatPayerChanged,
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (isVatPayer)
                    GTTextField(
                      controller: vatRateController,
                      labelText: 'Ставка НДС (%)',
                      enabled: !isLoading,
                      keyboardType: TextInputType.number,
                    ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        const GTSectionTitle(title: 'Контакты'),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: GTTextField(
                controller: phoneController,
                labelText: 'Телефон',
                prefixIcon: CupertinoIcons.phone,
                enabled: !isLoading,
                keyboardType: TextInputType.phone,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: GTTextField(
                controller: emailController,
                labelText: 'Email',
                prefixIcon: CupertinoIcons.mail,
                enabled: !isLoading,
                keyboardType: TextInputType.emailAddress,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        GTTextField(
          controller: websiteController,
          labelText: 'Сайт',
          prefixIcon: CupertinoIcons.globe,
          enabled: !isLoading,
          keyboardType: TextInputType.url,
        ),
        const SizedBox(height: 16),
        GTTextField(
          controller: contactPersonController,
          labelText: 'Контактное лицо',
          prefixIcon: CupertinoIcons.person_crop_square,
          enabled: !isLoading,
        ),
        const SizedBox(height: 24),
        const GTSectionTitle(title: 'Адреса'),
        const SizedBox(height: 16),
        GTTextField(
          controller: legalAddressController,
          labelText: 'Юридический адрес',
          prefixIcon: CupertinoIcons.location,
          enabled: !isLoading,
          maxLines: 2,
        ),
        const SizedBox(height: 16),
        GTTextField(
          controller: actualAddressController,
          labelText: 'Фактический адрес',
          prefixIcon: CupertinoIcons.location_north,
          enabled: !isLoading,
          maxLines: 2,
        ),
        const SizedBox(height: 24),
        const GTSectionTitle(title: 'Руководство и бухгалтерия'),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: GTTextField(
                controller: directorController,
                labelText: 'Генеральный директор *',
                prefixIcon: CupertinoIcons.person,
                validator: (v) => v == null || v.trim().isEmpty
                    ? 'Введите ФИО директора'
                    : null,
                enabled: !isLoading,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: GTTextField(
                controller: directorPhoneController,
                labelText: 'Телефон руководителя',
                prefixIcon: CupertinoIcons.phone,
                enabled: !isLoading,
                keyboardType: TextInputType.phone,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        GTTextField(
          controller: directorBasisController,
          labelText: 'Действует на основании',
          hintText: 'Устава, Доверенности...',
          prefixIcon: CupertinoIcons.doc_plaintext,
          enabled: !isLoading,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: GTTextField(
                controller: chiefAccountantNameController,
                labelText: 'Главный бухгалтер',
                prefixIcon: CupertinoIcons.person_crop_circle,
                enabled: !isLoading,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: GTTextField(
                controller: chiefAccountantPhoneController,
                labelText: 'Телефон бухгалтера',
                prefixIcon: CupertinoIcons.phone,
                enabled: !isLoading,
                keyboardType: TextInputType.phone,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Экран создания или редактирования данных контрагента.
///
/// Поддерживает работу в режимах создания нового контрагента (если [contractorId] null)
/// и редактирования существующего. Использует Clean Architecture и Riverpod для управления состоянием.
class ContractorFormScreen extends ConsumerStatefulWidget {
  /// Идентификатор контрагента для режима редактирования.
  /// Если null, экран работает в режиме создания нового контрагента.
  final String? contractorId;

  /// Предварительно заполненное имя (для быстрого создания из выписки).
  final String? initialName;

  /// Предварительно заполненный ИНН (для быстрого создания из выписки).
  final String? initialInn;

  /// Создает экран формы контрагента.
  const ContractorFormScreen({
    super.key,
    this.contractorId,
    this.initialName,
    this.initialInn,
  });

  @override
  ConsumerState<ContractorFormScreen> createState() =>
      _ContractorFormScreenState();
}

class _ContractorFormScreenState extends ConsumerState<ContractorFormScreen> {
  final _fullNameController = TextEditingController();
  final _shortNameController = TextEditingController();
  final _activityDescriptionController = TextEditingController();
  final _innController = TextEditingController();
  final _kppController = TextEditingController();
  final _ogrnController = TextEditingController();
  final _okpoController = TextEditingController();
  final _directorController = TextEditingController();
  final _directorBasisController = TextEditingController();
  final _directorPhoneController = TextEditingController();
  final _chiefAccountantNameController = TextEditingController();
  final _chiefAccountantPhoneController = TextEditingController();
  final _contactPersonController = TextEditingController();
  final _legalAddressController = TextEditingController();
  final _actualAddressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _websiteController = TextEditingController();
  final _taxationSystemController = TextEditingController();
  final _vatRateController = TextEditingController(text: '0');
  bool _isVatPayer = false;
  ContractorType _type = ContractorType.customer;
  File? _logoFile;
  String? _logoUrl;
  bool _isLoading = false;
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _fullNameController.dispose();
    _shortNameController.dispose();
    _activityDescriptionController.dispose();
    _innController.dispose();
    _kppController.dispose();
    _ogrnController.dispose();
    _okpoController.dispose();
    _directorController.dispose();
    _directorBasisController.dispose();
    _directorPhoneController.dispose();
    _chiefAccountantNameController.dispose();
    _chiefAccountantPhoneController.dispose();
    _contactPersonController.dispose();
    _legalAddressController.dispose();
    _actualAddressController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _websiteController.dispose();
    _taxationSystemController.dispose();
    _vatRateController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    if (widget.contractorId != null) {
      final state = ref.read(contractorNotifierProvider);
      final contractor = state.contractors.firstWhere(
        (c) => c.id == widget.contractorId,
        orElse: () => state.contractors.first,
      );
      _fullNameController.text = contractor.fullName;
      _shortNameController.text = contractor.shortName;
      _activityDescriptionController.text =
          contractor.activityDescription ?? '';
      _innController.text = contractor.inn;
      _kppController.text = contractor.kpp ?? '';
      _ogrnController.text = contractor.ogrn ?? '';
      _okpoController.text = contractor.okpo ?? '';
      _directorController.text = contractor.director;
      _directorBasisController.text = contractor.directorBasis ?? '';
      _directorPhoneController.text = contractor.directorPhone ?? '';
      _chiefAccountantNameController.text =
          contractor.chiefAccountantName ?? '';
      _chiefAccountantPhoneController.text =
          contractor.chiefAccountantPhone ?? '';
      _contactPersonController.text = contractor.contactPerson ?? '';
      _legalAddressController.text = contractor.legalAddress;
      _actualAddressController.text = contractor.actualAddress;
      _phoneController.text = contractor.phone;
      _emailController.text = contractor.email;
      _websiteController.text = contractor.website ?? '';
      _taxationSystemController.text = contractor.taxationSystem ?? '';
      _vatRateController.text = contractor.vatRate.toString();
      _isVatPayer = contractor.isVatPayer;
      _type = contractor.type;
      _logoUrl = contractor.logoUrl;
    } else {
      // Предзаполнение для нового контрагента (например, из банковской выписки)
      if (widget.initialName != null) {
        _fullNameController.text = widget.initialName!;
        _shortNameController.text = widget.initialName!;
      }
      if (widget.initialInn != null) {
        _innController.text = widget.initialInn!;
        // Автоматический поиск в DaData при наличии ИНН
        WidgetsBinding.instance.addPostFrameCallback((_) => _searchDaData());
      }
    }
  }

  Future<void> _searchDaData() async {
    final inn = _innController.text.trim();
    if (inn.length < 10) return;

    setState(() => _isLoading = true);
    try {
      final repository = ref.read(companyRepositoryProvider);
      final data = await repository.searchCompanyByInn(inn);

      if (data != null && mounted) {
        setState(() {
          _fullNameController.text =
              data['nameFull'] ?? _fullNameController.text;
          _shortNameController.text =
              data['nameShort'] ?? _shortNameController.text;
          _kppController.text = data['kpp'] ?? _kppController.text;
          _ogrnController.text = data['ogrn'] ?? _ogrnController.text;
          _okpoController.text = data['okpo'] ?? _okpoController.text;
          _legalAddressController.text =
              data['legalAddress'] ?? _legalAddressController.text;
          _actualAddressController.text =
              data['legalAddress'] ?? _actualAddressController.text;
          _directorController.text =
              data['directorName'] ?? _directorController.text;
          _activityDescriptionController.text =
              data['activityDescription'] ??
              _activityDescriptionController.text;
          _emailController.text = data['email'] ?? _emailController.text;
          _phoneController.text = data['phone'] ?? _phoneController.text;
        });
        if (mounted) {
          SnackBarUtils.showInfo(context, 'Данные загружены из DaData');
        }
      } else if (mounted) {
        SnackBarUtils.showError(context, 'Организация не найдена в DaData');
      }
    } catch (e) {
      if (mounted) {
        SnackBarUtils.showError(context, 'Ошибка при поиске в DaData: $e');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    final notifier = ref.read(contractorNotifierProvider.notifier);
    final activeCompanyId = ref.read(activeCompanyIdProvider);

    if (activeCompanyId == null) {
      if (mounted) {
        SnackBarUtils.showError(context, 'Ошибка: компания не выбрана');
        setState(() => _isLoading = false);
      }
      return;
    }

    final isNew = widget.contractorId == null;
    final id = widget.contractorId ?? const Uuid().v4();
    final contractor = Contractor(
      id: id,
      companyId: isNew
          ? activeCompanyId
          : ref
                .read(contractorNotifierProvider)
                .contractors
                .firstWhere((c) => c.id == id)
                .companyId,
      logoUrl: _logoUrl,
      fullName: _fullNameController.text.trim(),
      shortName: _shortNameController.text.trim(),
      activityDescription: _activityDescriptionController.text.trim(),
      inn: _innController.text.trim(),
      kpp: _kppController.text.trim(),
      ogrn: _ogrnController.text.trim(),
      okpo: _okpoController.text.trim(),
      director: _directorController.text.trim(),
      directorBasis: _directorBasisController.text.trim(),
      directorPhone: _directorPhoneController.text.trim(),
      chiefAccountantName: _chiefAccountantNameController.text.trim(),
      chiefAccountantPhone: _chiefAccountantPhoneController.text.trim(),
      contactPerson: _contactPersonController.text.trim(),
      legalAddress: _legalAddressController.text.trim(),
      actualAddress: _actualAddressController.text.trim(),
      phone: _phoneController.text.trim(),
      email: _emailController.text.trim(),
      website: _websiteController.text.trim(),
      taxationSystem: _taxationSystemController.text.trim(),
      isVatPayer: _isVatPayer,
      vatRate: double.tryParse(_vatRateController.text) ?? 0,
      type: _type,
    );
    try {
      if (isNew) {
        await notifier.addContractor(contractor);
        if (mounted) {
          SnackBarUtils.showSuccess(context, 'Контрагент успешно создан');
        }
      } else {
        await notifier.updateContractor(contractor);
        if (mounted) {
          SnackBarUtils.showInfo(context, 'Изменения успешно сохранены');
        }
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) SnackBarUtils.showError(context, 'Ошибка: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 900;
    final title = widget.contractorId == null
        ? 'Новый контрагент'
        : 'Редактировать контрагента';

    Widget footer = Row(
      children: [
        Expanded(
          child: GTSecondaryButton(
            text: 'Отмена',
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: GTPrimaryButton(
            text: widget.contractorId == null ? 'Создать' : 'Сохранить',
            isLoading: _isLoading,
            onPressed: _handleSave,
          ),
        ),
      ],
    );

    Widget formContent = Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: PhotoPickerAvatar(
              imageUrl: _logoUrl,
              localFile: _logoFile,
              label: 'Логотип контрагента',
              isLoading: _isLoading,
              entity: 'contractor',
              id: widget.contractorId ?? const Uuid().v4(),
              displayName: _shortNameController.text.trim(),
              onPhotoChanged: (url) {
                setState(() {
                  _logoUrl = url;
                  _logoFile = null;
                });
              },
              placeholderIcon: Icons.business,
              radius: 48,
            ),
          ),
          const SizedBox(height: 24),
          ContractorFormFields(
            isLoading: _isLoading,
            fullNameController: _fullNameController,
            shortNameController: _shortNameController,
            innController: _innController,
            kppController: _kppController,
            directorController: _directorController,
            legalAddressController: _legalAddressController,
            actualAddressController: _actualAddressController,
            phoneController: _phoneController,
            emailController: _emailController,
            websiteController: _websiteController,
            activityDescriptionController: _activityDescriptionController,
            ogrnController: _ogrnController,
            okpoController: _okpoController,
            directorBasisController: _directorBasisController,
            directorPhoneController: _directorPhoneController,
            chiefAccountantNameController: _chiefAccountantNameController,
            chiefAccountantPhoneController: _chiefAccountantPhoneController,
            contactPersonController: _contactPersonController,
            taxationSystemController: _taxationSystemController,
            vatRateController: _vatRateController,
            isVatPayer: _isVatPayer,
            onVatPayerChanged: (val) => setState(() => _isVatPayer = val),
            type: _type,
            onTypeChanged: (val) => setState(() => _type = val),
            onSearchInn: _searchDaData,
          ),
        ],
      ),
    );

    if (isDesktop) {
      return DesktopDialogContent(
        title: title,
        footer: footer,
        child: formContent,
      );
    }

    return MobileBottomSheetContent(
      title: title,
      footer: footer,
      child: formContent,
    );
  }
}
