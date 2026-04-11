import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:projectgt/core/di/providers.dart';
import 'package:projectgt/core/utils/employee_ui_utils.dart';
import 'package:projectgt/core/utils/formatters.dart';
import 'package:projectgt/core/utils/snackbar_utils.dart';
import 'package:projectgt/core/widgets/gt_buttons.dart';
import 'package:projectgt/core/widgets/gt_dropdown.dart';
import 'package:projectgt/core/widgets/gt_text_field.dart';
import 'package:projectgt/core/widgets/mobile_bottom_sheet_content.dart';
import 'package:projectgt/domain/entities/employee.dart';
import 'package:projectgt/features/employees/presentation/widgets/employees_mobile_atmosphere.dart';
import 'package:projectgt/features/objects/domain/entities/object.dart';
import 'package:projectgt/presentation/state/employee_state.dart'
    as employee_state;

void _employeeMobileUnfocusInput() {
  FocusManager.instance.primaryFocus?.unfocus();
}

/// Сохраняет частичное обновление сотрудника поверх актуальной записи в [employeeProvider].
Future<bool> _persistEmployeeUpdate(
  WidgetRef ref,
  BuildContext context, {
  required String employeeId,
  required Employee Function(Employee latest) apply,
}) async {
  try {
    final latest = ref
        .read(employee_state.employeeProvider)
        .employees
        .where((e) => e.id == employeeId)
        .firstOrNull;
    if (latest == null) return false;
    final updated = apply(latest);
    await ref
        .read(employee_state.employeeProvider.notifier)
        .updateEmployee(updated);
    if (!context.mounted) return false;
    SnackBarUtils.showSuccess(context, 'Сохранено');
    return true;
  } catch (e) {
    if (context.mounted) {
      SnackBarUtils.showError(context, 'Ошибка при сохранении: $e');
    }
    return false;
  }
}

/// Редактирование карточки сотрудника на мобильном.
///
/// [showProfileEditor] — ФИО, работа и контакты; остальные методы — отдельные
/// листы с «Сохранить» / «Закрыть» (карандаш в заголовке секции карточки).
///
/// Сохранение всегда накладывается на актуальную запись из [employeeProvider].
class EmployeesMobileEmployeeEditBlocks {
  EmployeesMobileEmployeeEditBlocks._();

  /// Открывает bottom sheet с полями ФИО, должности, типа занятости, статуса,
  /// телефона, объектов и даты приёма.
  ///
  /// [objects] используется для подписей в множественном выборе объектов.
  /// [onSaved] вызывается после успешного сохранения, перед закрытием листа.
  static Future<void> showProfileEditor(
    BuildContext context, {
    required Employee employee,
    required List<ObjectEntity> objects,
    VoidCallback? onSaved,
  }) async {
    final screenWidth = MediaQuery.sizeOf(context).width;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      constraints: BoxConstraints(maxWidth: screenWidth),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return Consumer(
          builder: (_, ref, __) {
            final state = ref.watch(employee_state.employeeProvider);
            final emp =
                state.employees.where((e) => e.id == employee.id).firstOrNull ??
                employee;
            return _EmployeeMobileProfileEditorSheet(
              employee: emp,
              objects: objects,
              onSaved: onSaved,
            );
          },
        );
      },
    );
  }

  /// Открывает bottom sheet с полями блока «Документы» и одной кнопкой «Сохранить».
  static Future<void> showDocumentsEditor(
    BuildContext context, {
    required Employee employee,
    VoidCallback? onSaved,
  }) async {
    final screenWidth = MediaQuery.sizeOf(context).width;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      constraints: BoxConstraints(maxWidth: screenWidth),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return Consumer(
          builder: (_, ref, __) {
            final state = ref.watch(employee_state.employeeProvider);
            final emp =
                state.employees.where((e) => e.id == employee.id).firstOrNull ??
                employee;
            return _EmployeeMobileDocumentsEditorSheet(
              employee: emp,
              onSaved: onSaved,
            );
          },
        );
      },
    );
  }

  /// Открывает bottom sheet с полями блока «Личные данные» и одной кнопкой «Сохранить».
  static Future<void> showPersonalEditor(
    BuildContext context, {
    required Employee employee,
    VoidCallback? onSaved,
  }) async {
    final screenWidth = MediaQuery.sizeOf(context).width;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      constraints: BoxConstraints(maxWidth: screenWidth),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return Consumer(
          builder: (_, ref, __) {
            final state = ref.watch(employee_state.employeeProvider);
            final emp =
                state.employees.where((e) => e.id == employee.id).firstOrNull ??
                employee;
            return _EmployeeMobilePersonalEditorSheet(
              employee: emp,
              onSaved: onSaved,
            );
          },
        );
      },
    );
  }
}

