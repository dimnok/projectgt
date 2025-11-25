import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import 'package:projectgt/core/di/providers.dart';
import 'package:projectgt/core/utils/employee_ui_utils.dart';
import 'package:projectgt/core/utils/snackbar_utils.dart';
import 'package:projectgt/core/widgets/gt_dropdown.dart';

import 'package:projectgt/domain/entities/employee.dart';

import 'package:projectgt/presentation/state/employee_state.dart'
    as employee_state;
import 'package:projectgt/presentation/widgets/photo_picker_avatar.dart';

import 'package:projectgt/features/employees/presentation/widgets/form_widgets.dart';
import 'package:projectgt/core/utils/modal_utils.dart';

/// Экран создания/редактирования сотрудника.
///
/// Позволяет добавлять и изменять данные сотрудника, включая тип трудоустройства и статус.
/// Использует Clean Architecture, Riverpod, TypeAheadField для UX.
class EmployeeFormScreen extends ConsumerStatefulWidget {
  /// [employeeId] — если null, создаётся новый сотрудник, иначе — редактирование.
  const EmployeeFormScreen({super.key, this.employeeId, this.scrollController});

  /// Идентификатор сотрудника для редактирования (null — новый сотрудник).
  final String? employeeId;

  /// Контроллер прокрутки для DraggableScrollableSheet.
  final ScrollController? scrollController;

  @override
  ConsumerState<EmployeeFormScreen> createState() => _EmployeeFormScreenState();
}

/// Состояние для [EmployeeFormScreen].
///
/// Управляет контроллерами, загрузкой данных, обработкой выбора полей с автодополнением.
class _EmployeeFormScreenState extends ConsumerState<EmployeeFormScreen> {
  // Общие поля
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isNewEmployee = true;
  String? _photoUrl; // Добавляем переменную для хранения URL фото
  File? _photoFile; // Для локального файла

  // Текстовые контроллеры для полей
  final _lastNameController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _middleNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _birthPlaceController = TextEditingController();
  final _citizenshipController = TextEditingController();

  // Паспортные данные
  final _passportSeriesController = TextEditingController();
  final _passportNumberController = TextEditingController();
  final _passportIssuedByController = TextEditingController();
  final _passportDepartmentCodeController = TextEditingController();
  final _registrationAddressController = TextEditingController();
  final _innController = TextEditingController();
  final _snilsController = TextEditingController();

  // Трудоустройство
  final _hourlyRateController = TextEditingController();

  // Даты
  DateTime? _birthDate;
  DateTime? _passportIssueDate;
  DateTime? _employmentDate;
  DateTime? _rateValidFrom;

  // Состояния
  EmployeeStatus _status = EmployeeStatus.working;
  EmploymentType _employmentType = EmploymentType.official;
  String? _selectedPosition;
  List<String> _selectedObjectIds = [];
  List<String> _positions = [];
  bool _positionsLoading = false;

  // Физические параметры
  String? _selectedClothingSize;
  String? _selectedShoeSize;
  String? _selectedHeight;

  // Данные для dropdown'ов физических параметров
  static const List<String> _clothingSizes = [
    '40-42(S)',
    '44-46(M)',
    '48-50(L)',
    '50-52(XL)',
    '54-56(2XL)',
    '56-58(3XL)',
    '60-62(4XL)',
    '64-66(5XL)',
  ];

  static const List<String> _shoeSizes = [
    '36',
    '37',
    '38',
    '39',
    '40',
    '41',
    '42',
    '43',
    '44',
    '45',
    '46',
    '47',
    '48',
  ];

  static const List<String> _heightRanges = [
    '150-160',
    '160-170',
    '170-180',
    '180-190',
    '190-200',
  ];

