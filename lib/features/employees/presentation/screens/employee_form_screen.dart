import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:dropdown_textfield/dropdown_textfield.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';

import 'package:projectgt/core/di/providers.dart';
import 'package:projectgt/core/utils/employee_ui_utils.dart';
import 'package:projectgt/core/utils/notifications_service.dart';
import 'package:projectgt/core/widgets/dropdown_typeahead_field.dart';

import 'package:projectgt/domain/entities/employee.dart';
import 'package:projectgt/domain/entities/object.dart';

import 'package:projectgt/presentation/state/employee_state.dart' as employee_state;
import 'package:projectgt/presentation/widgets/photo_picker_avatar.dart';

import 'package:projectgt/features/employees/presentation/widgets/form_widgets.dart';

/// Экран создания/редактирования сотрудника.
/// 
/// Позволяет добавлять и изменять данные сотрудника, включая тип трудоустройства и статус.
/// Использует Clean Architecture, Riverpod, TypeAheadField для UX.
class EmployeeFormScreen extends ConsumerStatefulWidget {
  /// [employeeId] — если null, создаётся новый сотрудник, иначе — редактирование.
  const EmployeeFormScreen({super.key, this.employeeId});

  /// Идентификатор сотрудника для редактирования (null — новый сотрудник).
  final String? employeeId;

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
  final _clothingSizeController = TextEditingController();
  final _shoeSizeController = TextEditingController();
  final _heightController = TextEditingController();
  
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
  
  // Состояния
  EmployeeStatus _status = EmployeeStatus.working;
  EmploymentType _employmentType = EmploymentType.official;
  late final MultiValueDropDownController _objectController;
  late final SingleValueDropDownController _employmentTypeController;
  late final SingleValueDropDownController _employeeStatusController;
  late final TextEditingController _positionTextController;
  late final TextEditingController _employmentTypeTextController;
  late final TextEditingController _employeeStatusTextController;
  List<String> _selectedObjectIds = [];
  String? _selectedPosition;
  List<String> _positions = [];
  bool _positionsLoading = false;

  /// Инициализация состояния и контроллеров.
  @override
  void initState() {
    super.initState();
    _isNewEmployee = widget.employeeId == null;
    _objectController = MultiValueDropDownController();
    _employmentTypeController = SingleValueDropDownController(
      data: DropDownValueModel(
        name: EmployeeUIUtils.getEmploymentTypeText(_employmentType),
        value: _employmentType,
      ),
    );
    _employeeStatusController = SingleValueDropDownController(
      data: DropDownValueModel(
        name: EmployeeUIUtils.getStatusInfo(_status).$1,
        value: _status,
      ),
    );
    _positionTextController = TextEditingController();
    _employmentTypeTextController = TextEditingController(
      text: EmployeeUIUtils.getEmploymentTypeText(_employmentType),
    );
    _employeeStatusTextController = TextEditingController(
      text: EmployeeUIUtils.getStatusInfo(_status).$1,
    );
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
    _clothingSizeController.dispose();
    _shoeSizeController.dispose();
    _heightController.dispose();
    _passportSeriesController.dispose();
    _passportNumberController.dispose();
    _passportIssuedByController.dispose();
    _passportDepartmentCodeController.dispose();
    _registrationAddressController.dispose();
    _innController.dispose();
    _snilsController.dispose();
    _hourlyRateController.dispose();
    _objectController.dispose();
    _employmentTypeController.dispose();
    _employeeStatusController.dispose();
    _positionTextController.dispose();
    _employmentTypeTextController.dispose();
    _employeeStatusTextController.dispose();
    super.dispose();
  }