class _EmployeeMobileProfileEditorSheet extends ConsumerStatefulWidget {
  const _EmployeeMobileProfileEditorSheet({
    required this.employee,
    required this.objects,
    this.onSaved,
  });

  final Employee employee;
  final List<ObjectEntity> objects;
  final VoidCallback? onSaved;

  @override
  ConsumerState<_EmployeeMobileProfileEditorSheet> createState() =>
      _EmployeeMobileProfileEditorSheetState();
}

class _EmployeeMobileProfileEditorSheetState
    extends ConsumerState<_EmployeeMobileProfileEditorSheet> {
  static const ObjectEntity _objectFallback = ObjectEntity(
    id: '',
    companyId: '',
    name: '—',
    address: '',
  );

  late final TextEditingController _lastNameController =
      TextEditingController();
  late final TextEditingController _firstNameController =
      TextEditingController();
  late final TextEditingController _middleNameController =
      TextEditingController();
  late final TextEditingController _positionController =
      TextEditingController();
  late final TextEditingController _phoneController = TextEditingController();

  EmployeeStatus? _status;
  EmploymentType? _employmentType;
  DateTime? _employmentDate;
  List<String> _objectIds = [];
  List<String> _positions = [];
  bool _positionsLoading = false;
  bool _loading = false;
  late Employee _baseline;

  @override
  void initState() {
    super.initState();
    _fillFrom(widget.employee);
    _loadPositions();
  }

  @override
  void didUpdateWidget(covariant _EmployeeMobileProfileEditorSheet oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.employee.id != oldWidget.employee.id) {
      _fillFrom(widget.employee);
    }
  }

  void _fillFrom(Employee e) {
    _baseline = e;
    _lastNameController.text = e.lastName;
    _firstNameController.text = e.firstName;
    _middleNameController.text = e.middleName ?? '';
    _positionController.text = e.position ?? '';
    _phoneController.text = e.phone ?? '';
    _status = e.status;
    _employmentType = e.employmentType;
    _employmentDate = e.employmentDate;
    _objectIds = List<String>.from(e.objectIds);
  }

  Future<void> _loadPositions() async {
    setState(() => _positionsLoading = true);
    try {
      final positions = await ref
          .read(employeeRepositoryProvider)
          .getPositions();
      if (mounted) {
        setState(() {
          _positions = positions;
          _positionsLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _positionsLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _lastNameController.dispose();
    _firstNameController.dispose();
    _middleNameController.dispose();
    _positionController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  bool _isStr(String? orig, String cur) => (orig?.trim() ?? '') != cur.trim();

  bool _listChanged(List<String> a, List<String> b) {
    if (a.length != b.length) return true;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return true;
    }
    return false;
  }

  bool get _dirty {
    final e = _baseline;
    return _isStr(e.lastName, _lastNameController.text) ||
        _isStr(e.firstName, _firstNameController.text) ||
        _isStr(e.middleName, _middleNameController.text) ||
        _isStr(e.position, _positionController.text) ||
        _isStr(e.phone, _phoneController.text) ||
        _status != e.status ||
        _employmentType != e.employmentType ||
        _employmentDate != e.employmentDate ||
        _listChanged(e.objectIds, _objectIds);
  }

  Future<void> _save() async {
    if (_lastNameController.text.trim().isEmpty ||
        _firstNameController.text.trim().isEmpty) {
      SnackBarUtils.showError(context, 'Укажите фамилию и имя');
      return;
    }
    setState(() => _loading = true);
    final ok = await _persistEmployeeUpdate(
      ref,
      context,
      employeeId: widget.employee.id,
      apply: (latest) => latest.copyWith(
        lastName: _lastNameController.text.trim(),
        firstName: _firstNameController.text.trim(),
        middleName: _middleNameController.text.trim().isEmpty
            ? null
            : _middleNameController.text.trim(),
        position: _positionController.text.trim().isEmpty
            ? null
            : _positionController.text.trim(),
        phone: _phoneController.text.trim().isEmpty
            ? null
            : _phoneController.text.trim(),
        status: _status ?? EmployeeStatus.working,
        employmentType: _employmentType ?? EmploymentType.official,
        employmentDate: _employmentDate,
        objectIds: _objectIds,
      ),
    );
    if (mounted) {
      setState(() => _loading = false);
      if (ok) {
        final synced = ref
            .read(employee_state.employeeProvider)
            .employees
            .where((e) => e.id == widget.employee.id)
            .firstOrNull;
        if (synced != null) {
          setState(() => _fillFrom(synced));
        }
        widget.onSaved?.call();
        Navigator.of(context).pop();
      }
    }
  }

  Widget _employmentDateField() {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Дата приёма',
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 6),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () async {
                final selected = await showDatePicker(
                  context: context,
                  initialDate: _employmentDate ?? DateTime.now(),
                  firstDate: DateTime(1900),
                  lastDate: DateTime(2100),
                );
                if (selected != null && mounted) {
                  setState(() => _employmentDate = selected);
                }
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: theme.colorScheme.outline.withValues(alpha: 0.25),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _employmentDate != null
                            ? formatRuDate(_employmentDate!)
                            : 'Не выбрано',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                          color: _employmentDate != null
                              ? theme.colorScheme.onSurface
                              : theme.colorScheme.onSurface.withValues(
                                  alpha: 0.5,
                                ),
                        ),
                      ),
                    ),
                    Icon(
                      Icons.calendar_today_outlined,
                      size: 18,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MobileBottomSheetContent(
      title: 'ФИО, работа и контакты',
      scrollable: true,
      sheetBackdrop: const EmployeesMobileAtmosphereBackdrop(),
      footer: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: GTSecondaryButton(
              text: 'Закрыть',
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: GTPrimaryButton(
              text: 'Сохранить',
              isLoading: _loading,
              onPressed: (_loading || !_dirty) ? null : _save,
            ),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            widget.employee.fullName,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          GTTextField(
            controller: _lastNameController,
            labelText: 'Фамилия',
            hintText: 'Фамилия',
            textCapitalization: TextCapitalization.words,
            borderRadius: 12,
            textInputAction: TextInputAction.next,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          GTTextField(
            controller: _firstNameController,
            labelText: 'Имя',
            hintText: 'Имя',
            textCapitalization: TextCapitalization.words,
            borderRadius: 12,
            textInputAction: TextInputAction.next,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          GTTextField(
            controller: _middleNameController,
            labelText: 'Отчество',
            hintText: 'Отчество',
            textCapitalization: TextCapitalization.words,
            borderRadius: 12,
            textInputAction: TextInputAction.next,
            onEditingComplete: _employeeMobileUnfocusInput,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 16),
          GTStringDropdown(
            items: _positions,
            selectedItem: _positionController.text.isEmpty
                ? null
                : _positionController.text,
            onSelectionChanged: (value) {
              setState(() {
                _positionController.text = value ?? '';
              });
            },
            labelText: 'Должность',
            hintText: 'Должность',
            allowCustomInput: true,
            showAddNewOption: true,
            isLoading: _positionsLoading,
            borderRadius: 12,
          ),
          const SizedBox(height: 12),
          GTEnumDropdown<EmploymentType>(
            values: EmploymentType.values,
            selectedValue: _employmentType,
            onChanged: (v) {
              setState(() => _employmentType = v);
            },
            enumToString: EmployeeUIUtils.getEmploymentTypeText,
            labelText: 'Тип занятости',
            hintText: 'Тип',
            borderRadius: 12,
          ),
          const SizedBox(height: 12),
          GTEnumDropdown<EmployeeStatus>(
            values: EmployeeStatus.values,
            selectedValue: _status,
            onChanged: (v) {
              setState(() => _status = v);
            },
            enumToString: (s) => EmployeeUIUtils.getStatusInfo(s).$1,
            labelText: 'Статус',
            hintText: 'Статус',
            borderRadius: 12,
          ),
          const SizedBox(height: 12),
          GTTextField(
            controller: _phoneController,
            labelText: 'Телефон',
            hintText: '+7 (___) ___ ____',
            keyboardType: TextInputType.phone,
            inputFormatters: [GtFormatters.phoneFormatter()],
            borderRadius: 12,
            textInputAction: TextInputAction.done,
            onEditingComplete: _employeeMobileUnfocusInput,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          GTDropdown<String>(
            items: widget.objects.map((e) => e.id).toList(),
            selectedItems: _objectIds,
            allowMultipleSelection: true,
            onMultiSelectionChanged: (items) {
              setState(() => _objectIds = items);
            },
            itemDisplayBuilder: (id) => widget.objects
                .firstWhere(
                  (o) => o.id == id,
                  orElse: () => _objectFallback,
                )
                .name,
            labelText: 'Объекты',
            hintText: 'Выберите объекты',
            borderRadius: 12,
          ),
          const SizedBox(height: 8),
          _employmentDateField(),
        ],
      ),
    );
  }
}

// --- Отдельные листы «Документы» и «Личные данные» (кнопка в заголовке секции карточки) ---

class _EmployeeMobileDocumentsEditorSheet extends ConsumerStatefulWidget {
  const _EmployeeMobileDocumentsEditorSheet({
    required this.employee,
    this.onSaved,
  });

  final Employee employee;
  final VoidCallback? onSaved;

  @override
  ConsumerState<_EmployeeMobileDocumentsEditorSheet> createState() =>
      _EmployeeMobileDocumentsEditorSheetState();
}

class _EmployeeMobileDocumentsEditorSheetState
    extends ConsumerState<_EmployeeMobileDocumentsEditorSheet> {
  late final TextEditingController _passportSeriesController =
      TextEditingController();
  late final TextEditingController _passportNumberController =
      TextEditingController();
  late final TextEditingController _passportIssuedByController =
      TextEditingController();
  late final TextEditingController _passportDepartmentCodeController =
      TextEditingController();
  late final TextEditingController _registrationAddressController =
      TextEditingController();
  late final TextEditingController _innController = TextEditingController();
  late final TextEditingController _snilsController = TextEditingController();
  DateTime? _passportIssueDate;
  bool _loading = false;
  late Employee _baseline;

  @override
  void initState() {
    super.initState();
    _fillFrom(widget.employee);
  }

  @override
  void didUpdateWidget(
    covariant _EmployeeMobileDocumentsEditorSheet oldWidget,
  ) {
    super.didUpdateWidget(oldWidget);
    if (widget.employee.id != oldWidget.employee.id) {
      _fillFrom(widget.employee);
    }
  }

  void _fillFrom(Employee e) {
    _baseline = e;
    _passportSeriesController.text = e.passportSeries ?? '';
    _passportNumberController.text = e.passportNumber ?? '';
    _passportIssuedByController.text = e.passportIssuedBy ?? '';
    _passportDepartmentCodeController.text = e.passportDepartmentCode == null
        ? ''
        : GtFormatters.formatPassportDepartmentCode(e.passportDepartmentCode);
    _registrationAddressController.text = e.registrationAddress ?? '';
    _innController.text = e.inn ?? '';
    _snilsController.text = e.snils ?? '';
    _passportIssueDate = e.passportIssueDate;
  }

  @override
  void dispose() {
    _passportSeriesController.dispose();
    _passportNumberController.dispose();
    _passportIssuedByController.dispose();
    _passportDepartmentCodeController.dispose();
    _registrationAddressController.dispose();
    _innController.dispose();
    _snilsController.dispose();
    super.dispose();
  }

  bool _digitsChanged(String? a, String b) {
    final o = a?.replaceAll(RegExp(r'\D'), '') ?? '';
    final c = b.replaceAll(RegExp(r'\D'), '');
    return o != c;
  }

  bool get _dirty {
    final e = _baseline;
    return _isStr(e.passportSeries, _passportSeriesController.text) ||
        _isStr(e.passportNumber, _passportNumberController.text) ||
        _isStr(e.passportIssuedBy, _passportIssuedByController.text) ||
        _passportIssueDate != e.passportIssueDate ||
        _digitsChanged(
          e.passportDepartmentCode,
          _passportDepartmentCodeController.text,
        ) ||
        _isStr(e.registrationAddress, _registrationAddressController.text) ||
        _digitsChanged(e.inn, _innController.text) ||
        _digitsChanged(e.snils, _snilsController.text);
  }

  bool _isStr(String? orig, String cur) => (orig?.trim() ?? '') != cur.trim();

  Future<void> _save() async {
    setState(() => _loading = true);
    final ok = await _persistEmployeeUpdate(
      ref,
      context,
      employeeId: widget.employee.id,
      apply: (latest) {
        final codeRaw = _passportDepartmentCodeController.text.replaceAll(
          RegExp(r'\D'),
          '',
        );
        final innRaw = _innController.text.replaceAll(RegExp(r'\D'), '');
        final snilsRaw = _snilsController.text.replaceAll(RegExp(r'\D'), '');
        return latest.copyWith(
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
          passportDepartmentCode: codeRaw.trim().isEmpty
              ? null
              : codeRaw.trim(),
          registrationAddress:
              _registrationAddressController.text.trim().isEmpty
              ? null
              : _registrationAddressController.text.trim(),
          inn: innRaw.trim().isEmpty ? null : innRaw.trim(),
          snils: snilsRaw.trim().isEmpty ? null : snilsRaw.trim(),
        );
      },
    );
    if (mounted) {
      setState(() => _loading = false);
      if (ok) {
        final synced = ref
            .read(employee_state.employeeProvider)
            .employees
            .where((e) => e.id == widget.employee.id)
            .firstOrNull;
        if (synced != null) {
          setState(() => _fillFrom(synced));
        }
        widget.onSaved?.call();
        Navigator.of(context).pop();
      }
    }
  }

  Widget _dateField({
    required String label,
    required DateTime? value,
    required Future<void> Function() onPick,
  }) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 6),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onPick,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: theme.colorScheme.outline.withValues(alpha: 0.25),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        value != null ? formatRuDate(value) : 'Не выбрано',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                          color: value != null
                              ? theme.colorScheme.onSurface
                              : theme.colorScheme.onSurface.withValues(
                                  alpha: 0.5,
                                ),
                        ),
                      ),
                    ),
                    Icon(
                      Icons.calendar_today_outlined,
                      size: 18,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MobileBottomSheetContent(
      title: 'Документы',
      scrollable: true,
      sheetBackdrop: const EmployeesMobileAtmosphereBackdrop(),
      footer: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: GTSecondaryButton(
              text: 'Закрыть',
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: GTPrimaryButton(
              text: 'Сохранить',
              isLoading: _loading,
              onPressed: (_loading || !_dirty) ? null : _save,
            ),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            widget.employee.fullName,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          GTTextField(
            controller: _passportSeriesController,
            labelText: 'Серия паспорта',
            hintText: 'Серия',
            borderRadius: 12,
            textInputAction: TextInputAction.done,
            onEditingComplete: _employeeMobileUnfocusInput,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          GTTextField(
            controller: _passportNumberController,
            labelText: 'Номер паспорта',
            hintText: 'Номер',
            borderRadius: 12,
            textInputAction: TextInputAction.done,
            onEditingComplete: _employeeMobileUnfocusInput,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          GTTextField(
            controller: _passportIssuedByController,
            labelText: 'Кем выдан',
            hintText: 'Орган выдачи',
            borderRadius: 12,
            textInputAction: TextInputAction.done,
            onEditingComplete: _employeeMobileUnfocusInput,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 8),
          _dateField(
            label: 'Дата выдачи',
            value: _passportIssueDate,
            onPick: () async {
              final selected = await showDatePicker(
                context: context,
                initialDate: _passportIssueDate ?? DateTime.now(),
                firstDate: DateTime(1900),
                lastDate: DateTime.now(),
              );
              if (selected != null && mounted) {
                setState(() => _passportIssueDate = selected);
              }
            },
          ),
          GTTextField(
            controller: _passportDepartmentCodeController,
            labelText: 'Код подразделения',
            hintText: '000-000',
            inputFormatters: [passportDepartmentCodeFormatter()],
            borderRadius: 12,
            textInputAction: TextInputAction.done,
            onEditingComplete: _employeeMobileUnfocusInput,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          GTTextField(
            controller: _registrationAddressController,
            labelText: 'Адрес регистрации',
            hintText: 'Адрес',
            maxLines: 2,
            borderRadius: 12,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          GTTextField(
            controller: _innController,
            labelText: 'ИНН',
            hintText: '12 цифр',
            keyboardType: TextInputType.number,
            inputFormatters: [innFormatter()],
            borderRadius: 12,
            textInputAction: TextInputAction.done,
            onEditingComplete: _employeeMobileUnfocusInput,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          GTTextField(
            controller: _snilsController,
            labelText: 'СНИЛС',
            hintText: 'XXX-XXX-XXX XX',
            keyboardType: TextInputType.number,
            inputFormatters: [snilsFormatter()],
            borderRadius: 12,
            textInputAction: TextInputAction.done,
            onEditingComplete: _employeeMobileUnfocusInput,
            onChanged: (_) => setState(() {}),
          ),
        ],
      ),
    );
  }
}

class _EmployeeMobilePersonalEditorSheet extends ConsumerStatefulWidget {
  const _EmployeeMobilePersonalEditorSheet({
    required this.employee,
    this.onSaved,
  });

  final Employee employee;
  final VoidCallback? onSaved;

  @override
  ConsumerState<_EmployeeMobilePersonalEditorSheet> createState() =>
      _EmployeeMobilePersonalEditorSheetState();
}

class _EmployeeMobilePersonalEditorSheetState
    extends ConsumerState<_EmployeeMobilePersonalEditorSheet> {
  late final TextEditingController _birthPlaceController =
      TextEditingController();
  late final TextEditingController _citizenshipController =
      TextEditingController();

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

  DateTime? _birthDate;
  String? _clothingSize;
  String? _shoeSize;
  String? _height;
  bool _loading = false;
  late Employee _baseline;

  @override
  void initState() {
    super.initState();
    _fillFrom(widget.employee);
  }

  @override
  void didUpdateWidget(covariant _EmployeeMobilePersonalEditorSheet oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.employee.id != oldWidget.employee.id) {
      _fillFrom(widget.employee);
    }
  }

  void _fillFrom(Employee e) {
    _baseline = e;
    _birthPlaceController.text = e.birthPlace ?? '';
    _citizenshipController.text = e.citizenship ?? '';
    _birthDate = e.birthDate;
    _clothingSize = e.clothingSize;
    _shoeSize = e.shoeSize;
    _height = e.height;
  }

  @override
  void dispose() {
    _birthPlaceController.dispose();
    _citizenshipController.dispose();
    super.dispose();
  }

  bool get _dirty {
    final e = _baseline;
    return _birthDate != e.birthDate ||
        _isStr(e.birthPlace, _birthPlaceController.text) ||
        _isStr(e.citizenship, _citizenshipController.text) ||
        _clothingSize != e.clothingSize ||
        _shoeSize != e.shoeSize ||
        _height != e.height;
  }

  bool _isStr(String? orig, String cur) => (orig?.trim() ?? '') != cur.trim();

  Future<void> _save() async {
    setState(() => _loading = true);
    final ok = await _persistEmployeeUpdate(
      ref,
      context,
      employeeId: widget.employee.id,
      apply: (latest) => latest.copyWith(
        birthDate: _birthDate,
        birthPlace: _birthPlaceController.text.trim().isEmpty
            ? null
            : _birthPlaceController.text.trim(),
        citizenship: _citizenshipController.text.trim().isEmpty
            ? null
            : _citizenshipController.text.trim(),
        clothingSize: _clothingSize,
        shoeSize: _shoeSize,
        height: _height,
      ),
    );
    if (mounted) {
      setState(() => _loading = false);
      if (ok) {
        final synced = ref
            .read(employee_state.employeeProvider)
            .employees
            .where((e) => e.id == widget.employee.id)
            .firstOrNull;
        if (synced != null) {
          setState(() => _fillFrom(synced));
        }
        widget.onSaved?.call();
        Navigator.of(context).pop();
      }
    }
  }

  Widget _dateField({
    required String label,
    required DateTime? value,
    required Future<void> Function() onPick,
  }) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 6),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onPick,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: theme.colorScheme.outline.withValues(alpha: 0.25),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        value != null ? formatRuDate(value) : 'Не выбрано',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                          color: value != null
                              ? theme.colorScheme.onSurface
                              : theme.colorScheme.onSurface.withValues(
                                  alpha: 0.5,
                                ),
                        ),
                      ),
                    ),
                    Icon(
                      Icons.calendar_today_outlined,
                      size: 18,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MobileBottomSheetContent(
      title: 'Личные данные',
      scrollable: true,
      sheetBackdrop: const EmployeesMobileAtmosphereBackdrop(),
      footer: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: GTSecondaryButton(
              text: 'Закрыть',
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: GTPrimaryButton(
              text: 'Сохранить',
              isLoading: _loading,
              onPressed: (_loading || !_dirty) ? null : _save,
            ),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            widget.employee.fullName,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          _dateField(
            label: 'Дата рождения',
            value: _birthDate,
            onPick: () async {
              final selected = await showDatePicker(
                context: context,
                initialDate: _birthDate ?? DateTime.now(),
                firstDate: DateTime(1900),
                lastDate: DateTime.now(),
              );
              if (selected != null && mounted) {
                setState(() => _birthDate = selected);
              }
            },
          ),
          GTTextField(
            controller: _birthPlaceController,
            labelText: 'Место рождения',
            hintText: 'Место рождения',
            borderRadius: 12,
            textInputAction: TextInputAction.done,
            onEditingComplete: _employeeMobileUnfocusInput,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          GTTextField(
            controller: _citizenshipController,
            labelText: 'Гражданство',
            hintText: 'Гражданство',
            borderRadius: 12,
            textInputAction: TextInputAction.done,
            onEditingComplete: _employeeMobileUnfocusInput,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          GTStringDropdown(
            items: _clothingSizes,
            selectedItem: _clothingSize,
            onSelectionChanged: (v) {
              setState(() => _clothingSize = v);
            },
            labelText: 'Размер одежды',
            hintText: 'Размер одежды',
            allowCustomInput: true,
            showAddNewOption: true,
            borderRadius: 12,
          ),
          const SizedBox(height: 12),
          GTStringDropdown(
            items: _shoeSizes,
            selectedItem: _shoeSize,
            onSelectionChanged: (v) {
              setState(() => _shoeSize = v);
            },
            labelText: 'Размер обуви',
            hintText: 'Размер обуви',
            allowCustomInput: true,
            showAddNewOption: true,
            borderRadius: 12,
          ),
          const SizedBox(height: 12),
          GTStringDropdown(
            items: _heightRanges,
            selectedItem: _height,
            onSelectionChanged: (v) {
              setState(() => _height = v);
            },
            labelText: 'Рост (см)',
            hintText: 'Диапазон роста',
            allowCustomInput: true,
            showAddNewOption: true,
            borderRadius: 12,
          ),
        ],
      ),
    );
  }
}
