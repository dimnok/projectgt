import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'dart:io';
import 'package:projectgt/domain/entities/contractor.dart';
import 'package:projectgt/core/di/providers.dart';
import 'package:uuid/uuid.dart';
import 'package:projectgt/presentation/widgets/photo_picker_avatar.dart';
import 'package:projectgt/core/utils/snackbar_utils.dart';

/// Контент формы создания/редактирования контрагента.
///
/// Используется для отображения и валидации полей контрагента, загрузки логотипа и управления состоянием формы.
///
/// Пример использования:
/// ```dart
/// ContractorFormContent(
///   isNew: true,
///   isLoading: false,
///   fullNameController: ..., // инициализированный TextEditingController
///   ...
/// )
/// ```
class ContractorFormContent extends StatelessWidget {
  /// Является ли форма созданием нового контрагента (`true`) или редактированием (`false`).
  final bool isNew;

  /// Флаг загрузки состояния (блокирует поля и кнопки).
  final bool isLoading;

  /// Контроллер для поля "Полное наименование".
  final TextEditingController fullNameController;

  /// Контроллер для поля "Сокращенное наименование".
  final TextEditingController shortNameController;

  /// Контроллер для поля "ИНН".
  final TextEditingController innController;

  /// Контроллер для поля "Директор".
  final TextEditingController directorController;

  /// Контроллер для поля "Юридический адрес".
  final TextEditingController legalAddressController;

  /// Контроллер для поля "Фактический адрес".
  final TextEditingController actualAddressController;

  /// Контроллер для поля "Телефон".
  final TextEditingController phoneController;

  /// Контроллер для поля "Почта".
  final TextEditingController emailController;

  /// Тип контрагента (заказчик, подрядчик, поставщик).
  final ContractorType type;

  /// Колбэк при изменении типа контрагента.
  final void Function(ContractorType) onTypeChanged;

  /// Локальный файл логотипа (если выбран).
  final File? logoFile;

  /// URL логотипа (если уже загружен).
  final String? logoUrl;

  /// Колбэк для сохранения формы.
  final VoidCallback onSave;

  /// Колбэк для отмены/закрытия формы.
  final VoidCallback onCancel;

  /// Флаг загрузки логотипа (отображает индикатор).
  final bool isLogoLoading;