  /// Загрузка данных сотрудника для редактирования.
  Future<void> _loadEmployeeData() async {
    if (widget.employeeId != null) {
      setState(() {
        _isLoading = true;
      });
      await ref.read(employee_state.employeeProvider.notifier).getEmployee(widget.employeeId!);
      final employeeState = ref.read(employee_state.employeeProvider);
      final employee = employeeState.employee;
      final objects = ref.read(objectProvider).objects;
      if (employee != null) {
        _lastNameController.text = employee.lastName;
        _firstNameController.text = employee.firstName;
        _middleNameController.text = employee.middleName ?? '';
        _phoneController.text = employee.phone ?? '';
        _birthPlaceController.text = employee.birthPlace ?? '';
        _citizenshipController.text = employee.citizenship ?? '';
        _clothingSizeController.text = employee.clothingSize ?? '';
        _shoeSizeController.text = employee.shoeSize ?? '';
        _heightController.text = employee.height ?? '';
        _passportSeriesController.text = employee.passportSeries ?? '';
        _passportNumberController.text = employee.passportNumber ?? '';
        _passportIssuedByController.text = employee.passportIssuedBy ?? '';
        _passportDepartmentCodeController.text = employee.passportDepartmentCode ?? '';
        _registrationAddressController.text = employee.registrationAddress ?? '';
        _innController.text = employee.inn ?? '';
        _snilsController.text = employee.snils ?? '';
        _selectedPosition = employee.position;
        _selectedObjectIds = List<String>.from(employee.objectIds);
        _objectController.setDropDown(
          employee.objectIds
            .map((id) => DropDownValueModel(
              name: objects.firstWhere((o) => o.id == id, orElse: () => const ObjectEntity(id: '', name: '—', address: '')).name,
              value: id,
            ))
            .toList(),
        );
        _employmentType = employee.employmentType;
        _employmentTypeController.setDropDown(
          DropDownValueModel(
            name: EmployeeUIUtils.getEmploymentTypeText(employee.employmentType),
            value: employee.employmentType,
          ),
        );
        _status = employee.status;
        _employeeStatusController.setDropDown(
          DropDownValueModel(
            name: EmployeeUIUtils.getStatusInfo(employee.status).$1,
            value: employee.status,
          ),
        );
        if (_selectedPosition != null && _selectedPosition!.isNotEmpty) {
          _positionTextController.text = _selectedPosition!;
        }
        setState(() {
          _photoUrl = employee.photoUrl;
          _photoFile = null;
          _birthDate = employee.birthDate;
          _passportIssueDate = employee.passportIssueDate;
          _employmentDate = employee.employmentDate;
          _employmentTypeTextController.text = EmployeeUIUtils.getEmploymentTypeText(employee.employmentType);
          _employeeStatusTextController.text = EmployeeUIUtils.getStatusInfo(employee.status).$1;
          _isLoading = false;
        });
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
          middleName: _middleNameController.text.trim().isEmpty ? null : _middleNameController.text.trim(),
          birthDate: _birthDate,
          birthPlace: _birthPlaceController.text.trim().isEmpty ? null : _birthPlaceController.text.trim(),
          citizenship: _citizenshipController.text.trim().isEmpty ? null : _citizenshipController.text.trim(),
          phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
          clothingSize: _clothingSizeController.text.trim().isEmpty ? null : _clothingSizeController.text.trim(),
          shoeSize: _shoeSizeController.text.trim().isEmpty ? null : _shoeSizeController.text.trim(),
          height: _heightController.text.trim().isEmpty ? null : _heightController.text.trim(),
          passportSeries: _passportSeriesController.text.trim().isEmpty ? null : _passportSeriesController.text.trim(),
          passportNumber: _passportNumberController.text.trim().isEmpty ? null : _passportNumberController.text.trim(),
          passportIssuedBy: _passportIssuedByController.text.trim().isEmpty ? null : _passportIssuedByController.text.trim(),
          passportIssueDate: _passportIssueDate,
          passportDepartmentCode: _passportDepartmentCodeController.text.trim().isEmpty ? null : _passportDepartmentCodeController.text.trim(),
          registrationAddress: _registrationAddressController.text.trim().isEmpty ? null : _registrationAddressController.text.trim(),
          inn: _innController.text.trim().isEmpty ? null : _innController.text.trim(),
          snils: _snilsController.text.trim().isEmpty ? null : _snilsController.text.trim(),
          position: _selectedPosition,
          employmentDate: _employmentDate,
          employmentType: _employmentType,
          hourlyRate: _hourlyRateController.text.trim().isEmpty ? null : double.parse(_hourlyRateController.text.trim()),
          objectIds: _selectedObjectIds,
          status: _status,
        );
        
        if (_isNewEmployee) {
          // Создаем нового сотрудника
          await ref.read(employee_state.employeeProvider.notifier).createEmployee(employee);
          if (mounted) {
            NotificationsService.showSuccessNotification(
              context,
              'Сотрудник успешно создан',
            );
          }
        } else {
          // Обновляем существующего сотрудника
          await ref.read(employee_state.employeeProvider.notifier).updateEmployee(employee);
          if (mounted) {
            NotificationsService.showInfoNotification(
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
            ref.read(employee_state.employeeProvider.notifier).getEmployee(employee.id);
          }
        }
      } catch (e) {
        // Показываем ошибку
        if (mounted) {
          NotificationsService.showErrorNotification(
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
          ? const Center(child: CircularProgressIndicator())
          : Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 700),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Заголовок
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16.0),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  _isNewEmployee ? 'Новый сотрудник' : 'Редактирование сотрудника',
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close),
                                style: IconButton.styleFrom(
                                  foregroundColor: Colors.red,
                                ),
                                onPressed: () => Navigator.pop(context),
                              ),
                            ],
                          ),
                        ),
                        const Divider(),
                        // Фото сотрудника
                        Center(
                          child: PhotoPickerAvatar(
                            imageUrl: _photoUrl,
                            localFile: _photoFile,
                            label: 'Фото сотрудника',
                            isLoading: _isLoading,
                            entity: 'employee',
                            id: widget.employeeId ?? const Uuid().v4(),
                            displayName: ('${_lastNameController.text.trim()} ${_firstNameController.text.trim()} ${_middleNameController.text.trim()}').trim(),
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
                                if (value == null || value.trim().isEmpty) {
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
                                if (value == null || value.trim().isEmpty) {
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
                            FormTextField(
                              controller: _heightController,
                              labelText: 'Рост',
                              hintText: 'Введите рост в см',
                              keyboardType: TextInputType.number,
                            ),
                            const SizedBox(height: 16),
                            
                            // Размер одежды (необязательное поле)
                            FormTextField(
                              controller: _clothingSizeController,
                              labelText: 'Размер одежды',
                              hintText: 'Например: M, L, XL',
                            ),
                            const SizedBox(height: 16),
                            
                            // Размер обуви (необязательное поле)
                            FormTextField(
                              controller: _shoeSizeController,
                              labelText: 'Размер обуви',
                              hintText: 'Например: 40, 41, 42',
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
                                    padding: EdgeInsets.symmetric(vertical: 16),
                                    child: Center(child: CircularProgressIndicator()),
                                  )
                                : TypeAheadField<String>(
                                    controller: _positionTextController,
                                    suggestionsCallback: (pattern) {
                                      return _positions.where((p) => p.toLowerCase().contains(pattern.toLowerCase())).toList();
                                    },
                                    builder: (context, controller, focusNode) {
                                      return TextFormField(
                                        controller: controller,
                                        focusNode: focusNode,
                                        decoration: const InputDecoration(
                                          labelText: 'Должность',
                                          hintText: 'Выберите или введите должность',
                                          border: OutlineInputBorder(),
                                        ),
                                      );
                                    },
                                    itemBuilder: (context, suggestion) {
                                      return ListTile(
                                        title: Text(suggestion),
                                      );
                                    },
                                    onSelected: (suggestion) {
                                      setState(() {
                                        _positionTextController.text = suggestion;
                                        _selectedPosition = suggestion;
                                      });
                                    },
                                    emptyBuilder: (context) {
                                      final input = _positionTextController.text.trim();
                                      if (input.isEmpty) return const SizedBox();
                                      return ListTile(
                                        title: Text('Добавить новую должность: "$input"'),
                                        onTap: () {
                                          setState(() {
                                            _selectedPosition = input;
                                            _positionTextController.text = input;
                                          });
                                          FocusScope.of(context).unfocus();
                                        },
                                      );
                                    },
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
                            EnumDropdownTypeAheadField<EmploymentType>(
                              controller: _employmentTypeTextController,
                              values: EmploymentType.values,
                              textConverter: EmployeeUIUtils.getEmploymentTypeText,
                              labelText: 'Тип трудоустройства',
                              hintText: 'Выберите тип',
                              onSelected: (suggestion) {
                                setState(() {
                                  _employmentType = suggestion;
                                  _employmentTypeTextController.text = EmployeeUIUtils.getEmploymentTypeText(suggestion);
                                });
                              },
                            ),
                            const SizedBox(height: 16),
                            
                            // Ставка (необязательное поле)
                            FormTextField(
                              controller: _hourlyRateController,
                              labelText: 'Ставка (руб/час)',
                              hintText: 'Введите почасовую ставку',
                              keyboardType: TextInputType.number,
                            ),
                            const SizedBox(height: 16),
                            
                            // Объекты и статус сотрудника
                            Consumer(
                              builder: (context, ref, _) {
                                final objectState = ref.watch(objectProvider);
                                final objects = objectState.objects;
                                final objectDropDownList = objects
                                    .map((o) => DropDownValueModel(name: o.name, value: o.id))
                                    .toList();

                                Widget objectMultiSelectField = DropDownTextField.multiSelection(
                                  controller: _objectController,
                                  dropDownList: objectDropDownList,
                                  submitButtonText: 'Выбрать',
                                  submitButtonColor: Colors.amber,
                                  checkBoxProperty: CheckBoxProperty(
                                    fillColor: WidgetStateProperty.all<Color>(Colors.green),
                                  ),
                                  displayCompleteItem: true,
                                  textFieldDecoration: const InputDecoration(
                                    labelText: 'Объекты',
                                    hintText: 'Выберите объекты',
                                    border: OutlineInputBorder(),
                                  ),
                                  listTextStyle: const TextStyle(color: Colors.black),
                                  onChanged: (val) {
                                    setState(() {
                                      final list = val is List<DropDownValueModel>
                                          ? val
                                          : List<DropDownValueModel>.from(val);
                                      _selectedObjectIds = list.map((e) => e.value.toString()).toList();
                                    });
                                  },
                                );
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 8),
                                    objectMultiSelectField,
                                    const SizedBox(height: 16),
                                    
                                    // Статус сотрудника
                                    EnumDropdownTypeAheadField<EmployeeStatus>(
                                      controller: _employeeStatusTextController,
                                      values: EmployeeStatus.values,
                                      textConverter: (status) => EmployeeUIUtils.getStatusInfo(status).$1,
                                      labelText: 'Статус сотрудника',
                                      hintText: 'Выберите статус',
                                      onSelected: (suggestion) {
                                        setState(() {
                                          _status = suggestion;
                                          _employeeStatusTextController.text = EmployeeUIUtils.getStatusInfo(suggestion).$1;
                                        });
                                      },
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
                              controller: _passportDepartmentCodeController,
                              labelText: 'Код подразделения',
                              hintText: 'Введите код',
                            ),
                            const SizedBox(height: 16),
                            
                            // Адрес регистрации
                            FormTextField(
                              controller: _registrationAddressController,
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

                        // Кнопки управления
                        FormButtons(
                          onSave: _saveEmployee,
                          onCancel: () => Navigator.pop(context),
                          isLoading: _isLoading,
                          saveText: _isNewEmployee ? 'Создать' : 'Сохранить',
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  Future<void> _loadPositions() async {
    setState(() => _positionsLoading = true);
    try {
      final positions = await ref.read(employeeRepositoryProvider).getPositions();
      setState(() {
        _positions = positions;
        _positionsLoading = false;
      });
    } catch (e) {
      setState(() => _positionsLoading = false);
      if (mounted) {
        NotificationsService.showErrorNotification(context, 'Ошибка загрузки должностей');
      }
    }
  }
}