  /// Инициализация состояния и контроллеров.
  @override
  void initState() {
    super.initState();
    _isNewEmployee = widget.employeeId == null;
    _rateValidFrom =
        DateTime.now(); // Инициализируем дату начала действия ставки
    _loadPositions();
    if (!_isNewEmployee) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadEmployeeData();
      });
    }
  }

  /// Освобождение ресурсов контроллеров.
  @override
  void dispose() {
    // Освобождаем ресурсы
    _lastNameController.dispose();
    _firstNameController.dispose();
    _middleNameController.dispose();
    _phoneController.dispose();
    _birthPlaceController.dispose();
    _citizenshipController.dispose();
    _passportSeriesController.dispose();
    _passportNumberController.dispose();
    _passportIssuedByController.dispose();
    _passportDepartmentCodeController.dispose();
    _registrationAddressController.dispose();
    _innController.dispose();
    _snilsController.dispose();
    _hourlyRateController.dispose();
    super.dispose();
  }

  /// Загрузка данных сотрудника для редактирования.
  Future<void> _loadEmployeeData() async {
    if (widget.employeeId != null) {
      setState(() {
        _isLoading = true;
      });
      await ref
          .read(employee_state.employeeProvider.notifier)
          .getEmployee(widget.employeeId!);
      final employeeState = ref.read(employee_state.employeeProvider);
      final employee = employeeState.employee;
      if (employee != null) {
        _lastNameController.text = employee.lastName;
        _firstNameController.text = employee.firstName;
        _middleNameController.text = employee.middleName ?? '';
        _phoneController.text = employee.phone ?? '';
        _birthPlaceController.text = employee.birthPlace ?? '';
        _citizenshipController.text = employee.citizenship ?? '';
        _selectedClothingSize = employee.clothingSize;
        _selectedShoeSize = employee.shoeSize;
        _selectedHeight = employee.height;
        _passportSeriesController.text = employee.passportSeries ?? '';
        _passportNumberController.text = employee.passportNumber ?? '';
        _passportIssuedByController.text = employee.passportIssuedBy ?? '';
        _passportDepartmentCodeController.text =
            employee.passportDepartmentCode ?? '';
        _registrationAddressController.text =
            employee.registrationAddress ?? '';
        _innController.text = employee.inn ?? '';
        _snilsController.text = employee.snils ?? '';
        // hourlyRate больше не загружается из employee,
        // будет загружен отдельно из employee_rates
        _selectedPosition = employee.position;
        _selectedObjectIds = List<String>.from(employee.objectIds);
        _employmentType = employee.employmentType;
        _status = employee.status;
        setState(() {
          _photoUrl = employee.photoUrl;
          _photoFile = null;
          _birthDate = employee.birthDate;
          _passportIssueDate = employee.passportIssueDate;
          _employmentDate = employee.employmentDate;
          _isLoading = false;
        });

        // Загружаем текущую ставку отдельно из employee_rates
        final rateDataSource = ref.read(employeeRateDataSourceProvider);
        final currentRate = await rateDataSource.getCurrentRate(employee.id);
        if (currentRate != null) {
          _hourlyRateController.text = currentRate.hourlyRate.toString();
          _rateValidFrom = currentRate.validFrom;
        } else {
          _rateValidFrom = employee.employmentDate;
        }
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Сохранение сотрудника
  Future<void> _saveEmployee() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });
      try {
        final employee = Employee(
          id: widget.employeeId ?? const Uuid().v4(),
          photoUrl: _photoUrl,
          lastName: _lastNameController.text.trim(),
          firstName: _firstNameController.text.trim(),
          middleName: _middleNameController.text.trim().isEmpty
              ? null
              : _middleNameController.text.trim(),
          birthDate: _birthDate,
          birthPlace: _birthPlaceController.text.trim().isEmpty
              ? null
              : _birthPlaceController.text.trim(),
          citizenship: _citizenshipController.text.trim().isEmpty
              ? null
              : _citizenshipController.text.trim(),
          phone: _phoneController.text.trim().isEmpty
              ? null
              : _phoneController.text.trim(),
          clothingSize: _selectedClothingSize,
          shoeSize: _selectedShoeSize,
          height: _selectedHeight,
          passportSeries: _passportSeriesController.text.trim().isEmpty
              ? null
              : _passportSeriesController.text.trim(),
          passportNumber: _passportNumberController.text.trim().isEmpty
              ? null
              : _passportNumberController.text.trim(),
          passportIssuedBy: _passportIssuedByController.text.trim().isEmpty
              ? null
              : _passportIssuedByController.text.trim(),
          passportIssueDate: _passportIssueDate,
          passportDepartmentCode:
              _passportDepartmentCodeController.text.trim().isEmpty
                  ? null
                  : _passportDepartmentCodeController.text.trim(),
          registrationAddress:
              _registrationAddressController.text.trim().isEmpty
                  ? null
                  : _registrationAddressController.text.trim(),
          inn: _innController.text.trim().isEmpty
              ? null
              : _innController.text.trim(),
          snils: _snilsController.text.trim().isEmpty
              ? null
              : _snilsController.text.trim(),
          position: _selectedPosition,
          employmentDate: _employmentDate,
          employmentType: _employmentType,
          objectIds: _selectedObjectIds,
          status: _status,
        );

        final newRate = _hourlyRateController.text.trim().isEmpty
            ? null
            : double.tryParse(_hourlyRateController.text.trim());

        if (_isNewEmployee) {
          // Создаем нового сотрудника
          await ref
              .read(employee_state.employeeProvider.notifier)
              .createEmployee(employee);

          // Если указана ставка, создаём запись в employee_rates
          if (newRate != null && newRate > 0) {
            final setRateUseCase = ref.read(setEmployeeRateUseCaseProvider);
            final validFrom = _rateValidFrom ?? DateTime.now();
            await setRateUseCase(employee.id, newRate, validFrom);
          }

          if (mounted) {
            SnackBarUtils.showSuccess(
              context,
              'Сотрудник успешно создан',
            );
          }
        } else {
          // Проверяем, изменилась ли ставка
          final rateDataSource = ref.read(employeeRateDataSourceProvider);
          final currentRate = await rateDataSource.getCurrentRate(employee.id);
          final oldRate = currentRate?.hourlyRate;
          final rateChanged = (oldRate != newRate);

          // Обновляем существующего сотрудника
          await ref
              .read(employee_state.employeeProvider.notifier)
              .updateEmployee(employee);

          // Если ставка изменилась, создаём новую запись в employee_rates
          if (rateChanged && newRate != null && newRate > 0) {
            final setRateUseCase = ref.read(setEmployeeRateUseCaseProvider);
            final validFrom = _rateValidFrom ?? DateTime.now();
            await setRateUseCase(employee.id, newRate, validFrom);
          }

          if (mounted) {
            SnackBarUtils.showInfo(
              context,
              'Изменения успешно сохранены',
            );
          }
        }

        // Закрываем модальное окно
        if (mounted) {
          Navigator.pop(context);

          // Обновляем данные на экране деталей
          if (!_isNewEmployee) {
            ref
                .read(employee_state.employeeProvider.notifier)
                .getEmployee(employee.id);
          }
        }
      } catch (e) {
        // Показываем ошибку
        if (mounted) {
          SnackBarUtils.showError(
            context,
            'Ошибка: ${e.toString()}',
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  /// Основной build-метод экрана.
  ///
  /// Формирует форму с полями, использует TypeAheadField для выбора типа трудоустройства и статуса.
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surface,
      child: _isLoading
          ? const Center(child: CupertinoActivityIndicator())
          : Stack(
              children: [
                // Основное содержимое
                Column(
                  children: [
                    // Заголовок (закреплен сверху)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        border: Border(
                          bottom: BorderSide(
                            color: theme.colorScheme.outline
                                .withValues(alpha: 0.2),
                            width: 1,
                          ),
                        ),
                      ),
                      child: ModalUtils.buildModalHeader(
                        title: _isNewEmployee
                            ? 'Новый сотрудник'
                            : 'Редактирование сотрудника',
                        onClose: () => Navigator.pop(context),
                        theme: theme,
                      ),
                    ),

                    // Прокручиваемое содержимое
                    Expanded(
                      child: SingleChildScrollView(
                        controller: widget.scrollController,
                        padding: EdgeInsets.fromLTRB(
                          24.0,
                          24.0,
                          24.0,
                          100.0 + MediaQuery.of(context).viewInsets.bottom,
                        ), // Адаптивный отступ снизу для кнопок и клавиатуры
                        child: ModalUtils.buildAdaptiveFormContainer(
                          context: context,
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Фото сотрудника
                                Center(
                                  child: PhotoPickerAvatar(
                                    imageUrl: _photoUrl,
                                    localFile: _photoFile,
                                    label: 'Фото сотрудника',
                                    isLoading: _isLoading,
                                    entity: 'employee',
                                    id: widget.employeeId ?? const Uuid().v4(),
                                    displayName:
                                        ('${_lastNameController.text.trim()} ${_firstNameController.text.trim()} ${_middleNameController.text.trim()}')
                                            .trim(),
                                    onPhotoChanged: (url) {
                                      setState(() {
                                        _photoUrl = url;
                                        _photoFile = null;
                                      });
                                    },
                                    placeholderIcon: Icons.person,
                                    radius: 50,
                                  ),
                                ),
                                const SizedBox(height: 16),

                                // Основная информация
                                FormSectionCard(
                                  title: 'Основная информация',
                                  children: [
                                    // Фамилия (обязательное поле)
                                    FormTextField(
                                      controller: _lastNameController,
                                      labelText: 'Фамилия *',
                                      hintText: 'Введите фамилию',
                                      validator: (value) {
                                        if (value == null ||
                                            value.trim().isEmpty) {
                                          return 'Введите фамилию';
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 16),

                                    // Имя (обязательное поле)
                                    FormTextField(
                                      controller: _firstNameController,
                                      labelText: 'Имя *',
                                      hintText: 'Введите имя',
                                      validator: (value) {
                                        if (value == null ||
                                            value.trim().isEmpty) {
                                          return 'Введите имя';
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 16),

                                    // Отчество (необязательное поле)
                                    FormTextField(
                                      controller: _middleNameController,
                                      labelText: 'Отчество',
                                      hintText: 'Введите отчество',
                                    ),
                                    const SizedBox(height: 16),

                                    // Телефон (необязательное поле)
                                    FormTextField(
                                      controller: _phoneController,
                                      labelText: 'Телефон',
                                      hintText: '+7 (XXX) XXX-XX-XX',
                                      keyboardType: TextInputType.phone,
                                    ),
                                    const SizedBox(height: 16),

                                    // Дата рождения (необязательное поле)
                                    DatePickerField(
                                      date: _birthDate,
                                      labelText: 'Дата рождения',
                                      hintText: 'Выберите дату',
                                      onDateSelected: (date) {
                                        setState(() {
                                          _birthDate = date;
                                        });
                                      },
                                    ),
                                    const SizedBox(height: 16),

                                    // Место рождения (необязательное поле)
                                    FormTextField(
                                      controller: _birthPlaceController,
                                      labelText: 'Место рождения',
                                      hintText: 'Введите место рождения',
                                    ),
                                    const SizedBox(height: 16),

                                    // Гражданство (необязательное поле)
                                    FormTextField(
                                      controller: _citizenshipController,
                                      labelText: 'Гражданство',
                                      hintText: 'Введите гражданство',
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 16),

                                // Физические параметры
                                FormSectionCard(
                                  title: 'Физические параметры',
                                  children: [
                                    // Рост (необязательное поле)
                                    GTStringDropdown(
                                      items: _heightRanges,
                                      selectedItem: _selectedHeight,
                                      onSelectionChanged: (value) {
                                        setState(() {
                                          _selectedHeight = value;
                                        });
                                      },
                                      labelText: 'Рост (см)',
                                      hintText: 'Выберите диапазон роста',
                                      allowCustomInput: false,
                                    ),
                                    const SizedBox(height: 16),

                                    // Размер одежды (необязательное поле)
                                    GTStringDropdown(
                                      items: _clothingSizes,
                                      selectedItem: _selectedClothingSize,
                                      onSelectionChanged: (value) {
                                        setState(() {
                                          _selectedClothingSize = value;
                                        });
                                      },
                                      labelText: 'Размер одежды',
                                      hintText: 'Выберите размер одежды',
                                      allowCustomInput: false,
                                    ),
                                    const SizedBox(height: 16),

                                    // Размер обуви (необязательное поле)
                                    GTStringDropdown(
                                      items: _shoeSizes,
                                      selectedItem: _selectedShoeSize,
                                      onSelectionChanged: (value) {
                                        setState(() {
                                          _selectedShoeSize = value;
                                        });
                                      },
                                      labelText: 'Размер обуви',
                                      hintText: 'Выберите размер обуви',
                                      allowCustomInput: false,
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 16),

                                // Информация о трудоустройстве
                                FormSectionCard(
                                  title: 'Информация о трудоустройстве',
                                  children: [
                                    // Должность (необязательное поле)
                                    _positionsLoading
                                        ? const Padding(
                                            padding: EdgeInsets.symmetric(
                                                vertical: 16),
                                            child: Center(
                                                child:
                                                    CupertinoActivityIndicator()),
                                          )
                                        : GTStringDropdown(
                                            items: _positions,
                                            selectedItem: _selectedPosition,
                                            onSelectionChanged: (value) {
                                              setState(() {
                                                _selectedPosition = value;
                                              });
                                            },
                                            labelText: 'Должность',
                                            hintText:
                                                'Выберите или введите должность',
                                            allowCustomInput: true,
                                            showAddNewOption: true,
                                          ),
                                    const SizedBox(height: 16),

                                    // Дата трудоустройства (необязательное поле)
                                    DatePickerField(
                                      date: _employmentDate,
                                      labelText: 'Дата трудоустройства',
                                      hintText: 'Выберите дату',
                                      onDateSelected: (date) {
                                        setState(() {
                                          _employmentDate = date;
                                        });
                                      },
                                    ),
                                    const SizedBox(height: 16),

                                    // Тип трудоустройства
                                    GTEnumDropdown<EmploymentType>(
                                      values: EmploymentType.values,
                                      selectedValue: _employmentType,
                                      onChanged: (value) {
                                        setState(() {
                                          _employmentType =
                                              value ?? EmploymentType.official;
                                        });
                                      },
                                      enumToString:
                                          EmployeeUIUtils.getEmploymentTypeText,
                                      labelText: 'Тип трудоустройства',
                                      hintText: 'Выберите тип',
                                    ),
                                    const SizedBox(height: 16),

                                    // Ставка (необязательное поле)
                                    FormTextField(
                                      controller: _hourlyRateController,
                                      labelText: 'Ставка (руб/час)',
                                      hintText: 'Введите почасовую ставку',
                                      keyboardType: TextInputType.number,
                                      validator: (value) {
                                        if (value != null &&
                                            value.trim().isNotEmpty) {
                                          if (double.tryParse(value.trim()) ==
                                              null) {
                                            return 'Введите корректное числовое значение';
                                          }
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 16),

                                    // Дата начала действия ставки
                                    DatePickerField(
                                      date: _rateValidFrom,
                                      labelText: 'Дата начала действия ставки',
                                      hintText: 'Выберите дату',
                                      onDateSelected: (date) {
                                        setState(() {
                                          _rateValidFrom = date;
                                        });
                                      },
                                    ),

                                    // Объекты и статус сотрудника
                                    Consumer(
                                      builder: (context, ref, _) {
                                        final objectState =
                                            ref.watch(objectProvider);
                                        final objects = objectState.objects;
                                        final objectNames =
                                            objects.map((o) => o.name).toList();
                                        final selectedObjectNames = objects
                                            .where((obj) => _selectedObjectIds
                                                .contains(obj.id))
                                            .map((obj) => obj.name)
                                            .toList();

                                        Widget objectMultiSelectField =
                                            GTStringDropdown(
                                          items: objectNames,
                                          selectedItems: selectedObjectNames,
                                          onMultiSelectionChanged:
                                              (selectedNames) {
                                            setState(() {
                                              _selectedObjectIds = objects
                                                  .where((obj) => selectedNames
                                                      .contains(obj.name))
                                                  .map((obj) => obj.id)
                                                  .toList();
                                            });
                                          },
                                          labelText: 'Объекты',
                                          hintText: 'Выберите объекты',
                                          allowMultipleSelection: true,
                                          allowCustomInput: false,
                                        );
                                        return Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const SizedBox(height: 8),
                                            objectMultiSelectField,
                                            const SizedBox(height: 16),

                                            // Статус сотрудника
                                            GTEnumDropdown<EmployeeStatus>(
                                              values: EmployeeStatus.values,
                                              selectedValue: _status,
                                              onChanged: (value) {
                                                setState(() {
                                                  _status = value ??
                                                      EmployeeStatus.working;
                                                });
                                              },
                                              enumToString: (status) =>
                                                  EmployeeUIUtils.getStatusInfo(
                                                          status)
                                                      .$1,
                                              labelText: 'Статус сотрудника',
                                              hintText: 'Выберите статус',
                                            ),
                                          ],
                                        );
                                      },
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 16),

                                // Документы
                                FormSectionCard(
                                  title: 'Документы',
                                  children: [
                                    // Серия паспорта
                                    FormTextField(
                                      controller: _passportSeriesController,
                                      labelText: 'Серия паспорта',
                                      hintText: 'Введите серию',
                                    ),
                                    const SizedBox(height: 16),

                                    // Номер паспорта
                                    FormTextField(
                                      controller: _passportNumberController,
                                      labelText: 'Номер паспорта',
                                      hintText: 'Введите номер',
                                    ),
                                    const SizedBox(height: 16),

                                    // Кем выдан
                                    FormTextField(
                                      controller: _passportIssuedByController,
                                      labelText: 'Кем выдан',
                                      hintText: 'Введите орган выдачи',
                                    ),
                                    const SizedBox(height: 16),

                                    // Дата выдачи
                                    DatePickerField(
                                      date: _passportIssueDate,
                                      labelText: 'Дата выдачи',
                                      hintText: 'Выберите дату',
                                      onDateSelected: (date) {
                                        setState(() {
                                          _passportIssueDate = date;
                                        });
                                      },
                                    ),
                                    const SizedBox(height: 16),

                                    // Код подразделения
                                    FormTextField(
                                      controller:
                                          _passportDepartmentCodeController,
                                      labelText: 'Код подразделения',
                                      hintText: 'Введите код',
                                    ),
                                    const SizedBox(height: 16),

                                    // Адрес регистрации
                                    FormTextField(
                                      controller:
                                          _registrationAddressController,
                                      labelText: 'Адрес регистрации',
                                      hintText: 'Введите адрес',
                                    ),
                                    const SizedBox(height: 16),

                                    // ИНН
                                    FormTextField(
                                      controller: _innController,
                                      labelText: 'ИНН',
                                      hintText: 'Введите ИНН',
                                    ),
                                    const SizedBox(height: 16),

                                    // СНИЛС
                                    FormTextField(
                                      controller: _snilsController,
                                      labelText: 'СНИЛС',
                                      hintText: 'Введите СНИЛС',
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 24),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                // Кнопки управления (плавающие снизу)
                ModalUtils.buildFloatingButtons(
                  onSave: _saveEmployee,
                  onCancel: () => Navigator.pop(context),
                  isLoading: _isLoading,
                  saveText: _isNewEmployee ? 'Создать' : 'Сохранить',
                ),
              ],
            ),
    );
  }

  Future<void> _loadPositions() async {
    setState(() => _positionsLoading = true);
    try {
      final positions =
          await ref.read(employeeRepositoryProvider).getPositions();
      setState(() {
        _positions = positions;
        _positionsLoading = false;
      });
    } catch (e) {
      setState(() => _positionsLoading = false);
      if (mounted) {
        SnackBarUtils.showError(context, 'Ошибка загрузки должностей');
      }
    }
  }
}