  /// Конструктор [ContractorFormContent]. Все параметры обязательны, кроме [isLogoLoading] (по умолчанию `false`).
  const ContractorFormContent({
    super.key,
    required this.isNew,
    required this.isLoading,
    required this.fullNameController,
    required this.shortNameController,
    required this.innController,
    required this.directorController,
    required this.legalAddressController,
    required this.actualAddressController,
    required this.phoneController,
    required this.emailController,
    required this.type,
    required this.onTypeChanged,
    required this.logoFile,
    required this.logoUrl,
    required this.onSave,
    required this.onCancel,
    this.isLogoLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          margin: EdgeInsets.zero,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color:
                  Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Информация о контрагенте',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: fullNameController,
                  decoration:
                      const InputDecoration(labelText: 'Полное наименование *'),
                  validator: (v) => v == null || v.trim().isEmpty
                      ? 'Введите полное наименование'
                      : null,
                  enabled: !isLoading,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: shortNameController,
                  decoration: const InputDecoration(
                      labelText: 'Сокращенное наименование *'),
                  validator: (v) => v == null || v.trim().isEmpty
                      ? 'Введите сокращенное наименование'
                      : null,
                  enabled: !isLoading,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: innController,
                  decoration: const InputDecoration(labelText: 'ИНН *'),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Введите ИНН' : null,
                  enabled: !isLoading,
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: directorController,
                  decoration: const InputDecoration(labelText: 'Директор'),
                  validator: (v) => null,
                  enabled: !isLoading,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: legalAddressController,
                  decoration:
                      const InputDecoration(labelText: 'Юридический адрес'),
                  validator: (v) => null,
                  enabled: !isLoading,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: actualAddressController,
                  decoration:
                      const InputDecoration(labelText: 'Фактический адрес'),
                  validator: (v) => null,
                  enabled: !isLoading,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: phoneController,
                  decoration:
                      const InputDecoration(labelText: 'Контактный номер'),
                  validator: (v) => null,
                  enabled: !isLoading,
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: emailController,
                  decoration: const InputDecoration(labelText: 'Почта'),
                  validator: (v) => null,
                  enabled: !isLoading,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<ContractorType>(
                  value: type,
                  decoration:
                      const InputDecoration(labelText: 'Тип контрагента'),
                  items: ContractorType.values.map((type) {
                    return DropdownMenuItem(
                      value: type,
                      child: Text(_typeLabel(type)),
                    );
                  }).toList(),
                  onChanged: isLoading ? null : (val) => onTypeChanged(val!),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 32),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: isLoading ? null : onCancel,
                child: const Text('Отмена'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton(
                onPressed: isLoading ? null : onSave,
                child: isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CupertinoActivityIndicator())
                    : Text(isNew ? 'Создать' : 'Сохранить'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Возвращает строковое представление типа контрагента для отображения в UI.
  ///
  /// [type] — тип контрагента.
  ///
  /// Возможные значения:
  /// - [ContractorType.customer] — "Заказчик"
  /// - [ContractorType.contractor] — "Подрядчик"
  /// - [ContractorType.supplier] — "Поставщик"
  String _typeLabel(ContractorType type) {
    switch (type) {
      case ContractorType.customer:
        return 'Заказчик';
      case ContractorType.contractor:
        return 'Подрядчик';
      case ContractorType.supplier:
        return 'Поставщик';
    }
  }
}

/// Экран создания/редактирования контрагента с поддержкой состояния через Riverpod.
///
/// Использует [ContractorFormContent] для отображения формы. Поддерживает работу как в Scaffold, так и встраивание в другие экраны.
class ContractorFormScreen extends ConsumerStatefulWidget {
  /// ID контрагента для редактирования. Если `null` — создаётся новый контрагент.
  final String? contractorId;

  /// Показывать ли Scaffold вокруг формы (по умолчанию `true`).
  final bool showScaffold;

  /// Конструктор [ContractorFormScreen].
  const ContractorFormScreen(
      {super.key, this.contractorId, this.showScaffold = true});

  @override
  ConsumerState<ContractorFormScreen> createState() =>
      _ContractorFormScreenState();
}

/// Состояние для [ContractorFormScreen]. Управляет контроллерами, загрузкой, логикой сохранения и загрузки логотипа.
class _ContractorFormScreenState extends ConsumerState<ContractorFormScreen> {
  final _fullNameController = TextEditingController();
  final _shortNameController = TextEditingController();
  final _innController = TextEditingController();
  final _directorController = TextEditingController();
  final _legalAddressController = TextEditingController();
  final _actualAddressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  ContractorType _type = ContractorType.customer;
  File? _logoFile;
  String? _logoUrl;
  bool _isLoading = false;
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _fullNameController.dispose();
    _shortNameController.dispose();
    _innController.dispose();
    _directorController.dispose();
    _legalAddressController.dispose();
    _actualAddressController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    if (widget.contractorId != null) {
      final state = ref.read(contractorProvider);
      final contractor = state.contractors.firstWhere(
        (c) => c.id == widget.contractorId,
        orElse: () =>
            state.contractor ??
            Contractor(
              id: widget.contractorId!,
              logoUrl: null,
              fullName: '',
              shortName: '',
              inn: '',
              director: '',
              legalAddress: '',
              actualAddress: '',
              phone: '',
              email: '',
              type: ContractorType.customer,
            ),
      );
      _fullNameController.text = contractor.fullName;
      _shortNameController.text = contractor.shortName;
      _innController.text = contractor.inn;
      _directorController.text = contractor.director;
      _legalAddressController.text = contractor.legalAddress;
      _actualAddressController.text = contractor.actualAddress;
      _phoneController.text = contractor.phone;
      _emailController.text = contractor.email;
      _type = contractor.type;
      _logoUrl = contractor.logoUrl;
    }
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    final notifier = ref.read(contractorProvider.notifier);
    final isNew = widget.contractorId == null;
    final id = widget.contractorId ?? const Uuid().v4();
    final contractor = Contractor(
      id: id,
      logoUrl: _logoUrl,
      fullName: _fullNameController.text.trim(),
      shortName: _shortNameController.text.trim(),
      inn: _innController.text.trim(),
      director: _directorController.text.trim(),
      legalAddress: _legalAddressController.text.trim(),
      actualAddress: _actualAddressController.text.trim(),
      phone: _phoneController.text.trim(),
      email: _emailController.text.trim(),
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
      if (mounted) {
        SnackBarUtils.showError(context, 'Ошибка: ${e.toString()}');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isNew = widget.contractorId == null;
    return Material(
      color: theme.colorScheme.surface,
      child: _isLoading
          ? const Center(child: CupertinoActivityIndicator())
          : Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 700),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16.0),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  isNew
                                      ? 'Новый контрагент'
                                      : 'Редактировать контрагента',
                                  style: theme.textTheme.titleLarge
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close),
                                style: IconButton.styleFrom(
                                    foregroundColor: Colors.red),
                                onPressed: () {
                                  if (Navigator.of(context).canPop()) {
                                    Navigator.pop(context);
                                  } else {
                                    context.goNamed('contractors');
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                        const Divider(),
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
                        ContractorFormContent(
                          isNew: isNew,
                          isLoading: _isLoading,
                          fullNameController: _fullNameController,
                          shortNameController: _shortNameController,
                          innController: _innController,
                          directorController: _directorController,
                          legalAddressController: _legalAddressController,
                          actualAddressController: _actualAddressController,
                          phoneController: _phoneController,
                          emailController: _emailController,
                          type: _type,
                          onTypeChanged: (val) => setState(() => _type = val),
                          logoFile: _logoFile,
                          logoUrl: _logoUrl,
                          onSave: _handleSave,
                          onCancel: () {
                            if (Navigator.of(context).canPop()) {
                              Navigator.pop(context);
                            } else {
                              context.goNamed('contractors');
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}
