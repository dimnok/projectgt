import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:projectgt/core/utils/formatters.dart';
import 'package:projectgt/core/utils/employee_ui_utils.dart';
import 'package:projectgt/core/utils/snackbar_utils.dart';
import 'package:projectgt/core/widgets/gt_dropdown.dart';
import 'package:projectgt/domain/entities/employee.dart';
import 'package:projectgt/features/objects/domain/entities/object.dart';
import 'package:projectgt/features/employees/presentation/widgets/editable_inline_text_row.dart';
import 'package:projectgt/presentation/state/employee_state.dart' as employee_state;
import 'package:projectgt/core/di/providers.dart';

/// Виджет формы редактирования данных сотрудника.
class EmployeeEditForm extends ConsumerStatefulWidget {
  /// Сотрудник для редактирования.
  final Employee employee;
  
  /// Список доступных объектов для привязки.
  final List<ObjectEntity> objects;
  
  /// Callback для отмены редактирования.
  final VoidCallback onCancel;
  
  /// Callback для сохранения изменений.
  final Function(Employee) onSaved;

  /// Конструктор виджета.
  const EmployeeEditForm({
    super.key,
    required this.employee,
    required this.objects,
    required this.onCancel,
    required this.onSaved,
  });

  @override
  ConsumerState<EmployeeEditForm> createState() => _EmployeeEditFormState();
}

class _EmployeeEditFormState extends ConsumerState<EmployeeEditForm> {
  bool _isLoading = false;
  bool _hasChanges = false;
  late Employee _employee;

  // Контроллеры для личных данных
  late TextEditingController _lastNameController;
  late TextEditingController _firstNameController;
  late TextEditingController _middleNameController;
  late TextEditingController _birthPlaceController;
  late TextEditingController _citizenshipController;
  late TextEditingController _registrationAddressController;
  late TextEditingController _passportSeriesController;
  late TextEditingController _passportNumberController;
  late TextEditingController _passportIssuedByController;
  late TextEditingController _passportDepartmentCodeController;
  late TextEditingController _innController;
  late TextEditingController _snilsController;

  // Контроллеры для рабочих данных
  late TextEditingController _positionController;
  late TextEditingController _phoneController;
  EmployeeStatus? _status;
  EmploymentType? _employmentType;
  DateTime? _employmentDate;

  // Даты и размеры
  DateTime? _birthDate;
  DateTime? _passportIssueDate;
  String? _clothingSize;
  String? _shoeSize;
  String? _height;
  List<String> _objectIds = [];

  static const List<String> _clothingSizes = [
    '40-42(S)', '44-46(M)', '48-50(L)', '50-52(XL)', '54-56(2XL)', '56-58(3XL)', '60-62(4XL)', '64-66(5XL)',
  ];
  static const List<String> _shoeSizes = [
    '36', '37', '38', '39', '40', '41', '42', '43', '44', '45', '46', '47', '48',
  ];
  static const List<String> _heightRanges = [
    '150-160', '160-170', '170-180', '180-190', '190-200',
  ];

  List<String> _positions = [];
  bool _positionsLoading = false;

  @override
  void initState() {
    super.initState();
    _initControllers(widget.employee);
    _loadPositions();
  }

  @override
  void didUpdateWidget(covariant EmployeeEditForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.employee.id != oldWidget.employee.id) {
      _initControllers(widget.employee);
      return;
    }
    // Фото меняется в шапке через [EmployeeAvatarController], не через поля формы.
    // Без синхронизации [_employee.photoUrl] при «Сохранить» уходит старый snapshot (часто null)
    // и перезаписывает photo_url в БД.
    if (widget.employee.photoUrl != _employee.photoUrl) {
      _employee = _employee.copyWith(photoUrl: widget.employee.photoUrl);
    }
  }

  Future<void> _loadPositions() async {
    setState(() => _positionsLoading = true);
    try {
      final positions = await ref.read(employeeRepositoryProvider).getPositions();
      if (mounted) {
        setState(() {
          _positions = positions;
          _positionsLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _positionsLoading = false);
      }
    }
  }

  void _initControllers(Employee emp) {
    _employee = emp;
    _hasChanges = false;

    _lastNameController = TextEditingController(text: emp.lastName);
    _firstNameController = TextEditingController(text: emp.firstName);
    _middleNameController = TextEditingController(text: emp.middleName ?? '');
    _birthPlaceController = TextEditingController(text: emp.birthPlace ?? '');
    _citizenshipController = TextEditingController(text: emp.citizenship ?? '');
    _registrationAddressController = TextEditingController(text: emp.registrationAddress ?? '');
    _passportSeriesController = TextEditingController(text: emp.passportSeries ?? '');
    _passportNumberController = TextEditingController(text: emp.passportNumber ?? '');
    _passportIssuedByController = TextEditingController(text: emp.passportIssuedBy ?? '');
    _passportDepartmentCodeController = TextEditingController(
      text: emp.passportDepartmentCode == null
          ? ''
          : GtFormatters.formatPassportDepartmentCode(emp.passportDepartmentCode),
    );
    _innController = TextEditingController(text: emp.inn ?? '');
    _snilsController = TextEditingController(text: emp.snils ?? '');
    _positionController = TextEditingController(text: emp.position ?? '');
    _phoneController = TextEditingController(text: emp.phone ?? '');

    _birthDate = emp.birthDate;
    _passportIssueDate = emp.passportIssueDate;
    _clothingSize = emp.clothingSize;
    _shoeSize = emp.shoeSize;
    _height = emp.height;
    _status = emp.status;
    _employmentType = emp.employmentType;
    _employmentDate = emp.employmentDate;
    _objectIds = List<String>.from(emp.objectIds);
  }

  void _checkForChanges() {
    bool isStringChanged(String? original, String current) {
      final orig = original?.trim() ?? '';
      final curr = current.trim();
      return orig != curr;
    }

    bool isDigitsChanged(String? original, String current) {
      final orig = original?.replaceAll(RegExp(r'\D'), '') ?? '';
      final curr = current.replaceAll(RegExp(r'\D'), '');
      return orig != curr;
    }

    bool isListChanged(List<String> original, List<String> current) {
      if (original.length != current.length) return true;
      for (int i = 0; i < original.length; i++) {
        if (original[i] != current[i]) return true;
      }
      return false;
    }

    final hasChanges =
        isStringChanged(_employee.lastName, _lastNameController.text) ||
        isStringChanged(_employee.firstName, _firstNameController.text) ||
        isStringChanged(_employee.middleName, _middleNameController.text) ||
        isStringChanged(_employee.birthPlace, _birthPlaceController.text) ||
        isStringChanged(_employee.citizenship, _citizenshipController.text) ||
        isStringChanged(_employee.registrationAddress, _registrationAddressController.text) ||
        isStringChanged(_employee.passportSeries, _passportSeriesController.text) ||
        isStringChanged(_employee.passportNumber, _passportNumberController.text) ||
        isStringChanged(_employee.passportIssuedBy, _passportIssuedByController.text) ||
        isDigitsChanged(_employee.passportDepartmentCode, _passportDepartmentCodeController.text) ||
        isDigitsChanged(_employee.inn, _innController.text) ||
        isDigitsChanged(_employee.snils, _snilsController.text) ||
        isStringChanged(_employee.position, _positionController.text) ||
        isStringChanged(_employee.phone, _phoneController.text) ||
        _birthDate != _employee.birthDate ||
        _passportIssueDate != _employee.passportIssueDate ||
        _clothingSize != _employee.clothingSize ||
        _shoeSize != _employee.shoeSize ||
        _height != _employee.height ||
        _status != _employee.status ||
        _employmentType != _employee.employmentType ||
        _employmentDate != _employee.employmentDate ||
        isListChanged(_employee.objectIds, _objectIds);

    if (_hasChanges != hasChanges) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _hasChanges = hasChanges;
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _lastNameController.dispose();
    _firstNameController.dispose();
    _middleNameController.dispose();
    _birthPlaceController.dispose();
    _citizenshipController.dispose();
    _registrationAddressController.dispose();
    _passportSeriesController.dispose();
    _passportNumberController.dispose();
    _passportIssuedByController.dispose();
    _passportDepartmentCodeController.dispose();
    _innController.dispose();
    _snilsController.dispose();
    _positionController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    setState(() => _isLoading = true);

    try {
      final latestFromProvider = ref
          .read(employee_state.employeeProvider)
          .employees
          .where((e) => e.id == _employee.id)
          .firstOrNull;
      final photoUrlToPersist =
          latestFromProvider?.photoUrl ?? _employee.photoUrl;

      final updatedEmployee = _employee.copyWith(
        photoUrl: photoUrlToPersist,
        lastName: _lastNameController.text.trim(),
        firstName: _firstNameController.text.trim(),
        middleName: _middleNameController.text.trim().isEmpty ? null : _middleNameController.text.trim(),
        birthPlace: _birthPlaceController.text.trim().isEmpty ? null : _birthPlaceController.text.trim(),
        citizenship: _citizenshipController.text.trim().isEmpty ? null : _citizenshipController.text.trim(),
        registrationAddress: _registrationAddressController.text.trim().isEmpty ? null : _registrationAddressController.text.trim(),
        passportSeries: _passportSeriesController.text.trim().isEmpty ? null : _passportSeriesController.text.trim(),
        passportNumber: _passportNumberController.text.trim().isEmpty ? null : _passportNumberController.text.trim(),
        passportIssuedBy: _passportIssuedByController.text.trim().isEmpty ? null : _passportIssuedByController.text.trim(),
        passportDepartmentCode: _passportDepartmentCodeController.text.replaceAll(RegExp(r'\D'), '').trim().isEmpty
            ? null
            : _passportDepartmentCodeController.text.replaceAll(RegExp(r'\D'), '').trim(),
        inn: _innController.text.replaceAll(RegExp(r'\D'), '').trim().isEmpty
            ? null
            : _innController.text.replaceAll(RegExp(r'\D'), '').trim(),
        snils: _snilsController.text.replaceAll(RegExp(r'\D'), '').trim().isEmpty
            ? null
            : _snilsController.text.replaceAll(RegExp(r'\D'), '').trim(),
        position: _positionController.text.trim().isEmpty ? null : _positionController.text.trim(),
        phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
        status: _status ?? EmployeeStatus.working,
        employmentType: _employmentType ?? EmploymentType.official,
        employmentDate: _employmentDate,
        birthDate: _birthDate,
        passportIssueDate: _passportIssueDate,
        clothingSize: _clothingSize,
        shoeSize: _shoeSize,
        height: _height,
        objectIds: _objectIds,
      );

      await ref.read(employee_state.employeeProvider.notifier).updateEmployee(updatedEmployee);

      if (mounted) {
        SnackBarUtils.showSuccess(context, 'Данные сохранены');
        widget.onSaved(updatedEmployee);
      }
    } catch (e) {
      if (mounted) {
        SnackBarUtils.showError(context, 'Ошибка при сохранении: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Widget _buildDivider() {
    return const Divider(height: 1, thickness: 1);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Данные сотрудника',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Row(
              children: [
                SizedBox(
                  height: 32,
                  child: TextButton(
                    onPressed: _isLoading ? null : widget.onCancel,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'Отмена',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  height: 32,
                  child: ElevatedButton(
                    onPressed: (_isLoading || !_hasChanges) ? null : _saveChanges,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Сохранить',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: theme.colorScheme.primary.withValues(alpha: 0.5),
            ),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Expanded(
                      flex: 2,
                      child: Text(
                        'ФИО',
                        style: TextStyle(
                          color: Colors.grey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 5,
                      child: Row(
                        children: [
                          Expanded(
                            child: SizedBox(
                              height: 32,
                              child: TextField(
                                controller: _lastNameController,
                                onChanged: (_) => _checkForChanges(),
                                style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
                                decoration: InputDecoration(
                                  hintText: 'Фамилия',
                                  isDense: true,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(6),
                                    borderSide: BorderSide(color: theme.colorScheme.outline.withValues(alpha: 0.5)),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(6),
                                    borderSide: BorderSide(color: theme.colorScheme.outline.withValues(alpha: 0.5)),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(6),
                                    borderSide: BorderSide(color: theme.colorScheme.primary),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: SizedBox(
                              height: 32,
                              child: TextField(
                                controller: _firstNameController,
                                onChanged: (_) => _checkForChanges(),
                                style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
                                decoration: InputDecoration(
                                  hintText: 'Имя',
                                  isDense: true,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(6),
                                    borderSide: BorderSide(color: theme.colorScheme.outline.withValues(alpha: 0.5)),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(6),
                                    borderSide: BorderSide(color: theme.colorScheme.outline.withValues(alpha: 0.5)),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(6),
                                    borderSide: BorderSide(color: theme.colorScheme.primary),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: SizedBox(
                              height: 32,
                              child: TextField(
                                controller: _middleNameController,
                                onChanged: (_) => _checkForChanges(),
                                style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
                                decoration: InputDecoration(
                                  hintText: 'Отчество',
                                  isDense: true,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(6),
                                    borderSide: BorderSide(color: theme.colorScheme.outline.withValues(alpha: 0.5)),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(6),
                                    borderSide: BorderSide(color: theme.colorScheme.outline.withValues(alpha: 0.5)),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(6),
                                    borderSide: BorderSide(color: theme.colorScheme.primary),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              _buildDivider(),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Expanded(
                      flex: 2,
                      child: Text(
                        'Работа',
                        style: TextStyle(
                          color: Colors.grey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 5,
                      child: Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: SizedBox(
                              height: 32,
                              child: GTStringDropdown(
                                items: _positions,
                                selectedItem: _positionController.text.isEmpty ? null : _positionController.text,
                                onSelectionChanged: (value) {
                                  setState(() {
                                    _positionController.text = value ?? '';
                                  });
                                  _checkForChanges();
                                },
                                labelText: '',
                                hintText: 'Должность',
                                allowCustomInput: true,
                                showAddNewOption: true,
                                isLoading: _positionsLoading,
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                borderRadius: 6,
                                style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 2,
                            child: SizedBox(
                              height: 32,
                              child: GTEnumDropdown<EmploymentType>(
                                values: EmploymentType.values,
                                selectedValue: _employmentType,
                                onChanged: (v) {
                                  setState(() => _employmentType = v);
                                  _checkForChanges();
                                },
                                enumToString: EmployeeUIUtils.getEmploymentTypeText,
                                labelText: '',
                                hintText: 'Тип',
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                borderRadius: 6,
                                style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 2,
                            child: SizedBox(
                              height: 32,
                              child: GTEnumDropdown<EmployeeStatus>(
                                values: EmployeeStatus.values,
                                selectedValue: _status,
                                onChanged: (v) {
                                  setState(() => _status = v);
                                  _checkForChanges();
                                },
                                enumToString: (status) => EmployeeUIUtils.getStatusInfo(status).$1,
                                labelText: '',
                                hintText: 'Статус',
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                borderRadius: 6,
                                style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              _buildDivider(),
              EditableInlineTextRow(
                label: 'Телефон',
                value: _employee.phone ?? '—',
                isEditing: true,
                controller: _phoneController,
                hintText: 'Введите телефон',
                keyboardType: TextInputType.phone,
                inputFormatters: [GtFormatters.phoneFormatter()],
                onChanged: (_) => _checkForChanges(),
              ),
              _buildDivider(),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Expanded(
                      flex: 2,
                      child: Text(
                        'Объекты и Дата',
                        style: TextStyle(
                          color: Colors.grey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 5,
                      child: Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: SizedBox(
                              height: 32,
                              child: GTDropdown<String>(
                                items: widget.objects.map((e) => e.id).toList(),
                                selectedItems: _objectIds,
                                allowMultipleSelection: true,
                                onMultiSelectionChanged: (items) {
                                  setState(() => _objectIds = items);
                                  _checkForChanges();
                                },
                                itemDisplayBuilder: (id) => widget.objects.firstWhere((o) => o.id == id, orElse: () => const ObjectEntity(id: '', companyId: '', name: '—', address: '')).name,
                                labelText: '',
                                hintText: 'Выберите объекты',
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                borderRadius: 6,
                                style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 2,
                            child: InkWell(
                              onTap: () async {
                                final selected = await showDatePicker(
                                  context: context,
                                  initialDate: _employmentDate ?? DateTime.now(),
                                  firstDate: DateTime(1900),
                                  lastDate: DateTime(2100),
                                );
                                if (selected != null) {
                                  setState(() => _employmentDate = selected);
                                  _checkForChanges();
                                }
                              },
                              child: Container(
                                height: 32,
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: theme.colorScheme.outline.withValues(alpha: 0.5),
                                  ),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                alignment: Alignment.centerLeft,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      _employmentDate != null ? formatRuDate(_employmentDate!) : 'Дата приёма',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w500,
                                        fontSize: 14,
                                        color: _employmentDate != null ? theme.colorScheme.onSurface : theme.colorScheme.onSurface.withValues(alpha: 0.6),
                                      ),
                                    ),
                                    const Icon(
                                      Icons.calendar_today,
                                      size: 16,
                                      color: Colors.grey,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 32, thickness: 2),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Expanded(
                      flex: 2,
                      child: Text(
                        'Паспорт',
                        style: TextStyle(
                          color: Colors.grey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 5,
                      child: Row(
                        children: [
                          Expanded(
                            flex: 1,
                            child: SizedBox(
                              height: 32,
                              child: TextField(
                                controller: _passportSeriesController,
                                onChanged: (_) => _checkForChanges(),
                                style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
                                decoration: InputDecoration(
                                  hintText: 'Серия',
                                  isDense: true,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(6),
                                    borderSide: BorderSide(color: theme.colorScheme.outline.withValues(alpha: 0.5)),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(6),
                                    borderSide: BorderSide(color: theme.colorScheme.outline.withValues(alpha: 0.5)),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 2,
                            child: SizedBox(
                              height: 32,
                              child: TextField(
                                controller: _passportNumberController,
                                onChanged: (_) => _checkForChanges(),
                                style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
                                decoration: InputDecoration(
                                  hintText: 'Номер',
                                  isDense: true,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(6),
                                    borderSide: BorderSide(color: theme.colorScheme.outline.withValues(alpha: 0.5)),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(6),
                                    borderSide: BorderSide(color: theme.colorScheme.outline.withValues(alpha: 0.5)),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 2,
                            child: SizedBox(
                              height: 32,
                              child: TextField(
                                controller: _citizenshipController,
                                onChanged: (_) => _checkForChanges(),
                                style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
                                decoration: InputDecoration(
                                  hintText: 'Гражданство',
                                  isDense: true,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(6),
                                    borderSide: BorderSide(color: theme.colorScheme.outline.withValues(alpha: 0.5)),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(6),
                                    borderSide: BorderSide(color: theme.colorScheme.outline.withValues(alpha: 0.5)),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              _buildDivider(),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Expanded(
                      flex: 2,
                      child: Text(
                        'Выдан',
                        style: TextStyle(
                          color: Colors.grey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 5,
                      child: Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: InkWell(
                              onTap: () async {
                                final selected = await showDatePicker(
                                  context: context,
                                  initialDate: _passportIssueDate ?? DateTime.now(),
                                  firstDate: DateTime(1900),
                                  lastDate: DateTime.now(),
                                );
                                if (selected != null) {
                                  setState(() => _passportIssueDate = selected);
                                  _checkForChanges();
                                }
                              },
                              child: Container(
                                height: 32,
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: theme.colorScheme.outline.withValues(alpha: 0.5),
                                  ),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                alignment: Alignment.centerLeft,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      _passportIssueDate != null ? formatRuDate(_passportIssueDate!) : 'Дата выдачи',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w500,
                                        fontSize: 14,
                                        color: _passportIssueDate != null ? theme.colorScheme.onSurface : theme.colorScheme.onSurface.withValues(alpha: 0.6),
                                      ),
                                    ),
                                    const Icon(
                                      Icons.calendar_today,
                                      size: 16,
                                      color: Colors.grey,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 2,
                            child: SizedBox(
                              height: 32,
                              child: TextField(
                                controller: _passportDepartmentCodeController,
                                onChanged: (_) => _checkForChanges(),
                                inputFormatters: [passportDepartmentCodeFormatter()],
                                style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
                                decoration: InputDecoration(
                                  hintText: 'Код подр.',
                                  isDense: true,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(6),
                                    borderSide: BorderSide(color: theme.colorScheme.outline.withValues(alpha: 0.5)),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(6),
                                    borderSide: BorderSide(color: theme.colorScheme.outline.withValues(alpha: 0.5)),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              _buildDivider(),
              EditableInlineTextRow(
                label: 'Кем выдан',
                value: _employee.passportIssuedBy?.isNotEmpty == true ? _employee.passportIssuedBy! : '—',
                isEditing: true,
                controller: _passportIssuedByController,
                hintText: 'Введите орган выдачи',
                onChanged: (_) => _checkForChanges(),
              ),
              _buildDivider(),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Expanded(
                      flex: 2,
                      child: Text(
                        'Рождение',
                        style: TextStyle(
                          color: Colors.grey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 5,
                      child: Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: InkWell(
                              onTap: () async {
                                final selected = await showDatePicker(
                                  context: context,
                                  initialDate: _birthDate ?? DateTime.now(),
                                  firstDate: DateTime(1900),
                                  lastDate: DateTime.now(),
                                );
                                if (selected != null) {
                                  setState(() => _birthDate = selected);
                                  _checkForChanges();
                                }
                              },
                              child: Container(
                                height: 32,
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: theme.colorScheme.outline.withValues(alpha: 0.5),
                                  ),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                alignment: Alignment.centerLeft,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      _birthDate != null ? formatRuDate(_birthDate!) : 'Дата рождения',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w500,
                                        fontSize: 14,
                                        color: _birthDate != null ? theme.colorScheme.onSurface : theme.colorScheme.onSurface.withValues(alpha: 0.6),
                                      ),
                                    ),
                                    const Icon(
                                      Icons.calendar_today,
                                      size: 16,
                                      color: Colors.grey,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 3,
                            child: SizedBox(
                              height: 32,
                              child: TextField(
                                controller: _birthPlaceController,
                                onChanged: (_) => _checkForChanges(),
                                style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
                                decoration: InputDecoration(
                                  hintText: 'Место рождения',
                                  isDense: true,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(6),
                                    borderSide: BorderSide(color: theme.colorScheme.outline.withValues(alpha: 0.5)),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(6),
                                    borderSide: BorderSide(color: theme.colorScheme.outline.withValues(alpha: 0.5)),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              _buildDivider(),
              EditableInlineTextRow(
                label: 'Адрес регистрации',
                value: _employee.registrationAddress?.isNotEmpty == true ? _employee.registrationAddress! : '—',
                isEditing: true,
                controller: _registrationAddressController,
                hintText: 'Введите адрес регистрации',
                onChanged: (_) => _checkForChanges(),
              ),
              _buildDivider(),
              EditableInlineTextRow(
                label: 'ИНН',
                value: _employee.inn?.isNotEmpty == true ? _employee.inn! : '—',
                isEditing: true,
                controller: _innController,
                hintText: 'Введите ИНН (12 цифр)',
                keyboardType: TextInputType.number,
                inputFormatters: [innFormatter()],
                onChanged: (_) => _checkForChanges(),
              ),
              _buildDivider(),
              EditableInlineTextRow(
                label: 'СНИЛС',
                value: _employee.snils?.isNotEmpty == true ? _employee.snils! : '—',
                isEditing: true,
                controller: _snilsController,
                hintText: 'XXX-XXX-XXX XX',
                keyboardType: TextInputType.number,
                inputFormatters: [snilsFormatter()],
                onChanged: (_) => _checkForChanges(),
              ),
              _buildDivider(),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Expanded(
                      flex: 2,
                      child: Text(
                        'Размеры',
                        style: TextStyle(
                          color: Colors.grey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 5,
                      child: Row(
                        children: [
                          Expanded(
                            child: SizedBox(
                              height: 32,
                              child: GTStringDropdown(
                                items: _clothingSizes,
                                selectedItem: _clothingSize,
                                onSelectionChanged: (v) {
                                  setState(() => _clothingSize = v);
                                  _checkForChanges();
                                },
                                labelText: '',
                                hintText: 'Одежда',
                                allowCustomInput: true,
                                showAddNewOption: true,
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                borderRadius: 6,
                                style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: SizedBox(
                              height: 32,
                              child: GTStringDropdown(
                                items: _shoeSizes,
                                selectedItem: _shoeSize,
                                onSelectionChanged: (v) {
                                  setState(() => _shoeSize = v);
                                  _checkForChanges();
                                },
                                labelText: '',
                                hintText: 'Обувь',
                                allowCustomInput: true,
                                showAddNewOption: true,
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                borderRadius: 6,
                                style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: SizedBox(
                              height: 32,
                              child: GTStringDropdown(
                                items: _heightRanges,
                                selectedItem: _height,
                                onSelectionChanged: (v) {
                                  setState(() => _height = v);
                                  _checkForChanges();
                                },
                                labelText: '',
                                hintText: 'Рост',
                                allowCustomInput: true,
                                showAddNewOption: true,
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                borderRadius: 6,
                                style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
